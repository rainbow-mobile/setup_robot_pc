#!/bin/bash

# 1. 빌드 디렉터리 설정 및 생성
BUILD_DIR="/home/rainbow/build-SLAMNAV2-Desktop-Release2"
PROJECT_FILE="/home/rainbow/app_slamnav2/SLAMNAV2.pro"   # SLAMNAV2.pro의 경로 (필요에 맞게 수정)

mkdir -p "$BUILD_DIR"                     # 빌드 디렉터리가 없으면 생성
cd "$BUILD_DIR" || {                      # 빌드 디렉터리로 이동
    echo "Error: 빌드 디렉터리로 이동할 수 없습니다: $BUILD_DIR"
    exit 1
}

# 2. qmake로 프로젝트 구성 (Release 모드)
qmake "$PROJECT_FILE" -spec linux-g++ CONFIG+=release
if [ $? -ne 0 ]; then
    echo "Error: qmake로 프로젝트 구성 중 오류가 발생했습니다."
    exit 1
fi

# 3. make로 빌드 수행
make -j$(nproc)
if [ $? -ne 0 ]; then
    echo "Error: 빌드 과정에서 오류가 발생했습니다 (컴파일 실패)."
    exit 1
fi

# 5. 빌드 성공 메시지 출력
echo "빌드가 성공적으로 완료되었습니다."

