#!/bin/bash
# TeamViewer 완전 삭제 스크립트
# 이 스크립트는 패키지 제거, 잔여 파일 삭제, 저장소 및 GPG 키 제거를 진행합니다.

# root 권한 확인
if [ "$EUID" -ne 0 ]; then
  echo "이 스크립트는 root 권한이 필요합니다. sudo를 사용하여 실행하세요."
  exit 1
fi

echo "TeamViewer 패키지 제거 중..."
# TeamViewer 패키지 및 설정 파일 제거
apt purge teamviewer -y

echo "불필요한 의존성 제거 중..."
apt autoremove -y

echo "잔여 디렉터리 및 파일 삭제 중..."
# 시스템 디렉터리 삭제
rm -rf /opt/teamviewer
rm -rf /etc/teamviewer

# 현재 사용자 홈 디렉터리의 TeamViewer 관련 파일 삭제
# sudo를 사용하여 실행 시 실제 사용자 홈 경로를 얻기 위해 SUDO_USER 사용
if [ -n "$SUDO_USER" ]; then
  USER_HOME=$(eval echo "~$SUDO_USER")
else
  USER_HOME="$HOME"
fi

rm -rf "$USER_HOME/.teamviewer"
rm -rf "$USER_HOME/.config/teamviewer"

echo "TeamViewer 저장소 정보 삭제 중..."
# TeamViewer 저장소 파일이 존재하면 삭제
if [ -f /etc/apt/sources.list.d/teamviewer.list ]; then
  rm /etc/apt/sources.list.d/teamviewer.list
  echo "/etc/apt/sources.list.d/teamviewer.list 삭제됨."
fi

echo "TeamViewer GPG 키 삭제 중..."
# TeamViewer GPG 키 파일이 존재하는 경우 삭제 (키 파일 경로는 시스템에 따라 다를 수 있음)
if [ -f /etc/apt/trusted.gpg.d/teamviewer.gpg ]; then
  rm /etc/apt/trusted.gpg.d/teamviewer.gpg
  echo "/etc/apt/trusted.gpg.d/teamviewer.gpg 삭제됨."
else
  # apt-key 명령어로 키 삭제 (키 ID를 확인 후 수정 필요)
  TEAMVIEWER_KEY_ID="YOUR_KEY_ID_HERE"
  if apt-key list | grep -qi "TeamViewer"; then
    apt-key del "$TEAMVIEWER_KEY_ID"
    echo "TeamViewer GPG 키 (ID: $TEAMVIEWER_KEY_ID) 삭제됨."
  fi
fi

echo "모든 작업 완료. 시스템을 재부팅하시거나 재로그인하여 변경 사항을 확인하세요."

