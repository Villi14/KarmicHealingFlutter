# Karmic Healing Flutter

Karmic Healing Flutter is a cross-platform Flutter app for spiritual healing workflows, energy-balancing sessions, requests, reminders, and personal practice settings.

## Features

### Home
- Main navigation across the core app areas.
- Adaptive card grid.
- Consistent aura-style gradient background.

### Onboarding
- First-launch introduction for new users.
- Local completion state stored on device.
- Skip flow that lands directly on the home screen.

### Energy Balancing
- Initial process for first-time practice.
- Essential Self and Divine Self session flows.
- Step-by-step localized instructions.
- Session timing, sound, vibration, screen-rest, and active-session state.

### Requests
- Healing request lists with nested subrequests.
- Priority, due date, notes, color, completion, and ordering support.
- Case-insensitive search across request content.
- SQLite-backed local persistence.

### Reminders
- Reminder topics and individual reminders.
- Due dates, flags, priorities, notes, completion, and ordering support.
- Local notification scheduling.
- Today, scheduled, flagged, completed, topic, and all-reminder views.

### Settings
- System, light, and dark theme modes.
- Device-locale-based localization for English, Ukrainian, and Russian.
- Energy-session preferences.
- About, contact, author link, privacy policy, and system settings actions.

## Technology

- **Flutter** for cross-platform app development.
- **Material** widgets with a custom app theme.
- **flutter_localizations + ARB** for localization.
- **SharedPreferences** for lightweight local settings.
- **SQLite / sqflite** for local structured data.
- **flutter_local_notifications** for reminder notifications.
- **ChangeNotifier + inherited scopes** for app state propagation.

## Project Structure

```text
lib/
├── constants/           # Theme, colors, and design constants
├── data/                # SQLite access, repositories, settings, notifications
├── l10n/                # Generated localization files and ARB sources
├── qa/                  # QA screenshot route selection
├── screens/             # App screens grouped by feature
├── widgets/             # Reusable UI components
├── main.dart            # App bootstrap and root widget
└── theme_controller.dart
```

## Getting Started

1. Install dependencies:

```bash
flutter pub get
```

2. Run the app:

```bash
flutter run
```

3. Run static analysis:

```bash
flutter analyze
```

4. Run tests:

```bash
flutter test
```

## QA Screens

The app supports deterministic QA screenshot routes through the `QA_SCREEN` compile-time environment value.

Example:

```bash
flutter run --dart-define=QA_SCREEN=requests_list
```

Seeded QA screens use an in-memory database and sample data. Empty-state QA screens also use an in-memory database but skip sample data.

## Design Notes

- The app uses a soft gradient background and custom color system for a calm visual tone.
- Layout constants live in `lib/constants/design_constants.dart`.
- Generated localization files should not be edited directly; update the `.arb` files instead.
- The SQLite schema mirrors the companion Swift app schema where compatibility matters.
