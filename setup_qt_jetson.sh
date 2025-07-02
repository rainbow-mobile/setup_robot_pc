#!/usr/bin/env bash
set -euo pipefail

echo "===== Jetson 개발 환경 자동 설치 ====="

ARCH=$(uname -m)
if [[ "${ARCH}" != "aarch64" ]]; then
  echo "[오류] 이 스크립트는 Jetson(ARM64) 전용입니다. 현재 아키텍처: ${ARCH}"
  exit 1
fi

#---------- 1. 기본 리포지터리 업데이트 ----------
sudo apt-get update -y
#sudo apt-get upgrade -y

# universe·multiverse가 비활성화돼 있으면 활성화
#sudo add-apt-repository -y universe
#sudo add-apt-repository -y multiverse

#---------- 2. 공통 개발 패키지 ----------
PACKAGES_COMMON=(
  build-essential      make              git          htop      sshpass
  cmake                cmake-gui
  qtbase5-dev          qtdeclarative5-dev           # Qt 핵심
  qtcreator            qttools5-dev
  libqt5x11extras5-dev libqt5websockets5-dev qtmultimedia5-dev
  libtbb-dev           libboost-all-dev   libeigen3-dev
  libpcl-dev           libvtk9-qt-dev
  libquazip5-dev       liblcm-dev
)

#---------- 3. OpenCV ----------
# JetPack에는 CUDA 가속 OpenCV가 이미 포함되어 있습니다.
# 별도 패키지가 필요하면 주석을 제거하세요.
# OPENCV_PKGS=(libopencv-dev libopencv-contrib-dev)
OPENCV_PKGS=()

#---------- 4. Jetson 전용 패키지 ----------
# JetPack 메타-패키지는 CUDA, cuDNN, TensorRT, OpenCV 등을 한 번에 설치
PACKAGES_JETSON=(
  nvidia-jetpack
)

#---------- 5. 패키지 설치 ----------
sudo apt-get install -y "${PACKAGES_COMMON[@]}" "${OPENCV_PKGS[@]}" "${PACKAGES_JETSON[@]}"

#---------- 6. 정리 ----------
#sudo apt-get autoremove -y
echo "===== 설치 완료! Jetson 재부팅 권장 ====="

