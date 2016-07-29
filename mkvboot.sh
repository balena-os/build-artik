#!/bin/bash

set -e
set -x

OUTPUT_DIR=$1
KEY_DIR=`readlink -e $2`
ITS_FILE=`readlink -e $3`
UBOOT_DIR=`pwd`/../u-boot-artik

ITS_NAME=$(basename "$ITS_FILE")

cp $ITS_FILE $OUTPUT_DIR
pushd $OUTPUT_DIR
./mkimage -D "-I dts -O dtb -p 2000" \
	-f $ITS_NAME -K u-boot.dtb \
	-k $KEY_DIR -r rsa_kernel.fit

# Copy verified boot files to original files
cp rsa_kernel.fit zImage
cat u-boot.bin u-boot.dtb > u-boot-dtb.bin
cp u-boot-dtb.bin u-boot.bin
cp params_vboot.bin params.bin
cp params_recovery_vboot.bin params_recovery.bin
cp params_sdvboot.bin params_sdboot.bin

popd
