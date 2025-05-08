#!/usr/bin/env bash
###############################################################################
# unified_installer_fixed.sh  (rev.2025-04-25)
#  · 진단/SLAMNAV2 단축키 설치 + sensor SDK + 시스템 패키지
#  · 오류 발생 시 다음 단계 계속 진행, 마지막에 요약 출력
###############################################################################
set -euo pipefail
IFS=$'\n\t'

: "${DEBUGINFOD_URLS:=}"; export DEBUGINFOD_URLS
: "${XDG_DATA_DIRS:=/usr/local/share:/usr/share}"; export XDG_DATA_DIRS

# ─────────────────────────────────────────────────────
## 0. 공통 함수 · 전역 변수
# ─────────────────────────────────────────────────────
need_root() { [[ $EUID -eq 0 ]] || { echo "sudo 로 실행하세요."; exit 1; }; }
log()       { echo -e "\e[32m[$(date +'%F %T')]\e[0m $*"; }

REAL_USER="${SUDO_USER:-$(id -un)}"
HOME_DIR="/home/$REAL_USER"
as_user()   { sudo -H -u "$REAL_USER" "$@"; }

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_HOME="$HOME_DIR"
DESKTOP_DIR="$(xdg-user-dir DESKTOP 2>/dev/null || true)"
[ -z "$DESKTOP_DIR" ] && DESKTOP_DIR="$USER_HOME/Desktop"
[ -d "$DESKTOP_DIR" ] || mkdir -p "$DESKTOP_DIR"

# 진행 현황 배열
INSTALLED=(); SKIPPED=(); FAILED=()

run_step() {
    local name="$1" check_cmd="$2" run_cmd="$3"
    echo ">> [$name] 진행..."
    if eval "$check_cmd"; then
        echo "   [$name] 이미 완료 → 건너뜀"
        SKIPPED+=("$name")
    elif eval "$run_cmd"; then
        echo "   [$name] 완료"
        INSTALLED+=("$name")
    else
        echo "   [$name] 실패!"
        FAILED+=("$name")
    fi
    echo "----------------------------------------"
}

# ─────────────────────────────────────────────────────
## 1. 메뉴
# ─────────────────────────────────────────────────────
declare -A SCRIPTS=(
  [1]="시스템 Env+의존성   / setup_system_build_env_s100-2.sh"
  [2]="센서 SDK 설치       / setup_sensor2.sh"
  [3]="udev rules          / install_udev_rules.sh"
  [4]="환경변수(bashrc)    / setup_env_path.sh"
  [5]="바탕화면 단축키     / setup_programs_slamnav_shortcut.sh"
  [6]="TeamViewer          / set_teamviewer.sh"
)
print_menu() {
  echo "설치할 스크립트 번호:"
  for i in "${!SCRIPTS[@]}"; do printf '  %d) %s\n' "$i" "${SCRIPTS[$i]}"; done
  echo "  a) 모두 설치"
}
read_selection() {
  local sel; read -rp "번호 선택: " sel
  if [[ $sel == a ]]; then printf '%s\n' "${!SCRIPTS[@]}" | sort -n
  else IFS=',' read -ra _nums <<<"$sel"; printf '%s\n' "${_nums[@]}"; fi
}

