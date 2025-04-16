#!/bin/bash
#
# 설명:
#  - 1) /usr/local/bin/ 위치에 teamviewer-fixed 실행 스크립트를 생성
#  - 2) 실행 권한 부여
#  - 3) ~/.config/autostart/teamviewer.desktop 생성
#  - 4) 이후 Ubuntu 로그인 시 자동으로 teamviewer-fixed를 실행

# 0. 실제 팀뷰어 실행 파일 경로 확인 (기본 /usr/bin/teamviewer)
TEAMVIEWER_BIN="$(which teamviewer)"
if [[ -z "$TEAMVIEWER_BIN" ]]; then
  echo "팀뷰어(teamviewer) 실행 파일을 찾을 수 없습니다."
  exit 1
fi

# 1. teamviewer-fixed 스크립트 만들기
sudo bash -c "cat << 'EOF' > /usr/local/bin/teamviewer-fixed
#!/bin/bash
# LD_LIBRARY_PATH 제거하고 XCB(즉 X11) 기반으로 TeamViewer 실행
env -u LD_LIBRARY_PATH QT_QPA_PLATFORM=xcb $TEAMVIEWER_BIN
EOF"

# 2. 실행 권한 부여
sudo chmod +x /usr/local/bin/teamviewer-fixed

# 3. autostart용 .desktop 파일 생성
mkdir -p ~/.config/autostart

cat << 'EOF' > ~/.config/autostart/teamviewer.desktop
[Desktop Entry]
Type=Application
Exec=/usr/local/bin/teamviewer-fixed
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=TeamViewer
Comment=Start TeamViewer GUI after login (LD_LIBRARY_PATH unset, XCB forced)
EOF

echo "========================================================"
echo "teamviewer-fixed 스크립트 및 자동 실행 설정이 완료되었습니다."
echo "이제 재부팅 후 로그인하면 TeamViewer가 자동으로 실행됩니다."
echo "========================================================"

