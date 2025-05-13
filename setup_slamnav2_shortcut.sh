#!/bin/bash
# 목적: .desktop 파일을 생성하여 setup_slamnav2.sh를 light 모드로 실행

TARGET_SCRIPT="/home/rainbow/setup_robot_pc/setup_slamnav2_final.sh"
DESKTOP_FILE="$HOME/Desktop/setup_slamnav2.desktop"

# Desktop 폴더가 없으면 생성
mkdir -p "$HOME/Desktop"

# .desktop 파일 생성 (light 모드로 실행되도록 인자 전달)
cat <<EOF > "$DESKTOP_FILE"
[Desktop Entry]
Type=Application
Name=Setup SLAMNAV2 (Light Mode)
Exec=bash -c '$TARGET_SCRIPT l'
Icon=utilities-terminal
Terminal=true
Categories=Utility;
EOF

# 실행 권한 부여
chmod +x "$DESKTOP_FILE"

# GNOME 기반 데스크탑의 경우, 실행 허용 표시 추가
gio set "$DESKTOP_FILE" metadata::trusted true 2>/dev/null || true

echo "✅ 바탕화면에 'Setup SLAMNAV2 (Light Mode)' 단축아이콘 생성 완료"

