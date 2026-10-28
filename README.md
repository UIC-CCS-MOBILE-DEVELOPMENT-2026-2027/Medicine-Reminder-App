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
                             Shared app state, restored and saved on-device
  services/storage_service.dart
                             Local medicine, settings, and dose-history storage
  services/notification_service.dart
                             Daily Android/iOS local notification scheduling
  utils.dart                 Date labels and navigation helper
test/
  widget_test.dart           Basic app and model tests
```

## Data and notification behavior

Medicines, settings, and dose history are stored locally with `shared_preferences`; they remain on the device and are not backed up or synchronized across devices. Clearing the app's data or uninstalling it removes this information.

Daily local notifications are scheduled on Android and iOS. The app asks for notification permission when an active medicine reminder is first scheduled. Android reminders use inexact scheduling to avoid requiring exact-alarm access, so delivery can be delayed by Android battery policies. Reminders also depend on device notification settings and should not be treated as a substitute for medical advice or a guaranteed alert. Web and desktop builds currently do not schedule reminders.
