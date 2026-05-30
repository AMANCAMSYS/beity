#!/bin/bash
# سكريبت لتشغيل شاشة الهاتف على اللابتوب

ADB_CMD="$HOME/Android/Sdk/platform-tools/adb"

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
    echo "❌ لم يتم العثور على أي هاتف متصل."
    exit 1
fi

scrcpy -s "$DEVICE_ID"
