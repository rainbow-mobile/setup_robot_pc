#!/bin/bash

# 1. 사용자로부터 빌드 디렉터리와 .pro 파일 경로 입력 받기
read -e -p "빌드 디렉터리 경로를 입력하세요 (예: /home/lee/code/build-SLAMNAV2-Desktop-Release2): " BUILD_DIR
read -e -p "Qt .pro 프로젝트 파일 경로를 입력하세요 (예: /home/lee/code/app_slamnav2/SLAMNAV2.pro): " PROJECT_FILE

# 2. 입력값 확인 및 검증
if [ -z "$BUILD_DIR" ] || [ -z "$PROJECT_FILE" ]; then
    echo "Error: 빌드 디렉터리 또는 프로젝트 파일 경로가 비어 있습니다."
    exit 1
fi

if [ ! -f "$PROJECT_FILE" ]; then
    echo "Error: 지정한 .pro 파일이 존재하지 않습니다: $PROJECT_FILE"
    exit 1
fi

# 3. 빌드 디렉터리 생성 및 이동
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR" || {
    echo "Error: 빌드 디렉터리로 이동할 수 없습니다: $BUILD_DIR"
    exit 1
}

# 4. qmake로 프로젝트 구성 (Release 모드)
qmake "$PROJECT_FILE" -spec linux-g++ CONFIG+=release
if [ $? -ne 0 ]; then
    echo "Error: qmake로 프로젝트 구성 중 오류가 발생했습니다."
    exit 1
fi

# 5. make로 빌드 수행
make -j$(nproc)
if [ $? -ne 0 ]; then
    echo "Error: 빌드 과정에서 오류가 발생했습니다 (컴파일 실패)."
    exit 1
fi

# 6. 빌드 성공 메시지 출력
echo "✅ 빌드가 성공적으로 완료되었습니다."

