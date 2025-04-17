#!/bin/bash
#
# TeamViewer 자동 실행(데몬 + GUI) 설정 스크립트
# 1) 데몬(teamviewerd) systemd 서비스 enable + start
# 2) /usr/local/bin/teamviewer-fixed 생성
# 3)   LD_LIBRARY_PATH unset & QT_QPA_PLATFORM=xcb 강제
# 4) ~/.config/autostart/teamviewer.desktop 생성

set -e

# 0. 팀뷰어 실행 파일 경로 확인
TV_BIN="$(which teamviewer || true)"
if [[ -z "$TV_BIN" ]]; then
  echo "teamviewer 실행 파일을 찾을 수 없습니다. 먼저 TeamViewer DEB 패키지를 설치하세요."
  exit 1
fi

echo "▶ teamviewerd 서비스 활성화"
sudo systemctl enable --now teamviewerd.service

echo "▶ /usr/local/bin/teamviewer-fixed 생성"
sudo bash -c "cat > /usr/local/bin/teamviewer-fixed" <<'EOF'
#!/bin/bash
# LD_LIBRARY_PATH 제거하고 X11(xcb) 백엔드로 TeamViewer GUI 실행
env -u LD_LIBRARY_PATH QT_QPA_PLATFORM=xcb $(which teamviewer)
EOF
sudo chmod +x /usr/local/bin/teamviewer-fixed

echo "▶ Autostart .desktop 파일 생성"
mkdir -p ~/.config/autostart
cat > ~/.config/autostart/teamviewer.desktop <<'EOF'
[Desktop Entry]
Type=Application
Exec=/usr/local/bin/teamviewer-fixed
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=TeamViewer
Comment=Start TeamViewer GUI after login (LD_LIBRARY_PATH unset, XCB forced)
EOF

echo "✅ 완료!  재부팅 후에도 데몬과 GUI가 자동으로 실행됩니다."

