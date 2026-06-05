#!/bin/bash
# سكريبت لبناء وتثبيت نسخة Release على الهاتف
set -e

PACKAGE_NAME="com.sawa.sawa"
ADB_CMD="$HOME/Android/Sdk/platform-tools/adb"
FLUTTER_CMD="flutter"
INSTALL_EXISTING=false
CLEAN_FIRST=false

for arg in "$@"; do
    case "$arg" in
        --existing|--run-existing) INSTALL_EXISTING=true ;;
        --clean) CLEAN_FIRST=true ;;
        -h|--help)
            echo "Usage: ./run_app_release.sh [--existing] [--clean]"
            exit 0
            ;;
        *) echo "خيار غير معروف: $arg"; exit 1 ;;
    esac
done

POSSIBLE_FLUTTER_PATHS=(
    "$HOME/development/flutter/bin/flutter"
    "$HOME/developer/flutter/bin/flutter"
    "$HOME/flutter/bin/flutter"
    "$HOME/Android/flutter/bin/flutter"
    "$HOME/src/flutter/bin/flutter"
    "/home/omar/flutter/bin/flutter"
    "/snap/bin/flutter"
    "/opt/flutter/bin/flutter"
    "/usr/bin/flutter"
    "/usr/local/bin/flutter"
)

if ! command -v flutter &> /dev/null; then
    for path in "${POSSIBLE_FLUTTER_PATHS[@]}"; do
        if [ -f "$path" ]; then
            FLUTTER_CMD="$path"
            echo "🎯 تم العثور على flutter تلقائياً في: $FLUTTER_CMD"
            break
        fi
    done
fi

if ! command -v "$FLUTTER_CMD" &> /dev/null && [ ! -f "$FLUTTER_CMD" ]; then
    echo "❌ لم يتم العثور على أمر 'flutter' في المسارات الشائعة."
    exit 1
fi

echo "🔍 جاري البحث عن الهاتف المتصل..."

mapfile -t DEVICE_IDS < <(
    "$ADB_CMD" devices |
        tail -n +2 |
        sed -n 's/[[:space:]]*device$//p' |
        sed '/^[[:space:]]*$/d'
)

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
    for id in "${DEVICE_IDS[@]}"; do
        if [[ "$id" == *"_adb-tls-connect._tcp"* ]]; then
            DEVICE_ID="$id"
            echo "ℹ️ تم العثور على الهاتف عبر mDNS. للحصول على اسم ثابت استخدم adb connect IP:PORT."
            break
        fi
    done
fi

if [ -z "$DEVICE_ID" ]; then
    echo "⚠️ لم يتم العثور على أي هاتف أندرويد متصل عبر الوايرلس أو USB."
    exit 1
fi

echo "✅ تم العثور على الهاتف: $DEVICE_ID"

if [ "$INSTALL_EXISTING" = false ]; then
    [ "$CLEAN_FIRST" = true ] && "$FLUTTER_CMD" clean
    echo "🏗️ جاري بناء نسخة Release خفيفة..."
    "$FLUTTER_CMD" pub get
    "$FLUTTER_CMD" build apk --release --split-per-abi
fi

DEVICE_ABI=$("$ADB_CMD" -s "$DEVICE_ID" shell getprop ro.product.cpu.abi | tr -d '\r')
case "$DEVICE_ABI" in
    arm64-v8a) APK_PATH="build/app/outputs/flutter-apk/app-arm64-v8a-release.apk" ;;
    armeabi-v7a) APK_PATH="build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk" ;;
    x86_64) APK_PATH="build/app/outputs/flutter-apk/app-x86_64-release.apk" ;;
    *) APK_PATH="build/app/outputs/flutter-apk/app-release.apk" ;;
esac

[ -f "$APK_PATH" ] || APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
if [ ! -f "$APK_PATH" ]; then
    echo "❌ لم يتم العثور على ملف APK. شغّل ./run_app_release.sh أولاً."
    exit 1
fi

echo "📦 ملف APK: $APK_PATH"
echo "📏 الحجم: $(du -h "$APK_PATH" | awk '{ print $1 }')"
echo "📲 جاري تثبيت نسخة Release على الهاتف..."
"$ADB_CMD" -s "$DEVICE_ID" install -r "$APK_PATH"

echo "🚀 جاري تشغيل التطبيق..."
"$ADB_CMD" -s "$DEVICE_ID" shell monkey \
    -p "$PACKAGE_NAME" \
    -c android.intent.category.LAUNCHER \
    1 >/dev/null
#./run_app_release.sh --existing