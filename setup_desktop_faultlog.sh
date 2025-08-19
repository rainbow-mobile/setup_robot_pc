#!/usr/bin/env bash

# 이 스크립트는 'Fault Log 분석기' 바탕화면 바로가기를 생성합니다.

# --- 설정 ---
ANALYZE_SCRIPT_PATH="$HOME/setup_robot_pc/analyze_fault_log3.sh"
DESKTOP_FILE_PATH="$HOME/Desktop/analyze_fault_log.desktop"
# --- 종료 ---

# 1. 분석 스크립트 존재 확인
if [[ ! -f "$ANALYZE_SCRIPT_PATH" ]]; then
    echo "[❌ 오류] 분석 스크립트가 존재하지 않습니다: $ANALYZE_SCRIPT_PATH"
    exit 1
fi

echo "📦 바탕화면 바로가기 파일을 생성합니다..."

# 2. .desktop 내용 생성
cat > "$DESKTOP_FILE_PATH" << EOF
[Desktop Entry]
Version=1.0
Name=Fault Log 분석기
Comment=SLAMNAV2 fault log를 분석합니다.
Type=Application
Exec=bash -c "$ANALYZE_SCRIPT_PATH; echo; read -p '분석이 완료되었습니다. Enter 키를 누르면 창이 닫힙니다... '"
Icon=utilities-terminal
Terminal=true
Categories=Utility;
EOF

# 3. 실행 권한 부여
chmod +x "$DESKTOP_FILE_PATH"

# 4. 신뢰 설정 (GNOME에서 필요)
if command -v gio &> /dev/null; then
    gio set "$DESKTOP_FILE_PATH" metadata::trusted true 2>/dev/null
fi

# 5. 결과 안내
echo ""
echo "✅ 완료! 바탕화면에 'Fault Log 분석기' 아이콘이 생성되었습니다."
echo "🛡️ 클릭 오류 발생 시, 아이콘 우클릭 후 'Allow Launching'을 수동 허용하거나"
echo "   GNOME 설정이 강제된 경우, 이 스크립트를 .local/share/applications/에 복사하는 것도 권장됩니다."

