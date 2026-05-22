#!/usr/bin/env bash
# Codemagic の Environment variables にコピペする値を、手元のファイルから生成する。
# 実行: ./scripts/prepare_codemagic_env.sh
# 出力: codemagic-env-paste.txt（git 除外。秘密情報を含む）
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/codemagic-env-paste.txt"
P8="${ASC_P8_PATH:-$HOME/.appstoreconnect/private_keys/AuthKey_ATBD5UGJTG.p8}"
ANDROID_JSON="$ROOT/android/app/google-services.json"
IOS_PLIST="$ROOT/ios/Runner/GoogleService-Info.plist"

missing=()
[[ -f "$P8" ]] || missing+=("App Store Connect API key: $P8")
[[ -f "$ANDROID_JSON" ]] || missing+=("Firebase Android: $ANDROID_JSON")
[[ -f "$IOS_PLIST" ]] || missing+=("Firebase iOS: $IOS_PLIST")

if ((${#missing[@]} > 0)); then
  echo "不足しているファイル:" >&2
  printf '  - %s\n' "${missing[@]}" >&2
  exit 1
fi

{
  echo "# Codemagic 用 — このファイルはコミットしない（.gitignore 済み）"
  echo "# 生成: $(date -Iseconds)"
  echo ""
  echo "=== グループ: appstore_credentials ==="
  echo ""
  echo "## Variable: APP_STORE_CONNECT_PRIVATE_KEY (Secret)"
  echo "## Type: Secret / Secure"
  cat "$P8"
  echo ""
  echo "=== グループ: firebase_credentials ==="
  echo ""
  echo "## Variable: GOOGLE_SERVICES_JSON (Secret)"
  echo "## Type: Secret / Secure"
  cat "$ANDROID_JSON"
  echo ""
  echo "## Variable: GOOGLE_SERVICE_INFO_PLIST (Secret)"
  echo "## Type: Secret / Secure"
  cat "$IOS_PLIST"
  echo ""
  echo "=== codemagic.yaml の vars（通常は変更不要）==="
  echo "APP_STORE_CONNECT_KEY_IDENTIFIER=ATBD5UGJTG"
  echo "APP_STORE_CONNECT_ISSUER_ID=c64fb6be-f1d2-4e04-80b5-2841def3da52"
  echo "APP_STORE_APPLE_ID=6756411322"
} > "$OUT"

echo "Wrote: $OUT"
echo ""
echo "次に Codemagic UI で:"
echo "  1. appstore_credentials → APP_STORE_CONNECT_PRIVATE_KEY に p8 ブロックを貼る"
echo "  2. firebase_credentials → GOOGLE_SERVICES_JSON / GOOGLE_SERVICE_INFO_PLIST を貼る"
echo "  3. Code signing → ./scripts/export_codemagic_signing.sh の p12 と .mobileprovision を Upload"
