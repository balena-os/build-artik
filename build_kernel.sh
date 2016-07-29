#!/bin/bash

set -e
set -x

test -d $TARGET_DIR || mkdir -p $TARGET_DIR

cd $KERNEL_DIR
make distclean
make $KERNEL_DEFCONFIG
make $KERNEL_IMAGE -j$JOBS EXTRAVERSION="-$BUILD_VERSION"
make $BUILD_DTB EXTRAVERSION="-$BUILD_VERSION"

[ -e ./scripts/mk_modules.h ] && ./scripts/mk_modules.sh $BUILD_VERSION

cp arch/$ARCH/boot/$KERNEL_IMAGE $TARGET_DIR
cp $DTB_PREFIX_DIR/$KERNEL_DTB $TARGET_DIR
cp vmlinux $TARGET_DIR

if [ -e ./scripts/mk_modules.h ]; then
	cp usr/modules.img $TARGET_DIR
else
	mkdir -p $TARGET_DIR/modules
	make modules EXTRAVERSION="-$BUILD_VERSION" -j$JOBS
	make modules_install INSTALL_MOD_PATH=$TARGET_DIR/modules INSTALL_MOD_STRIP=1
	make_ext4fs -b 4096 -L modules \
		-l ${MODULE_SIZE}M ${TARGET_DIR}/modules.img \
		${TARGET_DIR}/modules/lib/modules/
	rm -rf ${TARGET_DIR}/modules
fi

export KERNEL_VERSION=`make EXTRAVERSION="-$BUILD_VERSION" kernelrelease | grep -v scripts`

if [ "$KERNEL_TARGET_IMAGE" == "uImage" ]; then
	$TARGET_DIR/mkimage -A ${ARCH} -O linux -T kernel -C none \
		-a ${KERNEL_LOAD_ADDR} -e ${KERNEL_LOAD_ADDR} \
		-n $KERNEL_VERSION \
		-d ${TARGET_DIR}/${KERNEL_IMAGE} ${TARGET_DIR}/uImage
fi

sed -i "s/BUILD_KERNEL=.*/BUILD_KERNEL=${KERNEL_VERSION}/" $TARGET_DIR/artik_release
