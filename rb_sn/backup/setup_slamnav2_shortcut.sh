#!/bin/bash
# 목적: setup_slamnav2_final.sh를 Light 모드로 실행하는 .desktop 파일 생성
#        실행 전에 https://github.com/rainbow-mobile/setup_robot_pc 에서 git pull 수행

TARGET_DIR="/home/rainbow/setup_robot_pc"
TARGET_SCRIPT="$TARGET_DIR/setup_slamnav2_final.sh"
DESKTOP_FILE="$HOME/Desktop/setup_slamnav2.desktop"

# 바탕화면 폴더 생성
mkdir -p "$HOME/Desktop"

# .desktop 파일 생성
cat <<EOF > "$DESKTOP_FILE"
[Desktop Entry]
Type=Application
Name=Setup SLAMNAV2 (Light Mode)
# 실행 전 리포지토리 업데이트(git pull) 후 스크립트 실행
Exec=gnome-terminal -- bash -c 'cd "$TARGET_DIR" && git pull https://github.com/rainbow-mobile/setup_robot_pc && sudo bash "$TARGET_SCRIPT" l; echo; echo "Press ENTER to close..."; read'
Icon=utilities-terminal
Terminal=false
Categories=Utility;
EOF

# 실행 권한 부여 및 신뢰 표시
chmod +x "$DESKTOP_FILE"
gio set "$DESKTOP_FILE" metadata::trusted true 2>/dev/null || true

echo "✅ 바탕화면에 'Setup SLAMNAV2 (Light Mode)' 단축아이콘 생성 완료"

