#!/bin/zsh
# Çeyizim — arşivle ve TestFlight'a (App Store Connect) yükle.
# Ön koşul: App Store Connect'te com.tahacaliskan.ceyizim için uygulama kaydı oluşturulmuş olmalı
# ve Xcode > Settings > Accounts'ta Apple ID'n oturum açmış olmalı.
set -euo pipefail
cd "$(dirname "$0")/.."
rm -rf build/Ceyizim.xcarchive build/export
echo "▶︎ Arşivleniyor…"
xcodebuild archive -project Ceyizim.xcodeproj -scheme Ceyizim -configuration Release \
  -destination 'generic/platform=iOS' -archivePath build/Ceyizim.xcarchive \
  -allowProvisioningUpdates -quiet
echo "▶︎ App Store Connect'e yükleniyor…"
xcodebuild -exportArchive -archivePath build/Ceyizim.xcarchive \
  -exportOptionsPlist Tools/ExportOptions.plist -exportPath build/export \
  -allowProvisioningUpdates 2>&1 | tee build/export.log | grep -E "EXPORT|error|Upload" || true
grep -q "EXPORT SUCCEEDED" build/export.log && echo "✅ Yüklendi. 5-15 dk içinde App Store Connect > TestFlight'ta işlenir." || { echo "❌ Yükleme başarısız, ayrıntı: build/export.log"; exit 1; }
