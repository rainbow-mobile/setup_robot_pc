#!/bin/bash
set -e

echo "📦 APT 패키지 목록 초기화 및 업데이트 중..."
sudo rm -rf /var/lib/apt/lists/*
sudo apt update
sudo apt upgrade -y

echo "📦 개발 도구 및 라이브러리 설치 중..."
sudo apt install -y \
qtcreator \
qtbase5-dev \
qt5-qmake \
cmake \
libtbb-dev \
libboost-all-dev \
libopencv-dev \
libopencv-contrib-dev \
libeigen3-dev \
cmake-gui \
git \
htop \
build-essential \
rapidjson-dev \
libboost-system-dev \
libboost-thread-dev \
libssl-dev \
nmap \
qtmultimedia5-dev \
libqt5multimedia5-plugins \
pdal \
libpdal-dev \
librdkafka-dev \
libvtk9-qt-dev \
libpcl-dev \
openssh-server

echo "🎥 GStreamer 관련 패키지 설치 중..."
sudo apt install -y \
gstreamer1.0-plugins-base \
gstreamer1.0-plugins-good \
gstreamer1.0-plugins-bad \
gstreamer1.0-plugins-ugly

echo "⏱️ linuxptp 다운로드 및 설치 중..."
LINUXPTP_VERSION=3.1.1
wget https://sourceforge.net/projects/linuxptp/files/v3.1/linuxptp-${LINUXPTP_VERSION}.tgz/download -O linuxptp-${LINUXPTP_VERSION}.tgz
tar -xvf linuxptp-${LINUXPTP_VERSION}.tgz
cd linuxptp-${LINUXPTP_VERSION}
make
sudo make install
cd ..
rm -rf linuxptp-${LINUXPTP_VERSION}*

echo "🔧 .bashrc에 환경변수 추가 중..."
BASHRC_PATH="$HOME/.bashrc"

add_to_bashrc() {
    local line="$1"
    grep -qxF "$line" "$BASHRC_PATH" || echo "$line" >> "$BASHRC_PATH"
}

add_to_bashrc 'export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/lib'
add_to_bashrc 'export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/home/rainbow/rplidar_sdk/output/Linux/Release'
add_to_bashrc 'export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/home/rainbow/OrbbecSDK/lib/linux_x64'

echo "✅ 모든 작업이 완료되었습니다. 변경 사항을 적용하려면 'source ~/.bashrc'를 실행하세요."

