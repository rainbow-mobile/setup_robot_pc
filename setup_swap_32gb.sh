#!/usr/bin/env bash
# resize_swap_8G.sh
# ──────────────────────────────────────────
# 기존 /swapfile ➜ 8 GiB로 재생성

set -euo pipefail
IFS=$'\n\t'

# 단순 로그 함수
log_msg() { echo -e "\e[32m[$(date +'%F %T')]\e[0m $*"; }

# 단순 단계 실행 함수
run_step() {
    local name="$1"      # 단계 이름
    local check_cmd="$2" # 이미 완료됐는지 검사
    local run_cmd="$3"   # 실제 실행 명령

    log_msg ">> [$name] 진행 중..."
    if eval "$check_cmd"; then
        log_msg "   [$name] 이미 완료 – 건너뜀"
    else
        if eval "$run_cmd"; then
            log_msg "   [$name] 완료!"
        else
            log_msg "   [$name] 실패!"
            exit 1
        fi
    fi
}

# 루트 권한 체크
[[ $EUID -eq 0 ]] || { echo "❗ 반드시 sudo 또는 root로 실행하세요."; exit 1; }

#──────────────────────────────────────────
# 8 GiB 스왑파일 재구성
#──────────────────────────────────────────
log_msg "========================================"
log_msg "스왑파일 32 GiB 재구성"
log_msg "========================================"

run_step "스왑파일 설정(32G)" \
      "free -h | grep -q 'Swap:.*32G'" \
      "sudo swapoff /swapfile &> /dev/null || true && \
       sudo rm -f /swapfile && \
       sudo fallocate -l 32G /swapfile || sudo dd if=/dev/zero of=/swapfile bs=1M count=32768 && \
       sudo chmod 600 /swapfile && \
       sudo mkswap /swapfile && \
       sudo swapon /swapfile && \
       grep -q '/swapfile swap' /etc/fstab || echo '/swapfile swap swap defaults 0 0' | sudo tee -a /etc/fstab"

log_msg "✅ 스왑파일 8 GiB 설정이 완료되었습니다.  (free -h 로 확인)"

