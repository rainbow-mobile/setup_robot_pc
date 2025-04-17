#!/bin/bash
set -e

###############################################################################
# 통합 설치 스크립트
# - rplidar_sdk
# - OrbbecSDK (v1.10.11)
# - SICK Safety Scanners Base
#
# 사용법: 
#   1) 이 파일에 실행 권한 부여: chmod +x install_all.sh
#   2) 실행: ./install_all.sh   (또는 sudo ./install_all.sh)
###############################################################################

echo "========== START INSTALLATION =========="

############################
# 1. rplidar_sdk 설치
############################
echo
echo ">>> [rplidar_sdk] 설치 시작"
cd "$HOME"
if [ ! -d "rplidar_sdk" ]; then
    git clone https://github.com/Slamtec/rplidar_sdk.git
else
    echo "[rplidar_sdk] 이미 클론됨, 업데이트 및 재빌드"
    cd rplidar_sdk && git pull
fi
cd rplidar_sdk
echo "[rplidar_sdk] 빌드 중..."
make
echo "[rplidar_sdk] 설치 완료"

############################
# 2. OrbbecSDK 설치
############################
echo
echo ">>> [OrbbecSDK] 설치 시작"
cd "$HOME"
if [ ! -d "OrbbecSDK" ]; then
    git clone https://github.com/orbbec/OrbbecSDK.git
else
    echo "[OrbbecSDK] 이미 클론됨, 업데이트"
    cd OrbbecSDK && git fetch
fi
cd OrbbecSDK
git checkout v1.10.11
echo "[OrbbecSDK] udev 규칙 설치 스크립트 실행"
# 실제 스크립트 경로가 misc/scripts/install_udev_rules.sh 인 경우:
if [ -f "misc/scripts/install_udev_rules.sh" ]; then
    sudo bash misc/scripts/install_udev_rules.sh
else
    # 루트 디렉토리에 있는 경우:
    sudo bash install_udev_rules.sh
fi
echo "[OrbbecSDK] 설치 완료"

############################
# 3. SICK Safety Scanners Base 설치
############################
echo
echo ">>> [sick_safetyscanners_base] 설치 시작"
cd "$HOME"
if [ ! -d "sick_safetyscanners_base" ]; then
    git clone https://github.com/SICKAG/sick_safetyscanners_base.git
else
    echo "[sick_safetyscanners_base] 이미 클론됨, 업데이트"
    cd sick_safetyscanners_base && git pull
fi
cd sick_safetyscanners_base
mkdir -p build && cd build
echo "[sick_safetyscanners_base] cmake 구성 중..."
cmake ..
echo "[sick_safetyscanners_base] 병렬 빌드 중..."
make -j$(nproc)
echo "[sick_safetyscanners_base] 설치 중..."
sudo make install
echo "[sick_safetyscanners_base] 설치 완료"

echo
echo "========== ALL INSTALLATIONS COMPLETE =========="

