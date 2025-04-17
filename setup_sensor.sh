#!/bin/bash
set -e

###############################################################################
# install_all.sh
# - rplidar_sdk, OrbbecSDK, sick_safetyscanners_base 설치
# - 설치 대상 디렉토리는 항상 /home/원래사용자명 아래로 고정
# - 이미 설치된 디렉토리가 있으면 건너뜁니다.
#
# 사용법:
#   sudo ./install_all.sh
###############################################################################

# 1) 설치할 홈 디렉토리 결정
if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
    USER_NAME="$SUDO_USER"
else
    USER_NAME="$(id -un)"
fi
HOME_DIR="/home/$USER_NAME"
echo ">>> 설치 대상 홈 디렉토리: $HOME_DIR (사용자: $USER_NAME)"

# 2) 로그 출력 함수
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

########################################
# 1. rplidar_sdk 설치
########################################
log "=== [STEP 1] rplidar_sdk 설치 ==="
if [ -d "$HOME_DIR/rplidar_sdk" ]; then
    log "[SKIP] $HOME_DIR/rplidar_sdk 이미 존재"
else
    log "[INSTALL] rplidar_sdk 클론"
    git clone https://github.com/Slamtec/rplidar_sdk.git "$HOME_DIR/rplidar_sdk"
    log "[BUILD] rplidar_sdk"
    cd "$HOME_DIR/rplidar_sdk"
    make
    log "[DONE] rplidar_sdk 설치 완료"
fi

########################################
# 2. OrbbecSDK 설치
########################################
log "=== [STEP 2] OrbbecSDK 설치 ==="
if [ -d "$HOME_DIR/OrbbecSDK" ]; then
    log "[SKIP] $HOME_DIR/OrbbecSDK 이미 존재"
else
    log "[INSTALL] OrbbecSDK 클론"
    git clone https://github.com/orbbec/OrbbecSDK.git "$HOME_DIR/OrbbecSDK"
    cd "$HOME_DIR/OrbbecSDK"
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
if [ -d "$HOME_DIR/sick_safetyscanners_base" ]; then
    log "[SKIP] $HOME_DIR/sick_safetyscanners_base 이미 존재"
else
    log "[INSTALL] sick_safetyscanners_base 클론"
    git clone https://github.com/SICKAG/sick_safetyscanners_base.git "$HOME_DIR/sick_safetyscanners_base"
    cd "$HOME_DIR/sick_safetyscanners_base"
    mkdir -p build && cd build
    log "[CMAKE] 구성"
    cmake ..
    log "[MAKE] 병렬 빌드"
    make -j"$(nproc)"
    log "[INSTALL] 시스템에 설치"
    sudo make install
    log "[DONE] sick_safetyscanners_base 설치 완료"
fi

log "=== ALL INSTALLATION STEPS COMPLETE ==="

