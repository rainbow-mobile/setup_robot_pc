#!/usr/bin/env bash
# 목적:
#  1) 기존 rainbow 계정이 있으면 제거 후 새로 생성 (비번: rainbow) + sudo 권한 부여
#  2) --delete-ubuntu 옵션 시 ubuntu 계정(및 홈) 삭제 (안전검사 포함, --force로 강제)
# 사용: sudo ./setup_rainbow.sh [--delete-ubuntu] [--force]

# sudo ./setup_rainbow.sh                       	# ubuntu 삭제 안 함(기본)
# sudo ./setup_rainbow.sh --delete-ubuntu       	# ubuntu 자동 삭제(안전검사 통과 시)
# sudo ./setup_rainbow.sh --delete-ubuntu --force  	# 강제 삭제(위험, 주의)

set -euo pipefail

TARGET_USER="rainbow"
TARGET_PASS="rainbow"
DEFAULT_SHELL="/bin/bash"

DELETE_UBUNTU=false
FORCE_DELETE=false

for arg in "${@:-}"; do
  case "$arg" in
    --delete-ubuntu) DELETE_UBUNTU=true ;;
    --force)         FORCE_DELETE=true ;;
    *) echo "[WARN] 알 수 없는 옵션: $arg (무시)";;
  esac
done

log()  { echo -e "[INFO] $*"; }
warn() { echo -e "[WARN] $*" >&2; }
err()  { echo -e "[ERROR] $*" >&2; exit 1; }

need_root() {
  if [[ "$(id -u)" -ne 0 ]]; then
    err "루트 권한이 필요합니다. 'sudo ./setup_rainbow.sh'로 실행하세요."
  fi
}

kill_user_procs() {
  local user="$1"
  if pgrep -u "$user" >/dev/null 2>&1; then
    warn "'$user' 사용자 프로세스를 종료합니다."
    pkill -KILL -u "$user" || true
    sleep 1
  fi
}

delete_user_completely() {
  local user="$1"
  # deluser 우선, 없으면 userdel 사용
  if command -v deluser >/dev/null 2>&1; then
    log "deluser --remove-home $user"
    deluser --remove-home "$user"
  else
    log "userdel -r $user"
    userdel -r "$user"
  fi
}

create_rainbow() {
  # 1) 기존 rainbow 정리
  if getent passwd "${TARGET_USER}" >/dev/null 2>&1; then
    warn "'${TARGET_USER}' 계정이 이미 존재합니다. 먼저 삭제합니다."
    kill_user_procs "${TARGET_USER}"
    delete_user_completely "${TARGET_USER}" || err "'${TARGET_USER}' 삭제 실패"
    log "'${TARGET_USER}' 계정을 제거했습니다."
  else
    log "'${TARGET_USER}' 계정이 존재하지 않습니다. 새로 생성합니다."
  fi

  # 2) rainbow 생성
  log "'${TARGET_USER}' 계정을 생성합니다."
  useradd -m -s "${DEFAULT_SHELL}" "${TARGET_USER}" || err "useradd 실패"

  # 3) 비밀번호 설정
  echo "${TARGET_USER}:${TARGET_PASS}" | chpasswd || err "비밀번호 설정 실패"

  # 4) sudo 권한 부여
  if getent group sudo >/dev/null 2>&1; then
    usermod -aG sudo "${TARGET_USER}" || err "sudo 그룹 추가 실패"
    log "'${TARGET_USER}'에 sudo 권한을 부여했습니다."
  else
    warn "'sudo' 그룹이 없습니다. 관리자 그룹을 수동 확인하세요."
  fi

  # 5) 홈 권한 재확인
  chown -R "${TARGET_USER}:${TARGET_USER}" "/home/${TARGET_USER}" || err "홈 권한 설정 실패"
  chmod 700 "/home/${TARGET_USER}" || true
}

maybe_delete_ubuntu() {
  $DELETE_UBUNTU || { log "ubuntu 계정 삭제 옵션 미사용: 건너뜁니다."; return 0; }

  # 존재 여부
  if ! getent passwd ubuntu >/dev/null 2>&1; then
    log "'ubuntu' 계정이 존재하지 않습니다: 건너뜁니다."
    return 0
  fi

  # 안전 검사: 현재 sudo를 실행한 사용자가 ubuntu 인가?
  # - SUDO_USER: sudo를 호출한 원래 사용자
  # - LOGNAME/USER도 환경에 따라 참고
  SUDO_CALLER="${SUDO_USER:-${LOGNAME:-${USER:-}}}"

  if [[ "${SUDO_CALLER}" == "ubuntu" && "${FORCE_DELETE}" == false ]]; then
    warn "현재 세션이 'ubuntu'에서 sudo로 실행 중입니다. 세션이 끊기거나 문제가 발생할 수 있어 삭제를 차단합니다."
    warn "정말 삭제하려면: --delete-ubuntu --force 옵션을 사용하세요. (권장: rainbow로 로그인한 뒤 실행)"
    return 0
  fi

  # rainbow가 sudo 권한을 갖는지(그룹 확인) — 최소 안전망
  if id -nG "${TARGET_USER}" | tr ' ' '\n' | grep -qx sudo; then
    log "'${TARGET_USER}'의 sudo 권한 확인 완료."
  else
    warn "'${TARGET_USER}'가 sudo 그룹에 없음: ubuntu 삭제를 중단합니다."
    return 0
  fi

  # 프로세스 정리 후 삭제
  log "'ubuntu' 계정을 삭제합니다."
  kill_user_procs ubuntu
  delete_user_completely ubuntu || err "'ubuntu' 삭제 실패"
  log "'ubuntu' 계정 삭제 완료."
}

# === 실행 ===
need_root
create_rainbow
maybe_delete_ubuntu

# 요약
echo "----------------------------------------"
echo " 완료!"
echo "  사용자  : ${TARGET_USER}"
echo "  비밀번호: ${TARGET_PASS}"
echo "  홈 경로 : /home/${TARGET_USER}"
echo "  쉘     : ${DEFAULT_SHELL}"
echo "  sudo   : 부여됨"
$DELETE_UBUNTU && echo "  ubuntu : 삭제 시도 완료(상세는 로그 참고)"
echo "----------------------------------------"
echo "이제 로그아웃 후 '${TARGET_USER}' 계정으로 로그인해 사용하세요."

