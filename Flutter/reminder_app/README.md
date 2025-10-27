Reminder App
=============

A simple Flutter app demonstrating local notifications using `flutter_local_notifications`, timezone handling, and scheduling reminders via a DateTime picker.

Important notes
---------------
- This project uses `flutter_local_notifications` plus `timezone` and `flutter_native_timezone` to schedule notifications at the correct local time.
- Do NOT hardcode any sensitive data in source control.

Run
---

```powershell
cd c:\Users\Admin\Flutter\reminder_app
flutter pub get
flutter run
```

Android & iOS setup
-------------------
Follow the package docs for platform-specific setup (notification channel and AppDelegate changes on iOS). Basic pointers:
- Android: ensure you have an app icon at `android/app/src/main/res/mipmap-*/ic_launcher.png` (the code uses `@mipmap/ic_launcher`).
- iOS: update `Info.plist` to request notification permissions if needed.

Behavior
--------
- Tap + to add a reminder: enter title and pick date & time.
- The reminder will be scheduled as a local notification at the chosen time.
- Scheduled reminders are stored locally (SharedPreferences) and displayed in the list; tap the cancel icon to unschedule and remove.

Next improvements
-----------------
- Add repeat (daily/weekly) options.
- Add snooze and action buttons.
- Show notification delivery history and add deep-linking when tapping a notification.
- Add platform-specific handling for Android 12+ and iOS background modes if needed.
