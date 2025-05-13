#!/usr/bin/env bash
###############################################################################
# build_terminal.sh
#  · Qt 프로젝트를 터미널에서 자동으로 빌드하는 스크립트
#  · 릴리즈 or 디버그 모드를 선택할 수 있음 (기본: release)
###############################################################################
set -euo pipefail
IFS=$'\n\t'

# ① 빌드 모드 선택 (기본: release)
BUILD_MODE="${1:-release}"

# ② 사용자 디렉터리 정확히 추출
REAL_USER=${SUDO_USER:-$USER}
HOME_DIR=$(eval echo "~$REAL_USER")
SRC_DIR="$HOME_DIR/code/app_slamnav2"
PRO_FILE="$SRC_DIR/SLAMNAV2.pro"
BUILD_DIR="$SRC_DIR/build"
VTK_VERSION="9.1"

# ③ SDK 경로
ORB_INCLUDE="$HOME_DIR/OrbbecSDK/SDK/include"
ORB_LIB="$HOME_DIR/OrbbecSDK/SDK/lib"

RPLIDAR_INCLUDE="$HOME_DIR/rplidar_sdk/sdk/include"
RPLIDAR_LIB="$HOME_DIR/rplidar_sdk/output/Linux/Release"

# ④ 경로 확인 함수
check_path() {
    if [ ! -d "$1" ]; then
        echo -e "⚠️  누락: $1"
    else
        echo -e "✅ 확인됨: $1"
    fi
}

echo "[INFO] Qt 프로젝트를 터미널에서 빌드합니다."
echo "✅ 변수 설정 완료:
   HOME_DIR=$HOME_DIR
   SRC_DIR=$SRC_DIR
   VTK_VERSION=$VTK_VERSION"

check_path "$ORB_INCLUDE"
check_path "$RPLIDAR_INCLUDE"

# ⑤ 환경 변수 설정
export QT_SELECT=qt5
export QMAKE=$(/usr/bin/which qmake)
export MAKECMD="make -j$(nproc)"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-}:/usr/local/lib:$ORB_LIB:$RPLIDAR_LIB"

# ⑥ 빌드 디렉터리 생성
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# ⑦ qmake 및 make
echo "🛠 qmake"
"$QMAKE" "$PRO_FILE" CONFIG+=$BUILD_MODE
echo "🔨 make"
eval "$MAKECMD"

# ⑧ 빌드 완료 메시지
echo -e "\n✅ 빌드 완료: $BUILD_MODE 모드"

