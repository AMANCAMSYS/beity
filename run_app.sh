#!/bin/bash
# سكريبت لتشغيل تطبيق Flutter على الهاتف

# المسار الكامل لبرنامج adb
ADB_CMD="$HOME/Android/Sdk/platform-tools/adb"

# البحث عن مسار flutter
FLUTTER_CMD="flutter"

# قائمة بالمسارات الشائعة لـ flutter على لينكس
POSSIBLE_FLUTTER_PATHS=(
    "$HOME/development/flutter/bin/flutter"
    "$HOME/developer/flutter/bin/flutter"
    "$HOME/flutter/bin/flutter"
    "$HOME/Android/flutter/bin/flutter"
    "$HOME/src/flutter/bin/flutter"
    "/snap/bin/flutter"
    "/opt/flutter/bin/flutter"
    "/usr/bin/flutter"
    "/usr/local/bin/flutter"
)

# التحقق مما إذا كان flutter متاحاً في الـ PATH الافتراضي
if command -v flutter &> /dev/null; then
    FLUTTER_CMD="flutter"
else
    # البحث في المسارات الشائعة
    for path in "${POSSIBLE_FLUTTER_PATHS[@]}"; do
        if [ -f "$path" ]; then
            FLUTTER_CMD="$path"
            echo "🎯 تم العثور على flutter تلقائياً في: $FLUTTER_CMD"
            break
        fi
    done
fi

# التحقق النهائي من وجود flutter
if ! command -v "$FLUTTER_CMD" &> /dev/null && [ ! -f "$FLUTTER_CMD" ]; then
    echo "❌ لم يتم العثور على أمر 'flutter' في المسارات الشائعة."
    echo "💡 يرجى التأكد من إضافة مسار Flutter إلى متغير PATH، أو تعديل هذا السكريبت وتعيين مسار flutter اليدوي."
    exit 1
fi

echo "🔍 جاري البحث عن الهاتف المتصل..."

# استخراج الأجهزة المتصلة بدقة. بعض هواتف Android عبر Wi-Fi تظهر مرتين:
# مرة بعنوان IP صالح، ومرة باسم mDNS مثل adb-..._adb-tls-connect._tcp،
# وFlutter قد يفشل عند محاولة قراءة خصائص اسم mDNS.
mapfile -t DEVICE_IDS < <(
    "$ADB_CMD" devices |
        tail -n +2 |
        sed -n 's/[[:space:]]*device$//p' |
        sed '/^[[:space:]]*$/d'
)

# افصل مداخل mDNS المكررة إن وجدت حتى لا يحاول Flutter فحصها.
for stale_id in "${DEVICE_IDS[@]}"; do
    if [[ "$stale_id" == *"_adb-tls-connect._tcp"* ]]; then
        "$ADB_CMD" disconnect "$stale_id" >/dev/null 2>&1 || true
    fi
done

# فضّل الاتصال المباشر عبر IP:port، ثم USB، وتجاهل mDNS كاختيار افتراضي.
DEVICE_ID=""
for id in "${DEVICE_IDS[@]}"; do
    if [[ "$id" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+$ ]]; then
        DEVICE_ID="$id"
        break
    fi
done

if [ -z "$DEVICE_ID" ]; then
    for id in "${DEVICE_IDS[@]}"; do
        if [[ "$id" != *"_adb-tls-connect._tcp"* ]]; then
            DEVICE_ID="$id"
            break
        fi
    done
fi

if [ -z "$DEVICE_ID" ]; then
    echo "⚠️ لم يتم العثور على أي هاتف أندرويد متصل عبر الوايرلس أو USB."
    echo "🌐 جاري التبديل للتشغيل على متصفح Chrome كبديل..."
    DEVICE_ID="chrome"
else
    echo "✅ تم العثور على الهاتف: $DEVICE_ID"
fi

echo "🚀 جاري تشغيل التطبيق..."
"$FLUTTER_CMD" run -d "$DEVICE_ID"
