#!/bin/bash

set -x

if [ "$TARGET_DIR" == "" ]; then
	TARGET_DIR=$1
fi

ROOTFS_MAX=3096

test -e $TARGET_DIR/rootfs.tar.gz || exit 0
test -e $TARGET_DIR/artik_release || exit 0

dd if=/dev/zero of=$TARGET_DIR/rootfs.img bs=1M count=$ROOTFS_MAX

mkdir -p $TARGET_DIR/rootfs
mkfs.ext4 -F -b 4096 -L rootfs $TARGET_DIR/rootfs.img
sudo mount -o loop $TARGET_DIR/rootfs.img $TARGET_DIR/rootfs
sudo tar xf $TARGET_DIR/rootfs.tar.gz -C $TARGET_DIR/rootfs
sudo cp $TARGET_DIR/artik_release $TARGET_DIR/rootfs/etc/
sudo touch $TARGET_DIR/rootfs/.need_resize
sync

sudo umount $TARGET_DIR/rootfs
e2fsck -y -f $TARGET_DIR/rootfs.img
resize2fs -M $TARGET_DIR/rootfs.img

ls -al $TARGET_DIR/rootfs.img
