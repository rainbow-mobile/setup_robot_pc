#!/bin/bash

# 이 스크립트는 Intel 기반 시스템에서 vkms 커널 모듈을 사용하여 가상 모니터를 설정하거나 제거합니다.

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

    echo "systemd 데몬을 다시 로드합니다..."
    sudo systemctl daemon-reexec
    sudo systemctl daemon-reload

    echo "load-vkms.service를 활성화하고 시작합니다..."
    sudo systemctl enable load-vkms.service
    sudo systemctl start load-vkms.service

    echo "서비스 상태를 확인합니다..."
    systemctl status load-vkms.service

    echo "설정이 완료되었습니다. 서비스 상태가 'active (exited)'이면 성공적으로 설정된 것입니다."
}

# vkms 제거 함수
uninstall_vkms() {
    echo "load-vkms.service를 중지하고 비활성화합니다..."
    # 서비스가 존재하지 않아도 오류를 내지 않도록 || true를 추가합니다.
    sudo systemctl stop load-vkms.service || true
    sudo systemctl disable load-vkms.service || true

    echo "/etc/systemd/system/load-vkms.service 파일을 삭제합니다..."
    sudo rm -f /etc/systemd/system/load-vkms.service

    echo "systemd 데몬을 다시 로드합니다..."
    sudo systemctl daemon-reexec
    sudo systemctl daemon-reload

    echo "제거가 완료되었습니다."
}

# --- 메인 스크립트 실행 ---

# 명령어 실행 중 오류가 발생하면 즉시 스크립트를 종료합니다.
set -e

# 사용자에게 설치 또는 삭제를 묻습니다.
echo "Intel vkms 가상 모니터 설정을 시작합니다."
echo "원하는 작업을 선택해주세요:"
select choice in "설치 (Install)" "삭제 (Uninstall)" "취소 (Cancel)"; do
    case $choice in
        "설치 (Install)")
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


