#!/bin/bash

# PM2 시작 및 종료 .desktop 바로가기를 생성하는 스크립트입니다.
# 바로가기가 생성될 위치 (기본값: 사용자의 바탕화면)
OUTPUT_DIR="${HOME}/Desktop"

# 생성될 파일 이름 정의
START_FILE="pm2-start.desktop"
STOP_FILE="pm2-stop.desktop"

echo "PM2 바로가기 생성을 시작합니다..."
echo "생성 위치: ${OUTPUT_DIR}"

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

# 3. 생성된 바로가기 파일에 실행 권한 부여
chmod +x "${OUTPUT_DIR}/${START_FILE}"
chmod +x "${OUTPUT_DIR}/${STOP_FILE}"

echo ""
echo "✅ 완료! 바탕화면에 'PM2 시작'과 'PM2 종료' 바로가기가 생성되었습니다."
