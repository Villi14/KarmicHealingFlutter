import 'package:flutter/material.dart';

import 'models.dart';
import 'reminders_repository.dart';
import 'requests_repository.dart';

/// The rows the QA screens and the debug menu fill an empty store with.
///
/// A port of `Features/Db/Sources/SeedSampleData.swift`, dates and all, so a
/// screenshot taken here can be held against one taken there.
const _blue = Color(0xFF4A99EF);
const _amber = Color(0xFFED8935);
const _violet = Color(0xFFB25DD3);

Future<void> seedSampleData(
  RequestsRepository requests,
  RemindersRepository reminders,
) async {
  await _seedRequests(requests);
  await _seedReminders(reminders);
}

Future<void> _seedRequests(RequestsRepository repository) async {
  final personal = repository
      .draftRequest(_blue)
      .copyWith(title: 'Personal Request');
  final family = repository
      .draftRequest(_amber)
      .copyWith(title: 'Family Request');
  final business = repository
      .draftRequest(_violet)
      .copyWith(title: 'Business Request');

  for (final request in [personal, family, business]) {
    await repository.saveRequest(request);
  }

  Future<void> add(
    RequestsList request,
    String title, {
    String notes = '',
    bool isCompleted = false,
  }) => repository.saveSubrequest(
    repository
        .draftSubrequest(request.id)
        .copyWith(title: title, notes: notes, isCompleted: isCompleted),
  );

  await add(
    personal,
    'Groceries',
    notes: 'Milk\nEggs\nApples\nOatmeal\nSpinach',
  );
  await add(personal, 'Haircut');
  await add(personal, 'Doctor appointment', notes: 'Ask about diet');
  await add(personal, 'Take a walk', isCompleted: true);
  await add(personal, 'Buy concert tickets');
  await add(family, 'Pick up kids from school');
  await add(family, 'Get laundry', isCompleted: true);
  await add(family, 'Take out trash');
  await add(
    business,
    'Call accountant',
    notes:
        'Status of tax return\n'
        'Expenses for next year\n'
        'Changing payroll company',
  );
  await add(business, 'Send weekly emails', isCompleted: true);
  await add(business, 'Prepare for WWDC');
}

Future<void> _seedReminders(RemindersRepository repository) async {
  final now = DateTime.now();
  DateTime inDays(int days) => now.add(Duration(days: days));

  final personal = repository
      .draftTopic(_blue)
      .copyWith(title: 'Personal Reminder');
  final family = repository
      .draftTopic(_amber)
      .copyWith(title: 'Family Reminder');
  final business = repository
      .draftTopic(_violet)
      .copyWith(title: 'Business Reminder');

  for (final topic in [personal, family, business]) {
    await repository.saveTopic(topic);
  }

  Future<void> add(
    RemindersList topic,
    String title, {
    String notes = '',
    DateTime? dueDate,
    bool isCompleted = false,
    bool isFlagged = false,
    Priority? priority,
  }) => repository.saveReminder(
    repository
        .draftReminder(topic.id)
        .copyWith(
          title: title,
          notes: notes,
          dueDate: dueDate,
          isCompleted: isCompleted,
          isFlagged: isFlagged,
          priority: priority,
        ),
  );

  await add(
    personal,
    'Groceries',
    notes: 'Milk\nEggs\nApples\nOatmeal\nSpinach',
  );
  await add(personal, 'Haircut', dueDate: inDays(-2), isFlagged: true);
  await add(
    personal,
    'Doctor appointment',
    notes: 'Ask about diet',
    dueDate: now,
    priority: Priority.high,
  );
  await add(personal, 'Take a walk', dueDate: inDays(-190), isCompleted: true);
  await add(personal, 'Buy concert tickets', dueDate: now);
  await add(
    family,
    'Pick up kids from school',
    dueDate: inDays(2),
    isFlagged: true,
    priority: Priority.high,
  );
  await add(
    family,
    'Get laundry',
    dueDate: inDays(-2),
    isCompleted: true,
    priority: Priority.low,
  );
  await add(
    family,
    'Take out trash',
    dueDate: inDays(4),
    priority: Priority.high,
  );
  await add(
    business,
    'Call accountant',
    notes:
        'Status of tax return\n'
        'Expenses for next year\n'
        'Changing payroll company',
    dueDate: inDays(2),
  );
  await add(
    business,
    'Send weekly emails',
    dueDate: inDays(-2),
    isCompleted: true,
    priority: Priority.medium,
  );
  await add(business, 'Prepare for WWDC', dueDate: inDays(2));
}
