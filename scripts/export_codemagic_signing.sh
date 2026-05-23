#!/usr/bin/env bash
# Codemagic に Upload する .p12 / .mobileprovision を用意する。
# 実行: ./scripts/export_codemagic_signing.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/codemagic-signing"
mkdir -p "$OUT"

echo "==> Provisioning profile (com.joyphysics.unitgacha App Store)"
PROV_OUT="$OUT/com.joyphysics.unitgacha.appstore.mobileprovision"
XCODE_PROV_DIR="$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"
if [[ -f "$PROV_OUT" ]]; then
  echo "    既にあります: $PROV_OUT"
elif [[ -d "$XCODE_PROV_DIR" ]]; then
  found=""
  for f in "$XCODE_PROV_DIR"/*.mobileprovision; do
    [[ -f "$f" ]] || continue
    decoded=$(security cms -D -i "$f" 2>/dev/null || true)
    # App Store 配布用: bundle 一致かつ ProvisionedDevices なし（Store プロファイル）
    if echo "$decoded" | grep -q '7K99YVR868.com.joyphysics.unitgacha' \
      && ! echo "$decoded" | grep -q '<key>ProvisionedDevices</key>'; then
      found="$f"
      break
    fi
  done
  if [[ -n "$found" ]]; then
    cp "$found" "$PROV_OUT"
    echo "    Xcode からコピー: $PROV_OUT"
    echo "    元: $found"
  else
    echo "    App Store 用プロファイルが Xcode に見つかりません。"
    echo "    developer.apple.com から DL して $PROV_OUT に置いてください。"
  fi
else
  echo "    無い場合は App Store Connect API または developer.apple.com から DL"
fi

echo "==> Distribution certificate (.p12)"
P12="$OUT/unitgacha-distribution.p12"
read -r -s -p "キーチェーンのパスワード（Mac ログイン）: " LOGIN_PASS
echo
read -r -p "p12 に付けるパスワード（Codemagic 登録時に使う）: " P12_PASS
security export -k "$HOME/Library/Keychains/login.keychain-db" -t identities -f pkcs12 -o "$P12" -P "$P12_PASS" <<< "$LOGIN_PASS" 2>/dev/null || \
  security export -k "$HOME/Library/Keychains/login.keychain-db" -t identities -f pkcs12 -o "$P12" -P "$P12_PASS"
echo "    書き出し: $P12"
echo "    Codemagic の p12 パスワード: $P12_PASS"
echo ""
echo "Codemagic → Code signing identities → Upload:"
echo "  - $P12"
echo "  - $OUT/com.joyphysics.unitgacha.appstore.mobileprovision"
