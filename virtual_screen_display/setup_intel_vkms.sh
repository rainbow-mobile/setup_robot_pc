#!/bin/bash

# 이 스크립트는 Intel 기반 시스템에서 vkms 커널 모듈을 사용하여 가상 모니터를 설정하거나 제거합니다.
# 커널 부팅 파라미터를 수정하여 사용자가 입력한 해상도를 강제로 설정하는 가장 확실한 방법을 사용합니다.

# --- 함수 정의 ---

# vkms 설치 함수 (강화된 버전)
install_vkms() {
    echo "--- 가상 모니터 설치를 시작합니다 (커널 파라미터 방식) ---"

    # 사용자로부터 해상도 입력받기
    read -p "원하는 가로 해상도를 입력하세요 (예: 1920): " width
    read -p "원하는 세로 해상도를 입력하세요 (예: 1080): " height

    # 입력값이 숫자인지 간단히 확인
    if ! [[ "$width" =~ ^[0-9]+$ ]] || ! [[ "$height" =~ ^[0-9]+$ ]]; then
        echo "오류: 해상도는 숫자로만 입력해야 합니다."
        exit 1
    fi
    
    local resolution="${width}x${height}"
    echo "해상도를 ${resolution}으로 설정합니다."


    echo "1. 부팅 시 vkms 모듈을 로드하도록 설정합니다..."
    sudo tee /etc/modules-load.d/vkms.conf > /dev/null <<'EOF'
vkms
EOF

    # 기존의 systemd 서비스 방식이 남아있다면 정리합니다.
    if [ -f /etc/systemd/system/load-vkms.service ]; then
        echo "   > 기존 systemd 서비스를 정리합니다."
        sudo systemctl stop load-vkms.service || true
        sudo systemctl disable load-vkms.service || true
        sudo rm -f /etc/systemd/system/load-vkms.service
        sudo systemctl daemon-reload
    fi

    echo "2. GRUB 부트로더 설정을 백업합니다 (/etc/default/grub.bak.vkms)..."
    sudo cp /etc/default/grub /etc/default/grub.bak.vkms

    echo "3. GRUB 설정에 'video=Virtual-1-1:${resolution}@60' 커널 파라미터를 추가합니다..."
    # 기존에 추가되었을 수 있는 video 파라미터를 먼저 제거하여 중복을 방지합니다.
    sudo sed -i 's/ video=Virtual-1-1:[^"]*//g' /etc/default/grub
    # 새로운 파라미터를 추가합니다.
    sudo sed -i "s/\\(GRUB_CMDLINE_LINUX_DEFAULT=\"[^\"]*\\)\"/\\1 video=Virtual-1-1:${resolution}@60\"/" /etc/default/grub

    echo "4. GRUB 부트로더를 업데이트합니다. 시스템에 따라 시간이 걸릴 수 있습니다..."
    sudo update-grub

    echo "5. xrandr 해상도 설정 서비스를 생성합니다..."
    sudo tee /etc/systemd/system/vkms-resolution.service > /dev/null <<EOF
[Unit]
Description=Set vkms virtual display resolution
After=display-manager.service
Wants=display-manager.service

[Service]
Type=oneshot
Environment=DISPLAY=:0
ExecStartPre=/bin/sleep 3
ExecStart=/usr/bin/xrandr --output Virtual-1-1 --mode ${resolution}
RemainAfterExit=yes
User=$SUDO_USER

[Install]
WantedBy=graphical.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable vkms-resolution.service

    echo ""
    echo "--- 설치가 완료되었습니다 ---"
    echo "★★★★★ 중요: 변경 사항을 적용하려면 반드시 시스템을 재부팅해야 합니다. ★★★★★"
    echo "sudo reboot 명령으로 지금 재부팅해주세요."
}

# vkms 완전 제거 함수 (강화된 버전)
uninstall_vkms_thorough() {
    echo "--- 가상 모니터 설정 완전 제거를 시작합니다 ---"

    echo "1. GRUB 부트로더 설정을 복원하거나 정리합니다..."
    if [ -f /etc/default/grub.bak.vkms ]; then
        echo "   > 백업 파일로부터 GRUB 설정을 복원합니다."
        sudo mv /etc/default/grub.bak.vkms /etc/default/grub
    else
        echo "   > 백업 파일이 없습니다. GRUB 설정에서 video 파라미터를 수동으로 제거합니다."
        sudo sed -i 's/ video=Virtual-1-1:[^"]*//g' /etc/default/grub
    fi

    echo "2. GRUB 부트로더를 업데이트합니다..."
    sudo update-grub

    echo "3. 관련 설정 파일을 모두 삭제합니다..."
    sudo rm -f /etc/modules-load.d/vkms.conf
    sudo rm -f /etc/X11/xorg.conf.d/10-vkms-resolution.conf
    # systemd 서비스 파일 삭제
    sudo systemctl disable vkms-resolution.service 2>/dev/null || true
    sudo rm -f /etc/systemd/system/vkms-resolution.service
    sudo rm -f /etc/systemd/system/load-vkms.service
    sudo systemctl daemon-reload

    # 데스크톱 환경(GNOME 등)에 저장된 사용자 디스플레이 설정을 초기화합니다.
    MONITORS_CONFIG_FILE="$HOME/.config/monitors.xml"
    echo "4. 사용자 디스플레이 설정을 초기화합니다..."
    if [ -f "$MONITORS_CONFIG_FILE" ]; then
        echo "   > 기존 디스플레이 설정 파일($MONITORS_CONFIG_FILE)을 백업하고 삭제합니다."
        mv "$MONITORS_CONFIG_FILE" "${MONITORS_CONFIG_FILE}.bak"
    else
        echo "   > 사용자 디스플레이 설정 파일이 없어 건너뜁니다."
    fi
    
    echo "5. 부팅 환경(initramfs)을 업데이트합니다..."
    sudo update-initramfs -u

    echo ""
    echo "--- 제거 작업이 완료되었습니다 ---"
    echo "★★★★★ 중요: 모든 설정을 완전히 되돌리려면 반드시 시스템을 재부팅해야 합니다. ★★★★★"
    echo "sudo reboot 명령으로 지금 재부팅해주세요."
}


# --- 메인 스크립트 실행 ---

# 명령어 실행 중 오류가 발생하면 즉시 스크립트를 종료합니다.
set -e

# 사용자에게 설치 또는 삭제를 묻습니다.
echo "Intel vkms 가상 모니터 설정을 시작합니다."
echo "원하는 작업을 선택해주세요:"
select choice in "설치 (Install with custom resolution)" "삭제 (Thorough Uninstall)" "취소 (Cancel)"; do
    case $choice in
        "설치 (Install with custom resolution)")
            install_vkms
            break
            ;;
        "삭제 (Thorough Uninstall)")
            uninstall_vkms_thorough
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


