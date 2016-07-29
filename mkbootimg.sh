#!/bin/bash

set -x
set -e

die() {
	if [ -n "$1" ]; then echo $1; fi
	exit 1
}

test -e $TARGET_DIR/$KERNEL_TARGET_IMAGE || die "not found"
test -e $INITRD || die "not found"

test -e $TARGET_DIR || mkdir -p $TARGET_DIR
test -e $TMP_DIR || mkdir -p $TMP_DIR

cp $INITRD $TARGET_DIR/$RAMDISK_NAME

pushd $TMP_DIR
dd if=/dev/zero of=boot.img bs=1M count=$BOOT_SIZE
if [ "$BOOT_PART_TYPE" == "vfat" ]; then
	sudo mkfs.vfat -n boot boot.img
else
	if [ "$BOOT_PART_TYPE" == "ext4" ]; then
		sudo mkfs.ext4 -F -L boot -b 4096 boot.img
	fi
fi

test -d mnt || mkdir mnt
sudo mount -o loop boot.img mnt

sudo install -m 664 $TARGET_DIR/$KERNEL_TARGET_IMAGE mnt
sudo install -m 664 $TARGET_DIR/$KERNEL_DTB mnt
sudo install -m 664 $TARGET_DIR/$RAMDISK_NAME mnt

sync; sync;
sudo umount mnt

test -d $TARGET_DIR || mkdir -p $TARGET_DIR
mv boot.img $TARGET_DIR

popd
