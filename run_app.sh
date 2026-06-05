#!/usr/bin/env bash
set -Eeuo pipefail

# سكريبت سريع لتشغيل SAWA على الهاتف.
# الافتراضي: تثبيت وتشغيل نسخة Release الموجودة بدون إعادة بناء.
# للتطوير و Hot Reload استخدم: ./run_app.sh --debug

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

ACTION="release"
DEVICE_ID=""
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
PACKAGE_NAME="com.sawa.sawa"

usage() {
  cat <<'EOF'
Usage:
  ./run_app.sh [options]

Options:
  --release      Install and launch the existing release APK. Default.
  --debug        Run Flutter in debug mode for Hot Reload.
  --install      Install the existing release APK without launching.
  --launch       Launch the already installed release app without installing.
  -d, --device   Device id. Example: -d 192.168.1.50:5555
  -h, --help     Show this help.

Examples:
  ./run_app.sh
  ./run_app.sh --debug
  ./run_app.sh --launch
  ./run_app.sh -d emulator-5554
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --release|--run-existing)
      ACTION="release"
      shift
      ;;
    --debug)
      ACTION="debug"
      shift
      ;;
    --install|--install-existing)
      ACTION="install"
      shift
      ;;
    --launch)
      ACTION="launch"
      shift
      ;;
    -d|--device)
      DEVICE_ID="${2:-}"
      if [[ -z "$DEVICE_ID" ]]; then
        echo "Missing value for $1" >&2
        exit 2
      fi
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 2
      ;;
  esac
done

find_flutter() {
  if [[ -n "${FLUTTER_BIN:-}" && -x "${FLUTTER_BIN:-}" ]]; then
    printf '%s\n' "$FLUTTER_BIN"
    return
  fi

  if command -v flutter >/dev/null 2>&1; then
    command -v flutter
    return
  fi

  local candidates=(
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

  local candidate
  for candidate in "${candidates[@]}"; do
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return
    fi
  done

  echo "لم يتم العثور على Flutter. أضف flutter إلى PATH أو عيّن FLUTTER_BIN." >&2
  exit 1
}

find_adb() {
  if [[ -n "${ADB_BIN:-}" && -x "${ADB_BIN:-}" ]]; then
    printf '%s\n' "$ADB_BIN"
    return
  fi

  if command -v adb >/dev/null 2>&1; then
    command -v adb
    return
  fi

  local candidates=(
    "$HOME/Android/Sdk/platform-tools/adb"
    "${ANDROID_HOME:-}/platform-tools/adb"
    "${ANDROID_SDK_ROOT:-}/platform-tools/adb"
  )

  local candidate
  for candidate in "${candidates[@]}"; do
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return
    fi
  done

  echo "لم يتم العثور على adb. ثبّت Android platform-tools أو عيّن ADB_BIN." >&2
  exit 1
}

apk_size() {
  local path="$1"
  if [[ -f "$path" ]]; then
    du -h "$path" | awk '{ print $1 }'
  fi
}

find_device() {
  local adb="$1"

  if [[ -n "$DEVICE_ID" ]]; then
    return
  fi

  echo "🔍 جاري البحث عن الهاتف المتصل..."

  mapfile -t DEVICE_IDS < <(
    "$adb" devices |
      tail -n +2 |
      sed -n 's/[[:space:]]*device$//p' |
      sed '/^[[:space:]]*$/d'
  )

  local id
  for id in "${DEVICE_IDS[@]}"; do
    if [[ "$id" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+$ ]]; then
      DEVICE_ID="$id"
      break
    fi
  done

  if [[ -z "$DEVICE_ID" ]]; then
    for id in "${DEVICE_IDS[@]}"; do
      if [[ "$id" != *"_adb-tls-connect._tcp"* ]]; then
        DEVICE_ID="$id"
        break
      fi
    done
  fi

  if [[ -z "$DEVICE_ID" ]]; then
    for id in "${DEVICE_IDS[@]}"; do
      if [[ "$id" == *"_adb-tls-connect._tcp"* ]]; then
        DEVICE_ID="$id"
        echo "ℹ️ تم العثور على الهاتف عبر mDNS. للحصول على اسم ثابت استخدم adb connect IP:PORT."
        break
      fi
    done
  fi
}

require_android_device() {
  local adb="$1"
  find_device "$adb"

  if [[ -z "$DEVICE_ID" ]]; then
    echo "⚠️ لم يتم العثور على أي هاتف أندرويد متصل عبر الوايرلس أو USB." >&2
    exit 1
  fi

  echo "✅ تم العثور على الهاتف: $DEVICE_ID"
}

install_release_apk() {
  local adb="$1"

  if [[ ! -f "$APK_PATH" ]]; then
    echo "لم يتم العثور على نسخة Release: $APK_PATH" >&2
    echo "ابنها مرة واحدة باستخدام: ./run_app_release.sh" >&2
    exit 1
  fi

  echo "📦 حجم النسخة: $(apk_size "$APK_PATH")"
  echo "📲 جاري تثبيت نسخة Release الموجودة..."
  "$adb" -s "$DEVICE_ID" install -r "$APK_PATH"
}

launch_release_app() {
  local adb="$1"

  echo "🚀 جاري تشغيل نسخة Release..."
  "$adb" -s "$DEVICE_ID" shell monkey \
    -p "$PACKAGE_NAME" \
    -c android.intent.category.LAUNCHER \
    1 >/dev/null
}

ADB_CMD="$(find_adb)"

if [[ "$ACTION" == "debug" ]]; then
  FLUTTER_CMD="$(find_flutter)"
  find_device "$ADB_CMD"

  if [[ -z "$DEVICE_ID" ]]; then
    echo "⚠️ لم يتم العثور على أي هاتف أندرويد متصل عبر الوايرلس أو USB."
    echo "🌐 جاري التبديل للتشغيل على متصفح Chrome كبديل..."
    DEVICE_ID="chrome"
  else
    echo "✅ تم العثور على الهاتف: $DEVICE_ID"
  fi

  echo "🚀 جاري تشغيل التطبيق في وضع Debug..."
  "$FLUTTER_CMD" run -d "$DEVICE_ID"
  DEBUG_APK_PATH="build/app/outputs/flutter-apk/app-debug.apk"
  if [[ -f "$DEBUG_APK_PATH" ]]; then
    echo "📦 حجم نسخة Debug: $(apk_size "$DEBUG_APK_PATH")"
  fi
  exit 0
fi

require_android_device "$ADB_CMD"

if [[ "$ACTION" == "install" ]]; then
  install_release_apk "$ADB_CMD"
elif [[ "$ACTION" == "launch" ]]; then
  launch_release_app "$ADB_CMD"
else
  install_release_apk "$ADB_CMD"
  launch_release_app "$ADB_CMD"
fi
