#!/bin/bash
set -e

###############################################################################
# install_all.sh
# - 실행 위치: /home/setup_robot_pc
# - rplidar_sdk, OrbbecSDK, sick_safetyscanners_base 설치
# - 이미 설치된 디렉토리가 있으면 건너뜁니다.
###############################################################################

# 스크립트 위치 (BASE_DIR)에 설치
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
echo ">>> BASE_DIR: $BASE_DIR"

########################################
# 1. rplidar_sdk 설치
########################################
echo
echo "=== [STEP 1] rplidar_sdk 설치 ==="
if [ -d "$BASE_DIR/rplidar_sdk" ]; then
    echo "[SKIP] rplidar_sdk 디렉토리가 이미 존재합니다."
else
    echo "[INSTALL] rplidar_sdk 클론 및 빌드 시작"
    git clone https://github.com/Slamtec/rplidar_sdk.git "$BASE_DIR/rplidar_sdk"
    cd "$BASE_DIR/rplidar_sdk"
    make
    echo "[DONE] rplidar_sdk 설치 완료"
fi

########################################
# 2. OrbbecSDK 설치
########################################
echo
echo "=== [STEP 2] OrbbecSDK 설치 ==="
if [ -d "$BASE_DIR/OrbbecSDK" ]; then
    echo "[SKIP] OrbbecSDK 디렉토리가 이미 존재합니다."
else
    echo "[INSTALL] OrbbecSDK 클론 및 설치 시작"
    git clone https://github.com/orbbec/OrbbecSDK.git "$BASE_DIR/OrbbecSDK"
    cd "$BASE_DIR/OrbbecSDK"
    git checkout v1.10.11
    echo "[INSTALL] udev 규칙 설치 실행"
    # 스크립트 위치 확인 후 실행
    if [ -f "misc/scripts/install_udev_rules.sh" ]; then
        sudo bash misc/scripts/install_udev_rules.sh
    else
        sudo bash install_udev_rules.sh
    fi
    echo "[DONE] OrbbecSDK 설치 완료"
fi

########################################
# 3. sick_safetyscanners_base 설치
########################################
echo
echo "=== [STEP 3] sick_safetyscanners_base 설치 ==="
if [ -d "$BASE_DIR/sick_safetyscanners_base" ]; then
    echo "[SKIP] sick_safetyscanners_base 디렉토리가 이미 존재합니다."
else
    echo "[INSTALL] sick_safetyscanners_base 클론 및 빌드 시작"
    git clone https://github.com/SICKAG/sick_safetyscanners_base.git "$BASE_DIR/sick_safetyscanners_base"
    cd "$BASE_DIR/sick_safetyscanners_base"
    mkdir -p build && cd build
    cmake ..
    make -j"$(nproc)"
    sudo make install
    echo "[DONE] sick_safetyscanners_base 설치 완료"
fi

echo
echo "=== ALL INSTALLATION STEPS COMPLETE ==="

