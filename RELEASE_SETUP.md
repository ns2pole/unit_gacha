# unitGacha リリース設定（やることは 3 つだけ）

ローカルにはすでに Firebase・Android 署名・Play 用 JSON（joymath と同じサービスアカウント）が揃っています。  
**Codemagic だけ**初回セットアップが必要です。

## あなたがやること（Codemagic 初回のみ）

### 1. リポジトリを接続
[Codemagic](https://codemagic.io/) → Add application → unitGacha の Git リポジトリ → `codemagic.yaml` を認識させる。

### 2. Secret をコピペ（1 コマンドで用意）
```bash
cd unitGacha
./scripts/prepare_codemagic_env.sh
```
生成された `codemagic-env-paste.txt` を開き、Codemagic の環境変数グループに貼る:
- `appstore_credentials` → `APP_STORE_CONNECT_PRIVATE_KEY`
- `firebase_credentials` → `GOOGLE_SERVICES_JSON` / `GOOGLE_SERVICE_INFO_PLIST`

Key ID / Issuer ID / Apple ID は **yaml に既に記載**（`6756411322` = Unit Gacha !）。

### 3. 署名ファイルを Upload（対話あり・初回のみ）
```bash
./scripts/export_codemagic_signing.sh
```
出力した `.p12` と `.mobileprovision` を Codemagic → **Team settings → Code signing identities** に Upload。

---

その後: ワークフロー **ios-appstore-release** を実行。

## ローカル fastlane（任意・Codemagic とは別）

```bash
source ./scripts/setup_fastlane_env.sh
bundle exec fastlane release_all_platforms notes:"..." notes_en:"..."
```

`fastlane/unit-gacha-fastlane.json`・`android/key.properties`・Firebase 実ファイルは手元に既にある想定。
