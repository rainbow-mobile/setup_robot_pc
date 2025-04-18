#!/bin/bash
################################################################################
# setup_light_fixed.sh
# - 실행 위치   : /home/setup_robot_pc
# - git 패키지  : /home/<real user>/ 하위에만 설치
# - 이미 존재   : 건너뜀
################################################################################
set -e
sudo -v                               # sudo 캐시

# -----------------------------------------------------------------------------#
# 0. 절대 경로/사용자 홈 디렉터리 결정
# -----------------------------------------------------------------------------#
if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
else
    REAL_USER="$(id -un)"
fi
REAL_HOME="/home/$REAL_USER"       # 반드시 /home/<user>
export HOME="$REAL_HOME"           # 스크립트 내부 $HOME 강제 교정
echo ">>> REAL_USER  = $REAL_USER"
echo ">>> REAL_HOME  = $REAL_HOME"
echo ">>> SCRIPT DIR = $(pwd)"

# -----------------------------------------------------------------------------#
# 1. 공통 함수 (run_step)  ― 기존 그대로
# -----------------------------------------------------------------------------#
log_msg(){ ... }
run_step(){ ... }

# -----------------------------------------------------------------------------#
# 2. git‑clone & 빌드 스텝들  ── 경로를 $REAL_HOME 으로 고정
# -----------------------------------------------------------------------------#

# ★ rplidar_sdk ---------------------------------------------------------------#
run_step "rplidar_sdk" \
  "[ -d \"$REAL_HOME/rplidar_sdk\" ]" \
  "cd \"$REAL_HOME\" && \
   git clone https://github.com/Slamtec/rplidar_sdk.git && \
   cd rplidar_sdk && make"

# ★ Sophus --------------------------------------------------------------------#
run_step "Sophus" \
  "[ -d \"$REAL_HOME/Sophus/build\" ]" \
  "cd \"$REAL_HOME\" && \
   git clone https://github.com/strasdat/Sophus.git && \
   cd Sophus && mkdir -p build && cd build && \
   cmake .. -DBUILD_TESTS=OFF -DBUILD_EXAMPLES=OFF -DSOPHUS_USE_BASIC_LOGGING=ON && \
   make -j\$(nproc) && sudo make install"

# ★ OrbbecSDK (v1.10.11, udev 규칙 포함) --------------------------------------#
run_step "OrbbecSDK" \
  "[ -d \"$REAL_HOME/OrbbecSDK\" ]" \
  "cd \"$REAL_HOME\" && \
   git clone https://github.com/orbbec/OrbbecSDK.git && \
   cd OrbbecSDK && git checkout v1.10.11 && \
   ( [ -f misc/scripts/install_udev_rules.sh ] \
       && sudo bash misc/scripts/install_udev_rules.sh \
       || sudo bash install_udev_rules.sh )"

# ★ socket.io‑client‑cpp ------------------------------------------------------#
run_step "socket.io-client-cpp" \
  "[ -d \"$REAL_HOME/socket.io-client-cpp/build\" ]" \
  "cd \"$REAL_HOME\" && \
   git clone --recurse-submodules https://github.com/socketio/socket.io-client-cpp.git && \
   cd socket.io-client-cpp && mkdir -p build && cd build && \
   cmake .. -DBUILD_SHARED_LIBS=ON -DLOGGING=OFF && \
   make -j\$(nproc) && sudo make install"

# ★ 기타(GTSAM, OMPL, OctoMap, Livox 등)도 같은 패턴으로 REAL_HOME 사용 ----#

# -----------------------------------------------------------------------------#
# 3. LD_LIBRARY_PATH 항목 ― 사용자 홈을 하드코딩
# -----------------------------------------------------------------------------#
run_step "LD_LIBRARY_PATH(rplidar)" \
  "grep -q 'rplidar_sdk/output' /etc/profile" \
  "sudo sh -c \"echo 'export LD_LIBRARY_PATH=\\\${LD_LIBRARY_PATH}:$REAL_HOME/rplidar_sdk/output/Linux/Release' >> /etc/profile\""

run_step "LD_LIBRARY_PATH(Orbbec)" \
  "grep -q 'OrbbecSDK/lib' /etc/profile" \
  "sudo sh -c \"echo 'export LD_LIBRARY_PATH=\\\${LD_LIBRARY_PATH}:$REAL_HOME/OrbbecSDK/lib/linux_x64' >> /etc/profile\""

# -----------------------------------------------------------------------------#
# 이후 apt‑설치, 환경설정, udev, swap, 재부팅 안내 등
# (경로 의존 없는 부분은 기존 코드 그대로 복사)
# -----------------------------------------------------------------------------#

