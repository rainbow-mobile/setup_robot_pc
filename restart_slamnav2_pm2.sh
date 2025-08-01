#!/bin/bash

APP_NAME="SLAMNAV2"
WORK_DIR="/home/rainbow/slamnav2"
EXEC_PATH="./SLAMNAV2"

echo "🧹 기존 PM2 앱 삭제 중: $APP_NAME"
pm2 delete "$APP_NAME" >/dev/null 2>&1

echo "🖥️ DISPLAY 환경 설정 후 PM2에 재등록 중..."

# 래퍼 스크립트를 직접 실행하도록 등록
pm2 start --name "$APP_NAME" --cwd "$WORK_DIR" --interpreter bash -- \
  bash -c "export DISPLAY=:0; export QT_QPA_PLATFORM=xcb; exec $EXEC_PATH"

echo "💾 PM2 상태 저장 중..."
pm2 save

echo "✅ 완료! 현재 PM2 상태:"
pm2 list | grep "$APP_NAME"

