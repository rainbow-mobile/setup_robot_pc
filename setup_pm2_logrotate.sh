#!/bin/bash

echo "📦 pm2-logrotate 모듈 설치 중..."
pm2 install pm2-logrotate

echo "⚙️ pm2-logrotate 설정 적용 중..."
pm2 set pm2-logrotate:max_size 10M
pm2 set pm2-logrotate:retain 7
pm2 set pm2-logrotate:compress true
pm2 set pm2-logrotate:dateFormat YYYY-MM-DD_HH-mm-ss

echo "✅ 완료! 현재 logrotate 설정:"
pm2 conf pm2-logrotate

