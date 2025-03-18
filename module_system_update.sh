#!/bin/bash
# module_system_update.sh: 시스템 업데이트 및 APT 패키지 설치

source ./common.sh

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

# 설치할 APT 패키지 목록 (원본 스크립트에 나온 목록 사용)
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

