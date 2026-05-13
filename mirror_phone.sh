#!/bin/bash
# سكريبت لتشغيل شاشة الهاتف على اللابتوب

ADB_CMD="$HOME/Android/Sdk/platform-tools/adb"
DEVICE_ID=$($ADB_CMD devices | grep -w "device" | sed 's/[[:space:]]*device$//' | grep -v "List of devices" | head -n 1)

if [ -z "$DEVICE_ID" ]; then
    echo "❌ لم يتم العثور على أي هاتف متصل."
    exit 1
fi

scrcpy -s "$DEVICE_ID"
