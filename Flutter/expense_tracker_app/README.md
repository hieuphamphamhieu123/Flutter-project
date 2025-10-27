Expense Tracker App
====================

A minimal expense tracker demonstrating local persistence with `Hive` and visualization using `fl_chart`.

Run
---

1. Install dependencies and run:

```powershell
cd c:\Users\Admin\Flutter\expense_tracker_app
flutter pub get
flutter run
```

2. Notes for Android/iOS:
- Hive uses local storage; no special permissions are needed.

What it does
------------
- Add new expenses (title, amount, category).
- Persisted locally using Hive box `expenses` (each expense stored as a map keyed by id).
- Shows a pie chart summarizing expenses by category (uses `fl_chart`).

Next improvements
-----------------
- Add edit expense flow and filters by date range.
- Replace map storage with a proper Hive TypeAdapter for better typing and performance.
- Add monthly summary charts and export/import functionality.
- Add unit/widget tests for CRUD operations and chart rendering.
