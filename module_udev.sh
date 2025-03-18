#!/bin/bash
# module_udev.sh: USB udev 규칙 설정

source ./common.sh

echo "========================================"
echo "USB udev 규칙 설정"
echo "========================================"

run_step "USB udev 규칙" \
    "test -f /etc/udev/rules.d/99-usb-serial.rules" \
    "sudo bash -c 'cat > /etc/udev/rules.d/99-usb-serial.rules <<EOF
SUBSYSTEM==\"tty\", KERNELS==\"1-7\", ATTRS{idVendor}==\"10c4\", ATTRS{idProduct}==\"ea60\", SYMLINK+=\"ttyRP0\"
SUBSYSTEM==\"tty\", KERNELS==\"1-2.3\", ATTRS{idVendor}==\"067b\", ATTRS{idProduct}==\"2303\", SYMLINK+=\"ttyBL0\"
SUBSYSTEM==\"tty\", KERNELS==\"1-1.2\", ATTRS{idVendor}==\"2109\", ATTRS{idProduct}==\"0812\", SYMLINK+=\"ttyCB0\"
EOF' && sudo udevadm control --reload-rules && sudo udevadm trigger"

