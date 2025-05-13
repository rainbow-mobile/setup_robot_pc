#!/bin/bash
# 목적: .desktop 파일을 생성하여 setup_slamnav2.sh 실행

TARGET_SCRIPT="/home/rainbow/setup_robot_pc/setup_slamnav2.sh"
DESKTOP_FILE="$HOME/Desktop/setup_slamnav2.desktop"

# Desktop 폴더가 없으면 생성
mkdir -p "$HOME/Desktop"

# .desktop 파일 생성
cat <<EOF > "$DESKTOP_FILE"
[Desktop Entry]
Type=Application
Name=Setup SLAMNAV2
Exec=bash -c '$TARGET_SCRIPT'
Icon=utilities-terminal
Terminal=true
Categories=Utility;
EOF

# 실행 권한 부여
chmod +x "$DESKTOP_FILE"

# 신뢰 설정 (GNOME 등 일부 데스크탑 환경에서 필요)
gio set "$DESKTOP_FILE" metadata::trusted true 2>/dev/null || true

echo "✅ 바탕화면에 setup_slamnav2.desktop 생성 완료"

