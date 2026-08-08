import 'package:flutter/material.dart';

/// How loudly a thing asks to be seen.
///
/// The raw values are the ones the Swift app writes — `Priority` in
/// `Features/Db/Sources/Schema.swift` — so a database written by either app
/// reads the same.
enum Priority {
  low(1),
  medium(2),
  high(3);

  const Priority(this.rawValue);

  final int rawValue;

  static Priority? fromRaw(Object? raw) {
    if (raw is! int) return null;
    for (final priority in Priority.values) {
      if (priority.rawValue == raw) return priority;
    }
    return null;
  }
}

/// A colour as the database keeps it: one integer, `0xRRGGBBAA`.
///
/// Mirrors `Color.HexRepresentation` on the Swift side, alpha last, so the two
/// apps agree on what a stored colour means.
int colorToHex(Color color) {
  int channel(double value) => (value * 0xFF).round().clamp(0, 0xFF);
  return channel(color.r) << 24 |
      channel(color.g) << 16 |
      channel(color.b) << 8 |
      channel(color.a);
}

Color colorFromHex(int hex) => Color.fromARGB(
  hex & 0xFF,
  (hex >> 24) & 0xFF,
  (hex >> 16) & 0xFF,
  (hex >> 8) & 0xFF,
);

/// A request the user brings to their practice.
///
/// It stands on its own, or it is broken down into [Subrequest]s that pave the
/// way to it. Table `requestsLists`.
@immutable
class RequestsList {
  const RequestsList({
    required this.id,
    required this.color,
    this.position = 0,
    this.title = '',
    this.description = '',
    this.isCompleted = false,
    this.priority,
    this.dueDate,
    this.notes = '',
  });

  final String id;
  final Color color;
  final int position;
  final String title;
  final String description;
  final bool isCompleted;
  final Priority? priority;
  final DateTime? dueDate;
  final String notes;

  RequestsList copyWith({
    Color? color,
    int? position,
    String? title,
    String? description,
    bool? isCompleted,
    Priority? priority,
    bool clearPriority = false,
    DateTime? dueDate,
    bool clearDueDate = false,
    String? notes,
  }) => RequestsList(
    id: id,
    color: color ?? this.color,
    position: position ?? this.position,
    title: title ?? this.title,
    description: description ?? this.description,
    isCompleted: isCompleted ?? this.isCompleted,
    priority: clearPriority ? null : (priority ?? this.priority),
    dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
    notes: notes ?? this.notes,
  );

  Map<String, Object?> toRow() => {
    'id': id,
    'color': colorToHex(color),
    'position': position,
    'title': title,
    'description': description,
    'isCompleted': isCompleted ? 1 : 0,
    'priority': priority?.rawValue,
    'dueDate': encodeDate(dueDate),
    'notes': notes,
  };

  static RequestsList fromRow(Map<String, Object?> row) => RequestsList(
    id: row['id']! as String,
    color: colorFromHex(row['color']! as int),
    position: row['position']! as int,
    title: (row['title'] as String?) ?? '',
    description: (row['description'] as String?) ?? '',
    isCompleted: (row['isCompleted'] as int? ?? 0) != 0,
    priority: Priority.fromRaw(row['priority']),
    dueDate: decodeDate(row['dueDate'] as String?),
    notes: (row['notes'] as String?) ?? '',
  );
}

/// A step that has to be fulfilled before its [RequestsList] request can be.
///
/// This is the Swift app's `Request` — table `requests`. It has no priority of
/// its own, and no date of its own either: [dueDate] is a copy of the date of
/// the request it serves, kept in step by the repository and never shown or
/// edited on the subrequest itself.
@immutable
class Subrequest {
  const Subrequest({
    required this.id,
    required this.requestsListId,
    this.dueDate,
    this.isCompleted = false,
    this.notes = '',
    this.position = 0,
    this.title = '',
  });

  final String id;
  final String requestsListId;
  final DateTime? dueDate;
  final bool isCompleted;
  final String notes;
  final int position;
  final String title;

  Subrequest copyWith({
    String? requestsListId,
    DateTime? dueDate,
    bool clearDueDate = false,
    bool? isCompleted,
    String? notes,
    int? position,
    String? title,
  }) => Subrequest(
    id: id,
    requestsListId: requestsListId ?? this.requestsListId,
    dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
    isCompleted: isCompleted ?? this.isCompleted,
    notes: notes ?? this.notes,
    position: position ?? this.position,
    title: title ?? this.title,
  );

  Map<String, Object?> toRow() => {
    'id': id,
    'dueDate': encodeDate(dueDate),
    'isCompleted': isCompleted ? 1 : 0,
    'notes': notes,
    'position': position,
    'requestsListID': requestsListId,
    'title': title,
  };

