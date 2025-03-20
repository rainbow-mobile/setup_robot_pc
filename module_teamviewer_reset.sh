#!/bin/bash
# reset_teamviewer.sh: TeamViewer 재설치 및 설정 리셋 (추가 의존성 확인 포함) 스크립트
# 이 스크립트는 TeamViewer 설치 파일이 없으면 다운로드하고, 필수 32비트 라이브러리 등 의존성을 설치한 후 TeamViewer를 설치 또는 리셋합니다.
# 또한 Wayland 관련 설정도 변경합니다.

# common.sh 스크립트가 같은 디렉터리에 있어야 합니다.
source ./common.sh

echo "========================================"
echo "TeamViewer 재설치 및 리셋, 의존성 확인 및 Wayland 설정 변경"
echo "========================================"

# TeamViewer 설치 파일 위치 및 URL 설정
TEAMVIEWER_DEB="$HOME/teamviewer-host_amd64.deb"
TEAMVIEWER_URL="https://download.teamviewer.com/download/linux/teamviewer-host_amd64.deb"

# 32비트 라이브러리 등 필수 의존성 설치 (64비트 시스템의 경우)
echo "필수 의존성(32비트 라이브러리) 설치 중..."
sudo dpkg --add-architecture i386
sudo apt update
sudo apt install -y libjpeg62:i386 lib32stdc++6

# TeamViewer가 설치되어 있는지 확인
if ! command -v teamviewer &> /dev/null; then
    if [ ! -f "$TEAMVIEWER_DEB" ]; then
        log_msg "TeamViewer 설치 파일이 없으므로 다운로드를 진행합니다."
        wget -P ~ "$TEAMVIEWER_URL"
    fi
    log_msg "TeamViewer가 설치되어 있지 않으므로 설치를 진행합니다."
    sudo dpkg -i "$TEAMVIEWER_DEB"
    sudo apt-get install -f -y
else
    log_msg "TeamViewer가 이미 설치되어 있습니다. 설치는 건너뛰고 리셋만 진행합니다."
fi

# TeamViewer 리셋: 기존 설정 삭제 후 서비스 재시작
run_step "TeamViewer 리셋" \
    "test ! -f /etc/teamviewer/global.conf" \
    "sudo systemctl stop teamviewerd.service && sudo rm -f /etc/teamviewer/global.conf && sudo rm -rf ~/.config/teamviewer/ && sudo systemctl start teamviewerd.service"

# Wayland 설정 변경: /etc/gdm3/custom.conf 파일 내의 '#WaylandEnable=false' 주석을 해제
run_step "Wayland 설정 변경" \
    "grep '^WaylandEnable=false' /etc/gdm3/custom.conf &> /dev/null" \
    "sudo sed -i 's/^#\(WaylandEnable=false\)/\1/' /etc/gdm3/custom.conf"

echo "========================================"
echo "모든 작업이 완료되었습니다. TeamViewer를 실행하여 문제가 해결되었는지 확인하세요."

