#!/bin/bash
set -e

# 0. 작업 디렉토리 설정: /home/현재사용자
USERNAME=$(whoami)
TARGET_DIR="/home/$USERNAME"

echo "작업 디렉토리: $TARGET_DIR"

# 1. RB_MOBILE 클론 (이미 있으면 건너뜀)
if [ ! -d "$TARGET_DIR/RB_MOBILE" ]; then
    echo ">> RB_MOBILE 레포지토리 클론 중..."
    git clone https://github.com/yuuujinHeo/RB_MOBILE.git "$TARGET_DIR/RB_MOBILE"
else
    echo ">> $TARGET_DIR/RB_MOBILE 이미 존재, 클론 건너뜀"
fi

# 2. RB_MOBILE/release 삭제 (있으면 삭제)
cd "$TARGET_DIR/RB_MOBILE"
if [ -d release ]; then
    echo ">> 기존 release 디렉토리 삭제 중..."
    rm -rf release
else
    echo ">> release 디렉토리 없음, 삭제 건너뜀"
fi

# 3. release 레포지토리 클론
echo ">> release 레포지토리 클론 중..."
git clone https://github.com/yuuujinHeo/release.git release

# 4. release 브랜치 ultra로 체크아웃
cd release
echo ">> 'ultra' 브랜치로 전환 중..."
git fetch origin
if git show-ref --verify --quiet refs/heads/ultra; then
    git checkout ultra
else
    git checkout -b ultra origin/ultra
fi

# 5. qml-module-qtquick-dialogs 설치 (미설치 시에만)
PKG="qml-module-qtquick-dialogs"
echo ">> 패키지 '$PKG' 설치 확인..."
if ! dpkg -l | grep -qw "$PKG"; then
    echo ">>> 설치되어 있지 않음. 설치 중..."
    sudo apt-get update
    sudo apt-get install -y "$PKG"
else
    echo ">>> 이미 설치되어 있음, 건너뜀"
fi

echo "=== 모든 작업 완료 ==="

