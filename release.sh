#!/bin/bash

set -e

FULL_BUILD=false
VERIFIED_BOOT=false
VBOOT_KEYDIR=
VBOOT_ITS=

print_usage()
{
	echo "-h/--help         Show help options"
	echo "-c/--config       Config file path to build ex) -c config/artik5.cfg"
	echo "-v/--fullver      Pass full version name like: -v A50GC0E-3AF-01030"
	echo "-d/--date		Release date: -d 20150911.112204"
	echo "-m/--microsd	Make a microsd bootable image"
	echo "-u/--url		Specify an url for downloading rootfs"
	echo "--full-build	Full build with generating fedora rootfs"
	echo "--local-rootfs	Copy fedora rootfs from local file instead of downloading"
	echo "--vboot		Generated verified boot image"
	echo "--vboot-keydir	Specify key directoy for verified boot"
	echo "--vboot-its	Specify its file for verified boot"
	exit 0
}

error()
{
	JOB="$0"              # job name
	LASTLINE="$1"         # line of error occurrence
	LASTERR="$2"          # error code
	echo "ERROR in ${JOB} : line ${LASTLINE} with exit code ${LASTERR}"
	exit 1
}

parse_options()
{
	for opt in "$@"
	do
		case "$opt" in
			-h|--help)
				print_usage
				shift ;;
			-c|--config)
				CONFIG_FILE="$2"
				shift ;;
			-v|--fullver)
				BUILD_VERSION="$2"
				shift ;;
			-d|--date)
				BUILD_DATE="$2"
				shift ;;
			-m|--microsd)
				MICROSD_IMAGE="1"
				shift ;;
			-u|--url)
				SERVER_URL="$2"
				shift ;;
			--full-build)
				FULL_BUILD=true
				shift ;;
			--local-rootfs)
				LOCAL_ROOTFS="$2"
				shift ;;
			--vboot)
				VERIFIED_BOOT=true
				shift ;;
			--vboot-keydir)
				VBOOT_KEYDIR="$2"
				shift ;;
			--vboot-its)
				VBOOT_ITS="$2"
				shift ;;
			*)
				shift ;;
		esac
	done
}

package_check()
{
	command -v $1 >/dev/null 2>&1 || { echo >&2 "${1} not installed. Aborting."; exit 1; }
}

gen_artik_release()
{
	upper_model=$(echo -n ${TARGET_BOARD} | awk '{print toupper($0)}')
	cat > $TARGET_DIR/artik_release << __EOF__
BUILD_VERSION=${BUILD_VERSION}
BUILD_DATE=${BUILD_DATE}
BUILD_UBOOT=
BUILD_KERNEL=
MODEL=${upper_model}
WIFI_FW=${WIFI_FW}
BT_FW=${BT_FW}
ZIGBEE_FW=${ZIGBEE_FW}
SE_FW=${SE_FW}
__EOF__
}

trap 'error ${LINENO} ${?}' ERR
parse_options "$@"

package_check kpartx
package_check mkimage
package_check arm-linux-gnueabihf-gcc

if [ "$CONFIG_FILE" != "" ]
then
	. $CONFIG_FILE
fi

if [ "$BUILD_DATE" == "" ]
then
	BUILD_DATE=`date +"%Y%m%d.%H%M%S"`
fi

if [ "$BUILD_VERSION" == "" ]
then
	BUILD_VERSION=UNRELEASED
fi

export BUILD_DATE=$BUILD_DATE
export BUILD_VERSION=$BUILD_VERSION

TARGET_DIR_BACKUP=$TARGET_DIR

export TARGET_DIR=$TARGET_DIR/$BUILD_VERSION/$BUILD_DATE

sudo ls > /dev/null 2>&1

mkdir -p $TARGET_DIR

gen_artik_release

./build_uboot.sh
./build_kernel.sh

if $VERIFIED_BOOT ; then
	if [ "$VBOOT_ITS" == "" ]; then
		VBOOT_ITS=$PREBUILT_DIR/$TARGET_BOARD/kernel_fit_verify.its
	fi
	if [ "$VBOOT_KEYDIR" == "" ]; then
		echo "Please specify key directory using --vboot-keydir"
		exit 0
	fi
	./mkvboot.sh $TARGET_DIR $VBOOT_KEYDIR $VBOOT_ITS
fi

if [ "$BOOTLOADER_SINGLEIMAGE" == "1" ]; then
	./mksinglebootloader.sh
fi

./mksdboot.sh $MICROSD_IMAGE
./mkbootimg.sh

if $FULL_BUILD ; then
	if [ "$BASE_BOARD" != "" ]; then
		FEDORA_TARGET_BOARD=$BASE_BOARD
	else
		FEDORA_TARGET_BOARD=$TARGET_BOARD
	fi

	FEDORA_NAME=fedora-arm-artik-rootfs-$RELEASE_VER-$RELEASE_DATE
	if [ "$FEDORA_PREBUILT_RPM_DIR" != "" ]; then
		./build_fedora.sh -o $TARGET_DIR -b $FEDORA_TARGET_BOARD \
			-p $FEDORA_PACKAGE_FILE -n $FEDORA_NAME \
			-k $FEDORA_KICKSTART_FILE \
			-r $FEDORA_PREBUILT_RPM_DIR
	else
		./build_fedora.sh -o $TARGET_DIR -b $FEDORA_TARGET_BOARD \
			-p $FEDORA_PACKAGE_FILE -n $FEDORA_NAME \
			-k $FEDORA_KICKSTART_FILE
	fi

	FEDORA_TARBALL=${FEDORA_NAME}.tar.gz
	cp $TARGET_DIR/$FEDORA_TARBALL $TARGET_DIR/rootfs.tar.gz
else
	if [ "$LOCAL_ROOTFS" == "" ]; then
		./release_rootfs.sh $SERVER_URL
	else
		cp $LOCAL_ROOTFS $TARGET_DIR/rootfs.tar.gz
	fi
fi

./mksdfuse.sh $MICROSD_IMAGE

./mkrootfs_image.sh $TARGET_DIR

if [ -e $PREBUILT_DIR/$TARGET_BOARD/flash_all_by_fastboot.sh ]; then
	cp $PREBUILT_DIR/$TARGET_BOARD/flash_all_by_fastboot.sh $TARGET_DIR
	cp $PREBUILT_DIR/$TARGET_BOARD/partition.txt $TARGET_DIR
else
	cp flash_all_by_fastboot.sh $TARGET_DIR
fi

if [ -e $PREBUILT_DIR/$TARGET_BOARD/u-boot-recovery.bin ]; then
	cp $PREBUILT_DIR/$TARGET_BOARD/u-boot-recovery.bin $TARGET_DIR
fi

ls -al $TARGET_DIR

echo "ARTIK release information"
cat $TARGET_DIR/artik_release

export TARGET_DIR=$TARGET_DIR_BACKUP