# ─────────────────────────────────────────────────────
## 2-1. STEP-1  시스템 의존성
# ─────────────────────────────────────────────────────
run_1() {
  need_root; log "[STEP-1] APT 의존성 & 캐시 정리"
  export DEBIAN_FRONTEND=noninteractive

  # 1) 기존 리스트 제거 & 미러 통일
  log " → APT 리스트 캐시 삭제"
  rm -rf /var/lib/apt/lists/*
  log " → kr.archive.ubuntu.com → archive.ubuntu.com 변경"
  sed -i 's|http://kr.archive.ubuntu.com|http://archive.ubuntu.com|g' /etc/apt/sources.list || true

  # 2) 초기 업데이트 & 깨진 패키지 복구
  log " → apt-get update"
  apt-get update -qq
  log " → 깨진 의존성 자동 복구 (apt -f install)"
  apt-get -qq -f install -y

  # 3) 배포판 업그레이드 (의존성 충돌 해결)
  log " → apt-get dist-upgrade"
  apt-get -qq dist-upgrade -y

  # 4) 실제 APT 패키지 설치
  log " → 필수 패키지 설치"
  APT_PKGS=(curl git build-essential cmake cmake-gui ccache htop
            libqt5websockets5-dev qtdeclarative5-dev qtmultimedia5-dev
            libvtk9-qt-dev libquazip5-dev libtbb-dev
            libboost-all-dev libssl-dev rapidjson-dev
            libopencv-dev libopencv-contrib-dev libeigen3-dev
            libpcl-dev pdal libpdal-dev
            libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev
            gstreamer1.0-plugins-{base,good,bad,ugly}
            qml-module-qtquick-{controls2,shapes} qml-module-qtmultimedia
            qml-module-qt-labs-platform qtquickcontrols2-5-dev
            dkms sshpass nmap-common flex bison expect)
  apt-get install -y "${APT_PKGS[@]}"

  # 5) LD_LIBRARY_PATH 시스템 등록 (원본대로)
  cat <<EOF >/etc/profile.d/robot_env.sh
export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:/usr/local/lib:$HOME_DIR/rplidar_sdk/output/Linux/Release:$HOME_DIR/OrbbecSDK/lib/linux_x64
EOF
  chmod 644 /etc/profile.d/robot_env.sh
  
# GRUB, 자동 업데이트, 스왑
  grep -q usbcore.autosuspend /etc/default/grub ||
    sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT=/ s/"$/ usbcore.autosuspend=-1 intel_pstate=disable"/' /etc/default/grub
  update-grub

  cat >/etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "0";
APT::Periodic::Download-Upgradeable-Packages "0";
APT::Periodic::AutocleanInterval "0";
APT::Periodic::Unattended-Upgrade "0";
EOF

  swapoff -a || true
  fallocate -l 32G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=32768
  chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile
  grep -q '/swapfile' /etc/fstab || echo '/swapfile swap swap defaults 0 0' >> /etc/fstab
  log "[STEP-1] 완료"
}


# ─────────────────────────────────────────────────────
## 2-2. STEP-2  센서 SDK
# ─────────────────────────────────────────────────────
run_2() {
  log "[STEP-2] 센서 SDK"
  # rplidar
  run_step "rplidar_sdk" "[ -d \"$HOME_DIR/rplidar_sdk\" ]" \
           "as_user git clone https://github.com/Slamtec/rplidar_sdk.git \"$HOME_DIR/rplidar_sdk\" && as_user make -C \"$HOME_DIR/rplidar_sdk\""
  # Orbbec
  run_step "OrbbecSDK" "[ -d \"$HOME_DIR/OrbbecSDK\" ]" \
           "as_user git clone https://github.com/orbbec/OrbbecSDK.git \"$HOME_DIR/OrbbecSDK\" && (cd \"$HOME_DIR/OrbbecSDK\" && as_user git checkout v1.10.11 && sudo bash misc/scripts/install_udev_rules.sh)"
  # Sick
  run_step "sick_safetyscanners_base" "[ -d \"$HOME_DIR/sick_safetyscanners_base\" ]" \
           "as_user git clone https://github.com/SICKAG/sick_safetyscanners_base.git \"$HOME_DIR/sick_safetyscanners_base\" && as_user bash -c 'cd \"$HOME_DIR/sick_safetyscanners_base\" && mkdir -p build && cd build && cmake .. && make -j\$(nproc)' && sudo make -C \"$HOME_DIR/sick_safetyscanners_base/build\" install"
}

# ─────────────────────────────────────────────────────
## 2-3. STEP-3  udev rules
# ─────────────────────────────────────────────────────
run_3() {
  need_root
  run_step "udev rules" "[ -f /etc/udev/rules.d/99-obsensor-libusb.rules ]" \
           "cp \"$SRC_DIR/99-obsensor-libusb.rules\" /etc/udev/rules.d/ && udevadm control --reload && udevadm trigger"
}

# ─────────────────────────────────────────────────────
## 2-4. STEP-4  ~/.bashrc
# ─────────────────────────────────────────────────────
run_4() {
  run_step "bashrc LD_LIBRARY_PATH" "grep -q robot_env.sh \"$HOME_DIR/.bashrc\" || false" \
           "as_user bash -c 'echo source /etc/profile.d/robot_env.sh >> \"$HOME_DIR/.bashrc\"'"
}

# ─────────────────────────────────────────────────────
## 2-5. STEP-5  바탕화면 단축키
# ─────────────────────────────────────────────────────
run_5() {
  log "[STEP-5] 진단 단축키 및 slamnav2 설정"

  # diagnosis / slamnav2 리포지토리 ──────────────────
  if [ ! -d "$HOME_DIR/diagnosis" ]; then
    run_step "diagnosis clone" "false" \
      "git clone https://github.com/rainbow-mobile/diagnosis.git \"$HOME_DIR/diagnosis\""
  else
    run_step "diagnosis pull" "false" \
      "git -C \"$HOME_DIR/diagnosis\" pull"
  fi

  if [ ! -d "$HOME_DIR/slamnav2" ]; then
    run_step "slamnav2 clone" "false" \
      "git clone https://github.com/rainbow-mobile/slamnav2.git \"$HOME_DIR/slamnav2\""
  else
    run_step "slamnav2 pull" "false" \
      "git -C \"$HOME_DIR/slamnav2\" pull"
  fi

  # slamnav2 브랜치 선택 ─────────────────────────────
  if [ -d "$HOME_DIR/slamnav2" ]; then
    cd "$HOME_DIR/slamnav2"
    mapfile -t remotebr < <(git branch -r | sed 's| *origin/||' | grep -v HEAD)
    echo "[slamnav2] 원격 브랜치:"
    for i in "${!remotebr[@]}"; do printf ' %2d) %s\n' $((i+1)) "${remotebr[i]}"; done
    read -rp "체크아웃할 번호(엔터=건너뜀): " sel
    if [[ "$sel" =~ ^[0-9]+$ && sel -ge 1 && sel -le ${#remotebr[@]} ]]; then
      run_step "브랜치 checkout" "false" \
        "git checkout \"${remotebr[sel-1]}\""
    else
      SKIPPED+=("브랜치 선택")
    fi
    cd - >/dev/null
  fi

  # 소스·바탕화면 경로 ────────────────────────────────
  sourceDir="$HOME_DIR/diagnosis"
  DESKTOP_DIR="$(xdg-user-dir DESKTOP 2>/dev/null || true)"
  [ -z "$DESKTOP_DIR" ] && for d in "$HOME_DIR/Desktop" "$HOME_DIR/바탕화면"; do
      [ -d "$d" ] && DESKTOP_DIR="$d" && break; done
  mkdir -p "$DESKTOP_DIR"

  # shell 스크립트 복사 ───────────────────────────────
  if [ -f "$sourceDir/slamnav2.sh" ] && [ -f "$sourceDir/diagnostic.sh" ]; then
    run_step "shell scripts copy" "false" '
      install -m755 "'"$sourceDir/slamnav2.sh"'" "'"$HOME_DIR/slamnav2.sh"'" &&
      install -m755 "'"$sourceDir/diagnostic.sh"'" "'"$HOME_DIR/diagnostic.sh"'"'
  else
    FAILED+=("shell scripts 원본 없음")
  fi

  # desktop 파일 복사 ────────────────────────────────
  if [ -f "$sourceDir/SLAMNAV2.desktop" ] && [ -f "$sourceDir/diagnostic.desktop" ]; then
    run_step "desktop files copy" "false" '
      install -m644 "'"$sourceDir/SLAMNAV2.desktop"'" "'"$DESKTOP_DIR/SLAMNAV2.desktop"'" &&
      install -m644 "'"$sourceDir/diagnostic.desktop"'" "'"$DESKTOP_DIR/diagnostic.desktop"'"'
  else
    FAILED+=("desktop 파일 원본 없음")
  fi

  # trust(자물쇠) 해제 ───────────────────────────────
  for f in "$DESKTOP_DIR"/SLAMNAV2.desktop "$DESKTOP_DIR"/diagnostic.desktop; do
    [ -f "$f" ] && gio set "$f" metadata::trusted true 2>/dev/null
  done
}

# ─────────────────────────────────────────────────────
## 2-6. STEP-6  TeamViewer
# ─────────────────────────────────────────────────────
run_6() {
  need_root; log "[STEP-6] TeamViewer"
  ARCH=$(dpkg --print-architecture); TMP=/tmp/teamviewer.deb
  run_step "TeamViewer 설치" "dpkg -l | grep -q teamviewer-host" \
           "wget -qO \"$TMP\" \"https://download.teamviewer.com/download/linux/teamviewer-host_${ARCH}.deb\" && apt-get install -y \"$TMP\" && rm -f \"$TMP\" && sed -Ei '/^\[daemon]/,/^\[/{s/^#?WaylandEnable=.*/WaylandEnable=false/}' /etc/gdm3/custom.conf"
}

