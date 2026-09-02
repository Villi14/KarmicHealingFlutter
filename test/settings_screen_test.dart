import 'package:flutter_test/flutter_test.dart';
import 'package:karmic_healing_flutter/data/app_lock.dart';
import 'package:karmic_healing_flutter/screens/settings/settings_actions.dart';
import 'package:karmic_healing_flutter/screens/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_app.dart';
import 'support/test_app_lock.dart';

/// The outside world, written down instead of opened: whatever the screen asks
/// for lands in a list the test can read back.
class RecordingActions extends SettingsActions {
  RecordingActions({this.version = '1.2.3 (4)', this.mailAppAnswers = true});

  final String version;

  /// Whether a mail app takes the `mailto:` handed to it. A phone with no mail
  /// account set up answers no, and the screen falls back to the address.
  final bool mailAppAnswers;

  final List<Uri> opened = [];
  final List<String> copied = [];
  int systemSettingsOpened = 0;

  @override
  Future<String> appVersion() async => version;

  @override
  Future<bool> openUrl(Uri url) async {
    opened.add(url);
    return url.scheme == 'mailto' ? mailAppAnswers : true;
  }

  @override
  Future<void> openSystemSettings() async => systemSettingsOpened++;

  @override
  Future<void> copyToClipboard(String text) async => copied.add(text);
}

void main() {
  // Loaded in `setUp` rather than in a test body: that body runs in a fake-async
  // zone, and the read of the stored settings started there never completes.
  late AppLockSettings appLock;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    appLock = await testAppLock();
  });

  Future<RecordingActions> openSettings(
    WidgetTester tester, {
    bool mailAppAnswers = true,
  }) async {
    final actions = RecordingActions(mailAppAnswers: mailAppAnswers);
    await tester.pumpWidget(
      testApp(home: SettingsScreen(actions: actions), appLock: appLock),
    );
    await tester.pumpAndSettle();
    return actions;
  }

  testWidgets('About names the version the bundle actually is', (tester) async {
    await openSettings(tester);

    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();

    expect(find.text('Version 1.2.3 (4)'), findsNothing);
    expect(
      find.textContaining('Version 1.2.3 (4)'),
      findsOneWidget,
      reason: 'the version sits under the thanks, in the same paragraph',
    );
  });

  testWidgets('About sends a curious reader to the author', (tester) async {
    final actions = await openSettings(tester);

    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Author's website"));
    await tester.pumpAndSettle();

    expect(actions.opened, [SettingsScreen.authorSite]);
  });

  testWidgets('changing the language leaves for the system settings', (
    tester,
  ) async {
    final actions = await openSettings(tester);

    await tester.tap(find.text('Change Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open Settings'));
    await tester.pumpAndSettle();

    expect(actions.systemSettingsOpened, 1);
  });

  testWidgets('writing to us opens a mail app addressed to us', (tester) async {
    final actions = await openSettings(tester);

    await tester.tap(find.text('Write to us'));
    await tester.pumpAndSettle();

    expect(actions.opened.single.scheme, 'mailto');
    expect(actions.opened.single.path, SettingsScreen.contactEmail);
    // Nothing to fall back to: the mail app took it.
    expect(find.text('Copy to Clipboard'), findsNothing);
  });

  testWidgets('a phone with no mail app is offered the address instead', (
    tester,
  ) async {
    final actions = await openSettings(tester, mailAppAnswers: false);

    await tester.tap(find.text('Write to us'));
    await tester.pumpAndSettle();
    expect(find.textContaining(SettingsScreen.contactEmail), findsOneWidget);

    await tester.tap(find.text('Copy to Clipboard'));
    await tester.pumpAndSettle();

    expect(actions.copied, [SettingsScreen.contactEmail]);
  });
}
