#!/bin/bash

# PM2 시작 및 종료 .desktop 바로가기를 생성하고 '신뢰' 상태로 만드는 스크립트입니다.
OUTPUT_DIR="${HOME}/Desktop"
START_FILE="pm2-start.desktop"
STOP_FILE="pm2-stop.desktop"

echo "PM2 바로가기 생성을 시작합니다..."

# 1. PM2 시작 바로가기 파일 생성
cat <<EOF > "${OUTPUT_DIR}/${START_FILE}"
[Desktop Entry]
Version=1.0
Type=Application
Name=PM2 시작
Comment=ecosystem.config.js로 모든 PM2 프로세스를 시작합니다.
Exec=bash -c "cd /home/rainbow/slamnav2/ && pm2 start ecosystem.config.js; exec bash"
Icon=utilities-terminal
Terminal=true
Categories=Application;System;
EOF

# 2. PM2 종료 바로가기 파일 생성
cat <<EOF > "${OUTPUT_DIR}/${STOP_FILE}"
[Desktop Entry]
Version=1.0
Type=Application
Name=PM2 종료
Comment=실행중인 모든 pm2 프로세스와 데몬을 종료합니다.
Exec=bash -c "pm2 kill; exec bash"
Icon=process-stop
Terminal=true
Categories=Application;System;
EOF

# 3. 파일에 실행 권한 부여
chmod +x "${OUTPUT_DIR}/${START_FILE}"
chmod +x "${OUTPUT_DIR}/${STOP_FILE}"

# 4. 파일을 '신뢰하는 앱'으로 설정 (가장 중요!)
echo "'신뢰하는 앱'으로 설정합니다..."
gio set "${OUTPUT_DIR}/${START_FILE}" "metadata::trusted" yes
gio set "${OUTPUT_DIR}/${STOP_FILE}" "metadata::trusted" yes

echo ""
echo "✅ 완료! 바탕화면에 신뢰 상태의 바로가기가 생성되었습니다."
