#!/bin/bash
set -e

########################################
# Qt 실행 파일 런처 스크립트 (log + env 설정 포함)
#
# 🔹 기능:
#   - debug / release 모드 실행
#   - 실행 로그 저장
#   - Qt 관련 환경변수 설정 (예: plugin 경로)
#
# 사용법:
#   ./run.sh [debug|release]
#     예) ./run.sh
#         ./run.sh debug
########################################

# 1. 실행 모드 설정
MODE=${1:-release}
SRC_DIR="$(dirname "$(realpath "$0")")"
BUILD_DIR="$SRC_DIR/build-$MODE"

# 2. 실행 파일 이름 (필요 시 수정)
EXECUTABLE="SLAMNAV2"
EXEC_PATH="$BUILD_DIR/$EXECUTABLE"

# 3. 로그 저장 위치
LOG_DIR="$BUILD_DIR/log"
LOG_FILE="$LOG_DIR/run_$(date +%Y%m%d_%H%M%S).log"

# 4. Qt 플랫폼 플러그인 경로 설정 (필요 시 수정)
export QT_QPA_PLATFORM_PLUGIN_PATH="/usr/lib/qt5/plugins/platforms"

# 로그 디렉토리 생성
mkdir -p "$LOG_DIR"

# 5. 실행 파일 존재 확인
if [[ ! -x "$EXEC_PATH" ]]; then
    echo "❌ 실행 파일이 존재하거나 실행 권한이 없습니다: $EXEC_PATH"
    echo "💡 먼저 ./build.sh $MODE 로 빌드하세요."
    exit 1
fi

# 6. 실행
echo "🚀 [$MODE 모드] $EXECUTABLE 실행 중..."
echo "📁 로그 저장 위치: $LOG_FILE"

"$EXEC_PATH" 2>&1 | tee "$LOG_FILE"

