#!/bin/bash
# module_wireless_driver.sh: RTL8812AU 무선 드라이버 설치

source ./common.sh

echo "========================================"
echo "4. 무선 드라이버 (RTL8812AU)"
echo "========================================"

run_step "RTL8812AU 드라이버" \
    "[ -d rtl8812au ]" \
    "git clone https://github.com/gnab/rtl8812au.git && sudo cp -r rtl8812au /usr/src/rtl8812au-4.2.2 && sudo dkms add -m rtl8812au -v 4.2.2 && sudo dkms build -m rtl8812au -v 4.2.2 && sudo dkms install -m rtl8812au -v 4.2.2 && sudo modprobe 8812au"

