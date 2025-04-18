#!/bin/bash
# refresh_apt.sh
# Apt 인덱스 & 캐시 초기화 스크립트

set -e

echo ">>> Apt 패키지 캐시 삭제 중..."
apt-get clean

echo ">>> 기존 인덱스 파일 삭제 중..."
rm -rf /var/lib/apt/lists/*

echo ">>> 인덱스 파일 재다운로드 중..."
apt-get update

echo ">>> 완료!"

