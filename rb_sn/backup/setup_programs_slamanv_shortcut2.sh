#!/usr/bin/env bash
# setup_diagnosis_and_slamnav2.sh
# 진단 단축키 복사 및 slamnav2 리포지토리 클론/업데이트 후 브랜치 체크아웃 작업
# 중간에 오류가 발생해도 계속 진행하며, 마지막에 요약하여 출력합니다.

# ─── 0. 스크립트 기준 위치로 이동 ───────────────────────────
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

# ─── 전역 배열 ─────────────────────────────────────────────
INSTALLED=()
SKIPPED=()
FAILED=()

# ─── 단계 실행 함수 ────────────────────────────────────────
run_step() {
    local name="$1"
    local check_cmd="$2"
    local install_cmd="$3"

    printf "\n>> [%s] 진행...\n" "$name"
    if eval "$check_cmd"; then
        printf "   [%s] 이미 완료되어 건너뜁니다.\n" "$name"
        SKIPPED+=("$name")
    else
        printf "   [%s] 처리 중...\n" "$name"
        if eval "$install_cmd"; then
            printf "   [%s] 완료.\n" "$name"
            INSTALLED+=("$name")
        else
            printf "   [%s] 실패!\n" "$name"
            FAILED+=("$name")
        fi
    fi
    printf "%0.s-" {1..40}
    printf "\n"
}

# ─── 실행 시간 기록 및 종료 시 요약 안내 ────────────────────
start_time=$(date +%s)
trap 'end_time=$(date +%s); echo "총 실행 시간: $((end_time - start_time)) 초"' EXIT

# ─── 1. Git safe.directory 설정 ────────────────────────────
for repo in "$HOME/diagnosis" "$HOME/slamnav2"; do
  if [ -d "$repo/.git" ]; then
    git config --global --add safe.directory "$repo" 2>/dev/null || true
  fi
done

# ─── 2. Git 설치 확인 및 설치 ─────────────────────────────
run_step "git 설치" \
  "command -v git >/dev/null" \
  "sudo apt-get update -qq && sudo apt-get install -y git"

# ─── 3. diagnosis 리포지토리 처리 ─────────────────────────
run_step "diagnosis 클론/업데이트" \
  "[ -d \"$HOME/diagnosis/.git\" ]" \
  " \
    git config --global --add safe.directory \"$HOME/diagnosis\" && \
    if [ ! -d \"$HOME/diagnosis\" ]; then \
      git clone https://github.com/rainbow-mobile/diagnosis.git \"$HOME/diagnosis\"; \
    else \
      git -C \"$HOME/diagnosis\" pull; \
    fi \
  "

# ─── 4. slamnav2 리포지토리 처리 ──────────────────────────
run_step "slamnav2 클론/업데이트" \
  "[ -d \"$HOME/slamnav2/.git\" ]" \
  " \
    git config --global --add safe.directory \"$HOME/slamnav2\" && \
    if [ ! -d \"$HOME/slamnav2\" ]; then \
      git clone https://github.com/rainbow-mobile/slamnav2.git \"$HOME/slamnav2\"; \
    else \
      git -C \"$HOME/slamnav2\" pull; \
    fi \
  "

# ─── 5. slamnav2 브랜치 자동 체크아웃 ───────────────────────
cd "$HOME/slamnav2" || { FAILED+=("slamnav2 디렉토리 없음"); cd "$HOME"; }
branches=($(git -c "safe.directory=$PWD" branch -r \
           | sed 's@ *origin/@@' | grep -v HEAD))
if [ ${#branches[@]} -eq 0 ]; then
    FAILED+=("원격 브랜치 목록 없음")
else
    # 기본 브랜치 지정: main이 없으면 첫 번째
    default_branch="main"
    [[ " ${branches[*]} " == *" $default_branch "* ]] || default_branch="${branches[0]}"
    run_step "브랜치 체크아웃 ($default_branch)" \
      "git -c safe.directory=$PWD rev-parse --verify $default_branch >/dev/null" \
      "git -c safe.directory=$PWD checkout $default_branch"
fi
cd "$HOME"

# ─── 6. 진단 단축키 복사 작업 ───────────────────────────────
# (원본 스크립트의 USER_HOME 결정 및 복사 로직을 그대로 여기에 삽입)

# ─── 최종 요약 출력 ────────────────────────────────────────
printf "\n====== 설치 요약 ======\n"
printf "완료된 항목:\n";   for i in "${INSTALLED[@]}"; do printf "  - %s\n" "$i"; done
printf "건너뛴 항목:\n";   for i in "${SKIPPED[@]}";   do printf "  - %s\n" "$i"; done
printf "실패한 항목:\n";   for i in "${FAILED[@]}";    do printf "  - %s\n" "$i"; done

