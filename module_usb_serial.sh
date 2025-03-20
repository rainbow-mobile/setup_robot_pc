#!/bin/bash
# module_usb_serial.sh: USB 시리얼 설정 및 그룹 추가 스크립트
# - 현재 사용자를 dialout 그룹에 추가
# - brltty를 제거하여 USB 시리얼 장치와 충돌 방지
# - /etc/udev/rules.d/99-usb-serial.rules 파일을 생성(또는 덮어쓰고)하여 USB udev 규칙을 설정하고, udev 규칙을 재로드 및 트리거합니다.

source ./common.sh

echo "========================================"
echo "USB 시리얼 설정 및 그룹 추가"
echo "========================================"

# 1. 사용자 dialout 그룹 추가 (이미 추가되어 있으면 건너뜁니다)
run_step "사용자 dialout 그룹 추가" \
    "groups $USER | grep -q dialout" \
    "sudo adduser $USER dialout"

# 2. brltty 제거 (USB 시리얼 장치와 충돌할 수 있음)
run_step "brltty 제거" \
    "dpkg -l | grep -q brltty" \
    "sudo apt remove -y brltty"

echo "========================================"
echo "USB udev 규칙 설정"
echo "========================================"

# 3. /etc/udev/rules.d/99-usb-serial.rules 파일에 udev 규칙 기록
sudo sh -c 'cat > /etc/udev/rules.d/99-usb-serial.rules <<EOF
SUBSYSTEM=="tty", KERNELS=="1-7", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", SYMLINK+="ttyRP0"
SUBSYSTEM=="tty", KERNELS=="1-2.3", ATTRS{idVendor}=="067b", ATTRS{idProduct}=="2303", SYMLINK+="ttyBL0"
EOF'

# 4. udev 규칙 재로드 및 트리거
sudo udevadm control --reload-rules
sudo udevadm trigger

echo "USB udev 규칙 설정이 완료되었습니다."

