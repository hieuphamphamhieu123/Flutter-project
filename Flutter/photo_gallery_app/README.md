Photo Gallery App
=================

A simple Flutter app demonstrating image capture/pick and a gallery GridView. Uses `image_picker`, `permission_handler`, and `path_provider` to save photos to the app documents directory.

Run
---

```powershell
cd c:\Users\Admin\Flutter\photo_gallery_app
flutter pub get
flutter run
```

Permissions
-----------
- Android: add the following permissions to `android/app/src/main/AndroidManifest.xml` (outside `<application>`):

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

For Android 13+ you may also need the `READ_MEDIA_IMAGES` permission instead of READ_EXTERNAL_STORAGE.

- iOS: add these keys to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to take photos for your gallery.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to pick photos.</string>
```

Notes
-----
- Photos are saved under the app documents directory in a `photos` subfolder. They are private to the app.
- Long-press a thumbnail to delete. Tap to view fullscreen.
- On web the permission handling is skipped; picking behaves according to browser support.

Next improvements
-----------------
- Add ability to export/share photos.
- Allow selecting multiple images at once and add thumbnails (requires package support).
- Store and show lightweight metadata and sort/filter by date.
