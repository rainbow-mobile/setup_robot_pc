#!/bin/bash
# reinstall_teamviewer.sh: TeamViewer 실행 시 core dumped 오류가 발생하면
# 필요한 라이브러리와 환경 변수를 적용한 후 기존 설치를 제거하고 재설치 후 실행하는 스크립트.
# 이 스크립트를 실행하기 전에 Firefox 등 관련 프로그램은 종료하고, Xorg 환경에서 실행하는 것을 권장합니다.

# 필요한 필수 라이브러리 설치
echo "필수 라이브러리(libjpeg62, libxtst6, libqt5gui5, libcanberra-gtk-module) 설치 중..."
sudo apt-get update
sudo apt-get install -y libjpeg62 libxtst6 libqt5gui5 libcanberra-gtk-module

# 환경 변수 설정: TeamViewer의 core dumped 문제 해결을 위해 QT_XCB_GL_INTEGRATION을 none으로 설정
echo "QT_XCB_GL_INTEGRATION 환경 변수를 none으로 설정합니다."
export QT_XCB_GL_INTEGRATION=none

# Xorg 환경에서 실행하는 것을 권장합니다.
echo "Xorg 환경에서 실행하는 것을 권장합니다. (현재 Wayland 환경이라면 문제가 발생할 수 있습니다.)"

# 임시 로그 파일 설정
LOGFILE="/tmp/teamviewer_run.log"

# TeamViewer 실행 및 로그 저장
echo "TeamViewer 실행 중..."
teamviewer > "$LOGFILE" 2>&1
RET=$?

# core dumped 오류 감지
if grep -qi "core dumped" "$LOGFILE"; then
    echo "오류: TeamViewer 실행 중 'core dumped'가 발생했습니다."
    echo "기존 TeamViewer를 제거하고 재설치합니다."
    
    # 기존 설치 제거 (패키지 이름은 teamviewer-host로 가정)
    sudo dpkg --purge teamviewer-host
    
    # TeamViewer 설치 파일 및 URL 설정
    TEAMVIEWER_DEB="$HOME/teamviewer-host_amd64.deb"
    TEAMVIEWER_URL="https://download.teamviewer.com/download/linux/teamviewer-host_amd64.deb"
    
    # 설치 파일이 없으면 다운로드
    if [ ! -f "$TEAMVIEWER_DEB" ]; then
        echo "TeamViewer 설치 파일이 존재하지 않습니다. 다운로드합니다."
        wget -P ~ "$TEAMVIEWER_URL"
    fi
    
    # 재설치 진행
    echo "TeamViewer 재설치 중..."
    sudo dpkg -i "$TEAMVIEWER_DEB"
    sudo apt-get install -f -y

    # 재설치 후 환경 변수 재설정
    export QT_XCB_GL_INTEGRATION=none

    echo "TeamViewer 재실행 중..."
    teamviewer
else
    echo "TeamViewer가 정상적으로 실행되었습니다. 종료 코드: $RET"
fi

# 임시 로그 파일 삭제
rm -f "$LOGFILE"

