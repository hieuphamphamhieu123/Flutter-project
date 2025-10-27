Notes App
==========

A simple notes app demonstrating `Provider` and `ChangeNotifier` for app-wide state, with local persistence using `shared_preferences`. You can create, edit, and delete notes in real-time.

Run
---

```powershell
cd c:\Users\Admin\Flutter\note_app
flutter pub get
flutter run
```

Behavior
--------
- Notes are saved locally in SharedPreferences (key: `notes_v1`).
- Tap a note to edit it. Use the + FAB to create a new note.

Next improvements
-----------------
- Add search and sorting.
- Add note tagging and filter by tags.
- Add backup/export and import functionality.
- Add widget tests for provider behavior and editor flow.
