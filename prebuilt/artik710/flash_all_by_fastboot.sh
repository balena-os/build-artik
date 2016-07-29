#!/bin/bash

OUTPUT_DIR=`pwd`
MIGRATE_UBOOT=false

print_usage()
{
	echo "-h/--help         Show help options"
	echo "-o       Specify directory of output files"
	exit 0
}

parse_options()
{
	for opt in "$@"
	do
		case "$opt" in
			-h|--help)
				print_usage
				shift ;;
			-o)
				OUTPUT_DIR="$2"
				shift ;;
			*)
				shift ;;
		esac
	done
}

parse_options "$@"

echo "Fusing bootloader binaries..."
sudo fastboot flash partmap $OUTPUT_DIR/partmap_emmc.txt
sudo fastboot flash 2ndboot $OUTPUT_DIR/bl1-emmcboot.bin
sudo fastboot flash bootloader $OUTPUT_DIR/singleimage-emmcboot.bin
sudo fastboot flash env $OUTPUT_DIR/params_mmcboot.bin

echo "Fusing boot image..."
sudo fastboot flash boot $OUTPUT_DIR/boot.img
echo "Fusing modules image..."
sudo fastboot flash modules $OUTPUT_DIR/modules.img
echo "Fusing rootfs image..."

sudo fastboot flash setenv $OUTPUT_DIR/partition.txt
sudo fastboot flash -S 0 rootfs $OUTPUT_DIR/rootfs.img

sudo fastboot reboot

echo "Fusing done"
echo "You have to resize the rootfs after first booting"
echo "Run $ resize2fs /dev/mmcblk0p3"
