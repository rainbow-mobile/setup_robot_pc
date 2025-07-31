#!/bin/bash

# ========================== 설정 ==========================
PM2_PATH="/home/rainbow/.nvm/versions/node/v22.17.1/bin/pm2"
# ==========================================================

# 경로 설정
SYSTEM_APP_DIR="${HOME}/.local/share/applications"
DESKTOP_DIR="${HOME}/Desktop"
START_FILE="pm2-start.desktop"
STOP_FILE="pm2-stop-slamnav2.desktop"

echo "📦 PM2 데스크탑 및 시스템 바로가기 생성 시작..."

# 폴더 생성
mkdir -p "${SYSTEM_APP_DIR}"
mkdir -p "${DESKTOP_DIR}"

# ------------------------------
# 공통 내용 정의
# ------------------------------
START_CONTENT="[Desktop Entry]
Version=1.0
Type=Application
Name=PM2 전체 시작
Comment=ecosystem.config.js로 모든 PM2 프로세스를 시작합니다.
Exec=bash -c \"cd /home/rainbow/slamnav2/ && ${PM2_PATH} start ecosystem.config.js; exec bash\"
Icon=utilities-terminal
Terminal=true
Categories=Utility;
"

STOP_CONTENT="[Desktop Entry]
Version=1.0
Type=Application
Name=SLAMNAV2 종료
Comment=SLAMNAV2 프로세스만 종료합니다.
Exec=bash -c \"${PM2_PATH} stop SLAMNAV2; exec bash\"
Icon=process-stop
Terminal=true
Categories=Utility;
"

# ------------------------------
# 파일 생성 함수
# ------------------------------
create_shortcut() {
    local TARGET_DIR="$1"

    echo "$START_CONTENT" > "${TARGET_DIR}/${START_FILE}"
    echo "$STOP_CONTENT" > "${TARGET_DIR}/${STOP_FILE}"

    chmod +x "${TARGET_DIR}/${START_FILE}" "${TARGET_DIR}/${STOP_FILE}"
}

# 시스템 경로 생성
create_shortcut "${SYSTEM_APP_DIR}"

# 데스크탑 경로 생성 + 신뢰 설정
create_shortcut "${DESKTOP_DIR}"
gio set "${DESKTOP_DIR}/${START_FILE}" metadata::trusted true 2>/dev/null
gio set "${DESKTOP_DIR}/${STOP_FILE}" metadata::trusted true 2>/dev/null

# GNOME 애플리케이션 메뉴 갱신
if command -v update-desktop-database &>/dev/null; then
    update-desktop-database "${SYSTEM_APP_DIR}" || true
fi

echo ""
echo "✅ 생성 완료!"
echo "📂 [메뉴 실행] ~/.local/share/applications/pm2-start.desktop"
echo "🖥️ [바탕화면 실행] ~/Desktop/pm2-start.desktop"
echo "📎 GNOME에서 메뉴 등록이 안 보일 경우, 로그아웃 후 재로그인 하세요."

