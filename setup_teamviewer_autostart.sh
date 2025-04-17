#!/bin/bash
set -e

# ------------------------------------------------------------------
# TeamViewer 완전 자동설정 스크립트
# 1) teamviewerd 서비스 마스킹 해제 → 데몬 등록·시작
# 2) /usr/local/bin/teamviewer-fixed 스크립트 생성
#    → LD_LIBRARY_PATH 제거, XCB 플랫폼 강제
# 3) ~/.config/autostart/teamviewer.desktop 생성
#    → 로그인 시 teamviewer-fixed 자동 실행
# ------------------------------------------------------------------

# 0. teamviewer 실행 파일 위치 확인
TV_BIN="$(which teamviewer || true)"
if [[ -z "$TV_BIN" ]]; then
  echo "ERROR: teamviewer 실행 파일을 찾을 수 없습니다."
  echo "먼저 'sudo apt install teamviewer' 등으로 설치해주세요."
  exit 1
fi

echo "▶1) teamviewerd 서비스 unmask → daemon-reload → enable & start"
sudo systemctl unmask teamviewerd.service
sudo systemctl daemon-reload
sudo systemctl enable --now teamviewerd.service

echo "▶2) /usr/local/bin/teamviewer-fixed 생성"
sudo bash -c "cat > /usr/local/bin/teamviewer-fixed" <<EOF
#!/bin/bash
# LD_LIBRARY_PATH 제거하고 X11(xcb) 백엔드로 TeamViewer 실행
env -u LD_LIBRARY_PATH QT_QPA_PLATFORM=xcb $TV_BIN
EOF
sudo chmod +x /usr/local/bin/teamviewer-fixed

echo "▶3) GUI 자동실행용 .desktop 생성"
AUTOSTART_DIR="$HOME/.config/autostart"
mkdir -p "$AUTOSTART_DIR"
cat > "$AUTOSTART_DIR/teamviewer.desktop" <<EOF
[Desktop Entry]
Type=Application
Exec=/usr/local/bin/teamviewer-fixed
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=TeamViewer
Comment=Start TeamViewer GUI after login (LD_LIBRARY_PATH unset, XCB forced)
EOF

echo "✅ 설정 완료!"
echo "  • teamviewerd 데몬이 부팅 시 자동 시작됩니다."
echo "  • 로그인 후 GUI(teamviewer-fixed)가 자동 실행됩니다."

