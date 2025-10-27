Weather App
===========

A simple Flutter Weather app demonstrating geolocation with `geolocator`, HTTP requests with `http`, `FutureBuilder`, and JSON parsing using OpenWeatherMap.

Important: OpenWeatherMap requires an API key. Do NOT check your key into source control.

Run
---

1. Add platform permissions:
   - Android: add the following to `android/app/src/main/AndroidManifest.xml` inside `<manifest>`:
     ```xml
     <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
     <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
     ```
   - iOS: add to `ios/Runner/Info.plist`:
     ```xml
     <key>NSLocationWhenInUseUsageDescription</key>
     <string>We need your location to show local weather.</string>
     ```

2. Run with your API key supplied via dart-define:

```powershell
cd c:\Users\Admin\Flutter\weather_app
flutter pub get
flutter run --dart-define=WEATHER_API_KEY=your_openweathermap_api_key_here
```

Behavior
--------
- The app requests location permission and reads the device's current position.
- It then calls the OpenWeatherMap `weather` endpoint to fetch current weather using the `lat`/`lon` coordinates.
- Loading and error states are shown via `FutureBuilder`.

Notes and next steps
--------------------
- You can change units from metric to imperial by editing the service call.
- Consider adding caching, detailed forecasts (onecall API), manual city search, and background updates.
- For Android 12+ additional permission handling (approximate vs precise) may be required.
