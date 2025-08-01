#!/bin/bash

APP_NAME="SLAMNAV2"
SCRIPT_PATH="/home/rainbow/slamnav2/start_slamnav2.sh"

echo "🧹 기존 PM2 앱 삭제 중: $APP_NAME"
pm2 delete "$APP_NAME" >/dev/null 2>&1

echo "🚀 래퍼 스크립트로 PM2에 등록 중..."
pm2 start "$SCRIPT_PATH" --name "$APP_NAME"

echo "💾 PM2 상태 저장 중..."
pm2 save

echo "✅ 완료! 현재 PM2 상태:"
pm2 list | grep "$APP_NAME"

