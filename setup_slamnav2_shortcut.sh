#!/bin/bash
# 목적: setup_slamnav2_final.sh를 Light 모드로 실행하는 .desktop 파일 생성

TARGET_SCRIPT="/home/rainbow/setup_robot_pc/setup_slamnav2_final.sh"
DESKTOP_FILE="$HOME/Desktop/setup_slamnav2.desktop"

mkdir -p "$HOME/Desktop"

cat <<EOF > "$DESKTOP_FILE"
[Desktop Entry]
Type=Application
Name=Setup SLAMNAV2 (Light Mode)
Exec=gnome-terminal -- bash -c 'sudo bash "$TARGET_SCRIPT" l; echo; echo "Press ENTER to close..."; read'
Icon=utilities-terminal
Terminal=false
Categories=Utility;
EOF

chmod +x "$DESKTOP_FILE"
gio set "$DESKTOP_FILE" metadata::trusted true 2>/dev/null || true

echo "✅ 바탕화면에 'Setup SLAMNAV2 (Light Mode)' 단축아이콘 생성 완료"

