#!/usr/bin/env bash
###############################################################################
# setup_usb_serial.sh
#  · USB 시리얼 디바이스에 대한 udev 규칙 설정
#  · REAL_USER 사용자에 dialout 그룹 추가
###############################################################################
set -Eeuo pipefail
IFS=$'\n\t'

# 루트 권한 확인
need_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "❗ 이 스크립트는 sudo 또는 root 권한으로 실행해야 합니다." >&2
    exit 1
  fi
}

# 로그 출력 함수
log_msg() {
  local now
  now=$(date +'%F %T')
  echo -e "[${now}] $*"
}

# 단계 실행 헬퍼 (체크 & 설치)
run_step() {
  local name="$1"
  local check_cmd="$2"
  local install_cmd="$3"

  log_msg ">> [$name] 시작"
  if eval "$check_cmd"; then
    log_msg "   [$name] 이미 설정됨, 건너뜀"
  else
    log_msg "   [$name] 설정 중..."
    if eval "$install_cmd"; then
      log_msg "   [$name] 완료"
    else
      log_msg "   [$name] 실패" >&2
    fi
  fi
  echo
}

#####################
# 스크립트 시작
#####################
need_root

# 실제 사용자 계정 (sudo 사용 시)
REAL_USER=${SUDO_USER:-$(whoami)}
export USER="$REAL_USER"

log_msg "▶ USB 시리얼 및 udev 설정 시작 (실행 사용자: $REAL_USER)"

########################################
# 1. dialout 그룹 추가
########################################
log_msg "========================================"
log_msg "1. 사용자 dialout 그룹 추가"
log_msg "========================================"
run_step "dialout 그룹" \
  "groups \"$USER\" | grep -q '\\bdialout\\b'" \
  "sudo adduser \"$USER\" dialout"

########################################
# 2. brltty 패키지 제거
########################################
log_msg "========================================"
log_msg "2. brltty 제거"
log_msg "========================================"
run_step "brltty 제거" \
  "dpkg -l | grep -q '^ii  brltty'" \
  "sudo apt-get remove -y brltty"

########################################
# 3. USB udev 규칙 설정
########################################
log_msg "========================================"
log_msg "3. USB udev 규칙 설정"
log_msg "========================================"
run_step "udev 규칙" \
  "test -f /etc/udev/rules.d/99-usb-serial.rules" \
  "sudo bash -c 'cat > /etc/udev/rules.d/99-usb-serial.rules <<EOF
SUBSYSTEM==\"tty\", KERNELS==\"1-7\",   ATTRS{idVendor}==\"10c4\", ATTRS{idProduct}==\"ea60\", SYMLINK+=\"ttyRP0\"
SUBSYSTEM==\"tty\", KERNELS==\"1-2.3\", ATTRS{idVendor}==\"067b\", ATTRS{idProduct}==\"2303\", SYMLINK+=\"ttyBL0\"
SUBSYSTEM==\"tty\", KERNELS==\"1-1.2\", ATTRS{idVendor}==\"2109\", ATTRS{idProduct}==\"0812\", SYMLINK+=\"ttyCB0\"
EOF
' && \
sudo udevadm control --reload-rules && sudo udevadm trigger"

log_msg "▶ 모든 설정이 완료되었습니다."

