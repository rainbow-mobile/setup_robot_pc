#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

###############################################################################
# Unified Installer – refactored (2025-04-23)
###############################################################################

declare -A SCRIPTS=(
  [1]="setup_system_build_env_s100-2.sh"
  [2]="setup_sensor2.sh"
  [3]="install_udev_rules.sh"
  [4]="setup_env_path.sh"
  [5]="setup_programs_slamanv_shortcut.sh"
  [6]="set_teamviewer.sh"
  #[7]="setup_light_fixed.sh"           # 필요 시 주석 해제
)

#--------------------------------------------------------------------
# 공통 함수
#--------------------------------------------------------------------
need_root() { [[ $EUID -eq 0 ]] || { echo "sudo로 실행하세요."; exit 1; }; }
log()       { echo "[$(date +'%F %T')] $*"; }

print_menu() {
  echo "설치할 스크립트 번호를 선택하세요:"
  for i in "${!SCRIPTS[@]}"; do
    printf '  %d) %s\n' "$i" "${SCRIPTS[$i]}"
  done
  echo "  a) 모두 설치"
}

read_selection() {
  local sel; read -rp "번호 입력(예: 1,3,5 또는 a): " sel
  [[ $sel == a ]] && sel=$(IFS=,; echo "${!SCRIPTS[*]}" | tr ' ' ',')
  echo "$sel"
}

#--------------------------------------------------------------------
# 1) setup_system_build_env_s100-2.sh  (요약 버전)
#--------------------------------------------------------------------
run_1() {
  need_root; log "[STEP 1] 시스템 빌드 환경 설치"
  # 실제 스크립트 본문을 함수·모듈로 정리해 두고 호출만 하는 편이 좋습니다.
  bash setup_system_build_env_s100-2.sh
}

#--------------------------------------------------------------------
# 2) setup_sensor2.sh
#--------------------------------------------------------------------
run_2() {
  need_root; log "[STEP 2] Sensor 설정"
  bash setup_sensor2.sh
}

#--------------------------------------------------------------------
# 3) install_udev_rules.sh
#--------------------------------------------------------------------
run_3() {
  need_root; log "[STEP 3] udev rules 설치"
  bash install_udev_rules.sh
}

#--------------------------------------------------------------------
# 4) setup_env_path.sh
#--------------------------------------------------------------------
run_4() {
  log "[STEP 4] LD_LIBRARY_PATH 등 환경 변수 설정"
  bash setup_env_path.sh
}

#--------------------------------------------------------------------
# 5) setup_programs_slamanv_shortcut.sh
#--------------------------------------------------------------------
run_5() {
  log "[STEP 5] 단축키 및 SLAMNAV2 리포지토리 작업"
  bash setup_programs_slamanv_shortcut.sh
}

#--------------------------------------------------------------------
# 6) set_teamviewer.sh
#--------------------------------------------------------------------
run_6() {
  need_root; log "[STEP 6] TeamViewer 설치"
  bash set_teamviewer.sh
}

#--------------------------------------------------------------------
# (선택) 7) setup_light_fixed.sh
#--------------------------------------------------------------------
#run_7() {
#  need_root; log "[STEP 7] 경량 설치 스크립트"
#  bash setup_light_fixed.sh
#}

#--------------------------------------------------------------------
# 메인 루프
#--------------------------------------------------------------------
print_menu
IFS=',' read -ra CHOICE <<< "$(read_selection)"

for num in "${CHOICE[@]}"; do
  [[ -z ${SCRIPTS[$num]:-} ]] && { echo "잘못된 번호: $num"; continue; }
  echo "=============================="
  echo "실행: ${SCRIPTS[$num]} (run_$num)"
  echo "=============================="
  "run_$num"
done

