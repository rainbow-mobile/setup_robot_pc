#!/usr/bin/env bash
###############################################################################
# setup_amr.sh  (rev.2025-05-08)
#  · Full / Light 모드 선택 가능 (기본 = Full)
###############################################################################
set -Eeuo pipefail
IFS=$'\n\t'

###############################################################################
## 🆕 APT Hash-Sum mismatch 자동 복구 함수
###############################################################################
fix_hash_mismatch() {
  echo -e "\e[34m[APT] Hash-Sum mismatch 복구: 캐시 초기화\e[0m"

  # 0) 인덱스·캐시 전부 삭제
  rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/partial/*
  mkdir -p /var/lib/apt/lists/partial

  # 1) i386 아키텍처 제거(필요 없을 때)
  dpkg --remove-architecture i386 2>/dev/null || true

  # 2) 미러 교체: kr.archive + security → archive.ubuntu.com
  sed -Ei 's|http://(kr\.archive|security)\.ubuntu\.com/ubuntu|http://archive.ubuntu.com/ubuntu|g' \
          /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null || true
}

#──────────────────────────────────────────────────────────────────────────────
## 0. 공통 초기화
#──────────────────────────────────────────────────────────────────────────────
need_root() { [[ $EUID -eq 0 ]] || { echo "sudo 로 실행하세요." >&2; exit 1; }; }
log()       { echo -e "\e[32m[$(date +'%F %T')]\e[0m $*"; }

###############################################################################
# profile 재읽기 helper – set -u 상태에서도 안전
###############################################################################
safe_source() {
  set +u
  # shellcheck disable=SC1090
  source "$1"
  set -u
}

need_root
fix_hash_mismatch                  # ←★ 이 한 줄만 추가해도 충분
# 첫 update 시도
apt-get update -o Acquire::CompressionTypes::Order::=gz \
               -o Acquire::http::No-Cache=true \
               -o Acquire::https::No-Cache=true \
               || {
  echo "[WARN] update 실패, 캐시 재정비 후 재시도"
  fix_hash_mismatch
  apt-get update -o Acquire::CompressionTypes::Order::=gz \
                 -o Acquire::http::No-Cache=true \
                 -o Acquire::https::No-Cache=true
}
REAL_USER=${SUDO_USER:-$(logname)}
[[ $REAL_USER == root ]] && {
  echo "❗ 반드시 일반 사용자에서:  sudo ./setup_amr.sh  형태로 실행하세요."
  exit 1
}
USER_HOME=$(eval echo "~$REAL_USER")
as_user()   { sudo -u "$REAL_USER" -H bash -c "$*"; }

sudo apt-get update -qq
sudo adduser "$REAL_USER" dialout || true           # dialout 그룹은 항상 추가

: "${DEBUGINFOD_URLS:=}"                            ; export DEBUGINFOD_URLS
: "${XDG_DATA_DIRS:=/usr/local/share:/usr/share}"   ; export XDG_DATA_DIRS

declare -ag INSTALLED=()  SKIPPED=()  FAILED=()

#──────────────────────────────────────────────────────────────────────────────
## 1. 설치 모드 선택 (Full / Light)
#──────────────────────────────────────────────────────────────────────────────
read -rp $'\n'"설치 모드 선택 (f=Full, l=Light) [f]: " MODE_SEL
MODE_SEL=${MODE_SEL:-f}
[[ $MODE_SEL =~ ^[FfLl]$ ]] || { echo "잘못된 입력"; exit 1; }
MODE=$([[ $MODE_SEL =~ ^[Ll]$ ]] && echo "LIGHT" || echo "FULL")
log "▶ 설치 모드: $MODE"
###############################################################################
# (Light 전용) Qt 런타임 최소 패키지 – xcb platform-plugin 포함
###############################################################################
if [[ $MODE == "LIGHT" ]]; then
  QT_RUNTIME_PKGS=(
    libqt5gui5 libqt5core5a libqt5widgets5 libqt5network5
    libqt5qml5 libqt5quick5 qtwayland5
    libxcb-xinerama0 libxcb-icccm4 libxcb-image0
    libxcb-keysyms1  libxcb-render-util0
  )
  log "[Light] Qt 런타임 최소 패키지 설치"
  apt-get update -qq
  apt-get install -y --no-install-recommends "${QT_RUNTIME_PKGS[@]}"
fi
#──────────────────────────────────────────────────────────────────────────────
## 2. 스크립트 번호·설명 매핑
#──────────────────────────────────────────────────────────────────────────────
declare -A SCRIPTS=(
  [1]="빌드 환경·의존성        / run_1"
  [2]="센서 SDK 설치           / run_2"
  [3]="obSensor udev 규칙      / run_3"
  [4]="LD_LIBRARY_PATH 추가    / run_4"
  [5]="단축키·리포지토리       / run_5"
  [6]="TeamViewer 설치         / run_6"
)

# 모드에 따라 1 · 2단계 제외
if [[ $MODE == LIGHT ]]; then unset 'SCRIPTS[1]' 'SCRIPTS[2]'; fi

print_menu() {
  echo -e "\n설치할 단계 번호를 선택하세요:"
  for k in $(printf "%s\n" "${!SCRIPTS[@]}" | sort -n); do
    printf "  %s) %s\n" "$k" "${SCRIPTS[$k]%%/*}"
  done
  echo "  a) 모두 설치"
}

read_selection() {
  local sel; read -rp "번호 입력 (예: 3,5 또는 a): " sel
  if [[ $sel == a ]]; then printf "%s\n" "${!SCRIPTS[@]}" | sort -n
  else IFS=',' read -ra nums <<< "$sel"; printf "%s\n" "${nums[@]}"; fi
}

#──────────────────────────────────────────────────────────────────────────────
## 3. 각 단계(run_1 ~ run_6) 정의
#     · 아래 run_1 ~ run_6 내용은 **사용자께서 제공하신 원본을 그대로 유지**하며
#       필요한 작은 버그·타이포만 교정했습니다.
#──────────────────────────────────────────────────────────────────────────────

### 3-1. STEP 1 ─ 빌드 환경 & 의존성 (원본 run_1 그대로)  ######################
run_1() { # setup_system_build_env_s100-2.sh

  log "[STEP 1] 시스템 빌드 환경 & 의존성 설치"  
  # 통합 설치 스크립트 (선택된 일부 단계 제외)
  # - Node.js 및 Mobile/Task/Web 환경 설치 제외
  # - 화면 blank(절전) 옵션 비활성화 제외
  # - 자동 로그인 설정(GDM3 기준) 제외
  #
  # 기존 스크립트에서 apt 패키지 설치 부분을 수정하여,
  # dpkg -s 체크 없이 무조건 설치를 시도하고, 로그 정보를 더 자세히 남기도록 개선했습니다.

  sudo -v


  ########################################
  # 1. 로그 설정 및 로깅 함수
  ########################################
  LOG_FILE="$HOME/setup_detailed.log"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] 설치 스크립트 시작" > "$LOG_FILE"

  log_msg() {
      #local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
      local now
      now=$(date '+%Y-%m-%d %H:%M:%S')
      local msg="[$now] $1"
      echo "$msg" | tee -a "$LOG_FILE"
  }

  # 결과 추적용 배열
  #declare -a INSTALLED=() SKIPPED=() FAILED=()
  INSTALLED=(); SKIPPED=(); FAILED=()


  # 실행 시간 측정
  start_time=$(date +%s)
  trap 'end_time=$(date +%s); log_msg "총 실행 시간: $((end_time - start_time))초"' EXIT

  # CPU 코어 수 확인(병렬 빌드용)
  NUM_CORES=$(nproc)
  log_msg "감지된 CPU 코어: $NUM_CORES개"

  ########################################
  # 2. run_step 함수 정의 (패키지 설치 외 단계용)
  ########################################
  run_step() {
      local name="$1"
      local check_cmd="${2:-true}"
      local install_cmd="${3:-true}"
    
      log_msg ">> [$name] 진행 중..."
      if eval "$check_cmd"; then
          log_msg "   [$name] 이미 설치됨/설정됨, 건너뜁니다."
          SKIPPED+=("$name")
      else
          log_msg "   [$name] 설치/설정 시도..."
          if eval "$install_cmd"; then
              log_msg "   [$name] 완료됨"
              INSTALLED+=("$name")
          else
              log_msg "   [$name] 실패!"
              FAILED+=("$name")
          fi
      fi
      log_msg "----------------------------------------"
  }

  ########################################
  # 3. 시스템 업데이트 및 패키지 설치
  ########################################
  log_msg "========================================"
  log_msg "1. 시스템 업데이트 및 패키지 설치"
  log_msg "========================================"

  # 불필요한 패키지 제거
  log_msg "[시스템] 불필요한 패키지 제거 중..."
  if sudo apt remove -y update-notifier orca; then
      log_msg "[시스템] update-notifier, orca 제거 완료 (또는 이미 제거됨)"
  else
      log_msg "[경고] update-notifier, orca 제거 과정에서 오류가 발생했을 수 있음."
  fi

  # 시스템 업데이트
  log_msg "[시스템] apt-get update & upgrade 실행..."
  if sudo apt-get update && sudo apt-get upgrade -y; then
      INSTALLED+=("시스템 업데이트 완료")
  else
      FAILED+=("시스템 업데이트 실패")
      log_msg "[오류] 시스템 업데이트(apt-get upgrade) 중 문제가 발생했습니다. 로그 확인 요망."
  fi

  # (중요) apt 패키지 설치 목록
  APT_PACKAGES=(
    curl
    libqt5websockets5-dev
    qtmultimedia5-dev
    libquazip5-dev
    sshpass
    qtdeclarative5-dev
    libvtk9-qt-dev
    qtcreator
    qtbase5-dev
    qt5-qmake
    cmake
    libtbb-dev
    libboost-all-dev
    libopencv-dev
    libopencv-contrib-dev
    libeigen3-dev
    cmake-gui
    git
    htop
    build-essential
    rapidjson-dev
    libboost-system-dev
    libboost-thread-dev
    libssl-dev
    nmap
    libqt5multimedia5-plugins
    gstreamer1.0-plugins-base
    gstreamer1.0-plugins-good
    gstreamer1.0-plugins-bad
    gstreamer1.0-plugins-ugly
    libpcl-dev
    libgstreamer1.0-dev
    libgstreamer-plugins-base1.0-dev
    dkms
    qtquickcontrols2-5-dev
    libqt5serialport5-dev
    ccache
    qml-module-qtquick-controls2
    qml-module-qtmultimedia
    qml-module-qt-labs-platform
    qml-module-qtquick-shapes
    nmap-common
    flex
    bison
    mysql-server
    expect
  )

  log_msg "[시스템] APT 패키지 설치(무조건 시도). 이미 설치된 경우 별도 조치 없음."
  for pkg in "${APT_PACKAGES[@]}"; do
      log_msg ">>> [$pkg] 설치 시도 중..."
      if sudo apt-get install -y "$pkg"; then
          log_msg ">>> [$pkg] 설치(또는 업데이트) 완료"
          # INSTALLED 배열에는 "전체 시스템 업데이트"와 구분하기 위해
          # 여기서는 개별 패키지 이름을 굳이 넣지 않아도 되지만, 필요시 추가 가능
      else
          log_msg ">>> [$pkg] 설치 실패!"
          FAILED+=("apt 패키지: $pkg")
      fi
  done

  ########################################
  # 4. 시스템 환경 설정 (LD_LIBRARY_PATH, GRUB, 자동 업데이트 비활성화)
  ########################################
  log_msg "========================================"
  log_msg "2. 시스템 환경 설정"
  log_msg "========================================"

  # 4.1 LD_LIBRARY_PATH 설정
  run_step "LD_LIBRARY_PATH (/usr/local/lib)" \
      "grep '/usr/local/lib' /etc/profile &> /dev/null" \
      "sudo sh -c 'echo \"export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:/usr/local/lib\" >> /etc/profile'"

  run_step "LD_LIBRARY_PATH (rplidar_sdk)" \
      "grep 'rplidar_sdk/output/Linux/Release' /etc/profile &> /dev/null" \
      "sudo sh -c 'echo \"export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:\$HOME/rplidar_sdk/output/Linux/Release\" >> /etc/profile'"

  run_step "LD_LIBRARY_PATH (OrbbecSDK)" \
      "grep 'OrbbecSDK/lib/linux_x64' /etc/profile &> /dev/null" \
      "sudo sh -c 'echo \"export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:\$HOME/OrbbecSDK/lib/linux_x64\" >> /etc/profile'"

  # 프로필 재적용 + ldconfig
  
  #(1) LD_LIBRARY_PATH 설정 직후
  #if source /etc/profile && sudo ldconfig; then
  if safe_source /etc/profile && sudo ldconfig; then 
      INSTALLED+=("프로필 재적용 및 ldconfig")
  else
      FAILED+=("프로필 재적용 및 ldconfig")
  fi

  # 4.2 GRUB 설정 (USB 전원 관리 해제, intel_pstate 비활성화)
  run_step "GRUB 설정" \
      "grep 'usbcore.autosuspend=-1 intel_pstate=disable' /etc/default/grub &> /dev/null" \
      "sudo sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT=/ s/\"$/ usbcore.autosuspend=-1 intel_pstate=disable\"/' /etc/default/grub && sudo update-grub"
  # 4.3 자동 업데이트 비활성화
  run_step "자동 업데이트 비활성화" \
      "grep 'APT::Periodic::Update-Package-Lists \"0\"' /etc/apt/apt.conf.d/20auto-upgrades &> /dev/null" \
      "sudo sh -c 'cat > /etc/apt/apt.conf.d/20auto-upgrades <<EOF
APT::Periodic::Update-Package-Lists \"0\";
APT::Periodic::Download-Upgradeable-Packages \"0\";
APT::Periodic::AutocleanInterval \"0\";
APT::Periodic::Unattended-Upgrade \"0\";
EOF
' && sudo sed -i 's/^Prompt=.*/Prompt=never/' /etc/update-manager/release-upgrades && \
gsettings set com.ubuntu.update-notifier regular-auto-launch-interval 0"


  ########################################
  # 5. 스왑파일 설정
  ########################################
  log_msg "========================================"
  log_msg "3. 스왑파일 설정"
  log_msg "========================================"

  SWAP_SIZE=$([[ $MODE == "LIGHT" ]] && echo "8G" || echo "32G")
  SWAP_MB=$([[ $MODE == "LIGHT" ]] && echo "8192" || echo "32768")

  run_step "스왑파일 설정 ($SWAP_SIZE)" \
      "free -h | grep -q \"Swap:.*$SWAP_SIZE\"" \
      "sudo swapoff /swapfile &> /dev/null || true && \
       sudo rm -f /swapfile && \
       sudo fallocate -l $SWAP_SIZE /swapfile || sudo dd if=/dev/zero of=/swapfile bs=1M count=$SWAP_MB && \
       sudo chmod 600 /swapfile && \
       sudo mkswap /swapfile && \
       sudo swapon /swapfile && \
       grep -q '/swapfile swap' /etc/fstab || echo '/swapfile swap swap defaults 0 0' | sudo tee -a /etc/fstab"

  ########################################
  # 6. 무선 드라이버 (RTL8812AU) 설치
  ########################################
  #log_msg "========================================"
  #log_msg "4. 무선 드라이버 (RTL8812AU) 설치"
  #log_msg "========================================"

  #run_step "RTL8812AU 드라이버" \
  #    "[ -d rtl8812au ]" \
  #    "git clone https://github.com/gnab/rtl8812au.git && \
  #     sudo cp -r rtl8812au /usr/src/rtl8812au-4.2.2 && \
  #     sudo dkms add -m rtl8812au -v 4.2.2 && \
  #     sudo dkms build -m rtl8812au -v 4.2.2 && \
  #     sudo dkms install -m rtl8812au -v 4.2.2 && \
  #     sudo modprobe 8812au"

  ########################################
  # 7. SLAMNAV2 관련 의존성 및 SDK (소스 빌드)
  ########################################
  log_msg "========================================"
  log_msg "5. SLAMNAV2 관련 의존성 및 SDK 설치"
  log_msg "========================================"

  # 7.1 CMake 3.27.7 (이미 최신 버전이면 skip)
  CMAKE_VERSION=3.27.7
  run_step "CMake $CMAKE_VERSION" \
      "[ -x \$(command -v cmake) ] && cmake --version | grep $CMAKE_VERSION &> /dev/null" \
      "wget https://github.com/Kitware/CMake/releases/download/v$CMAKE_VERSION/cmake-$CMAKE_VERSION.tar.gz && \
       tar -xvzf cmake-$CMAKE_VERSION.tar.gz && \
       cd cmake-$CMAKE_VERSION && \
       ./bootstrap --qt-gui && \
       make -j$NUM_CORES && \
       sudo make install && \
       cd ~"

  # 7.2 Sophus
  run_step "Sophus" \
      "[ -d Sophus/build ]" \
      "git clone https://github.com/strasdat/Sophus.git && \
       cd Sophus && \
       mkdir -p build && cd build && \
       cmake .. -DBUILD_TESTS=OFF -DBUILD_EXAMPLES=OFF -DSOPHUS_USE_BASIC_LOGGING=ON && \
       make -j$NUM_CORES && \
       sudo make install && \
       cd ~"

  # 7.3 GTSAM (4.2.0)
  run_step "GTSAM" \
      "[ -d gtsam/build ]" \
      "git clone https://github.com/borglab/gtsam.git && \
       cd gtsam && \
       git checkout 4.2.0 && \
       mkdir -p build && cd build && \
       cmake .. -DGTSAM_USE_SYSTEM_EIGEN=ON -DGTSAM_BUILD_TESTS=OFF -DGTSAM_BUILD_EXAMPLES_ALWAYS=OFF && \
       make -j$NUM_CORES && \
       sudo make install && \
       cd ~"

  # 7.4 OMPL (1.6.0)
  run_step "OMPL" \
      "[ -d ompl/build ]" \
      "git clone https://github.com/ompl/ompl.git && \
       cd ompl && \
       git checkout 1.6.0 && \
       mkdir -p build && cd build && \
       cmake .. && \
       make -j$NUM_CORES && \
       sudo make install && \
       cd ~"

  # 7.5 socket.io-client-cpp
  run_step "socket.io-client-cpp" \
      "[ -d socket.io-client-cpp/build ]" \
      "git clone --recurse-submodules https://github.com/socketio/socket.io-client-cpp.git && \
       cd socket.io-client-cpp && \
       mkdir -p build && cd build && \
       cmake .. -DBUILD_SHARED_LIBS=ON -DLOGGING=OFF && \
       make -j$NUM_CORES && \
       sudo make install && \
       cd ~"

  # 7.6 OctoMap (1.10.0)
  run_step "OctoMap" \
      "[ -d octomap/build ]" \
      "git clone https://github.com/OctoMap/octomap.git && \
       cd octomap && \
       git checkout v1.10.0 && \
       mkdir -p build && cd build && \
       cmake .. -DBUILD_DYNAMICETD3D=OFF -DBUILD_OCTOVIS_SUBPROJECT=OFF -DBUILD_TESTING=OFF && \
       make -j$NUM_CORES && \
       sudo make install && \
       cd ~"

  # 7.7 PDAL
  run_step "PDAL" \
      "dpkg -s pdal libpdal-dev &> /dev/null" \
      "sudo apt-get update && sudo apt-get install -y pdal libpdal-dev"

  # 7.8 Livox SDK2
  run_step "Livox SDK2" \
      "[ -d Livox-SDK2/build ]" \
      "git clone https://github.com/Livox-SDK/Livox-SDK2.git && \
       cd Livox-SDK2 && \
       mkdir -p build && cd build && \
       cmake .. && \
       make -j$NUM_CORES && \
       sudo make install && \
       cd ~"

  ########################################
  # 8. 환경 변수 재적용 및 OrbbecSDK 경로 업데이트
  ########################################
  log_msg "========================================"
  log_msg "7. 환경 변수 재적용 및 OrbbecSDK 경로 업데이트"
  log_msg "========================================"

  # 9. 환경 변수 재적용 및 OrbbecSDK 경로 업데이트
  run_step "OrbbecSDK path in /etc/profile" \
      "grep -q 'OrbbecSDK/SDK/lib' /etc/profile" \
      "sudo sh -c 'echo \"export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:/home/rainbow/OrbbecSDK/SDK/lib\" >> /etc/profile'"

  run_step "Re-apply profile" \
      "true" \
      "safe_source /etc/profile && sudo ldconfig && source ~/.bashrc"

  ########################################
  # 9. USB 시리얼 설정 및 dialout 그룹 추가
  ########################################
  log_msg "========================================"
  log_msg "8. USB 시리얼 설정 및 dialout 그룹"
  log_msg "========================================"

  # dialout 그룹
  run_step "사용자 dialout 그룹 추가" \
      "groups $USER | grep -q dialout" \
      "sudo adduser $USER dialout"

  # brltty 제거
  run_step "brltty 제거" \
      "dpkg -l | grep -q brltty" \
      "sudo apt remove -y brltty"

  ########################################
  # 10. USB udev 규칙 설정
  ########################################
  log_msg "========================================"
  log_msg "9. USB udev 규칙 설정"
  log_msg "========================================"

  run_step "USB udev 규칙" \
      "test -f /etc/udev/rules.d/99-usb-serial.rules" \
      "sudo bash -c 'cat > /etc/udev/rules.d/99-usb-serial.rules <<EOF
  SUBSYSTEM==\"tty\", KERNELS==\"1-7\", ATTRS{idVendor}==\"10c4\", ATTRS{idProduct}==\"ea60\", SYMLINK+=\"ttyRP0\"
  SUBSYSTEM==\"tty\", KERNELS==\"1-2.3\", ATTRS{idVendor}==\"067b\", ATTRS{idProduct}==\"2303\", SYMLINK+=\"ttyBL0\"
  SUBSYSTEM==\"tty\", KERNELS==\"1-1.2\", ATTRS{idVendor}==\"2109\", ATTRS{idProduct}==\"0812\", SYMLINK+=\"ttyCB0\"
  EOF
  ' && sudo udevadm control --reload-rules && sudo udevadm trigger"

  

  ########################################
  # 11. (선택) 추가 환경 설정
  ########################################
  log_msg "========================================"
  log_msg "10. 추가 환경 설정"
  log_msg "========================================"

  run_step "추가 환경 변수 재적용" \
      "true" \
      "sudo sh -c 'echo \"export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:/usr/local/lib\" >> /etc/profile' && \
       sudo sh -c 'echo \"export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:\$HOME/rplidar_sdk/output/Linux/Release\" >> /etc/profile' && \
       sudo sh -c 'echo \"export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:\$HOME/OrbbecSDK/lib/linux_x64\" >> /etc/profile' && \
       safe_source /etc/profile && \
       sudo ldconfig"

  ########################################
  # 12. 최종 요약 및 재부팅 안내
  ########################################
  echo "========================================"
  echo "설치 요약"
  echo "========================================"
  echo "설치 완료된 항목:"
  for item in "${INSTALLED[@]}"; do
      echo " - $item"
  done

  echo ""
  echo "이미 설치되어 건너뛴 항목:"
  for item in "${SKIPPED[@]}"; do
      echo " - $item"
  done

  echo ""
  echo "설치 실패한 항목:"
  for item in "${FAILED[@]}"; do
      echo " - $item"
  done

  echo "========================================"
  echo "모든 작업이 완료되었습니다."
  echo "※ 주의: USB 시리얼 설정 변경(dialout 그룹 추가) 등은 재부팅 후 적용됩니다."
  #read -p "재부팅하려면 엔터키를 누르세요..." 
  #sudo reboot
}

