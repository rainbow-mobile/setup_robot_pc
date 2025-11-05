#!/bin/bash
# AppImage 빌드 스크립트

set -e

echo "=== Docker SLAMNAV2 Manager AppImage 빌드 시작 ==="

# 디렉토리 확인
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Qt 버전 확인
QT_VERSION=$(qmake --version | grep -oP 'Qt version \K[0-9]+\.[0-9]+' || echo "")
if [ -z "$QT_VERSION" ]; then
    echo "오류: qmake를 찾을 수 없습니다. Qt가 설치되어 있는지 확인하세요."
    exit 1
fi
echo "Qt 버전: $QT_VERSION"

# 빌드 디렉토리 생성
BUILD_DIR="build"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# qmake 실행
echo "qmake 실행 중..."
qmake ../docker_manager.pro

# make 실행
echo "컴파일 중..."
make -j$(nproc)

echo "빌드 완료: $BUILD_DIR/docker_manager"

# AppImage 빌드 (linuxdeploy 사용)
if command -v linuxdeploy &> /dev/null; then
    echo "=== AppImage 생성 중 ==="
    
    # AppDir 생성
    APPDIR="AppDir"
    rm -rf "$APPDIR"
    mkdir -p "$APPDIR/usr/bin"
    
    # 바이너리 복사
    cp docker_manager "$APPDIR/usr/bin/"
    
    # linuxdeploy 실행
    linuxdeploy --appdir="$APPDIR" \
                --executable="$APPDIR/usr/bin/docker_manager" \
                --plugin=qt \
                --create-desktop-file \
                --output=appimage
    
    echo "=== AppImage 생성 완료 ==="
    ls -lh Docker_SLAMNAV2_Manager*.AppImage
else
    echo "경고: linuxdeploy가 설치되어 있지 않습니다."
    echo "AppImage 생성을 건너뜁니다."
    echo "설치: https://github.com/linuxdeploy/linuxdeploy"
fi

echo "=== 빌드 완료 ==="

