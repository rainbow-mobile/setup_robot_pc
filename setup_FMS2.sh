#!/bin/bash
set -e

# 1) 패키지 목록 업데이트
sudo apt update

# 2) 설치할 패키지 목록
PKGS=(
    qtbase5-dev
    qt5-qmake
    qtmultimedia5-dev
    libqt5-multimedia5-plugins
    libopencv-dev
    libopencv-contrib-dev
    libeigen3-dev
    libboost-all-dev
    libtbb-dev
    libssl-dev
    librdkafka-dev
    libvtk9-qt-dev
    libpcl-dev
    gstreamer1.0-plugins-base
    gstreamer1.0-plugins-good
    gstreamer1.0-plugins-ugly
    libgstreamer1.0-dev
    libgstreamer-plugins-base1.0-dev
    gstreamer1.0-rtsp
)

# 3) 설치 루프
for pkg in "${PKGS[@]}"; do
  if dpkg -s "$pkg" &> /dev/null; then
    echo "[SKIP] $pkg 이미 설치됨"
  else
    echo "[INSTALL] $pkg 설치 중..."
    sudo apt install -y "$pkg"
  fi
done

echo
echo "모든 의존성 설치가 완료되었습니다."

