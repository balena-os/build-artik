#!/bin/bash

set -x
set -e

CHECK_COUNT=0
MAX_RETRY=3

if [ "$1" == "" ]; then
	SERVER_URL="http://artik:artik%40iot@59.13.55.140/downloads/artik/fedora"
else
	SERVER_URL=$1
fi

test -d ${TARGET_DIR} || mkdir -p ${TARGET_DIR}

if [ ! -f $PREBUILT_DIR/$ROOTFS_FILE ]; then
	echo "Not found rootfs. Just download it"
	wget ${SERVER_URL}/$ROOTFS_FILE -O $PREBUILT_DIR/$ROOTFS_FILE
fi

while :
do
	MD5_SUM=$(md5sum $PREBUILT_DIR/$ROOTFS_FILE | awk '{print $1}')
	if [ "$ROOTFS_FILE_MD5" == "$MD5_SUM" ]; then
		break
	fi

	echo "Mismatch MD5 hash. Just download again"
	wget ${SERVER_URL}/$ROOTFS_FILE -O $PREBUILT_DIR/$ROOTFS_FILE

	CHECK_COUNT=$((CHECK_COUNT + 1))

	if [ $CHECK_COUNT -ge $MAX_RETRY ]; then
		exit -1
	fi
done

cp $PREBUILT_DIR/$ROOTFS_FILE $TARGET_DIR/rootfs.tar.gz
