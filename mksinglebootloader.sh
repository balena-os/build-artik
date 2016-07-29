#!/bin/bash

set -e
set -x

$PREBUILT_DIR/fip_create --dump --bl2 $BL2_BIN --bl31 $BL31_BIN --bl32 $BL32_BIN \
	--bl33 $TARGET_DIR/u-boot.bin $TARGET_DIR/fip.bin
./gen_singleimage.sh -o $TARGET_DIR -e $LLOADER_BIN -f $TARGET_DIR/fip.bin

$PREBUILT_DIR/BOOT_BINGEN -c $BASE_MACH -t 3rdboot -n $NSIH_EMMC \
	-i $TARGET_DIR/singleimage.bin \
	-o $TARGET_DIR/singleimage-emmcboot.bin \
	-l $BL2_LOAD_ADDR -e $BL2_JUMP_ADDR

$PREBUILT_DIR/BOOT_BINGEN -c $BASE_MACH -t 3rdboot -n $NSIH_SD \
	-i $TARGET_DIR/singleimage.bin \
	-o $TARGET_DIR/singleimage-sdboot.bin \
	-l $BL2_LOAD_ADDR -e $BL2_JUMP_ADDR