  static Subrequest fromRow(Map<String, Object?> row) => Subrequest(
    id: row['id']! as String,
    requestsListId: row['requestsListID']! as String,
    dueDate: decodeDate(row['dueDate'] as String?),
    isCompleted: (row['isCompleted'] as int? ?? 0) != 0,
    notes: (row['notes'] as String?) ?? '',
    position: row['position']! as int,
    title: (row['title'] as String?) ?? '',
  );
}

/// A topic reminders live in. Table `remindersLists`.
@immutable
class RemindersList {
  const RemindersList({
    required this.id,
    required this.color,
    this.position = 0,
    this.title = '',
  });

  final String id;
  final Color color;
  final int position;
  final String title;

  RemindersList copyWith({Color? color, int? position, String? title}) =>
      RemindersList(
        id: id,
        color: color ?? this.color,
        position: position ?? this.position,
        title: title ?? this.title,
      );

  Map<String, Object?> toRow() => {
    'id': id,
    'color': colorToHex(color),
    'position': position,
    'title': title,
  };

  static RemindersList fromRow(Map<String, Object?> row) => RemindersList(
    id: row['id']! as String,
    color: colorFromHex(row['color']! as int),
    position: row['position']! as int,
    title: (row['title'] as String?) ?? '',
  );
}

/// One reminder inside a [RemindersList] topic. Table `reminders`.
@immutable
class Reminder {
  const Reminder({
    required this.id,
    required this.remindersListId,
    this.dueDate,
    this.isCompleted = false,
    this.isFlagged = false,
    this.notes = '',
    this.position = 0,
    this.priority,
    this.title = '',
  });

  final String id;
  final String remindersListId;
  final DateTime? dueDate;
  final bool isCompleted;
  final bool isFlagged;
  final String notes;
  final int position;
  final Priority? priority;
  final String title;

  Reminder copyWith({
    String? remindersListId,
    DateTime? dueDate,
    bool clearDueDate = false,
    bool? isCompleted,
    bool? isFlagged,
    String? notes,
    int? position,
    Priority? priority,
    bool clearPriority = false,
    String? title,
  }) => Reminder(
    id: id,
    remindersListId: remindersListId ?? this.remindersListId,
    dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
    isCompleted: isCompleted ?? this.isCompleted,
    isFlagged: isFlagged ?? this.isFlagged,
    notes: notes ?? this.notes,
    position: position ?? this.position,
    priority: clearPriority ? null : (priority ?? this.priority),
    title: title ?? this.title,
  );

  Map<String, Object?> toRow() => {
    'id': id,
    'dueDate': encodeDate(dueDate),
    'isCompleted': isCompleted ? 1 : 0,
    'isFlagged': isFlagged ? 1 : 0,
    'notes': notes,
    'position': position,
    'priority': priority?.rawValue,
    'remindersListID': remindersListId,
    'title': title,
  };

  static Reminder fromRow(Map<String, Object?> row) => Reminder(
    id: row['id']! as String,
    remindersListId: row['remindersListID']! as String,
    dueDate: decodeDate(row['dueDate'] as String?),
    isCompleted: (row['isCompleted'] as int? ?? 0) != 0,
    isFlagged: (row['isFlagged'] as int? ?? 0) != 0,
    notes: (row['notes'] as String?) ?? '',
    position: row['position']! as int,
    priority: Priority.fromRaw(row['priority']),
    title: (row['title'] as String?) ?? '',
  );
}

/// How many subrequests a request has, and how many of them are already
/// fulfilled.
///
/// A request without subrequests counts as fully covered — [allCompleted] is
/// `true` — so it can be fulfilled at any moment.
@immutable
class SubrequestProgress {
  const SubrequestProgress({this.total = 0, this.completed = 0});

  final int total;
  final int completed;

  bool get hasSubrequests => total > 0;
  bool get allCompleted => completed == total;
}

/// The date format GRDB writes and reads — UTC, to the millisecond.
///
/// Kept byte for byte so `date(dueDate)` in SQL and a database carried over
/// from the Swift app both still mean what they meant there.
String? encodeDate(DateTime? date) {
  if (date == null) return null;
  final utc = date.toUtc();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${utc.year.toString().padLeft(4, '0')}-${two(utc.month)}-${two(utc.day)} '
      '${two(utc.hour)}:${two(utc.minute)}:${two(utc.second)}.'
      '${utc.millisecond.toString().padLeft(3, '0')}';
}

DateTime? decodeDate(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  return DateTime.parse('${raw.replaceFirst(' ', 'T')}Z').toLocal();
}
