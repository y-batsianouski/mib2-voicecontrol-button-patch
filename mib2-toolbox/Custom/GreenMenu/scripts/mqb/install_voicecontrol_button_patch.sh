#!/bin/sh
# Installs the voice-control-button patch jar and prepends it to the HMI bootclasspath.
# Every name here is deliberately distinct from other MIB2 patches so several can be
# installed, and uninstalled, independently of each other.
#
# Usage:
#   install_voicecontrol_button_patch.sh            - SD-card install (mounts SD via util_mountsd.sh)
#   install_voicecontrol_button_patch.sh <basedir>  - SD-free install, <basedir> is the parent of Custom/

SCRIPTDIR=$(dirname "$0")

SD_FREE=0
if [ -n "$1" ] && [ -d "$1" ]; then
  export VOLUME="$1"; SD_FREE=1
  echo "Using base dir override: VOLUME=$VOLUME (SD-free install)"
else
  . ${SCRIPTDIR}/util_mountsd.sh
fi

JAR_NAME=VoiceControlButtonPatch.jar
JAR_SRC=${VOLUME}/Custom/LSD/${JAR_NAME}
JAR_DIR=/mnt/app/eso/hmi/lsd/jars
JAR_DST=${JAR_DIR}/${JAR_NAME}

LSD=/mnt/app/eso/hmi/lsd/lsd.sh
LSD_BU=${LSD}.vcbpatch.bu

echo "=== Voice Control Button Patch: install ==="

if [ ! -f "$JAR_SRC" ]; then
  echo "!! ${JAR_SRC} missing, aborting"
  exit 1
fi

mount -uw /mnt/app 2>/dev/null

echo "Installing ${JAR_NAME}"
mkdir -p "$JAR_DIR"
cp -v "$JAR_SRC" "$JAR_DST" || { echo "!! jar copy FAILED"; exit 1; }

if grep -q "${JAR_NAME}" "$LSD"; then
  echo "bootclasspath already patched, skipping"
else
  [ -e "$LSD_BU" ] || { echo "Backup ${LSD} -> ${LSD_BU}"; cp -v "$LSD" "$LSD_BU"; }
  sed -ir 's,^$J9,BOOTCLASSPATH="$BOOTCLASSPATH -Xbootclasspath/p:$BASE_DIR/lsd/jars/'${JAR_NAME}'"\n$J9,g' "$LSD"
  if grep -q "${JAR_NAME}" "$LSD"; then
    echo "  bootclasspath patch OK"
  else
    echo "  bootclasspath patch FAILED, restoring"
    cp -v "$LSD_BU" "$LSD"
    exit 1
  fi
fi

echo
echo "Current bootclasspath lines in ${LSD}:"
grep -n "Xbootclasspath/p:" "$LSD"
echo
echo "Done. REBOOT the unit, then drive-test."