### 3-2. STEP 2 ─ 센서 SDK 설치 (원본 run_2 그대로)  ##########################
run_2() {  # setup_sensor2.sh
  log "[STEP 2] 센서 SDK / 드라이버 설치"

  INSTALL_BASE="$USER_HOME"                # 이미 계산된 USER_HOME 사용
  log ">>> REAL_USER  : $REAL_USER"
  log ">>> INSTALL_TO : $INSTALL_BASE"

  # 1. rplidar_sdk -----------------------------------------------------------
  if [ ! -d "$INSTALL_BASE/rplidar_sdk" ]; then
      log "[CLONE] rplidar_sdk"
      as_user "git clone https://github.com/Slamtec/rplidar_sdk.git \"$INSTALL_BASE/rplidar_sdk\""
      log "[BUILD] rplidar_sdk"
      as_user "make -C \"$INSTALL_BASE/rplidar_sdk\""
  else
      log "[SKIP] rplidar_sdk 이미 존재"
  fi

  # 2. OrbbecSDK -------------------------------------------------------------
  if [ ! -d "$INSTALL_BASE/OrbbecSDK" ]; then
      log "[CLONE] OrbbecSDK"
      as_user "git clone https://github.com/orbbec/OrbbecSDK.git \"$INSTALL_BASE/OrbbecSDK\""
      as_user "cd \"$INSTALL_BASE/OrbbecSDK\" && git checkout v1.10.11"
      log "[UDEV] Orbbec udev 규칙 설치"
      sudo bash "$INSTALL_BASE/OrbbecSDK/misc/scripts/install_udev_rules.sh"
  else
      log "[SKIP] OrbbecSDK 이미 존재"
  fi

  # 3. sick_safetyscanners_base ---------------------------------------------
  if [ ! -d "$INSTALL_BASE/sick_safetyscanners_base" ]; then
      log "[CLONE] sick_safetyscanners_base"
      as_user "git clone https://github.com/SICKAG/sick_safetyscanners_base.git \"$INSTALL_BASE/sick_safetyscanners_base\""
      as_user "mkdir -p \"$INSTALL_BASE/sick_safetyscanners_base/build\""
      as_user "cmake -S \"$INSTALL_BASE/sick_safetyscanners_base\" -B \"$INSTALL_BASE/sick_safetyscanners_base/build\""
      as_user "make -C \"$INSTALL_BASE/sick_safetyscanners_base/build\" -j$(nproc)"
      sudo make -C "$INSTALL_BASE/sick_safetyscanners_base/build" install
  else
      log "[SKIP] sick_safetyscanners_base 이미 존재"
  fi

  log "=== ALL INSTALLATION STEPS COMPLETE ==="
}

