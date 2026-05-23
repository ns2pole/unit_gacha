#!/usr/bin/env bash
# Prints SHA-1 fingerprints to register in Firebase Console (Project settings → Your apps → Android).
# Register BOTH debug and release SHA-1, then re-download google-services.json.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "=== Debug keystore (flutter run / local debug) ==="
keytool -list -v \
  -alias androiddebugkey \
  -keystore "${HOME}/.android/debug.keystore" \
  -storepass android -keypass android 2>/dev/null \
  | grep -E 'SHA1:|SHA-1:' || echo "(debug keystore not found)"

echo ""
echo "=== Release keystore (Play / Codemagic) ==="
KEY_PROPS="$ROOT/android/key.properties"
if [[ ! -f "$KEY_PROPS" ]]; then
  echo "android/key.properties がありません。Play 用 keystore の SHA-1 は手元で keytool -list -v -keystore <your.jks> を実行してください。"
  exit 0
fi

store_file=$(grep '^storeFile=' "$KEY_PROPS" | cut -d= -f2-)
key_alias=$(grep '^keyAlias=' "$KEY_PROPS" | cut -d= -f2-)
store_password=$(grep '^storePassword=' "$KEY_PROPS" | cut -d= -f2-)

if [[ -z "$store_file" || -z "$key_alias" ]]; then
  echo "key.properties の storeFile / keyAlias を確認してください。"
  exit 1
fi

if [[ "$store_file" != /* ]]; then
  store_file="$ROOT/android/$store_file"
fi

keytool -list -v \
  -keystore "$store_file" \
  -alias "$key_alias" \
  -storepass "$store_password" \
  | grep -E 'SHA1:|SHA-1:'

echo ""
echo "Firebase Console → unitgacha → Android app → Add fingerprint に上記 SHA-1 を登録し、"
echo "google-services.json を再ダウンロードして android/app/ と Codemagic Secret を更新してください。"
