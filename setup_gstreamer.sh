#!/bin/bash

echo "📦 GStreamer 관련 패키지 설치 스크립트 시작..."

# 루트 권한 확인
if [[ "$EUID" -ne 0 ]]; then
  echo "❌ 루트 권한이 필요합니다. sudo로 실행해주세요."
  exit 1
fi

# 패키지 목록 업데이트
echo "🔄 패키지 목록 업데이트 중..."
apt update

# GStreamer 패키지 설치
echo "📥 GStreamer 관련 패키지 설치 중..."
apt install -y \
  libgstreamer1.0-dev \
  libgstreamer-plugins-base1.0-dev \
  gstreamer1.0-plugins-ugly \
  gstreamer1.0-rtsp

# 설치 결과 확인
if [[ $? -eq 0 ]]; then
  echo "✅ GStreamer 관련 패키지 설치 완료!"
else
  echo "❌ 설치 중 오류가 발생했습니다."
fi

