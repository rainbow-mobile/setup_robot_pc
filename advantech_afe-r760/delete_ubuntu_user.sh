#!/usr/bin/env bash
# 목적: rainbow 계정에서 ubuntu 계정을 안전하게 삭제 (옵션: 홈 백업)
# 사용: sudo ./delete_ubuntu_user.sh [--backup]


# sudo ./delete_ubuntu_user.sh           # 바로 삭제
# sudo ./delete_ubuntu_user.sh --backup  # 홈 백업 후 삭제


set -euo pipefail

BACKUP=false
for arg in "${@:-}"; do
  case "$arg" in
    --backup) BACKUP=true ;;
    *) echo "[WARN] 알 수 없는 옵션: $arg (무시)";;
  esac
done

log()  { echo -e "[INFO] $*"; }
warn() { echo -e "[WARN] $*" >&2; }
err()  { echo -e "[ERROR] $*" >&2; exit 1; }

# 0) 루트 권한 확인
if [[ "$(id -u)" -ne 0 ]]; then
  err "루트 권한이 필요합니다. 'sudo ./delete_ubuntu_user.sh'로 실행하세요."
fi

# 1) 현재 sudo 호출자 확인 (ubuntu에서 실행 중이면 차단)
CALLER="${SUDO_USER:-${LOGNAME:-${USER:-}}}"
if [[ "${CALLER}" == "ubuntu" ]]; then
  err "현재 세션이 'ubuntu'입니다. rainbow로 로그인 후 실행하세요."
fi

# 2) ubuntu 계정 존재 여부
if ! getent passwd ubuntu >/dev/null 2>&1; then
  log "'ubuntu' 계정이 존재하지 않습니다. 할 일 없음."
  exit 0
fi

# 3) (옵션) 홈 백업
if $BACKUP; then
  SRC="/home/ubuntu"
  DST="/home/rainbow/ubuntu_backup"
  if [[ -d "$SRC" ]]; then
    log "ubuntu 홈을 ${DST} 로 백업합니다."
    mkdir -p "$DST"
    rsync -aHAX --delete "$SRC"/ "$DST"/
    chown -R rainbow:rainbow "$DST"
    log "백업 완료."
  else
    warn "백업 스킵: ${SRC} 가 존재하지 않습니다."
  fi
fi

# 4) ubuntu 사용자 프로세스 종료
if pgrep -u ubuntu >/dev/null 2>&1; then
  warn "'ubuntu' 사용자 프로세스를 종료합니다."
  pkill -KILL -u ubuntu || true
  sleep 1
fi

# 5) 계정 삭제 (홈 포함)
if command -v deluser >/dev/null 2>&1; then
  log "deluser --remove-home ubuntu"
  deluser --remove-home ubuntu
else
  log "userdel -r ubuntu"
  userdel -r ubuntu
fi

log "'ubuntu' 계정 삭제 완료."

