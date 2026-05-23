# Configuration (secrets)

This repository does not store Firebase plist/json API keys or RevenueCat SDK keys in Git.

Files matched by [`.gitignore`](.gitignore) (e.g. `google-services.json`, `GoogleService-Info.plist`, `assets/*.key`, keystores, `.env`) must stay local only; `git add -A` will not stage them.

## Firebase (Android / iOS)

1. Download `google-services.json` and `GoogleService-Info.plist` from the Firebase console.
2. Place them at:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
3. **iOS（joymath 同様）:** `GoogleService-Info.plist` を差し替えたら `ios/Runner/Info.plist` も手で揃える:
   - `GIDClientID` = plist の `CLIENT_ID`
   - `CFBundleURLSchemes` の1つ目 = plist の `REVERSED_CLIENT_ID`
   - 2つ目 = `GOOGLE_APP_ID`（`1:番号:ios:サフィックス`）から `app-1-番号-ios-サフィックス`

4. **Android Google ログイン:** リリース用 SHA-1 を Firebase に登録し `google-services.json` を再取得（下記「Android SHA-1」）。

`lib/firebase_options.dart` の `--dart-define` は **Web ビルドのみ** 必須。iOS/Android は joymath と同様 plist/json のみ。

## Dart defines (Web Firebase + RevenueCat)

Minimum defines for **web** (GitHub Pages CI):

- `FIREBASE_WEB_API_KEY`, `FIREBASE_WEB_APP_ID`, `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_PROJECT_ID`, `FIREBASE_AUTH_DOMAIN`, `FIREBASE_STORAGE_BUCKET`
- Optional: `FIREBASE_MEASUREMENT_ID`

**Apple Sign-In (Android)** needs `FIREBASE_APPLE_WEB_CLIENT_ID` and `FIREBASE_AUTH_HANDLER_URL` (typically `https://<project-id>.firebaseapp.com/__/auth/handler`).

## Android SHA-1（Google ログインが Android で落ちる場合）

```bash
./scripts/print_android_sha1.sh
```

表示された SHA-1 を Firebase Console → **unitgacha** → Android アプリ → **フィンガープリントを追加** に登録し、`google-services.json` を再ダウンロードして `android/app/` と Codemagic の `GOOGLE_SERVICES_JSON` を更新する。

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

## Codemagic（iOS App Store）

詳細は [`RELEASE_SETUP.md`](RELEASE_SETUP.md)。Secret の中身は `./scripts/prepare_codemagic_env.sh` が手元ファイルから生成する。
