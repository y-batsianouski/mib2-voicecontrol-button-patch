#!/bin/sh
# Removes the voice-control-button patch jar and reverts the bootclasspath patch.
#
# Only touches names owned by this patch, so any co-installed MIB2 patch survives
# untouched. Restoring lsd.sh from our own backup would clobber a
# co-installed patch, so the line is deleted surgically instead.

JAR_NAME=VoiceControlButtonPatch.jar
JAR_DST=/mnt/app/eso/hmi/lsd/jars/${JAR_NAME}

LSD=/mnt/app/eso/hmi/lsd/lsd.sh
LSD_BU=${LSD}.vcbpatch.bu

echo "=== Voice Control Button Patch: uninstall ==="

mount -uw /mnt/app 2>/dev/null

if grep -q "${JAR_NAME}" "$LSD"; then
  echo "Removing bootclasspath line for ${JAR_NAME}"
  sed -i "/${JAR_NAME}/d" "$LSD"
  if grep -q "${JAR_NAME}" "$LSD"; then
    echo "  surgical removal FAILED, falling back to backup restore"
    [ -e "$LSD_BU" ] && cp -v "$LSD_BU" "$LSD"
  else
    echo "  bootclasspath line removed"
  fi
else
  echo "bootclasspath not patched, nothing to revert"
fi

[ -e "$LSD_BU" ] && rm -f "$LSD_BU"

echo "Removing ${JAR_DST}"
rm -f "$JAR_DST"


echo
echo "Remaining bootclasspath lines in ${LSD}:"
grep -n "Xbootclasspath/p:" "$LSD"
echo
echo "Done. REBOOT the unit."
