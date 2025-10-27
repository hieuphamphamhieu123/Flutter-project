Personal Profile App
=====================

A minimal Flutter app demonstrating layout, responsive UI and a dark mode toggle. It uses `Column`, `ListTile`, `CircleAvatar`, and `Card` as required.

Getting started
---------------

1. Install Flutter: https://flutter.dev/docs/get-started/install

2. Open the project folder in VS Code or your editor:

   c:\Users\Admin\Flutter\personal_profile_app

3. Get packages and run:

```powershell
cd c:\Users\Admin\Flutter\personal_profile_app
flutter pub get
flutter run
```

Notes
-----
- The app attempts to load a local image from `assets/profile.jpg`. If you want to use a real picture, add your image at that path and uncomment the `assets` section in `pubspec.yaml`.
- The dark mode toggle is in the app bar.

Files added
-----------
- `lib/main.dart` — main application with responsive layout and theme toggle.
- `pubspec.yaml` — minimal manifest (uses `cupertino_icons`).
- `README.md` — instructions to run and how to add an asset.

Next steps / Improvements
------------------------
- Add `url_launcher` to open links.
- Add a real `assets/profile.jpg` image and enable it in `pubspec.yaml`.
- Add tests and CI workflow to validate builds.
