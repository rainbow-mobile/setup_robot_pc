#!/bin/bash
set -e

###############################################################################
# install_all.sh
# - rplidar_sdk, OrbbecSDK, sick_safetyscanners_base 설치
# - 설치 대상 경로: /home
# - 이미 설치된 디렉토리가 있으면 건너뜁니다.
#
# 실행 위치: /home/setup_robot_pc
# 사용법:
#   sudo ./install_all.sh
###############################################################################

INSTALL_BASE="/home"
echo ">>> 설치 대상 경로: $INSTALL_BASE"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

########################################
# 1. rplidar_sdk 설치
########################################
log "=== [STEP 1] rplidar_sdk 설치 ==="
if [ -d "$INSTALL_BASE/rplidar_sdk" ]; then
    log "[SKIP] $INSTALL_BASE/rplidar_sdk 이미 존재"
else
    log "[INSTALL] rplidar_sdk 클론"
    git clone https://github.com/Slamtec/rplidar_sdk.git "$INSTALL_BASE/rplidar_sdk"
    log "[BUILD] rplidar_sdk"
    cd "$INSTALL_BASE/rplidar_sdk"
    make
    log "[DONE] rplidar_sdk 설치 완료"
fi

########################################
# 2. OrbbecSDK 설치
########################################
log "=== [STEP 2] OrbbecSDK 설치 ==="
if [ -d "$INSTALL_BASE/OrbbecSDK" ]; then
    log "[SKIP] $INSTALL_BASE/OrbbecSDK 이미 존재"
else
    log "[INSTALL] OrbbecSDK 클론"
    git clone https://github.com/orbbec/OrbbecSDK.git "$INSTALL_BASE/OrbbecSDK"
    cd "$INSTALL_BASE/OrbbecSDK"
    log "[CHECKOUT] v1.10.11"
    git checkout v1.10.11
    log "[UDEV] udev 규칙 설치"
    if [ -f "misc/scripts/install_udev_rules.sh" ]; then
        sudo bash misc/scripts/install_udev_rules.sh
    else
        sudo bash install_udev_rules.sh
    fi
    log "[DONE] OrbbecSDK 설치 완료"
fi

########################################
# 3. sick_safetyscanners_base 설치
########################################
log "=== [STEP 3] sick_safetyscanners_base 설치 ==="
if [ -d "$INSTALL_BASE/sick_safetyscanners_base" ]; then
    log "[SKIP] $INSTALL_BASE/sick_safetyscanners_base 이미 존재"
else
    log "[INSTALL] sick_safetyscanners_base 클론"
    git clone https://github.com/SICKAG/sick_safetyscanners_base.git "$INSTALL_BASE/sick_safetyscanners_base"
    cd "$INSTALL_BASE/sick_safetyscanners_base"
    log "[BUILD] 디렉토리 생성 및 CMake"
    mkdir -p build && cd build
    cmake ..
    log "[MAKE] 병렬 빌드"
    make -j"$(nproc)"
    log "[INSTALL] 시스템에 설치"
    sudo make install
    log "[DONE] sick_safetyscanners_base 설치 완료"
fi

log "=== ALL INSTALLATION STEPS COMPLETE ==="

