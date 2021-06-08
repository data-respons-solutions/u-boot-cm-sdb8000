#!/bin/bash

set -e

BUILD_DIR="build/nor"

mkdir -p "$BUILD_DIR"

rm -f "$BUILD_DIR"/spl-prepad
for i in {1..1024}; do
	printf '\xff' >> "$BUILD_DIR"/spl-prepad
done

objcopy -I binary -O binary --pad-to 0x03FC00 --gap-fill 0xff build/imx-mkimage/iMX8M/spl.img "$BUILD_DIR"/spl-padded.img
rm -f "$BUILD_DIR"/platform-padded.bin
for i in {1..65536}; do
	printf '\xff' >> "$BUILD_DIR"/platform-padded.bin
done
objcopy -I binary -O binary --pad-to 0x1A0000 --gap-fill 0xff build/imx-mkimage/iMX8M/u-boot.itb "$BUILD_DIR"/u-boot-padded.itb

cat "$BUILD_DIR"/spl-prepad "$BUILD_DIR"/spl-padded.img "$BUILD_DIR"/platform-padded.bin "$BUILD_DIR"/u-boot-padded.itb > "$BUILD_DIR"/flash.bin
