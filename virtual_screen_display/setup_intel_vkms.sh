#!/bin/bash

# 이 스크립트는 Intel 기반 시스템에서 vkms 커널 모듈을 사용하여 가상 모니터를 설정하거나 제거합니다.
# 1280x1024 해상도를 사용하도록 Xorg 설정을 추가합니다.

# --- 함수 정의 ---

# vkms 설치 함수
install_vkms() {
    echo "vkms를 위한 systemd 서비스를 생성합니다..."
    # 'here document' 문법을 사용하여 파일에 내용을 작성합니다.
    sudo tee /etc/systemd/system/load-vkms.service > /dev/null <<'EOF'
[Unit]
Description=Load vkms kernel module
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/sbin/modprobe vkms
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF

    echo "vkms 가상 모니터의 해상도를 1280x1024으로 설정하기 위한 Xorg 설정을 생성합니다..."
    # Xorg 설정 디렉토리가 없으면 생성합니다.
    sudo mkdir -p /etc/X11/xorg.conf.d/

    # cvt 1280 1024 60 명령으로 생성된 Modeline을 사용합니다.
    sudo tee /etc/X11/xorg.conf.d/10-vkms-resolution.conf > /dev/null <<'EOF'
Section "Monitor"
    Identifier "VirtualMonitor"
    Modeline "1280x1024_60.00"  109.00  1280 1368 1496 1712  1024 1027 1034 1063 -hsync +vsync
EndSection

Section "Device"
    Identifier "VirtualDevice"
    Driver "modesetting"
EndSection

Section "Screen"
    Identifier "VirtualScreen"
    Device "VirtualDevice"
    Monitor "VirtualMonitor"
    DefaultDepth 24
    SubSection "Display"
        Depth 24
        Modes "1280x1024_60.00"
    EndSubSection
EndSection
EOF

    echo "systemd 데몬을 다시 로드합니다..."
    sudo systemctl daemon-reexec
    sudo systemctl daemon-reload

    echo "load-vkms.service를 활성화하고 시작합니다..."
    sudo systemctl enable load-vkms.service
    sudo systemctl restart load-vkms.service

    echo "설정이 완료되었습니다. 시스템을 재부팅하면 변경된 해상도가 적용됩니다."
    echo "sudo reboot 명령으로 재부팅해주세요."
}

# vkms 제거 함수
uninstall_vkms() {
    echo "load-vkms.service를 중지하고 비활성화합니다..."
    # 서비스가 존재하지 않아도 오류를 내지 않도록 || true를 추가합니다.
    sudo systemctl stop load-vkms.service || true
    sudo systemctl disable load-vkms.service || true

    echo "/etc/systemd/system/load-vkms.service 파일을 삭제합니다..."
    sudo rm -f /etc/systemd/system/load-vkms.service

    echo "/etc/X11/xorg.conf.d/10-vkms-resolution.conf 파일을 삭제합니다..."
    sudo rm -f /etc/X11/xorg.conf.d/10-vkms-resolution.conf

    echo "systemd 데몬을 다시 로드합니다..."
    sudo systemctl daemon-reexec
    sudo systemctl daemon-reload

    echo "제거가 완료되었습니다. 재부팅하면 설정이 완전히 제거됩니다."
}

# --- 메인 스크립트 실행 ---

# 명령어 실행 중 오류가 발생하면 즉시 스크립트를 종료합니다.
set -e

# 사용자에게 설치 또는 삭제를 묻습니다.
echo "Intel vkms 가상 모니터 설정을 시작합니다."
echo "원하는 작업을 선택해주세요:"
select choice in "설치 (Install 1280x1024)" "삭제 (Uninstall)" "취소 (Cancel)"; do
    case $choice in
        "설치 (Install 1280x1024)")
            install_vkms
            break
            ;;
        "삭제 (Uninstall)")
            uninstall_vkms
            break
            ;;
        "취소 (Cancel)")
            echo "작업을 취소했습니다."
            break
            ;;
        *)
            echo "잘못된 선택입니다. 1, 2, 3 중에서 선택해주세요."
            ;;
    esac
done


