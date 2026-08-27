#!/bin/sh
# Build VoiceControlButtonPatch.jar for the VW MIB2 / MIB2.5 head unit.
#
# The unit runs IBM J9 on QNX and will only load class-major-46 (Java 1.2) bytecode, so the
# build needs an ancient javac. Two inputs are NOT in this repo and must be supplied:
#
#   VCB_JDK_DIR  directory containing bin/javac. A 32-bit i386 ELF JDK 1.4-era toolchain;
#                it runs only inside the i386 container this script starts.
#                Default: ./toolchain/jdk
#   VCB_LSD_JAR  the OEM lsd.jar extracted from your head unit's lsd.jxe, used solely as the
#                compile classpath so our class can reference OEM types.
#                Default: ./toolchain/lsd.jar
#
# See README.md for how to obtain both.
set -e

ROOT="$(cd "$(dirname "$0")" && pwd)"
SRC="$ROOT/src"
BSRC="$ROOT/.bsrc"
CLS="$ROOT/build/classes"
OUT="$ROOT/build/out"
JAR_NAME="VoiceControlButtonPatch.jar"

VCB_JDK_DIR="${VCB_JDK_DIR:-$ROOT/toolchain/jdk}"
VCB_LSD_JAR="${VCB_LSD_JAR:-$ROOT/toolchain/lsd.jar}"

if [ ! -x "$VCB_JDK_DIR/bin/javac" ]; then
  echo "ERROR: javac not found at $VCB_JDK_DIR/bin/javac"
  echo "       Set VCB_JDK_DIR to a 1.2-capable JDK. See README.md."
  exit 1
fi
if [ ! -f "$VCB_LSD_JAR" ]; then
  echo "ERROR: lsd.jar not found at $VCB_LSD_JAR"
  echo "       Set VCB_LSD_JAR to your unit's lsd.jar. See README.md."
  exit 1
fi

JDK_DIR="$(cd "$VCB_JDK_DIR" && pwd)"
LSD_DIR="$(cd "$(dirname "$VCB_LSD_JAR")" && pwd)"
LSD_FILE="$(basename "$VCB_LSD_JAR")"

echo ">> jdk      : $JDK_DIR"
echo ">> classpath: $LSD_DIR/$LSD_FILE"

# The J9 1.2 javac rejects some 'final' usages accepted by modern compilers.
echo ">> staging src -> .bsrc (stripping 'final')"
rm -rf "$BSRC" "$CLS"
mkdir -p "$BSRC" "$CLS" "$OUT"
( cd "$SRC" && find . -name '*.java' | while read -r f; do
    mkdir -p "$BSRC/$(dirname "$f")"
    sed 's: final : /*final*/ :g' "$SRC/$f" > "$BSRC/$f"
  done )

echo ">> compiling (i386 docker, -source/-target 1.2)"
FILES="$(cd "$BSRC" && find . -name '*.java' | sed 's,^\./,.bsrc/,')"
docker run --rm --platform linux/386 \
  -v "$ROOT":/w \
  -v "$JDK_DIR":/jdk:ro \
  -v "$LSD_DIR":/lsd:ro \
  -w /w \
  i386/debian:bullseye-slim \
  /jdk/bin/javac -encoding UTF-8 -source 1.2 -target 1.2 \
    -cp ".:/lsd/$LSD_FILE" \
    -d build/classes \
    $FILES

echo ">> packaging $JAR_NAME"
JAR="$OUT/$JAR_NAME"
rm -f "$JAR"
( cd "$CLS" && zip -qr "$JAR" . )

echo ">> verifying class major version (must be 46)"
BAD=0
for f in $(find "$CLS" -name '*.class'); do
  MAJ=$(od -An -tu1 -j6 -N2 "$f" | awk 'NF>=2{print $1*256+$2; exit}')
  if [ "$MAJ" != "46" ]; then echo "   !! $f major=$MAJ"; BAD=1; fi
done
[ "$BAD" = "0" ] && echo "   all classes major=46 OK" || { echo "   FAILED"; exit 1; }

echo ">> done: $JAR"
md5 "$JAR" 2>/dev/null || md5sum "$JAR"
