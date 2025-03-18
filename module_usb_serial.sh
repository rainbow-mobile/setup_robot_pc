#!/bin/bash
# module_usb_serial.sh: USB 시리얼 설정 및 dialout 그룹 추가, brltty 제거

source ./common.sh

echo "========================================"
echo "USB 시리얼 설정 및 그룹 추가"
echo "========================================"

run_step "사용자 dialout 그룹 추가" \
    "groups $USER | grep -q dialout" \
    "sudo adduser $USER dialout"

run_step "brltty 제거" \
    "dpkg -l | grep -q brltty" \
    "sudo apt remove -y brltty"