# ─────────────────────────────────────────────────────
## 3. 실행 루프
# ─────────────────────────────────────────────────────
print_menu; mapfile -t STEPS < <(read_selection)

for n in "${STEPS[@]}"; do
  FN="run_$n"
  echo -e "\n=============================="
  echo   "실행: ${SCRIPTS[$n]}"
  echo   "=============================="
  if declare -f "$FN" >/dev/null; then "$FN"; else echo "[WARN] 잘못된 번호: $n"; fi
done

# ─────────────────────────────────────────────────────
## 4. 설치 이후 소유권 · 최종 요약
# ─────────────────────────────────────────────────────
log "소유권(root→$REAL_USER) 확인 중…"
chown -R "$REAL_USER:$REAL_USER" "$HOME_DIR"/{rplidar_sdk,OrbbecSDK,sick_safetyscanners_base,slamnav2,diagnosis} 2>/dev/null || true

echo -e "\n========= 설치 요약 ========="
echo "✅ 완료:"
for i in "${INSTALLED[@]}";  do echo "  - $i"; done
echo "⏭️  건너뜀:"
for i in "${SKIPPED[@]}";    do echo "  - $i"; done
echo "❌ 실패:"
for i in "${FAILED[@]}";     do echo "  - $i"; done
echo "=============================="
log "설치 완료!  새 터미널에서 LD_LIBRARY_PATH 적용을 확인하세요."

