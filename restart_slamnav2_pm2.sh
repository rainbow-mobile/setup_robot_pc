#!/bin/bash

APP_NAME="SLAMNAV2"
EXEC_PATH="/home/rainbow/slamnav2/SLAMNAV2"

echo "🧹 기존 PM2 앱 삭제 중: $APP_NAME"
pm2 delete "$APP_NAME" >/dev/null 2>&1

echo "🖥️ DISPLAY 환경 설정 후 재등록 중..."
DISPLAY=:0 QT_QPA_PLATFORM=xcb pm2 start "$EXEC_PATH" --name "$APP_NAME"

echo "✅ PM2 등록 완료. 상태 확인:"
pm2 list | grep "$APP_NAME"