### 3-3. STEP 3 ─ obSensor udev 규칙  ########################################
run_3() { # install_udev_rules.sh
    
    
  # Check if user is root/running with sudo
  if [ "$(whoami)" != "root" ]; then
      echo Please run this script with sudo
      exit
  fi

  ORIG_PATH=$(pwd)
  cd "$(dirname "$0")"
  SCRIPT_PATH=$(pwd)
  cd "$ORIG_PATH"

  if [ "$(uname -s)" != "Darwin" ]; then
      # Install udev rules for USB device
      cp "${SCRIPT_PATH}/99-obsensor-libusb.rules" /etc/udev/rules.d/99-obsensor-libusb.rules

      # resload udev rules
      udevadm control --reload && udevadm trigger

      echo "usb rules file install at /etc/udev/rules.d/99-obsensor-libusb.rules"
  fi
  echo "exit"
}
### 3-4. STEP 4 ─ LD_LIBRARY_PATH 추가  ######################################
run_4() {  # setup_env_path.sh
   log "[STEP 4] 환경 변수 추가"
  # 환경변수 설정을 위한 스크립트
  # ~/.bashrc 에 LD_LIBRARY_PATH 경로를 추가하는 스크립트

  #BASHRC="$HOME/.bashrc"
  BASHRC="$USER_HOME/.bashrc"
  PATHS=(
    "export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:${USER_HOME}/slamnav2"
    "export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:${USER_HOME}/fms2"
  )

  for line in "${PATHS[@]}"; do
    # 이미 동일한 라인이 있는지 확인 후, 없으면 추가
    if ! grep -Fxq "$line" "$BASHRC"; then
      echo "$line" >> "$BASHRC"
      echo "추가됨: $line"
    else
      echo "이미 존재함: $line"
    fi
  done

  echo "완료! 변경사항을 적용하려면 다음을 실행하세요:"
  echo "  source ~/.bashrc"
  as_user "source $USER_HOME/.bashrc" 2>/dev/null || true
}

