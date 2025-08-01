#!/bin/bash
set -e

# 1) 패키지 목록 업데이트
sudo apt update

# 2) 설치할 패키지 목록
PKGS=(
    qtbase5-dev
    qt5-qmake
    qtmultimedia5-dev
    libqt5multimedia5-plugins
    libopencv-dev
    libopencv-contrib-dev
    libeigen3-dev
    libboost-thread-dev
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
    libqt5websockets5-dev          # QT += websockets
    libboost-system-dev               # Boost
    libjsoncpp-dev                 # JSONCPP
    libminizip-dev                 # minizip
    zlib1g-dev                     # zlib
    #libsophus-dev                  # Sophus (if 제공되는 경우)
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

# ---- fms2 레포지토리 설치 옵션 ----
# 실제 사용자 홈 디렉토리 결정 (sudo 실행 시 원사용자 홈 사용)
if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
  REAL_USER="$SUDO_USER"
else
  REAL_USER="$(id -un)"
fi

INSTALL_DIR="/home/$REAL_USER/fms2"

if [ ! -d "$INSTALL_DIR" ]; then
  read -p "'$INSTALL_DIR' 디렉토리가 없습니다. github.com/rainbow-mobile/fms2를 클론하여 설치하시겠습니까? [Y/n]: " ans
  ans="${ans:-Y}"
  case "$ans" in
    [Yy]* )
      echo "fms2 설치를 진행합니다..."
      sudo -u "$REAL_USER" git clone https://github.com/rainbow-mobile/fms2.git "$INSTALL_DIR"
      echo "fms2 설치가 완료되었습니다: $INSTALL_DIR"
      ;;
    * )
      echo "fms2 설치를 건너뜁니다."
      ;;
  esac
else
  echo "fms2 디렉토리가 이미 존재합니다: $INSTALL_DIR"
fi

