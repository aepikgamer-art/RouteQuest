#!/bin/bash
# build_ipa.sh — builds an unsigned RouteQuest.ipa for LiveContainer.
# RouteQuest is 100% AI-coded. 🤖
set -euo pipefail

if ! command -v xcodegen >/dev/null; then
  echo "❌ xcodegen not found. Install it first: brew install xcodegen"
  exit 1
fi

xcodegen generate

xcodebuild -project RouteQuest.xcodeproj \
  -scheme RouteQuest \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
  -derivedDataPath build/DerivedData \
  build

rm -rf build/Payload RouteQuest.ipa
mkdir -p build/Payload
cp -r "build/DerivedData/Build/Products/Release-iphoneos/RouteQuest.app" build/Payload/
(cd build && zip -qr ../RouteQuest.ipa Payload)

echo "✅ Built unsigned IPA: $(pwd)/RouteQuest.ipa"
echo "→ Airdrop / save it to your device, then import it into LiveContainer (it re-signs automatically)."
