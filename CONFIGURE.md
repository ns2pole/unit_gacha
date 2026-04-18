# Configuration (secrets)

This repository does not store Firebase plist/json API keys or RevenueCat SDK keys in Git.

## Firebase (Android / iOS)

1. Download `google-services.json` and `GoogleService-Info.plist` from the Firebase console.
2. Place them at:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
3. For `lib/firebase_options.dart`, pass `--dart-define` at build time (see below) or use your IDE’s “Additional run args”.

## Dart defines (Firebase + RevenueCat)

`lib/firebase_options.dart` reads Firebase settings from `String.fromEnvironment(...)`.

Minimum defines for **web** (GitHub Pages CI):

- `FIREBASE_WEB_API_KEY`, `FIREBASE_WEB_APP_ID`, `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_PROJECT_ID`, `FIREBASE_AUTH_DOMAIN`, `FIREBASE_STORAGE_BUCKET`
- Optional: `FIREBASE_MEASUREMENT_ID`

**Android** additionally: `FIREBASE_ANDROID_API_KEY`, `FIREBASE_ANDROID_APP_ID`

**iOS** additionally: `FIREBASE_IOS_API_KEY`, `FIREBASE_IOS_APP_ID`, `FIREBASE_IOS_CLIENT_ID`, `FIREBASE_IOS_BUNDLE_ID`

**Google Sign-In (iOS)** uses `FIREBASE_IOS_CLIENT_ID` (same as `CLIENT_ID` in `GoogleService-Info.plist`).

**Apple Sign-In (Android)** needs `FIREBASE_APPLE_WEB_CLIENT_ID` and `FIREBASE_AUTH_HANDLER_URL` (typically `https://<project-id>.firebaseapp.com/__/auth/handler`).

**RevenueCat** (mobile only; web skips SDK):

- `REVENUECAT_IOS_API_KEY` (e.g. `appl_...`)
- `REVENUECAT_ANDROID_API_KEY` (e.g. `goog_...`)

Example local run:

```bash
flutter run \
  --dart-define=FIREBASE_WEB_API_KEY=... \
  --dart-define=FIREBASE_PROJECT_ID=...
```

GitHub Actions should set the same keys as encrypted repository secrets and pass them to `flutter build web`.

## GitHub Pages

1. On GitHub: **Settings → Pages → Build and deployment → Source**: choose **GitHub Actions**.
2. **Settings → Secrets and variables → Actions**: add the secrets referenced in [`.github/workflows/pages.yml`](.github/workflows/pages.yml) (`FIREBASE_WEB_API_KEY`, `FIREBASE_WEB_APP_ID`, etc.).
3. After the first successful run, the site is served at `https://ns2pole.github.io/unit_gacha/` (project page; build uses `--base-href /unit_gacha/`).
4. In Firebase Console → Authentication → **Authorized domains**, add `ns2pole.github.io`.
