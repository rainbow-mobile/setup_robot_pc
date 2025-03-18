#!/bin/bash
# module_teamviewer.sh: TeamViewer 설정 리셋 및 Wayland 설정 변경

source ./common.sh

echo "========================================"
echo "TeamViewer 리셋 및 Wayland 설정 변경"
echo "========================================"

# 패키지 리스트 업데이트
sudo apt-get update

# 팀뷰어 설치 파일을 Home 경로에 다운로드
#wget -P ~/ https://download.teamviewer.com/download/linux/teamviewer_arm64.deb
wget -P ~/ https://download.teamviewer.com/download/linux/teamviewer-host_amd64.deb

# 다운로드한 설치 파일을 이용하여 팀뷰어 설치
sudo apt install ~/teamviewer-host_amd64.deb -y

# TeamViewer 리셋
run_step "TeamViewer 리셋" \
    "test ! -f /etc/teamviewer/global.conf" \
    "sudo teamviewer --daemon stop && sudo rm -f /etc/teamviewer/global.conf && sudo rm -rf ~/.config/teamviewer/ && sudo teamviewer --daemon start"

# Wayland 설정 변경: /etc/gdm3/custom.conf 파일 내의 "#WaylandEnable=false" 라인의 주석 해제
run_step "Wayland 설정 변경" \
    "grep '^WaylandEnable=false' /etc/gdm3/custom.conf &> /dev/null" \
    "sudo sed -i 's/^#\(WaylandEnable=false\)/\1/' /etc/gdm3/custom.conf"

