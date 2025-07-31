#!/bin/bash

# ========================== 설정 ==========================
PM2_PATH="/home/rainbow/.nvm/versions/node/v22.17.1/bin/pm2"
# =========================================================

# 설치 위치 변경: .local/share/applications (신뢰 오류 방지)
OUTPUT_DIR="${HOME}/.local/share/applications"
mkdir -p "${OUTPUT_DIR}"

START_FILE="pm2-start.desktop"
STOP_FILE="pm2-stop-slamnav2.desktop"

echo "📦 PM2 데스크탑 바로가기 생성 시작..."

# 기존 파일 삭제
rm -f "${OUTPUT_DIR}/${START_FILE}" "${OUTPUT_DIR}/${STOP_FILE}"

# 시작 바로가기
cat <<EOF > "${OUTPUT_DIR}/${START_FILE}"
[Desktop Entry]
Version=1.0
Type=Application
Name=PM2 전체 시작
Comment=ecosystem.config.js로 모든 PM2 프로세스를 시작합니다.
Exec=bash -c "cd /home/rainbow/slamnav2/ && ${PM2_PATH} start ecosystem.config.js; exec bash"
Icon=utilities-terminal
Terminal=true
Categories=Application;System;
EOF

# 종료 바로가기
cat <<EOF > "${OUTPUT_DIR}/${STOP_FILE}"
[Desktop Entry]
Version=1.0
Type=Application
Name=SLAMNAV2 종료
Comment=SLAMNAV2 프로세스만 종료합니다.
Exec=bash -c "${PM2_PATH} stop SLAMNAV2; exec bash"
Icon=process-stop
Terminal=true
Categories=Application;System;
EOF

# 실행 권한 부여
chmod +x "${OUTPUT_DIR}/${START_FILE}" "${OUTPUT_DIR}/${STOP_FILE}"

echo ""
echo "✅ 완료! '응용 프로그램 메뉴'에서 바로 실행 가능합니다."
echo "📍 위치: ~/.local/share/applications"
echo "📎 팁: 필요 시 GNOME '메뉴에 즐겨찾기 추가' 가능"

