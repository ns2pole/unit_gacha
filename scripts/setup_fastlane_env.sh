#!/usr/bin/env bash
# 手元 fastlane 用の環境変数（joymath と同じ App Store Connect API キー）
# 使い方: source ./scripts/setup_fastlane_env.sh
export ASC_KEY_ID="${ASC_KEY_ID:-ATBD5UGJTG}"
export ASC_ISSUER_ID="${ASC_ISSUER_ID:-c64fb6be-f1d2-4e04-80b5-2841def3da52}"
export ASC_P8_PATH="${ASC_P8_PATH:-$HOME/.appstoreconnect/private_keys/AuthKey_${ASC_KEY_ID}.p8}"

if [[ ! -f "$ASC_P8_PATH" ]]; then
  echo "WARN: ASC_P8_PATH not found: $ASC_P8_PATH" >&2
else
  echo "ASC_KEY_ID=$ASC_KEY_ID"
  echo "ASC_ISSUER_ID=$ASC_ISSUER_ID"
  echo "ASC_P8_PATH=$ASC_P8_PATH"
fi
