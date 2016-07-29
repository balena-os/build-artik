#!/bin/bash

VERBOSE=false

TOP=`pwd`
BUILD_DIR="${TOP}/optee_build"
RESULT=${BUILD_DIR}/result


MERGE_TYPE=fixed

BASE_ADDR=0x7fe00000
LOAD_ADDR=0x40000000

LLOADER_FILE=${TOP}/l-loader/l-loader.bin
FIP_FILE=${TOP}/arm-trusted-firmware/build/s5p6818/release/fip.bin
HEADER_FILE=${RESULT}/hdr.bin
SINGLE_FILE=${RESULT}/singleimage.bin
DUMMY_FILE=${RESULT}/dummy.bin

function usage()
{
	echo "Usage: ./gen_singleimage.sh -o RESULT_DIR -l LOADADDR -e LLOADER_BIN -f FIP_BIN -b BASEADDR"
}

function prepare()
{
	if [ ! -f $FIP_FILE ]; then
		echo "no fip file"
		exit 2
	fi

	if [ ! -f $LLOADER_FILE ]; then
		echo "no l-loader file"
		exit 3
	fi

	if [ ! -d ${RESULT} ]; then
		mkdir -p ${RESULT}
	fi
}

function parse_args()
{
    TEMP=`getopt -o "b:e:f:l:ho:v" -- "$@"`
    eval set -- "$TEMP"

    while true; do
        case "$1" in
            -f ) FIP_FILE=$2; shift 2 ;;
	    -e ) LLOADER_FILE=$2; shift 2;;
	    -l ) LOAD_ADDR=$2; shift 2 ;;
	    -b ) BASE_ADDR=$2; shift 2 ;;
            -o )
		    RESULT=$2;
		    HEADER_FILE=${RESULT}/hdr.bin
		    SINGLE_FILE=${RESULT}/singleimage.bin
		    DUMMY_FILE=${RESULT}/dummy.bin
		    shift 2 ;;
            -h ) usage; exit 1 ;;
            -v ) VERBOSE=true; shift 1 ;;
            -- ) break ;;
            *  ) echo "invalid option $1"; usage; exit 1 ;;
        esac
    done
}

function write_header()
{
        if [ ${MERGE_TYPE} != "fixed" ]; then
		FIP_SIZE=`stat --printf="%s" $FIP_FILE`
		LL_SIZE=`stat --printf="%s" $LLOADER_FILE`

		FIP_START=$(($BASE_ADDR + 0x800 + $LL_SIZE))
		#echo -e $(printf "%08x" $xxx)

		./rev.sh $(printf "%08x" $FIP_START) | xxd -r -p >  ${HEADER_FILE}
		./rev.sh $(printf "%08x" $FIP_SIZE)  | xxd -r -p >> ${HEADER_FILE}
		./rev.sh $(printf "%08x" $LOAD_ADDR) | xxd -r -p >> ${HEADER_FILE}
		./rev.sh $(printf "%08x" 0x0) | xxd -r -p >> ${HEADER_FILE}
	fi
}

function merge_bins()
{
        if [ ${MERGE_TYPE} == "fixed" ]; then
		dd if=/dev/zero ibs=1024 count=2050 of=${SINGLE_FILE}
		dd if=${FIP_FILE} of=${SINGLE_FILE} conv=notrunc
		cat ${LLOADER_FILE} >> ${SINGLE_FILE}
	else
		dd if=/dev/zero ibs=2048 count=1 of=${DUMMY_FILE}
		cat ${HEADER_FILE}  >  ${SINGLE_FILE}
		cat ${DUMMY_FILE}   >> ${SINGLE_FILE}
		cat ${LLOADER_FILE} >> ${SINGLE_FILE}
		cat ${FIP_FILE}     >> ${SINGLE_FILE}
        fi
}

parse_args $@


prepare

write_header

merge_bins

exit 0