### 3-5. STEP 5 ─ 단축키·리포지토리  #########################################
run_5() { # setup_programs_slamanv_shortcut.sh
  log "[STEP 5] SLAMNAV2 / diagnosis 단축키"

  #-------------------------------------------------------------------------#
  # 0. 사용자 홈·바탕화면 디렉터리 결정
  #-------------------------------------------------------------------------#
  if [ -n "${SUDO_USER-}" ]; then
      USER_HOME="$(eval echo "~$SUDO_USER")"
  else
      USER_HOME="$HOME"
  fi

  # 후보: ~/Desktop → ~/바탕화면
  for d in "$USER_HOME/Desktop" "$USER_HOME/바탕화면"; do
      [ -d "$d" ] && { DESKTOP_DIR="$d"; break; }
  done
  if [ -z "${DESKTOP_DIR:-}" ]; then
      DESKTOP_DIR="$USER_HOME/Desktop"
      echo "[INFO] $DESKTOP_DIR 폴더가 없어 새로 생성합니다."
      mkdir -p "$DESKTOP_DIR" || { echo "[ERROR] 폴더 생성 실패"; return; }
  fi
  log "바탕화면 경로: $DESKTOP_DIR"

  #-------------------------------------------------------------------------#
  # 1. diagnosis 리포지토리 (~/diagnosis)
  #-------------------------------------------------------------------------#
  #if [ ! -d "$USER_HOME/diagnosis" ]; then
  #    git clone https://github.com/rainbow-mobile/diagnosis.git "$USER_HOME/diagnosis"
  #else
  #    ( cd "$USER_HOME/diagnosis" && git pull )
  #fi
  #SRC_DIR="$USER_HOME/diagnosis"
  if [ ! -d "$USER_HOME/diagnosis" ]; then
    #as_user "git clone https://github.com/rainbow-mobile/diagnosis.git \"$USER_HOME/diagnosis\""
    as_user "git clone https://github.com/rainbow-mobile/diagnosis.git \"$USER_HOME/diagnosis\""
  else
    #as_user "(cd \"$USER_HOME/diagnosis\" && git pull)"
    as_user "git -C \"$USER_HOME/diagnosis\" pull"
  fi  

  SRC_DIR="$USER_HOME/diagnosis"


  #-------------------------------------------------------------------------#
  # 2. slamnav2 리포지토리 (~/slamnav2)
  #-------------------------------------------------------------------------#
  #if [ ! -d "$USER_HOME/slamnav2" ]; then
  #    git clone https://github.com/rainbow-mobile/slamnav2.git "$USER_HOME/slamnav2"
  #else
  #    ( cd "$USER_HOME/slamnav2" && git pull )
  #fi
  if [ ! -d \"$USER_HOME/slamnav2\" ]; then
    as_user "git clone https://github.com/rainbow-mobile/slamnav2.git \"$USER_HOME/slamnav2\""
  else
    as_user "(cd \"$USER_HOME/slamnav2\" && git pull)"
  fi

  # 브랜치 선택
  #cd "$USER_HOME/slamnav2"
  #mapfile -t BRS < <(git branch -r | sed 's| *origin/||' | grep -v HEAD)
  #log "[slamnav2] 원격 브랜치 목록:"
  #for i in "${!BRS[@]}"; do
  #    idx=$((i+1))
  #    printf ' %2d) %s\n' "$idx" "${BRS[i]}"
  #done
  #read -rp "체크아웃할 번호: " n
  #if [[ "$n" =~ ^[0-9]+$ ]] && (( n>=1 && n<=${#BRS[@]} )); then
  #    git checkout "${BRS[n-1]}"
  #else
  #    echo "[WARN] 잘못된 번호, 브랜치 변경을 건너뜁니다."
  #fi
  #cd -
  as_user "cd \"$USER_HOME/slamnav2\" && \
    mapfile -t BRS < <(git branch -r | sed 's| *origin/||' | grep -v HEAD); \
    echo '--- 원격 브랜치 목록 ---'; \
    for i in \"\${!BRS[@]}\"; do printf '%3d) %s\n' \"\$((i+1))\" \"\${BRS[i]}\"; done; \
    read -rp '번호 선택(엔터=main): ' n; \
    if [[ -z \"\$n\" ]]; then \
        git checkout main; \
    elif [[ \"\$n\" =~ ^[0-9]+$ && \"\$n\" -ge 1 && \"\$n\" -le \${#BRS[@]} ]]; then \
        git checkout \"\${BRS[\$((n-1))]}\"; \
    else \
        echo '[WARN] 잘못된 번호, 브랜치 변경 건너뜀'; \
    fi"

  #-------------------------------------------------------------------------#
  # 3. 단축키 및 실행 스크립트 복사
  #-------------------------------------------------------------------------#
  #install -Dm755 "$SRC_DIR/slamnav2.sh"     "$USER_HOME/slamnav2.sh"
  #install -Dm755 "$SRC_DIR/diagnostic.sh"   "$USER_HOME/diagnostic.sh"
  #install -Dm644 "$SRC_DIR/SLAMNAV2.desktop"   "$DESKTOP_DIR/SLAMNAV2.desktop"
  #install -Dm644 "$SRC_DIR/diagnostic.desktop" "$DESKTOP_DIR/diagnostic.desktop"
  
  #gio set "$DESKTOP_DIR/SLAMNAV2.desktop"   metadata::trusted true 2>/dev/null || true
  #gio set "$DESKTOP_DIR/diagnostic.desktop" metadata::trusted true 2>/dev/null || true

# ① .desktop 파일은 755 로, 복사 단계에서 바로 실행권한 부여
  install -Dm755 -o "$REAL_USER" -g "$REAL_USER" "$SRC_DIR/slamnav2.sh"     "$USER_HOME/slamnav2.sh"
  install -Dm755 -o "$REAL_USER" -g "$REAL_USER" "$SRC_DIR/diagnostic.sh"   "$USER_HOME/diagnostic.sh"
  install -Dm755 -o "$REAL_USER" -g "$REAL_USER" "$SRC_DIR/SLAMNAV2.desktop"  "$DESKTOP_DIR/SLAMNAV2.desktop"
  install -Dm755 -o "$REAL_USER" -g "$REAL_USER" "$SRC_DIR/diagnostic.desktop" "$DESKTOP_DIR/diagnostic.desktop"

  
  
  chown -R "$REAL_USER:$REAL_USER" \
    "$USER_HOME"/{rplidar_sdk,OrbbecSDK,sick_safetyscanners_base,slamnav2,diagnosis} \
    "$DESKTOP_DIR"/{SLAMNAV2.desktop,diagnostic.desktop} \
    "$USER_HOME"/{slamnav2.sh,diagnostic.sh} 2>/dev/null || true

  # 2) .desktop 신뢰 플래그 ▶ 실제 사용자 세션 DBus로 실행
  REAL_UID=$(id -u "$REAL_USER")
  DBUS_ADDR="unix:path=/run/user/${REAL_UID}/bus"
  RUN_DIR="/run/user/${REAL_UID}"
  
  as_user "DBUS_SESSION_BUS_ADDRESS='${DBUS_ADDR}' XDG_RUNTIME_DIR='${RUN_DIR}' \
           gio set '${DESKTOP_DIR}/SLAMNAV2.desktop'  metadata::trusted true"
  as_user "DBUS_SESSION_BUS_ADDRESS='${DBUS_ADDR}' XDG_RUNTIME_DIR='${RUN_DIR}' \
           gio set '${DESKTOP_DIR}/diagnostic.desktop' metadata::trusted true"

  
  log "단축키 설치 완료"
}

### 3-6. STEP 6 ─ TeamViewer 설치  ###########################################
run_6() { # set_teamviewer.sh
    
  need_root; log "[STEP 6] TeamViewer 설치"
  
  # 1) TeamViewer .deb 다운로드 및 설치
  ARCH=$(dpkg --print-architecture)            # amd64, arm64 …
  URL="https://download.teamviewer.com/download/linux/teamviewer-host_${ARCH}.deb"
  TMP_DEB="/tmp/teamviewer.deb"
  wget -qO "$TMP_DEB" "$URL"
  sudo apt-get install -y "$TMP_DEB"
  rm -f "$TMP_DEB"
  
  # 2) GDM3 설정 파일에 Wayland 비활성화 설정 적용
  log "[STEP 6] GDM3 설정 파일 자동 수정: Wayland 비활성화"
  CONF="/etc/gdm3/custom.conf"

  if grep -Eq '^[[:space:]]*#?[[:space:]]*WaylandEnable=false' "$CONF"; then
    # 주석(#) 제거
    sudo sed -i 's/^[[:space:]]*#\?[[:space:]]*WaylandEnable=false/WaylandEnable=false/' "$CONF"
  else
    # 해당 라인이 없으면 [daemon] 섹션 아래에 추가
    sudo sed -i '/^\[daemon\]/a WaylandEnable=false' "$CONF"
  fi

  log "GDM3 커스텀 설정 완료 (/etc/gdm3/custom.conf)"
  sudo systemctl enable --now teamviewerd.service
  sudo teamviewer daemon restart 2>/dev/null || true
  log "TeamViewer 데몬 활성화 완료"
  
  
}
#──────────────────────────────────────────────────────────────────────────────
## 4. 실행
#──────────────────────────────────────────────────────────────────────────────
print_menu
mapfile -t STEPS < <(read_selection)

for n in "${STEPS[@]}"; do
  # 슬래시 뒤 문자열을 잘라서 앞뒤 공백을 xargs 로 제거
  FN=$(echo "${SCRIPTS[$n]##*/}" | xargs)
  if declare -f "$FN" >/dev/null; then
    echo -e "\n=============================="
    echo "실행: ${SCRIPTS[$n]%%/*}"
    echo "=============================="
    "$FN" || { FAILED+=("$FN"); log "[WARN] $FN 실패"; }
  else
    echo "[WARN] 잘못된 번호: $n"
  fi
done

#──────────────────────────────────────────────────────────────────────────────
## 5. 마무리
#──────────────────────────────────────────────────────────────────────────────
log "root → $REAL_USER 소유권 확인 중"
chown -R "$REAL_USER:$REAL_USER" \
  "$USER_HOME"/{rplidar_sdk,OrbbecSDK,sick_safetyscanners_base,slamnav2,diagnosis} 2>/dev/null || true

echo -e "\n========= 설치 요약 ($MODE) ========="
echo "✅ 완료:";   for i in "${INSTALLED[@]}"; do echo "  - $i"; done
echo "⏭️  건너뜀:"; for i in "${SKIPPED[@]}";   do echo "  - $i"; done
echo "❌ 실패:";   for i in "${FAILED[@]}";    do echo "  - $i"; done
echo "======================================"
log "설치 완료 — 새 터미널에서 LD_LIBRARY_PATH·dialout 적용 여부를 확인하세요."

