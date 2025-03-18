#!/bin/bash
# common.sh: 공통 로깅, 변수, 함수 정의

# 로그 파일 설정
LOG_FILE="$HOME/setup_detailed.log"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 설치 스크립트 시작" > "$LOG_FILE"

# 로깅 함수
log_msg() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$msg" | tee -a "$LOG_FILE"
}

# 결과 추적 배열
declare -a INSTALLED=()
declare -a SKIPPED=()
declare -a FAILED=()

# CPU 코어 수 확인 (병렬 빌드를 위한 변수)
NUM_CORES=$(nproc)
log_msg "감지된 CPU 코어: $NUM_CORES개"

# 단계 실행 함수
run_step() {
    local name="$1"
    local check_cmd="$2"
    local install_cmd="$3"

    log_msg ">> [$name] 진행 중..."
    if eval "$check_cmd"; then
        log_msg "   [$name] 이미 설치됨, 건너뜁니다."
        SKIPPED+=("$name")
    else
        log_msg "   [$name] 설치 중..."
        if eval "$install_cmd"; then
            log_msg "   [$name] 완료됨"
            INSTALLED+=("$name")
        else
            log_msg "   [$name] 실패!"
            FAILED+=("$name")
        fi
    fi
    log_msg "----------------------------------------"
}

