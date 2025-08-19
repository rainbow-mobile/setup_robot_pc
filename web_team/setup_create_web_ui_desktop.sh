#!/usr/bin/env bash
###############################################################################
# create_rdk_install_desktop.sh
# · 바탕화면에 "Install Rainbow Deploy Kit (S100)" 단축아이콘 생성
###############################################################################
set -Eeuo pipefail

TARGET_SCRIPT="/home/rainbow/setup_robot_pc/setup_web_ui.sh"   # 필요 시 절대경로 수정
DESKTOP_FILE="$HOME/Desktop/install_rdk.desktop"

# 바탕화면 폴더가 없으면 생성
mkdir -p "$HOME/Desktop"

# .desktop 파일 작성
cat <<EOF > "$DESKTOP_FILE"
[Desktop Entry]
Type=Application
Name=Install Rainbow Deploy Kit (S100)
Exec=gnome-terminal -- bash -c 'sudo bash "$TARGET_SCRIPT"; echo; echo "Press ENTER to close..."; read'
Icon=utilities-terminal
Terminal=false
Categories=Utility;
EOF

# 실행 권한 부여 및 GNOME 신뢰 플래그 설정
chmod +x "$DESKTOP_FILE"
gio set "$DESKTOP_FILE" metadata::trusted true 2>/dev/null || true

echo "✅ 바탕화면에 'Install Rainbow Deploy Kit (S100)' 아이콘이 생성되었습니다."

