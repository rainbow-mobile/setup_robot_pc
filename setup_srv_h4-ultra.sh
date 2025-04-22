#!/bin/bash
set -e

# 0. 작업 디렉토리 설정: /home/현재사용자
USERNAME=$(whoami)
TARGET_DIR="/home/$USERNAME"

echo "작업 디렉토리: $TARGET_DIR"

# 1. RB_MOBILE 클론 (없으면 클론, 있으면 건너뜀)
if [ ! -d "$TARGET_DIR/RB_MOBILE" ]; then
    echo ">> RB_MOBILE 레포지토리 클론 중..."
    git clone https://github.com/yuuujinHeo/RB_MOBILE.git "$TARGET_DIR/RB_MOBILE"
else
    echo ">> $TARGET_DIR/RB_MOBILE 이미 존재, 클론 건너뜀"
fi

# RB_MOBILE 디렉토리로 이동
cd "$TARGET_DIR/RB_MOBILE"

# 1-1. maps 폴더 생성 (없으면)
if [ ! -d maps ]; then
    echo ">> maps 디렉토리 없음, 생성 중..."
    mkdir maps
else
    echo ">> maps 디렉토리 이미 존재, 건너뜀"
fi

# 2. RB_MOBILE/release 삭제 (있으면 삭제)
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
if git show-ref --verify --quiet refs/heads/S1002SRV; then
    git checkout S1002SRV
else
    git checkout -b S1002SRV origin/S1002SRV
fi

# 5. Qt QML 모듈 설치 (미설치 시에만)
declare -a PKGS=(
  qml-module-qtquick-shapes
  qml-module-qtmultimedia
  qml-module-qt-labs-platform
  qml-module-qtquick-controls2
  qml-module-qtquick-dialogs
)

# 설치되지 않은 패키지 수집
MISSING=()
for pkg in "${PKGS[@]}"; do
  if ! dpkg -l | grep -qw "$pkg"; then
    MISSING+=("$pkg")
  fi
done

# 설치
if [ ${#MISSING[@]} -gt 0 ]; then
  echo ">> 다음 패키지 설치 필요: ${MISSING[*]}"
  sudo apt-get update
  sudo apt-get install -y "${MISSING[@]}"
else
  echo ">> 모든 Qt QML 모듈이 이미 설치되어 있습니다."
fi

echo "=== 모든 작업 완료 ==="

