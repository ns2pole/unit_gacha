# unitGacha（物理単位ガチャ）

Flutter アプリ（iOS / Android）。ストア ID: `com.joyphysics.unitgacha`

## Web（GitHub Pages）

**URL:** [https://ns2pole.github.io/unit_gacha/](https://ns2pole.github.io/unit_gacha/)

1. GitHub **Settings → Pages → Source:** **GitHub Actions**
2. **Settings → Secrets and variables → Actions** に Firebase Web 用シークレット（`CONFIGURE.md` 参照）
3. `main` へ push または workflow **Deploy GitHub Pages** を手動実行

## Firebase（ローカル）

| プラットフォーム | 配置先 |
|------------------|--------|
| Android | `android/app/google-services.json`（`.example` 参照） |
| iOS | `ios/Runner/GoogleService-Info.plist`（`.example` 参照） |

`lib/firebase_options.dart` は `--dart-define` で値を渡す（詳細は `CONFIGURE.md`）。

## Firebase（Codemagic / CI）

環境変数グループ **`firebase_credentials`** に Secret を追加:

| Secret | 内容 |
|--------|------|
| `GOOGLE_SERVICES_JSON` | `google-services.json` の全文 |
| `GOOGLE_SERVICE_INFO_PLIST` | `GoogleService-Info.plist` の全文 |

（base64 版 `GOOGLE_SERVICES_JSON_BASE64` / `GOOGLE_SERVICE_INFO_PLIST_BASE64` でも可）

`codemagic.yaml` がビルド前に `dart run tool/inject_*.dart` を実行します。

## Codemagic / ストアリリース

**手順は [`RELEASE_SETUP.md`](RELEASE_SETUP.md) の 3 ステップのみ。**  
（Apple ID `6756411322`、API Key ID、Firebase 注入スクリプトはリポジトリ側で済み）

## ローカル fastlane リリース

`fastlane/UNITGACHA.md` を参照。要約:

```bash
cd unitGacha
bundle install
# fastlane/unit-gacha-fastlane.json, android/key.properties, ASC_* などを用意
bundle exec fastlane release_all_platforms notes:"..." notes_en:"..."
```

## その他の秘密情報（コミットしない）

- `fastlane/unit-gacha-fastlane.json`（Google Play）
- `android/key.properties`、`.jks`
- RevenueCat / Firebase の dart-define（`CONFIGURE.md`）
