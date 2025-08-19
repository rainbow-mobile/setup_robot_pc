#!/bin/bash

echo "✅ rtl8821cu WiFi 동글 드라이버 설치 스크립트 시작"

# 1. apt 업데이트
echo "🔄 apt-get update 실행 중..."
sudo apt-get update

# 2. dkms 설치
echo "📦 dkms 설치 중..."
sudo apt-get install dkms git -y

# 3. 드라이버 다운로드
echo "⬇️ GitHub에서 rtl8821cu 드라이버 클론 중..."
git clone https://github.com/brektrou/rtl8821cu.git

# 4. 디렉토리 이동
cd rtl8821cu || { echo "❌ 디렉토리 이동 실패"; exit 1; }

# 5. 드라이버 설치
echo "🔧 DKMS를 이용한 드라이버 설치 중..."
sudo ./dkms-install.sh

# 6. 재부팅 여부 확인
read -p "🚀 설치가 완료되었습니다. 지금 시스템을 재부팅하시겠습니까? (y/n): " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo "♻️ 시스템 재부팅 중..."
    sudo reboot
else
    echo "✅ 재부팅은 나중에 수동으로 진행해주세요."
fi

