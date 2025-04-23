#!/usr/bin/env bash
# =============================================================================
# setup_mapper_env.sh  ─ Qt mapper 프로젝트 통합 설치 스크립트
# 작성 : 2025-04-23
# 사용법:
#   sudo ./setup_mapper_env.sh
# =============================================================================
set -euo pipefail

# --------- 기본 설정 ----------------------------------------------------------
NPROC=$(nproc)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$HOME/.mapper_build"      # 소스 빌드 임시폴더
LOG()  { echo -e "\033[1;32m[$(date '+%F %T')] $*\033[0m"; }
SKIP() { echo -e "\033[0;33m[SKIP] $*\033[0m"; }

mkdir -p "$BUILD_DIR"

# --------- 1. APT 패키지 설치 -------------------------------------------------
APT_PKGS=(
  build-essential cmake git wget curl unzip pkg-config
  # Qt (Qt5 기준)
  qtbase5-dev qttools5-dev qttools5-dev-tools qtdeclarative5-dev
  qml-module-qtquick-shapes qml-module-qtmultimedia
  qml-module-qt-labs-platform qml-module-qtquick-controls2
  qml-module-qtquick-dialogs
  # OpenCV & Boost
  libopencv-dev libopencv-contrib-dev libboost-all-dev
  # VTK 9.x + PCL 1.12
  libvtk9-dev libvtk9-qt-dev libpcl-dev
  # Eigen · TBB · JSONCPP · USB · 압축
  libeigen3-dev libtbb-dev libjsoncpp-dev libusb-1.0-0-dev
  zlib1g-dev libbz2-dev liblzma-dev libarchive-dev
  # GTSAM (패키지 있음 → 4.2.x)
  libgtsam-dev
  # PDAL
  libpdal-dev
  # spdlog (depth-ai 의존)
  libspdlog-dev
)

LOG "APT 패키지 설치"
apt-get update -y
for pkg in "${APT_PKGS[@]}"; do
  dpkg -s "$pkg" &>/dev/null && SKIP "$pkg 이미 설치" && continue
  apt-get install -y "$pkg"
done

# --------- 2. FBoW 빌드 -------------------------------------------------------
if ldconfig -p | grep -q libfbow.so; then
  SKIP "FBoW 이미 설치"
else
  LOG "FBoW 빌드/설치"
  cd "$BUILD_DIR"
  git clone --depth 1 https://github.com/rmsalinas/fbow.git
  cd fbow && mkdir -p build && cd build
  cmake .. -DCMAKE_BUILD_TYPE=Release
  make -j"$NPROC"
  make install
fi

# --------- 3. depthai-core 빌드 ----------------------------------------------
if ldconfig -p | grep -q libdepthai-core.so; then
  SKIP "depthai-core 이미 설치"
else
  LOG "depthai 의 시스템 의존 패키지 설치"
  wget -qO- https://docs.luxonis.com/install_dependencies.sh | bash

  LOG "depthai-core 소스 클론 및 체크아웃"
  cd "$BUILD_DIR"
  git clone https://github.com/luxonis/depthai-core.git
  cd depthai-core
  git checkout v2.25.1
  git submodule update --init --recursive
  mkdir -p build && cd build
  cmake .. -DCMAKE_BUILD_TYPE=Release \
           -DDEPTHAI_BUILD_EXAMPLES=ON \
           -DDEPTHAI_BUILD_TESTS=ON \
           -DDEPTHAI_TEST_EXAMPLES=ON
  make -j"$NPROC"
  make install
fi

# --------- 4. Livox LiDAR SDK (정적 라이브러리) ------------------------------
if ldconfig -p | grep -q livox_lidar_sdk_static; then
  SKIP "Livox LiDAR SDK 이미 설치"
else
  LOG "Livox LiDAR SDK 빌드/설치"
  cd "$BUILD_DIR"
  git clone --depth 1 https://github.com/Livox-SDK/Livox-SDK.git
  cd Livox-SDK && mkdir -p build && cd build
  cmake .. -DCMAKE_BUILD_TYPE=Release -DBUILD_DYNAMIC=OFF
  make -j"$NPROC"
  make install
fi

# --------- 5. (선택) Sophus 최신판 빌드 ---------------------------------------
if [ ! -d /usr/local/include/sophus ]; then
  LOG "Sophus 빌드/설치"
  cd "$BUILD_DIR"
  git clone --depth 1 https://github.com/strasdat/Sophus.git
  cd Sophus && mkdir -p build && cd build
  cmake .. -DCMAKE_BUILD_TYPE=Release
  make -j"$NPROC"
  make install
else
  SKIP "Sophus 이미 설치"
fi

# --------- 6. 정리 및 종료 -----------------------------------------------------
LOG "모든 의존 항목 설치/빌드 완료!"
LOG "필요 시 환경변수 LD_LIBRARY_PATH, PKG_CONFIG_PATH 를 확인하세요."
echo -e "\n이제 Qt Creator(또는 CMake)에서 mapper 프로젝트를 빌드하면 됩니다.\n"

exit 0

