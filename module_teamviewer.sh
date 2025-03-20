#!/bin/bash
# module_teamviewer.sh: 팀뷰어 설치 (파일이 없으면 다운로드 후 설치) 및 리셋, Wayland 설정 변경

source ./common.sh

echo "========================================"
echo "TeamViewer 설치/리셋 및 Wayland 설정 변경"
echo "========================================"

# 팀뷰어 설치 파일 위치 및 URL 설정
TEAMVIEWER_DEB="$HOME/teamviewer-host_amd64.deb"
TEAMVIEWER_URL="https://download.teamviewer.com/download/linux/teamviewer-host_amd64.deb"

# 팀뷰어 패키지 이름 (설치 후 dpkg -s 로 확인)
PACKAGE_NAME="teamviewer-host"

if [ ! -f "$TEAMVIEWER_DEB" ]; then
    log_msg "TeamViewer 설치 파일이 존재하지 않아 다운로드 및 설치를 진행합니다."
    sudo apt-get update
    wget -P ~ "$TEAMVIEWER_URL"
    sudo apt install "$TEAMVIEWER_DEB" -y
else
    # 설치 파일이 존재하는 경우, 패키지가 설치되어 있는지 확인
    if dpkg -s "$PACKAGE_NAME" &> /dev/null; then
        log_msg "TeamViewer 설치 파일과 패키지가 모두 존재합니다. 설치를 건너뛰고 리셋만 진행합니다."
    else
        log_msg "TeamViewer 설치 파일은 존재하나, 패키지가 설치되지 않았습니다. 설치를 진행합니다."
        sudo apt install "$TEAMVIEWER_DEB" -y
    fi
fi

# TeamViewer 리셋: 이미 설치된 경우 리셋만 적용하도록 함
run_step "TeamViewer 리셋" \
    "test ! -f /etc/teamviewer/global.conf" \
    "sudo teamviewer --daemon stop && sudo rm -f /etc/teamviewer/global.conf && sudo rm -rf ~/.config/teamviewer/ && sudo teamviewer --daemon start"

# Wayland 설정 변경: /etc/gdm3/custom.conf 파일 내의 "#WaylandEnable=false" 주석을 해제
run_step "Wayland 설정 변경" \
    "grep '^WaylandEnable=false' /etc/gdm3/custom.conf &> /dev/null" \
    "sudo sed -i 's/^#\(WaylandEnable=false\)/\1/' /etc/gdm3/custom.conf"

