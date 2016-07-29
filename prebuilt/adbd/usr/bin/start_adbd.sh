#!/bin/bash

echo 0 > /sys/class/android_usb/android0/enable
echo adb > /sys/class/android_usb/android0/functions
echo 1 > /sys/class/android_usb/android0/enable

/usr/bin/adbd&
