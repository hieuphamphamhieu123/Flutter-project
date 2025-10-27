Firebase Login App
==================

A minimal Firebase Authentication example using `firebase_core` and `firebase_auth`.

Important setup (required)
-------------------------
1. Create a Firebase project at https://console.firebase.google.com/ and enable Email/Password sign-in in Authentication > Sign-in method.

2. Add your app to Firebase and download the platform config files:
   - Android: `google-services.json` -> place in `android/app/`
   - iOS: `GoogleService-Info.plist` -> place in `ios/Runner/`

3. Follow the official FlutterFire setup guide for platform-specific installation and Gradle / CocoaPods steps:
   https://firebase.flutter.dev/docs/overview

Run
---

```powershell
cd c:\Users\Admin\Flutter\firebase_login_app
flutter pub get
flutter run
```

Notes
-----
- The app uses `StreamBuilder` on `FirebaseAuth.instance.authStateChanges()` to react to login/logout in real time.
- If Firebase is not configured or `Firebase.initializeApp()` fails, the app shows a warning and the auth UI remains available for local testing (it will fail to sign in until configured).

Next improvements
-----------------
- Add password reset, email verification, and user profile editing.
- Add social sign-in (Google, Apple, Facebook) following the FlutterFire docs.
- Add secure storage for tokens or server-side session if needed.
