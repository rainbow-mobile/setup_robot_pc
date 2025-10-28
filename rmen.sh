#!/usr/bin/env bash
# netbufctl.sh - Linux 네트워크 메모리 버퍼(rmem/wmem) 튜닝 도우미
# 사용법:
#   sudo ./netbufctl.sh show
#   sudo ./netbufctl.sh apply --rmem-max 134217728 --wmem-max 134217728 \
#       --tcp-rmem "4096 87380 134217728" --tcp-wmem "4096 65536 134217728"
#   sudo ./netbufctl.sh persist [동일옵션]           # /etc/sysctl.d/99-net-buffers.conf 생성
#   sudo ./netbufctl.sh revert                       # persist로 적용한 파일을 되돌림
#   sudo ./netbufctl.sh nic --dev eth0 --rx 4096 --tx 4096  # (선택) NIC 버퍼 조정
#   ./netbufctl.sh help

set -euo pipefail

# ---------- 스타일 ----------
RED() { echo -e "\033[31m$*\033[0m"; }
GRN() { echo -e "\033[32m$*\033[0m"; }
YLW() { echo -e "\033[33m$*\033[0m"; }
BLU() { echo -e "\033[34m$*\033[0m"; }
BOLD() { echo -e "\033[1m$*\033[0m"; }

# ---------- 기본값 ----------
RMEM_MAX_DEF=134217728          # 128MB
WMEM_MAX_DEF=134217728          # 128MB
TCP_RMEM_DEF="4096 87380 134217728"
TCP_WMEM_DEF="4096 65536 134217728"
CONF_DIR="/etc/sysctl.d"
CONF_FILE="$CONF_DIR/99-net-buffers.conf"
BACKUP_FILE="$CONF_FILE.bak.$(date +%Y%m%d-%H%M%S)"

need_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "$(RED "[ERR]") 루트 권한이 필요합니다. sudo로 실행해 주세요."
    exit 1
  fi
}

# ---------- 공용 출력 ----------
print_current() {
  echo "$(BOLD "커널 네트워크 버퍼 현재 설정")"
  sysctl net.core.rmem_default 2>/dev/null || true
  sysctl net.core.rmem_max     2>/dev/null || true
  sysctl net.core.wmem_default 2>/dev/null || true
  sysctl net.core.wmem_max     2>/dev/null || true
  sysctl net.ipv4.tcp_rmem     2>/dev/null || true
  sysctl net.ipv4.tcp_wmem     2>/dev/null || true
  echo
  echo "$(BOLD "소켓별 실사용량 확인 예시:") ss -m | head -n 10"
}

apply_runtime() {
  local rmem_max="$1" wmem_max="$2" tcp_rmem="$3" tcp_wmem="$4"
  echo "$(BLU "[RUN]") sysctl -w net.core.rmem_max=${rmem_max}"
  sysctl -w "net.core.rmem_max=${rmem_max}" >/dev/null
  echo "$(BLU "[RUN]") sysctl -w net.core.wmem_max=${wmem_max}"
  sysctl -w "net.core.wmem_max=${wmem_max}" >/dev/null

  echo "$(BLU "[RUN]") sysctl -w net.ipv4.tcp_rmem=\"${tcp_rmem}\""
  sysctl -w "net.ipv4.tcp_rmem=${tcp_rmem}" >/dev/null
  echo "$(BLU "[RUN]") sysctl -w net.ipv4.tcp_wmem=\"${tcp_wmem}\""
  sysctl -w "net.ipv4.tcp_wmem=${tcp_wmem}" >/dev/null

  echo "$(GRN "[OK]") 일시적 적용 완료 (재부팅 시 초기화)."
}

apply_persist() {
  need_root
  local rmem_max="$1" wmem_max="$2" tcp_rmem="$3" tcp_wmem="$4"

  mkdir -p "$CONF_DIR"
  if [[ -f "$CONF_FILE" ]]; then
    cp -a "$CONF_FILE" "$BACKUP_FILE"
    echo "$(YLW "[WARN]") 기존 $CONF_FILE 백업: $BACKUP_FILE"
  fi

  cat > "$CONF_FILE" <<EOF
# 생성 시각: $(date -Is)
# 네트워크 버퍼 튜닝 (rmem/wmem, TCP rmem/wmem)
net.core.rmem_max=${rmem_max}
net.core.wmem_max=${wmem_max}
net.ipv4.tcp_rmem=${tcp_rmem}
net.ipv4.tcp_wmem=${tcp_wmem}
EOF

  echo "$(BLU "[RUN]") sysctl --system"
  sysctl --system >/dev/null

  echo "$(GRN "[OK]") 영구 적용 완료: $CONF_FILE"
}

revert_persist() {
  need_root
  if [[ ! -f "$CONF_FILE" ]]; then
    echo "$(YLW "[WARN]") 되돌릴 파일이 없습니다: $CONF_FILE"
    exit 0
  fi
  cp -a "$CONF_FILE" "$BACKUP_FILE"
  rm -f "$CONF_FILE"
  echo "$(BLU "[RUN]") sysctl --system"
  sysctl --system >/dev/null
  echo "$(GRN "[OK]") 되돌림 완료 (백업: $BACKUP_FILE)"
}

