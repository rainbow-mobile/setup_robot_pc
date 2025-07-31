#!/bin/bash

# ========================== 설정 ==========================
# 1. 'which pm2' 명령어로 찾은 pm2의 전체 경로를 아래에 붙여넣으세요.
PM2_PATH="/home/rainbow/.nvm/versions/node/v22.17.1/bin/pm2"
# ========================================================

# 바로가기가 생성될 위치
OUTPUT_DIR="${HOME}/Desktop"
START_FILE="pm2-start.desktop"
STOP_FILE="pm2-stop.desktop"

echo "PM2 바로가기 생성을 시작합니다..."

# PM2 시작 바로가기 파일 생성
cat <<EOF > "${OUTPUT_DIR}/${START_FILE}"
[Desktop Entry]
Version=1.0
Type=Application
Name=PM2 시작
Comment=ecosystem.config.js로 모든 PM2 프로세스를 시작합니다.
Exec=bash -c "cd /home/rainbow/slamnav2/ && ${PM2_PATH} start ecosystem.config.js; exec bash"
Icon=utilities-terminal
Terminal=true
Categories=Application;System;
EOF

# PM2 종료 바로가기 파일 생성
cat <<EOF > "${OUTPUT_DIR}/${STOP_FILE}"
[Desktop Entry]
Version=1.0
Type=Application
Name=PM2 종료
Comment=실행중인 모든 pm2 프로세스와 데몬을 종료합니다.
Exec=bash -c "${PM2_PATH} kill; exec bash"
Icon=process-stop
Terminal=true
Categories=Application;System;
EOF

# 파일에 실행 권한 부여 및 '신뢰' 상태로 설정
chmod +x "${OUTPUT_DIR}/${START_FILE}"
chmod +x "${OUTPUT_DIR}/${STOP_FILE}"
gio set "${OUTPUT_DIR}/${START_FILE}" "metadata::trusted" yes
gio set "${OUTPUT_DIR}/${STOP_FILE}" "metadata::trusted" yes

echo ""
echo "✅ 완료! 바탕화면에 최종 바로가기가 생성되었습니다."
