#!/bin/bash
# setup_light_fixed.sh
# 통합 설치 스크립트 (선택된 일부 단계 제외)
# - Node.js 및 Mobile/Task/Web 환경 설치 제외
# - 화면 blank(절전) 옵션 비활성화 제외
# - 자동 로그인 설정(GDM3 기준) 제외
#
# 기존 스크립트에서 apt 패키지 설치 부분을 수정하여,
# dpkg -s 체크 없이 무조건 설치를 시도하고, 로그 정보를 더 자세히 남기도록 개선했습니다.

sudo -v

########################################
# 0. nohup 백그라운드 실행 여부 확인
########################################
if [ "${NOHUP_EXECUTED}" != "true" ]; then
    echo "스크립트를 백그라운드에서 안전하게 실행합니다..."
    export NOHUP_EXECUTED=true
    nohup bash "$0" > setup_log.txt 2>&1 &
    echo "설치가 백그라운드에서 진행됩니다."
    echo "로그 확인: tail -f setup_log.txt"
    exit 0
fi

########################################
# 1. 로그 설정 및 로깅 함수
########################################
LOG_FILE="$HOME/setup_detailed.log"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 설치 스크립트 시작" > "$LOG_FILE"

log_msg() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$msg" | tee -a "$LOG_FILE"
}

# 결과 추적용 배열
declare -a INSTALLED=() SKIPPED=() FAILED=()

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
    local check_cmd="$2"
    local install_cmd="$3"
    
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
if source /etc/profile && sudo ldconfig; then
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
' && sudo sed -i 's/^Prompt=.*/Prompt=never/' /etc/update-manager/release-upgrades && gsettings set com.ubuntu.update-notifier regular-auto-launch-interval 0"

########################################
# 5. 스왑파일 설정
########################################
log_msg "========================================"
log_msg "3. 스왑파일 설정"
log_msg "========================================"

run_step "스왑파일 설정(32G)" \
    "free -h | grep -q 'Swap:.*32G'" \
    "sudo swapoff /swapfile &> /dev/null || true && \
     sudo rm -f /swapfile && \
     sudo fallocate -l 32G /swapfile || sudo dd if=/dev/zero of=/swapfile bs=1M count=32768 && \
     sudo chmod 600 /swapfile && \
     sudo mkswap /swapfile && \
     sudo swapon /swapfile && \
     grep -q '/swapfile swap' /etc/fstab || echo '/swapfile swap swap defaults 0 0' | sudo tee -a /etc/fstab"

########################################
# 6. 무선 드라이버 (RTL8812AU) 설치
########################################
log_msg "========================================"
log_msg "4. 무선 드라이버 (RTL8812AU) 설치"
log_msg "========================================"

run_step "RTL8812AU 드라이버" \
    "[ -d rtl8812au ]" \
    "git clone https://github.com/gnab/rtl8812au.git && \
     sudo cp -r rtl8812au /usr/src/rtl8812au-4.2.2 && \
     sudo dkms add -m rtl8812au -v 4.2.2 && \
     sudo dkms build -m rtl8812au -v 4.2.2 && \
     sudo dkms install -m rtl8812au -v 4.2.2 && \
     sudo modprobe 8812au"

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
# (선택) Node.js 및 Mobile/Task/Web 환경 설치 - 제외
########################################

########################################
# 8. TeamViewer 리셋 (또는 설치+리셋)
########################################
#log_msg "========================================"
#log_msg "6. TeamViewer 리셋"
#log_msg "========================================"

#run_step "TeamViewer 리셋" \
#    "test ! -f /etc/teamviewer/global.conf" \
#    "sudo teamviewer --daemon stop && \
#     sudo rm -f /etc/teamviewer/global.conf && \
#     sudo rm -rf ~/.config/teamviewer/ && \
#     sudo teamviewer --daemon start"

########################################
# 9. 환경 변수 재적용 및 OrbbecSDK 경로 업데이트
########################################
log_msg "========================================"
log_msg "7. 환경 변수 재적용 및 OrbbecSDK 경로 업데이트"
log_msg "========================================"

run_step "OrbbecSDK path in /etc/profile" \
    "grep 'OrbbecSDK/SDK/lib' /etc/profile &> /dev/null" \
    "sudo sh -c 'echo \"export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:/home/rainbow/OrbbecSDK/SDK/lib\" >> /etc/profile'"

run_step "Re-apply profile" \
    "true" \
    "source /etc/profile && sudo ldconfig && source ~/.bashrc"

########################################
# 10. USB 시리얼 설정 및 dialout 그룹 추가
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
# 11. USB udev 규칙 설정
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
# 화면 blank(절전) 옵션 비활성화 - 제외
########################################

########################################
# 자동 로그인 설정(GDM3) - 제외
########################################

########################################
# 12. (선택) 추가 환경 설정
########################################
log_msg "========================================"
log_msg "10. 추가 환경 설정"
log_msg "========================================"

run_step "추가 환경 변수 재적용" \
    "true" \
    "sudo sh -c 'echo \"export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:/usr/local/lib\" >> /etc/profile' && \
     sudo sh -c 'echo \"export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:\$HOME/rplidar_sdk/output/Linux/Release\" >> /etc/profile' && \
     sudo sh -c 'echo \"export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:\$HOME/OrbbecSDK/lib/linux_x64\" >> /etc/profile' && \
     source /etc/profile && \
     sudo ldconfig"

########################################
# 13. 최종 요약 및 재부팅 안내
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
read -p "재부팅하려면 엔터키를 누르세요..." 
sudo reboot

