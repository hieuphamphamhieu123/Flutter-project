Chat UI Clone
==============

A mock chat interface demonstrating complex layouts and scrolling in Flutter. Uses `ListView`, `Row`, `Column`, and `Container` to build dynamic message bubbles.

Run
---

```powershell
cd c:\Users\Admin\Flutter\chat_ui_clone
flutter pub get
flutter run
```

Features
--------
- Left/right aligned message bubbles for other/user messages.
- Avatars, timestamps, and a simple "read" indicator.
- Scrolls to the bottom when sending a new message.

Next improvements
-----------------
- Persist messages locally (shared_preferences/Hive).
- Add message reactions, image messages, and long-press actions.
- Add unit/widget tests for message layout and input behavior.
