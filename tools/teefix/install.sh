#!/usr/bin/env bash
# install.sh — push TEEFix tools and FIXTEE helper onto a connected
# crDroid 16 (Sony Xperia 1V / SM8550) device via ADB.
#
# Prerequisites:
#   - adb is in PATH
#   - device has root (KernelSU / SukiSU)
#   - device has a keybox imported via Settings → crDroid Settings →
#     Misc → Tricky Store
#
# Usage: ./install.sh
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"

if ! command -v adb >/dev/null 2>&1; then
    echo "adb not found on PATH" >&2
    exit 1
fi

DEVICE="$(adb get-state 2>/dev/null || true)"
if [ "$DEVICE" != "device" ]; then
    echo "No ADB device connected (got: '${DEVICE:-none}')" >&2
    exit 1
fi

echo "[*] Pushing TEEFix binaries to /data/local/tmp/TEEFix/"
adb shell "su -c 'mkdir -p /data/local/tmp/TEEFix /data/adb/teefix'"
adb push "$HERE/KmInstallKeybox"     /data/local/tmp/TEEFix/KmInstallKeybox
adb push "$HERE/libqtikeymaster4.so" /data/local/tmp/TEEFix/libqtikeymaster4.so
adb push "$HERE/FIXTEE"              /data/local/tmp/FIXTEE

echo "[*] Stashing backup copies and installing FIXTEE on root PATH"
adb shell "su -c '
    cp /data/local/tmp/TEEFix/KmInstallKeybox     /data/adb/teefix/
    cp /data/local/tmp/TEEFix/libqtikeymaster4.so /data/adb/teefix/
    chmod 0755 /data/local/tmp/TEEFix/KmInstallKeybox /data/adb/teefix/KmInstallKeybox

    cp /data/local/tmp/FIXTEE /data/adb/ksu/bin/FIXTEE
    chmod 0755 /data/adb/ksu/bin/FIXTEE
    chown root:root /data/adb/ksu/bin/FIXTEE
    ln -sf /data/adb/ksu/bin/FIXTEE /data/adb/ksu/bin/TEEFIX

    rm -f /data/local/tmp/FIXTEE
'"

echo
echo "[OK] Installed. From Termux on the device:"
echo "       su"
echo "       FIXTEE       (or TEEFIX — both work)"
echo "     Then reboot."
