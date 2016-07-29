#!/bin/bash

set -x
set -e

MICROSD_IMAGE=$1

SD_BOOT_SZ=`expr $ENV_OFFSET + 32`

if [ "$BOOTLOADER_SINGLEIMAGE" == "1" ]; then
	test -e $PREBUILT_DIR/$TARGET_BOARD/bl1-sdboot.bin || exit 0
	test -e $TARGET_DIR/singleimage-sdboot.bin || exit 0
else
	test -e $PREBUILT_DIR/$TARGET_BOARD/bl1.bin || exit 0
	if [ "$USE_BL2_BUILD" == "1" ]; then
		test -e $TARGET_DIR/$UBOOT_SPL || exit 0
	else
		test -e $PREBUILT_DIR/$TARGET_BOARD/bl2.bin || exit 0
	fi
	test -e $PREBUILT_DIR/$TARGET_BOARD/tzsw.bin || exit 0
	test -e $TARGET_DIR/u-boot.bin || exit 0
fi

if [ "$MICROSD_IMAGE" == "1" ]; then
	PARAMS_NAME="params_sdboot.bin"
else
	PARAMS_NAME="params_recovery.bin"
fi

test -e $TARGET_DIR/$PARAMS_NAME || exit 0

IMG_NAME=sd_boot.img

test -d ${TARGET_DIR} || mkdir -p ${TARGET_DIR}
test -d ${TMP_DIR} || mkdir -p ${TMP_DIR}

pushd ${TMP_DIR}

dd if=/dev/zero of=$IMG_NAME bs=512 count=$SD_BOOT_SZ

if [ "$BOOTLOADER_SINGLEIMAGE" == "1" ]; then
	cp $PREBUILT_DIR/$TARGET_BOARD/bl1-sdboot.bin $TARGET_DIR
	cp $PREBUILT_DIR/$TARGET_BOARD/bl1-emmcboot.bin $TARGET_DIR
	cp $PREBUILT_DIR/$TARGET_BOARD/partmap_emmc.txt $TARGET_DIR

	dd conv=notrunc if=$TARGET_DIR/bl1-sdboot.bin of=$IMG_NAME bs=512 seek=$BL1_OFFSET
	dd conv=notrunc if=$TARGET_DIR/singleimage-sdboot.bin of=$IMG_NAME bs=512 seek=$BL2_OFFSET
	dd conv=notrunc if=$TARGET_DIR/$PARAMS_NAME of=$IMG_NAME bs=512 seek=$ENV_OFFSET
else
	cp $PREBUILT_DIR/$TARGET_BOARD/bl1.bin $TARGET_DIR/
	if [ "$USE_BL2_BUILD" == "1" ]; then
		cp $TARGET_DIR/$UBOOT_SPL $TARGET_DIR/bl2.bin
	else
		cp $PREBUILT_DIR/$TARGET_BOARD/bl2.bin $TARGET_DIR/
	fi
	cp $PREBUILT_DIR/$TARGET_BOARD/tzsw.bin $TARGET_DIR/

	dd conv=notrunc if=$TARGET_DIR/bl1.bin of=$IMG_NAME bs=512 seek=$BL1_OFFSET
	dd conv=notrunc if=$TARGET_DIR/bl2.bin of=$IMG_NAME bs=512 seek=$BL2_OFFSET
	dd conv=notrunc if=$TARGET_DIR/u-boot.bin of=$IMG_NAME bs=512 seek=$UBOOT_OFFSET
	dd conv=notrunc if=$TARGET_DIR/tzsw.bin of=$IMG_NAME bs=512 seek=$TZSW_OFFSET
	dd conv=notrunc if=$TARGET_DIR/$PARAMS_NAME of=$IMG_NAME bs=512 seek=$ENV_OFFSET
fi

sync

mv $IMG_NAME $TARGET_DIR

