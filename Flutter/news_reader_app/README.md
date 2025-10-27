News Reader App
=================

A small Flutter app demonstrating fetching news from NewsAPI.org using `http` and `FutureBuilder`.

Important: NewsAPI requires an API key. Do NOT hardcode your key in source control. Provide it at run time with `--dart-define`.

Run
---

Open a terminal and run:

```powershell
cd c:\Users\Admin\Flutter\news_reader_app
flutter pub get
flutter run --dart-define=NEWSAPI_KEY=your_api_key_here
```

If you don't provide `NEWSAPI_KEY` the app will show a banner explaining how to add the key.

Notes
-----
- The app fetches top headlines (country configurable via the app bar).
- Error handling: non-200 responses and network errors show a message with a retry button.
- Details screen shows article content and a button to open the original article in the browser (uses `url_launcher`).

Next improvements
-----------------
- Add paging/infinite scroll.
- Add search and category filters.
- Add caching and offline mode.
