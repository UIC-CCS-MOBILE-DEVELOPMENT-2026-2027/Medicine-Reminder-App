# MedCare

Medminder is a Flutter medicine reminder app designed to make daily medication routines easier to follow. It provides a clear daily schedule, large and easy-to-read controls, and a simple way to track doses.

## Features

- Add and edit medicines with dosage, form, notes, and one or more daily reminder times.
- View today's dose schedule and mark each dose as taken or skipped.
- Undo a dose status if it was selected by mistake.
- Review dose history and adherence, with filters for taken and skipped doses.
- Pause or resume reminders for an individual medicine.
- Set a display name, enable or disable reminders, and choose a snooze length.
- High-contrast colors, larger text, and generous touch targets for easier use.

## Requirements

- Flutter SDK (the project uses Dart SDK `^3.13.2`; use a compatible Flutter release).
- An Android emulator or device, or another Flutter-supported target.

## Run the app

From the project directory:

```shell
flutter pub get
flutter run
```

To select a connected device or emulator:

```shell
flutter devices
flutter run -d <device-id>
```

On Windows, if Flutter is not on your `PATH`, run the Flutter batch file directly. For example:

```powershell
& 'C:\path\to\flutter\bin\flutter.bat' pub get
& 'C:\path\to\flutter\bin\flutter.bat' run
```

## Run tests and analysis

```shell
flutter test
flutter analyze
```

## Project structure

```text
lib/
  main.dart                  App entry point and shared theme
  models/medicine.dart       Medicine and dose data models
  screens/                   Home, medicine, history, and settings screens
  services/medicine_store.dart
                             Shared in-memory medicine and dose state
  services/notification_service.dart
                             Notification service placeholder
  utils.dart                 Date labels and navigation helper
test/
  widget_test.dart           Basic app and model tests
```

## Current limitations

Medicine, settings, and dose history are currently kept in memory, so they reset when the app is restarted. The notification service is also a placeholder: it logs reminder scheduling actions for development but does not yet deliver operating-system notifications. Persistent storage and platform notification setup are needed before relying on the app for real medication reminders.
