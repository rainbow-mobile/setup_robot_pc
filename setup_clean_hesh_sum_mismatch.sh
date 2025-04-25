#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# root 권한 확인
if [[ $(id -u) -ne 0 ]]; then
  echo "이 스크립트는 root 권한으로 실행해야 합니다. sudo를 사용하세요."
  exit 1
fi

echo "🔧 1. 원본 소스 리스트 백업: /etc/apt/sources.list.bak"
cp /etc/apt/sources.list /etc/apt/sources.list.bak

echo "🔄 2. kr.archive.ubuntu.com → archive.ubuntu.com 로 변경"
sed -E -i 's|http://kr\.archive\.ubuntu\.com/ubuntu|http://archive.ubuntu.com/ubuntu|g' /etc/apt/sources.list

echo "🧹 3. apt 캐시(clean) 시작..."
apt-get clean

echo "🗑️ 4. /var/lib/apt/lists/ 디렉토리 삭제..."
rm -rf /var/lib/apt/lists/*

echo "🔄 5. 패키지 리스트 업데이트(apt-get update) 시작..."
apt-get update

echo "✅ 미러 변경 및 캐시 정리 완료! 이제 apt update 시 Hash Sum mismatch 오류가 발생하지 않습니다."

