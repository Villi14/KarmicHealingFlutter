import 'package:flutter/material.dart';

import 'app_database.dart';
import 'reminders_repository.dart';
import 'requests_repository.dart';

/// The two repositories, handed down the tree.
///
/// They are plain [ChangeNotifier]s, so a screen that wants to follow one wraps
/// what it draws in a [ListenableBuilder] — the same shape `ThemeController`
/// already uses for the appearance.
class RepositoryScope extends InheritedWidget {
  const RepositoryScope({
    super.key,
    required this.requests,
    required this.reminders,
    required super.child,
  });

  final RequestsRepository requests;
  final RemindersRepository reminders;

  static RepositoryScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<RepositoryScope>();
    assert(scope != null, 'No RepositoryScope above this widget');
    return scope!;
  }

  static RequestsRepository requestsOf(BuildContext context) =>
      of(context).requests;

  static RemindersRepository remindersOf(BuildContext context) =>
      of(context).reminders;

  @override
  bool updateShouldNotify(RepositoryScope oldWidget) =>
      requests != oldWidget.requests || reminders != oldWidget.reminders;
}

/// Opens the store and loads both repositories once, at launch.
Future<({RequestsRepository requests, RemindersRepository reminders})>
loadRepositories({AppDatabase? database}) async {
  final store = database ?? await AppDatabase.open();
  final requests = RequestsRepository(store);
  final reminders = RemindersRepository(store);
  await requests.load();
  await reminders.load();
  return (requests: requests, reminders: reminders);
}
