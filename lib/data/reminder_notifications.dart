import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

// A reminder's own `Priority` would collide with the plugin's; only the model
// is wanted here.
import 'models.dart' hide Priority;

/// Where a reminder's due date turns into a notification.
///
/// The repository knows only this much of it, so a test — or a QA run, which
/// must not put anything in the notification tray — can hand it one that does
/// nothing at all.
abstract class ReminderScheduler {
  const ReminderScheduler();

  /// Replaces everything pending with what [reminders] now asks for.
  ///
  /// The repository calls this after each write, so a reminder that was
  /// fulfilled, moved, retitled or deleted falls out of the tray by the same
  /// path it fell out of the store.
  Future<void> sync(List<Reminder> reminders);
}

/// The scheduler a test gets: it accepts everything and remembers nothing.
class NoReminderScheduler extends ReminderScheduler {
  const NoReminderScheduler();

  @override
  Future<void> sync(List<Reminder> reminders) async {}
}

/// Schedules the reminders the device should speak up about.
class LocalReminderScheduler extends ReminderScheduler {
  LocalReminderScheduler._(this._plugin, this.launchReminderId);

  final FlutterLocalNotificationsPlugin _plugin;

  /// The reminder whose notification started the app, if one did.
  ///
  /// A tap that wakes a running app comes back through `onOpened`, but a tap on
  /// a app that was not running arrives as a launch detail instead, before
  /// there is any tree to show it in — so it is handed over rather than acted
  /// on here.
  final String? launchReminderId;

  /// iOS keeps at most 64 pending notifications and drops the rest without
  /// saying so, so only the soonest are scheduled. The ones beyond that are
  /// picked up by a later sync, long before their own date arrives.
  static const _pendingLimit = 60;

  /// The channel Android files these under, and the category iOS groups them
  /// by — the same name the Swift app uses, so a device that has both sees one
  /// kind of reminder rather than two.
  static const _channelId = 'REMINDER';

  /// Starts the plugin and points the local timezone at wherever the device
  /// actually is — a due date means the user's own clock.
  ///
  /// Permission is not asked for here: that question waits for
  /// [requestPermission], so the app is on screen behind it rather than a blank
  /// window the user has to answer their way past.
  ///
  /// [onOpened] is handed the id of the reminder whose notification was tapped.
  static Future<LocalReminderScheduler> start({
    required String channelName,
    void Function(String reminderId)? onOpened,
  }) async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(
      tz.getLocation((await FlutterTimezone.getLocalTimezone()).identifier),
    );

    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Permission is asked for below instead, once, rather than in the
        // middle of the first frame.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final reminderId = response.payload;
        if (reminderId != null && reminderId.isNotEmpty) {
          onOpened?.call(reminderId);
        }
      },
    );

    await plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          AndroidNotificationChannel(
            _channelId,
            channelName,
            importance: Importance.high,
          ),
        );

    final launch = await plugin.getNotificationAppLaunchDetails();
    return LocalReminderScheduler._(
      plugin,
      launch?.didNotificationLaunchApp == true
          ? launch?.notificationResponse?.payload
          : null,
    );
  }

  /// Asks the device for leave to speak up.
  ///
  /// Asked once a frame is on screen, and asked again on every launch until it
  /// is answered — the platforms only put the question to the user the first
  /// time, so a later call to a device that has made up its mind costs nothing.
  Future<void> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      await android.requestNotificationsPermission();
      // An exact alarm is what lands a reminder on its own minute rather than
      // whenever the system next feels like waking up.
      await android.requestExactAlarmsPermission();
      return;
    }

    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  @override
  Future<void> sync(List<Reminder> reminders) async {
    // Everything pending is dropped and rebuilt rather than reconciled: the
    // store is small, and this way there is one path a reminder can take out of
    // the tray, whichever way it left the store.
    await _plugin.cancelAll();

    for (final entry in pending(reminders, now: DateTime.now())) {
      await _schedule(entry.reminder, entry.at);
    }
  }

  /// The reminders worth putting in the tray, soonest first.
  ///
  /// What is fulfilled, undated, or already past says nothing to anyone, so it
  /// is left out; the tail beyond [_pendingLimit] waits for a later sync, which
  /// comes round long before its own date does.
  @visibleForTesting
  static List<({Reminder reminder, tz.TZDateTime at})> pending(
    List<Reminder> reminders, {
    required DateTime now,
  }) {
    final entries =
        reminders
            .where((r) => !r.isCompleted && r.dueDate != null)
            .map((r) => (reminder: r, at: _localise(r.dueDate!)))
            .where((entry) => entry.at.isAfter(_localise(now)))
            .toList()
          ..sort((a, b) => a.at.compareTo(b.at));

    return entries.take(_pendingLimit).toList();
  }

  Future<void> _schedule(Reminder reminder, tz.TZDateTime at) async {
    try {
      await _plugin.zonedSchedule(
        id: notificationIdOf(reminder.id),
        title: reminder.title,
        body: reminder.notes.isEmpty ? null : reminder.notes,
        payload: reminder.id,
        scheduledDate: at,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelId,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(categoryIdentifier: _channelId),
        ),
      );
    } on PlatformException catch (error) {
      // Android can refuse an exact alarm outright — the user may have turned
      // that permission down. One reminder going unscheduled must not stop the
      // rest, and it is offered again on the next sync.
      debugPrint(
        'Could not schedule reminder ${reminder.id}: ${error.message}',
      );
    }
  }

  /// A due date is stored in UTC but meant in the user's own day, so it is read
  /// back at the wall-clock time it was set to.
  static tz.TZDateTime _localise(DateTime dueDate) {
    final local = dueDate.toLocal();
    return tz.TZDateTime(
      tz.local,
      local.year,
      local.month,
      local.day,
      local.hour,
      local.minute,
      local.second,
    );
  }

  /// A notification is addressed by number while a reminder is addressed by
  /// uuid, so the id is folded down to a positive 31-bit one — the same uuid
  /// always giving the same number, whatever run asks for it.
  @visibleForTesting
  static int notificationIdOf(String reminderId) {
    var hash = 0x811c9dc5;
    for (final unit in reminderId.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
