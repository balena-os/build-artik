#!/bin/bash

OUTPUT_DIR=`pwd`
MIGRATE_UBOOT=false

print_usage()
{
	echo "-h/--help         Show help options"
	echo "-o       Specify directory of output files"
	echo "-m       Specify option to migrate bootloader"
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
			-m)
				MIGRATE_UBOOT=true
				shift ;;
			*)
				shift ;;
		esac
	done
}

parse_options "$@"

if $MIGRATE_UBOOT; then
	echo "Migrate to new bootloader..."
	sudo fastboot flash bootloader $OUTPUT_DIR/u-boot-recovery.bin
	sudo fastboot reboot-bootloader

	sleep 4
fi

echo "Fusing bootloader binaries..."
sudo fastboot flash fwbl1 $OUTPUT_DIR/bl1.bin
sudo fastboot flash bl2 $OUTPUT_DIR/bl2.bin
sudo fastboot flash bootloader $OUTPUT_DIR/u-boot.bin
sudo fastboot flash tzsw $OUTPUT_DIR/tzsw.bin
sudo fastboot flash env $OUTPUT_DIR/params.bin

sudo fastboot reboot-bootloader

sleep 4
echo "Formatting user partition"
sudo fastboot oem format

sleep 4
echo "Fusing boot image..."
sudo fastboot flash boot $OUTPUT_DIR/boot.img
echo "Fusing modules image..."
sudo fastboot flash modules $OUTPUT_DIR/modules.img
echo "Fusing rootfs image..."
sudo fastboot flash rootfs $OUTPUT_DIR/rootfs.img

sudo fastboot reboot
echo "Fusing done"
