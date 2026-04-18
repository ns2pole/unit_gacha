## unitGacha fastlane ガイド（手動メモ）

`fastlane/README.md` は fastlane 実行時に自動生成されるため、このファイルに運用メモを置きます。

### セットアップ

```bash
cd unitGacha
bundle config set --local path "vendor/bundle"
bundle install
```

### UTF-8 locale（警告が出る場合）

```bash
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
```

### 必要ファイル / secrets

#### Android (Google Play)

- `unitGacha/fastlane/unit-gacha-fastlane.json`
  - Play Console の service account key
  - `.gitignore` で除外済み（コミットしない）

#### Android (release signing)

production 配信する場合は release keystore 署名が必要です。

- `unitGacha/android/key.properties`（テンプレ: `unitGacha/android/key.properties.example`）
- `*.jks`（keystore）

#### iOS (App Store Connect)

推奨: App Store Connect API Key

- `ASC_KEY_ID`
- `ASC_ISSUER_ID`
- `ASC_P8_PATH`（省略時は `~/.appstoreconnect/private_keys/AuthKey_<ASC_KEY_ID>.p8` を探索）

フォールバック: Apple ID

- `FASTLANE_USER`
- `FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD`

### スモーク（ビルド/アップロード無し）

```bash
bundle exec fastlane release_all_platforms skip_build:true skip_ios:true skip_android:true
```

### リリース実行例

```bash
bundle exec fastlane release_all_platforms notes:"バグ修正" notes_en:"Bug fixes"
```

片側だけ:

```bash
bundle exec fastlane release_all_platforms skip_android:true
bundle exec fastlane release_all_platforms skip_ios:true
```