nic_tune() {
  need_root
  local dev="" rx="" tx=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dev) dev="$2"; shift 2;;
      --rx)  rx="$2";  shift 2;;
      --tx)  tx="$2";  shift 2;;
      *) echo "$(RED "[ERR]") 알 수 없는 옵션: $1"; exit 1;;
    esac
  done
  if [[ -z "$dev" ]]; then
    echo "$(RED "[ERR]") --dev <인터페이스> 를 지정해 주세요. 예: --dev eth0"; exit 1
  fi

  echo "$(BOLD "NIC 버퍼 현재값 ($dev)")"
  ethtool -g "$dev" || { echo "$(RED "[ERR]") ethtool 실패"; exit 1; }
  echo

  local args=()
  [[ -n "$rx" ]] && args+=(rx "$rx")
  [[ -n "$tx" ]] && args+=(tx "$tx")
  if [[ ${#args[@]} -gt 0 ]]; then
    echo "$(BLU "[RUN]") ethtool -G $dev ${args[*]}"
    ethtool -G "$dev" "${args[@]}" || {
      echo "$(RED "[ERR]") NIC 버퍼 설정 실패 (드라이버/하드웨어 제한 가능)"
      exit 1
    }
    echo "$(GRN "[OK]") NIC 버퍼 적용 완료"
  else
    echo "$(YLW "[WARN]") --rx 또는 --tx 값을 지정하지 않아 변경하지 않았습니다."
  fi

  echo
  echo "$(BOLD "NIC 버퍼 변경 후 확인 ($dev)")"
  ethtool -g "$dev" || true
}

print_help() {
  cat <<'HLP'
사용법:
  sudo ./netbufctl.sh show
      - 현재 커널 rmem/wmem, TCP rmem/wmem 출력

  sudo ./netbufctl.sh apply [옵션]
      - 재부팅 시 초기화되는 일시적 적용
      옵션(미지정 시 괄호의 기본값 사용):
        --rmem-max <바이트>            (134217728)
        --wmem-max <바이트>            (134217728)
        --tcp-rmem "min def max"       ("4096 87380 134217728")
        --tcp-wmem "min def max"       ("4096 65536 134217728")

  sudo ./netbufctl.sh persist [옵션]
      - /etc/sysctl.d/99-net-buffers.conf 생성하여 영구 적용
      - 옵션은 apply와 동일

  sudo ./netbufctl.sh revert
      - persist로 만든 99-net-buffers.conf 삭제 후 sysctl 재적용

  sudo ./netbufctl.sh nic --dev eth0 [--rx N] [--tx N]
      - (선택) NIC RX/TX 큐 버퍼 크기 조정 (드라이버/하드웨어 제약 있을 수 있음)

예시:
  sudo ./netbufctl.sh apply
  sudo ./netbufctl.sh persist --rmem-max 268435456 --wmem-max 268435456
  sudo ./netbufctl.sh nic --dev eth0 --rx 4096 --tx 4096

참고:
  - 컨테이너 개별 적용: docker run --sysctl net.core.rmem_max=134217728 ...
HLP
}

# ---------- 메인 ----------
cmd="${1:-help}"
shift || true

case "$cmd" in
  show)
    print_current
    ;;
  apply|persist)
    need_root
    # 기본값
    rmem_max="$RMEM_MAX_DEF"
    wmem_max="$WMEM_MAX_DEF"
    tcp_rmem="$TCP_RMEM_DEF"
    tcp_wmem="$TCP_WMEM_DEF"
    # 옵션 파싱
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --rmem-max) rmem_max="$2"; shift 2;;
        --wmem-max) wmem_max="$2"; shift 2;;
        --tcp-rmem) tcp_rmem="$2"; shift 2;;
        --tcp-wmem) tcp_wmem="$2"; shift 2;;
        *)
          echo "$(RED "[ERR]") 알 수 없는 옵션: $1"; exit 1;;
      esac
    done
    echo "$(BOLD "적용값")"
    echo "  net.core.rmem_max      = $rmem_max"
    echo "  net.core.wmem_max      = $wmem_max"
    echo "  net.ipv4.tcp_rmem      = $tcp_rmem"
    echo "  net.ipv4.tcp_wmem      = $tcp_wmem"
    echo

    if [[ "$cmd" == "apply" ]]; then
      apply_runtime "$rmem_max" "$wmem_max" "$tcp_rmem" "$tcp_wmem"
    else
      apply_persist "$rmem_max" "$wmem_max" "$tcp_rmem" "$tcp_wmem"
    fi

    echo
    print_current
    ;;
  revert)
    revert_persist
    ;;
  nic)
    nic_tune "$@"
    ;;
  help|--help|-h)
    print_help
    ;;
  *)
    echo "$(RED "[ERR]") 알 수 없는 명령: $cmd"
    print_help
    exit 1
    ;;
esac

