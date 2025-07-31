#!/usr/bin/env bash

# 이 스크립트는 'Fault Log 분석기' 바탕화면 바로가기를 생성합니다.

# --- 설정 ---
# 분석 스크립트 경로 (수정 가능)
ANALYZE_SCRIPT_PATH="$HOME/setup_robot_pc/analyze_fault_log3.sh"

# 생성될 바탕화면 바로가기 파일 경로
DESKTOP_FILE_PATH="$HOME/Desktop/analyze_fault_log.desktop"
# --- 종료 ---


# 1. 분석 스크립트 파일이 실제로 존재하는지 확인
if [[ ! -f "$ANALYZE_SCRIPT_PATH" ]]; then
    echo "[오류] 분석 스크립트 파일을 찾을 수 없습니다."
    echo "경로를 확인하세요: $ANALYZE_SCRIPT_PATH"
    exit 1
fi

echo "바탕화면 바로가기 파일을 생성합니다..."

# 2. .desktop 파일 내용 작성 (Here Document 사용)
#    Exec 라인에 read 명령어를 추가하여 실행 후 바로 닫히는 것을 방지
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

# 3. 생성된 파일에 실행 권한 부여
chmod +x "$DESKTOP_FILE_PATH"

echo "✅ 완료! 바로가기가 수정되었습니다. 바탕화면에서 다시 실행해보세요."
