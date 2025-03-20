#!/bin/bash
# module_teamviewer.sh: TeamViewer 설치 (파일이 없으면 다운로드 후 설치) 및 리셋, Wayland 설정 변경

source ./common.sh

echo "========================================"
echo "TeamViewer 설치/리셋 및 Wayland 설정 변경"
echo "========================================"

# TeamViewer 설치 파일 위치 및 URL 설정
TEAMVIEWER_DEB="$HOME/teamviewer-host_amd64.deb"
TEAMVIEWER_URL="https://download.teamviewer.com/download/linux/teamviewer-host_amd64.deb"

# TeamViewer가 설치되어 있는지, 즉 teamviewer 실행 파일이 있는지 확인합니다.
if ! command -v teamviewer &> /dev/null; then
    # 설치 파일이 없으면 다운로드
    if [ ! -f "$TEAMVIEWER_DEB" ]; then
        log_msg "TeamViewer 설치 파일이 존재하지 않아 다운로드 진행합니다."
        sudo apt-get update
        wget -P ~ "$TEAMVIEWER_URL"
    fi
    log_msg "TeamViewer가 설치되어 있지 않으므로 설치를 진행합니다."
    sudo dpkg -i "$TEAMVIEWER_DEB"
    sudo apt-get install -f -y
else
    log_msg "TeamViewer가 이미 설치되어 있습니다. 설치를 건너뛰고 리셋만 진행합니다."
fi

# TeamViewer 리셋: 이미 설치된 경우 리셋만 적용하도록 함
run_step "TeamViewer 리셋" \
    "test ! -f /etc/teamviewer/global.conf" \
    "sudo systemctl stop teamviewerd.service && sudo rm -f /etc/teamviewer/global.conf && sudo rm -rf ~/.config/teamviewer/ && sudo systemctl start teamviewerd.service"

# Wayland 설정 변경: /etc/gdm3/custom.conf 파일 내의 '#WaylandEnable=false' 주석을 해제
run_step "Wayland 설정 변경" \
    "grep '^WaylandEnable=false' /etc/gdm3/custom.conf &> /dev/null" \
    "sudo sed -i 's/^#\(WaylandEnable=false\)/\1/' /etc/gdm3/custom.conf"

