#!/bin/bash
# setup_all.sh
# 통합 설치 스크립트 – 각 단계별로 이미 설치되었으면 건너뛰고, 실패하면 기록하며,
# 마지막에 설치된 항목, 건너뛴 항목, 실패한 항목을 출력합니다.
# 사용 전 각 단계별 체크 명령 및 설치 명령을 환경에 맞게 수정하세요.

# 스크립트가 이미 nohup으로 실행 중인지 확인
if [ "${NOHUP_EXECUTED}" != "true" ]; then
    echo "스크립트를 백그라운드에서 안전하게 실행합니다..."
    export NOHUP_EXECUTED=true
    nohup bash "$0" > setup_log.txt 2>&1 &
    echo "설치가 백그라운드에서 진행됩니다."
    echo "로그 확인: tail -f setup_log.txt"
    exit 0
fi

# 로그 설정
LOG_FILE="$HOME/setup_detailed.log"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 설치 스크립트 시작" > "$LOG_FILE"

# 로그 함수
log_msg() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$msg" | tee -a "$LOG_FILE"
}

# 결과 추적용 배열 초기화
declare -a INSTALLED=() SKIPPED=() FAILED=()

# CPU 코어 수 확인 (병렬 빌드용)
NUM_CORES=$(nproc)
log_msg "감지된 CPU 코어: $NUM_CORES개"

