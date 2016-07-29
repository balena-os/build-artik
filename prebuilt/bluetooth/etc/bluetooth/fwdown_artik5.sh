#!/bin/sh

./brcm_patchram_plus --patchram ./BCM4354_003.001.012.0301.0000_Samsung_Artik_TEST_ONLY.hcd  --no2bytes --baudrate 3000000 --use_baudrate_for_download /dev/ttySAC0 --enable_hci &


