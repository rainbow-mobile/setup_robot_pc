#!/bin/bash
set -e
###############################################################################
# install_all.sh
# - rplidar_sdk, OrbbecSDK, sick_safetyscanners_base 설치
# - 설치 대상 : /home/<로그인‑사용자>/ (root 가 아님)
# - 이미 디렉터리가 있으면 건너뜀
#
# 실행 위치 : /home/setup_robot_pc
# 권장 실행 : sudo ./install_all.sh
###############################################################################

#--------------------------------------------------------------------
# 0. 실제 사용자 / 홈 디렉터리 결정  (sudo 로 실행해도 원사용자 홈 사용)
#--------------------------------------------------------------------
if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
else
    REAL_USER="$(id -un)"
fi
INSTALL_BASE="/home/$REAL_USER"           # ⇒ /home/사용자
echo ">>> REAL_USER  : $REAL_USER"
echo ">>> INSTALL_TO : $INSTALL_BASE"

log() {  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

#--------------------------------------------------------------------
# 1. rplidar_sdk
#--------------------------------------------------------------------
log "=== [STEP 1] rplidar_sdk 설치 ==="
if [ -d "$INSTALL_BASE/rplidar_sdk" ]; then
    log "[SKIP] $INSTALL_BASE/rplidar_sdk 이미 존재"
else
    log "[CLONE] rplidar_sdk"
    git clone https://github.com/Slamtec/rplidar_sdk.git "$INSTALL_BASE/rplidar_sdk"
    log "[BUILD] rplidar_sdk"
    make -C "$INSTALL_BASE/rplidar_sdk"
    log "[DONE] rplidar_sdk 설치 완료"
fi

#--------------------------------------------------------------------
# 2. OrbbecSDK
#--------------------------------------------------------------------
log "=== [STEP 2] OrbbecSDK 설치 ==="
if [ -d "$INSTALL_BASE/OrbbecSDK" ]; then
    log "[SKIP] $INSTALL_BASE/OrbbecSDK 이미 존재"
else
    log "[CLONE] OrbbecSDK"
    git clone https://github.com/orbbec/OrbbecSDK.git "$INSTALL_BASE/OrbbecSDK"
    cd "$INSTALL_BASE/OrbbecSDK"
    git checkout v1.10.11
    log "[UDEV] Orbbec udev 규칙 설치"
    if [ -f misc/scripts/install_udev_rules.sh ]; then
        sudo bash misc/scripts/install_udev_rules.sh
    else
        sudo bash install_udev_rules.sh
    fi
    log "[DONE] OrbbecSDK 설치 완료"
fi

#--------------------------------------------------------------------
# 3. sick_safetyscanners_base
#--------------------------------------------------------------------
log "=== [STEP 3] sick_safetyscanners_base 설치 ==="
if [ -d "$INSTALL_BASE/sick_safetyscanners_base" ]; then
    log "[SKIP] $INSTALL_BASE/sick_safetyscanners_base 이미 존재"
else
    log "[CLONE] sick_safetyscanners_base"
    git clone https://github.com/SICKAG/sick_safetyscanners_base.git \
              "$INSTALL_BASE/sick_safetyscanners_base"
    mkdir -p "$INSTALL_BASE/sick_safetyscanners_base/build"
    cd       "$INSTALL_BASE/sick_safetyscanners_base/build"
    log "[CMAKE]"
    cmake ..
    log "[MAKE] 병렬 빌드"
    make -j"$(nproc)"
    log "[INSTALL] 시스템 라이브러리 설치"
    sudo make install
    log "[DONE] sick_safetyscanners_base 설치 완료"
fi

log "=== ALL INSTALLATION STEPS COMPLETE ==="