# 단계 실행 함수
run_step() {
    local name="$1"
    local check_cmd="$2"
    local install_cmd="$3"
    
    log_msg ">> [$name] 진행 중..."
    if eval "$check_cmd"; then
        log_msg "   [$name] 이미 설치됨, 건너뜁니다."
        SKIPPED+=("$name")
    else
        log_msg "   [$name] 설치 중..."
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

# 실행 시간 측정
start_time=$(date +%s)
trap 'end_time=$(date +%s); log_msg "총 실행 시간: $((end_time - start_time))초"' EXIT

##############################
# 1. 시스템 업데이트 및 패키지 설치
##############################
log_msg "========================================"
log_msg "1. 시스템 업데이트 및 패키지 설치"
log_msg "========================================"

# 불필요한 패키지 제거 (한 번의 apt 호출로 최적화)
log_msg "[시스템] 불필요한 패키지 제거 중..."
sudo apt remove -y update-notifier orca || log_msg "일부 패키지 제거 실패 (이미 제거되었을 수 있음)"

# 시스템 업데이트
if sudo apt-get update && sudo apt-get upgrade -y; then
    INSTALLED+=("시스템 업데이트 완료")
else
    FAILED+=("시스템 업데이트 실패")
fi
fi

# 각 apt 패키지를 개별적으로 설치 (dpkg -s로 이미 설치 여부 확인)
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

for pkg in "${APT_PACKAGES[@]}"; do
    run_step "apt 패키지: $pkg" \
      "dpkg -s $pkg &> /dev/null" \
      "sudo apt-get install -y $pkg"
done

##############################
# 2. 시스템 환경 설정 (LD_LIBRARY_PATH, GRUB, 자동 업데이트 비활성화)
##############################
echo "========================================"
echo "2. 시스템 환경 설정"
echo "========================================"

# LD_LIBRARY_PATH 설정 – /etc/profile에 추가
run_step "LD_LIBRARY_PATH (/usr/local/lib)" \
    "grep '/usr/local/lib' /etc/profile &> /dev/null" \
    "sudo sh -c 'echo \"export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:/usr/local/lib\" >> /etc/profile'"

run_step "LD_LIBRARY_PATH (rplidar_sdk)" \
    "grep 'rplidar_sdk/output/Linux/Release' /etc/profile &> /dev/null" \
    "sudo sh -c 'echo \"export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:\$HOME/rplidar_sdk/output/Linux/Release\" >> /etc/profile'"

run_step "LD_LIBRARY_PATH (OrbbecSDK)" \
    "grep 'OrbbecSDK/lib/linux_x64' /etc/profile &> /dev/null" \
    "sudo sh -c 'echo \"export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:\$HOME/OrbbecSDK/lib/linux_x64\" >> /etc/profile'"

# 프로필 재적용 및 ldconfig
if source /etc/profile && sudo ldconfig; then
    INSTALLED+=("프로필 재적용 및 ldconfig")
else
    FAILED+=("프로필 재적용 및 ldconfig")
fi

# GRUB 설정 (USB 전원 관리 해제, intel_pstate 비활성화)
run_step "GRUB 설정" \
    "grep 'usbcore.autosuspend=-1 intel_pstate=disable' /etc/default/grub &> /dev/null" \
    "sudo sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT=/ s/\"$/ usbcore.autosuspend=-1 intel_pstate=disable\"/' /etc/default/grub && sudo update-grub"

# 자동 업데이트 비활성화
run_step "자동 업데이트 비활성화" \
    "grep 'APT::Periodic::Update-Package-Lists \"0\"' /etc/apt/apt.conf.d/20auto-upgrades &> /dev/null" \
    "sudo sh -c 'cat > /etc/apt/apt.conf.d/20auto-upgrades <<EOF
APT::Periodic::Update-Package-Lists \"0\";
APT::Periodic::Download-Upgradeable-Packages \"0\";
APT::Periodic::AutocleanInterval \"0\";
APT::Periodic::Unattended-Upgrade \"0\";
EOF' && sudo sed -i 's/^Prompt=.*/Prompt=never/' /etc/update-manager/release-upgrades && gsettings set com.ubuntu.update-notifier regular-auto-launch-interval 0"


##############################
# 3. 스왑파일 설정
##############################
echo "========================================"
echo "3. 스왑파일 설정"
echo "========================================"

run_step "스왑파일 설정" \
    "free -h | grep -q 'Swap:.*32G'" \
    "sudo swapoff /swapfile &> /dev/null || true && \
    sudo rm -f /swapfile && \
    sudo fallocate -l 32G /swapfile || sudo dd if=/dev/zero of=/swapfile bs=1M count=32768 && \
    sudo chmod 600 /swapfile && \
    sudo mkswap /swapfile && \
    sudo swapon /swapfile && \
    grep -q '/swapfile swap' /etc/fstab || echo '/swapfile swap swap defaults 0 0' | sudo tee -a /etc/fstab"


##############################
# 3. 무선 드라이버 (RTL8812AU) 설치
##############################
echo "========================================"
echo "3. 무선 드라이버 (RTL8812AU)"
echo "========================================"

run_step "RTL8812AU 드라이버" \
    "[ -d rtl8812au ]" \
    "git clone https://github.com/gnab/rtl8812au.git && sudo cp -r rtl8812au /usr/src/rtl8812au-4.2.2 && sudo dkms add -m rtl8812au -v 4.2.2 && sudo dkms build -m rtl8812au -v 4.2.2 && sudo dkms install -m rtl8812au -v 4.2.2 && sudo modprobe 8812au"

##############################
# 4. SLAMNAV2 관련 의존성 및 SDK (소스 빌드)
##############################
echo "========================================"
echo "4. SLAMNAV2 관련 의존성 및 SDK 설치"
echo "========================================"

# 4.1 CMake 3.27.7 (이미 최신 버전이면 skip)

CMAKE_VERSION=3.27.7
run_step "CMake $CMAKE_VERSION" \
    "[ -x \$(command -v cmake) ] && cmake --version | grep $CMAKE_VERSION &> /dev/null" \
    "wget https://github.com/Kitware/CMake/releases/download/v$CMAKE_VERSION/cmake-$CMAKE_VERSION.tar.gz && tar -xvzf cmake-$CMAKE_VERSION.tar.gz && cd cmake-$CMAKE_VERSION && ./bootstrap --qt-gui && make -j$NUM_CORES && sudo make install && cd ~"

# 4.2 Sophus
run_step "Sophus" \
    "[ -d Sophus/build ]" \
    "git clone https://github.com/strasdat/Sophus.git && cd Sophus && mkdir -p build && cd build && cmake .. -DBUILD_TESTS=OFF -DBUILD_EXAMPLES=OFF -DSOPHUS_USE_BASIC_LOGGING=ON && make -j$NUM_CORES && sudo make install && cd ~"

# 4.3 GTSAM (버전 4.2.0)
run_step "GTSAM" \
    "[ -d gtsam/build ]" \
    "git clone https://github.com/borglab/gtsam.git && cd gtsam && git checkout 4.2.0 && mkdir -p build && cd build && cmake .. -DGTSAM_USE_SYSTEM_EIGEN=ON -DGTSAM_BUILD_TESTS=OFF -DGTSAM_BUILD_EXAMPLES_ALWAYS=OFF && make -j$NUM_CORES && sudo make install && cd ~"

# 4.4 OMPL (버전 1.6.0)
run_step "OMPL" \
    "[ -d ompl/build ]" \
    "git clone https://github.com/ompl/ompl.git && cd ompl && git checkout 1.6.0 && mkdir -p build && cd build && cmake .. && make -j$NUM_CORES && sudo make install && cd ~"

# 4.5 socket.io-client-cpp
run_step "socket.io-client-cpp" \
    "[ -d socket.io-client-cpp/build ]" \
    "git clone --recurse-submodules https://github.com/socketio/socket.io-client-cpp.git && cd socket.io-client-cpp && mkdir -p build && cd build && cmake .. -DBUILD_SHARED_LIBS=ON -DLOGGING=OFF && make -j$NUM_CORES && sudo make install && cd ~"

# 4.6 OctoMap (버전 1.10.0)
run_step "OctoMap" \
    "[ -d octomap/build ]" \
    "git clone https://github.com/OctoMap/octomap.git && cd octomap && git checkout v1.10.0 && mkdir -p build && cd build && cmake .. -DBUILD_DYNAMICETD3D=OFF -DBUILD_OCTOVIS_SUBPROJECT=OFF -DBUILD_TESTING=OFF && make -j$NUM_CORES && sudo make install && cd ~"

# 4.7 OrbbecSDK (버전 v1.10.11)
#run_step "OrbbecSDK" \
#    "[ -d OrbbecSDK/misc/scripts ]" \
#    "git clone https://github.com/orbbec/OrbbecSDK.git && cd OrbbecSDK && git checkout v1.10.11 && cd misc/scripts && sudo bash install_udev_rules.sh && cd ~"

# 4.8 RPlidar SDK (release/v1.12.0)
#run_step "RPlidar SDK" \
#    "[ -d rplidar_sdk ]" \
#    "git clone https://github.com/Slamtec/rplidar_sdk.git && cd rplidar_sdk && git checkout release/v1.12.0 && make -j$NUM_CORES && cd ~ && (grep -q 'rplidar_sdk' ~/.bashrc || echo #'export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:$HOME/rplidar_sdk/output/Linux/Release' >> ~/.bashrc) && source ~/.bashrc && sudo ldconfig"

# 4.9 PDAL
run_step "PDAL" \
    "dpkg -s pdal libpdal-dev &> /dev/null" \
    "sudo apt update && sudo apt install -y pdal libpdal-dev"

# 4.10 Livox SDK2
run_step "Livox SDK2" \
    "[ -d Livox-SDK2/build ]" \
    "git clone https://github.com/Livox-SDK/Livox-SDK2.git && cd Livox-SDK2 && mkdir -p build && cd build && cmake .. && make -j$NUM_CORES && sudo make install && cd ~"


##############################
# 5. Node.js 및 Mobile/Task/Web 환경 설치(안함)
##############################
echo "========================================"
echo "5. Node.js 및 Mobile/Task/Web 환경 설치"
echo "========================================"

# 5.1 nvm 및 Node.js 설치 (LTS)
#run_step "nvm/Node.js" \
#    "[ -d \$HOME/.nvm ]" \
#    "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash && export NVM_DIR=\$HOME/.nvm && [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\" && nvm #install --lts && nvm use --lts && npm install -g npm@latest"

# 5.2 MobileServer 설치
#run_step "MobileServer" \
#    "[ -d web_robot_server ]" \
#    "if [ -d web_robot_server ]; then cd web_robot_server && git pull && npm install && cd ~; else git clone https://github.com/rainbow-mobile/web_robot_server.git && cd #web_robot_server && npm install && cd ~; fi"

# 5.3 MobileWeb 설치
#run_step "MobileWeb" \
#    "[ -d web_robot_ui ]" \
#    "if [ -d web_robot_ui ]; then cd web_robot_ui && git pull && npm install && npm run build && cd ~; else git clone https://github.com/rainbow-mobile/web_robot_ui.git && cd #web_robot_ui && npm install && npm run build && cd ~; fi"

# 5.4 TaskMan 설치
#run_step "TaskMan" \
#    "[ -d app_taskman ]" \
#    "if [ -d app_taskman ]; then cd app_taskman && git pull && cd ~; else git clone https://github.com/rainbow-mobile/app_taskman.git && cd app_taskman && cd ~; fi"

##############################
# 6. TeamViewer 리셋
##############################
echo "========================================"
echo "6. TeamViewer 리셋"
echo "========================================"
run_step "TeamViewer 리셋" \
    "test ! -f /etc/teamviewer/global.conf" \
    "sudo teamviewer --daemon stop && sudo rm -f /etc/teamviewer/global.conf && sudo rm -rf ~/.config/teamviewer/ && sudo teamviewer --daemon start"

##############################
# 7. Configure environment paths in /etc/profile
##############################
echo "========================================"
echo "7. Configuring environment paths in /etc/profile"
echo "========================================"

# Update path for OrbbecSDK
run_step "Update OrbbecSDK path in /etc/profile" \
    "grep 'OrbbecSDK/SDK/lib' /etc/profile &> /dev/null" \
    "sudo sh -c 'echo \"export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:/home/rainbow/OrbbecSDK/SDK/lib\" >> /etc/profile'"

# Apply the profile changes
run_step "Apply profile changes" \
    "true" \
    "source /etc/profile && source /etc/profile && sudo ldconfig && source ~/.bashrc"

# Note: The previously added paths for /usr/local/lib and rplidar_sdk are already included in section 2

##############################
# 7. USB udev 규칙 설정
##############################
echo "========================================"
echo "7. USB udev 규칙 설정"
echo "========================================"
run_step "USB udev 규칙" \
    "test -f /etc/udev/rules.d/99-usb-serial.rules" \
    "sudo bash -c 'cat > /etc/udev/rules.d/99-usb-serial.rules <<EOF
SUBSYSTEM==\"tty\", KERNELS==\"1-7\", ATTRS{idVendor}==\"10c4\", ATTRS{idProduct}==\"ea60\", SYMLINK+=\"ttyRP0\"
SUBSYSTEM==\"tty\", KERNELS==\"1-2.3\", ATTRS{idVendor}==\"067b\", ATTRS{idProduct}==\"2303\", SYMLINK+=\"ttyBL0\"
EOF' && sudo udevadm control --reload-rules && sudo udevadm trigger"

##############################
# 8. MySQL 초기 설정 (보안 설정 및 DB/테이블 생성)(안함)
##############################
#echo "========================================"
#echo "8. MySQL 초기 설정"
#echo "========================================"
# MySQL 설치는 1번에서 진행되었으므로, 여기서는 보안 설정 자동화(예: expect 사용) 및 DB 생성은 별도 작업으로 처리
#run_step "MySQL 설정" \
#    "mysql -u root -e 'show databases;' &> /dev/null" \
#    "echo 'MySQL 설정은 수동으로 진행되었거나 이미 완료된 것으로 가정합니다.'"

##############################
# 9. pm2 서비스 설정 및 부팅 자동 실행(안함)
##############################
#echo "========================================"
#echo "9. pm2 서비스 설정"
#echo "========================================"
#run_step "pm2 설정" \
#    "[ -x \$(command -v pm2) ]" \
#    "npm install -g pm2 && pm2 start --cwd ~/web_robot_server src/server.js --name 'MobileServer' && pm2 start ~/slamnav2/SLAMNAV2 --name 'SLAMNAV2' && pm2 start --cwd ~/app_taskman #TaskMan --name 'TaskMan' && pm2 start npm --name 'MobileWebUI' --cwd ~/web_robot_ui -- start && pm2 save && eval \"\$(pm2 startup | tail -n 1)\""


########################################
# 9. 화면 blank(절전) 옵션 비활성화 (never)
########################################
echo "========================================"
echo "9. 화면 blank(절전) 옵션 비활성화"
echo "========================================"

# GNOME 및 power 관련 설정: idle-delay, screensaver, 그리고 power daemon 설정
echo "[Power Saving] GNOME 및 전원 관리 설정 변경..."
gsettings set org.gnome.desktop.session idle-delay 0
gsettings set org.gnome.desktop.screensaver idle-activation-enabled false
gsettings set org.gnome.desktop.screensaver lock-enabled false

# GNOME power plugin의 화면 절전 시간(AC, 배터리 모드) 모두 0(never)로 설정
gsettings set org.gnome.settings-daemon.plugins.power sleep-display-ac 0
gsettings set org.gnome.settings-daemon.plugins.power sleep-display-battery 0

echo "[Power Saving] 화면 blank 옵션이 'never'로 설정되었습니다."


# X 환경에서 실행 중이면 xset 명령어 실행 (DISPLAY 환경 변수 확인)
if [ -z "$DISPLAY" ]; then
    echo "DISPLAY 환경 변수가 설정되지 않아 xset 명령어 건너뜁니다."
    SKIPPED+=("xset 화면 blank 옵션 (DISPLAY 없음)")
else
    if xset s off && xset -dpms && xset s noblank; then
        INSTALLED+=("xset 화면 blank 옵션 비활성화")
    else
        FAILED+=("xset 화면 blank 옵션 비활성화 실패")
    fi
fi

########################################
# 자동 로그인 설정 (GDM3 기준)
########################################
echo "========================================"
echo "자동 로그인 설정"
echo "========================================"
if [ -f /etc/gdm3/custom.conf ]; then
    echo "[Auto Login] /etc/gdm3/custom.conf 파일 수정 중..."
    # 자동 로그인 활성화: 주석 제거 및 값 변경 (현재 사용자를 자동 로그인으로 설정)
    sudo sed -i 's/^#\?AutomaticLoginEnable\s*=.*/AutomaticLoginEnable = true/' /etc/gdm3/custom.conf
    sudo sed -i "s/^#\?AutomaticLogin\s*=.*/AutomaticLogin = $USER/" /etc/gdm3/custom.conf
    echo "[Auto Login] 자동 로그인 설정 완료 (사용자: $USER)."
else
    echo "[Auto Login] /etc/gdm3/custom.conf 파일을 찾을 수 없습니다. 자동 로그인 설정을 건너뜁니다."
fi

##############################
# 10. (선택) 추가 환경 설정 – 예: TeamViewer, 환경 변수 재적용 등
##############################
echo "========================================"
echo "10. 추가 환경 설정"
echo "========================================"
# (이미 2번, 6번에서 처리한 경우 생략 가능)
run_step "추가 환경 변수 재적용" \
    "true" \
    "sudo sh -c 'echo \"export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:/usr/local/lib\" >> /etc/profile' && sudo sh -c 'echo \"export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:\$HOME/rplidar_sdk/output/Linux/Release\" >> /etc/profile' && sudo sh -c 'echo \"export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:\$HOME/OrbbecSDK/lib/linux_x64\" >> /etc/profile' && source /etc/profile && sudo ldconfig"

##############################
# 11. 최종 요약 및 재부팅 안내
##############################
echo "========================================"
echo "설치 요약"
echo "========================================"
echo "설치 완료된 항목:"
for item in "${INSTALLED[@]}"; do
    echo " - $item"
done

echo "이미 설치되어 건너뛴 항목:"
for item in "${SKIPPED[@]}"; do
    echo " - $item"
done

echo "설치 실패한 항목:"
for item in "${FAILED[@]}"; do
    echo " - $item"
done

echo "========================================"
echo "모든 작업이 완료되었습니다. 시스템 재부팅을 권장합니다."
read -p "재부팅하려면 엔터키를 누르세요..."
sudo reboot

