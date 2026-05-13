#!/bin/bash
# سكريبت لتشغيل تطبيق Flutter على الهاتف

# المسار الكامل لبرنامج adb
ADB_CMD="$HOME/Android/Sdk/platform-tools/adb"

echo "🔍 جاري البحث عن الهاتف المتصل..."

# استخراج معرّف الجهاز بدقة (حتى لو كان يحتوي على مسافات)
DEVICE_ID=$($ADB_CMD devices | grep -w "device" | sed 's/[[:space:]]*device$//' | grep -v "List of devices" | head -n 1)

if [ -z "$DEVICE_ID" ]; then
    echo "⚠️ لم يتم العثور على أي هاتف أندرويد متصل عبر الوايرلس أو USB."
    echo "🌐 جاري التبديل للتشغيل على متصفح Chrome كبديل..."
    DEVICE_ID="chrome"
else
    echo "✅ تم العثور على الهاتف: $DEVICE_ID"
fi

echo "🚀 جاري تشغيل التطبيق..."
flutter run -d "$DEVICE_ID"
