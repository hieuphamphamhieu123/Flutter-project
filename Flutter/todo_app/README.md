Todo App
=========

A minimal Flutter Todo app demonstrating local state management with `StatefulWidget`, `ListView.builder()`, and `setState()`. Tasks are persisted locally using `shared_preferences`.

Run
---

```powershell
cd c:\Users\Admin\Flutter\todo_app
flutter pub get
flutter run
```

Notes
-----
- Tasks are saved automatically in device storage. Deleting or reordering will update the saved list.
- This app is intentionally minimal to focus on local state and persistence. You can extend it with editing, due dates, categories, or migrating to a database like Hive or sqflite.
