#!/usr/bin/env bash
###############################################################################
# unified_installer_fixed.sh (2025-04-23)
#  - 홈 디렉터리 소스는 “일반 사용자” 권한으로 클론/빌드
#  - root 권한이 필요한 APT, make install, /etc 수정만 sudo 사용
#  - LD_LIBRARY_PATH 는 /etc/profile.d + ~/.bashrc 모두에 반영
#  - 설치가 끝난 뒤 소유권(chown) 재점검
###############################################################################
set -euo pipefail
IFS=$'\n\t'

: "${DEBUGINFOD_URLS:=}"
export DEBUGINFOD_URLS
: "${XDG_DATA_DIRS:=/usr/local/share:/usr/share}"
export XDG_DATA_DIRS

#──────────────────────────────────────────────────────────────────────────────
## 0. 공통 함수
#──────────────────────────────────────────────────────────────────────────────
need_root() { [[ $EUID -eq 0 ]] || { echo "sudo 로 실행하세요."; exit 1; }; }
log()       { echo -e "\e[32m[$(date +'%F %T')]\e[0m $*"; }

REAL_USER="${SUDO_USER:-$(id -un)}"
HOME_DIR="/home/$REAL_USER"
as_user() { sudo -H -u "$REAL_USER" "$@"; }        # 사용자 권한 전환

#──────────────────────────────────────────────────────────────────────────────
## 1. 스크립트 메뉴
#──────────────────────────────────────────────────────────────────────────────
declare -A SCRIPTS=(
  [1]="시스템 Env+의존성   / setup_system_build_env_s100-2.sh"
  [2]="센서 SDK 설치       / setup_sensor2.sh"
  [3]="udev rules          / install_udev_rules.sh"
  [4]="환경변수(bashrc)    / setup_env_path.sh"
  [5]="바탕화면 단축키     / setup_programs_slamnav_shortcut.sh"
  [6]="TeamViewer          / set_teamviewer.sh"
)

print_menu() {
  echo "설치할 스크립트 번호를 선택하세요:"
  for i in "${!SCRIPTS[@]}"; do printf '  %d) %s\n' "$i" "${SCRIPTS[$i]}"; done
  echo "  a) 모두 설치"
}
read_selection() {
  local sel; read -rp "번호 입력(예: 1,3,5 또는 a): " sel
  if [[ $sel == a ]]; then printf '%s\n' "${!SCRIPTS[@]}" | sort -n
  else IFS=',' read -ra _nums <<<"$sel"; printf '%s\n' "${_nums[@]}"; fi
}

#──────────────────────────────────────────────────────────────────────────────
## 2-1. STEP 1 – 시스템 의존성 (root)
#──────────────────────────────────────────────────────────────────────────────
run_1() {
  need_root; log "[STEP 1] 시스템 의존성 설치"
  export DEBIAN_FRONTEND=noninteractive

  apt-get update -qq
  apt-get upgrade -y
  apt-get remove -y update-notifier orca || true

  APT_PKGS=(
    curl git build-essential cmake cmake-gui ccache htop
    libqt5websockets5-dev qtdeclarative5-dev qtmultimedia5-dev
    libvtk9-qt-dev libquazip5-dev libtbb-dev
    libboost-all-dev libssl-dev rapidjson-dev
    libopencv-dev libopencv-contrib-dev libeigen3-dev
    libpcl-dev pdal libpdal-dev
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev
    gstreamer1.0-plugins-{base,good,bad,ugly}
    qml-module-qtquick-{controls2,shapes} qml-module-qtmultimedia
    qml-module-qt-labs-platform qtquickcontrols2-5-dev
    dkms sshpass nmap-common flex bison expect
  )
  apt-get install -y "${APT_PKGS[@]}"

  # /etc/profile.d 로 LD_LIBRARY_PATH 등록
  cat <<EOF | tee /etc/profile.d/robot_env.sh
export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:/usr/local/lib
export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:$HOME_DIR/rplidar_sdk/output/Linux/Release
export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:$HOME_DIR/OrbbecSDK/lib/linux_x64
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
}

#──────────────────────────────────────────────────────────────────────────────
## 2-2. STEP 2 – 센서 SDK (user)
#──────────────────────────────────────────────────────────────────────────────
run_2() {
  log "[STEP 2] 센서 SDK 설치 (USER=$REAL_USER)"

  # rplidar_sdk
  if [ ! -d "$HOME_DIR/rplidar_sdk" ]; then
    as_user git clone https://github.com/Slamtec/rplidar_sdk.git "$HOME_DIR/rplidar_sdk"
    as_user make -C "$HOME_DIR/rplidar_sdk"
  fi

  # OrbbecSDK
  if [ ! -d "$HOME_DIR/OrbbecSDK" ]; then
    as_user git clone https://github.com/orbbec/OrbbecSDK.git "$HOME_DIR/OrbbecSDK"
    pushd "$HOME_DIR/OrbbecSDK" >/dev/null
    as_user git checkout v1.10.11
    sudo bash misc/scripts/install_udev_rules.sh
    popd >/dev/null
  fi

  # sick_safetyscanners_base
  if [ ! -d "$HOME_DIR/sick_safetyscanners_base" ]; then
    as_user git clone https://github.com/SICKAG/sick_safetyscanners_base.git \
             "$HOME_DIR/sick_safetyscanners_base"
    as_user bash -c "cd '$HOME_DIR/sick_safetyscanners_base' && mkdir -p build && cd build && cmake .. && make -j\$(nproc)"
    make -C "$HOME_DIR/sick_safetyscanners_base/build" install   # root만 install
  fi
}

#──────────────────────────────────────────────────────────────────────────────
## 2-3. STEP 3 – udev rules (root)
#──────────────────────────────────────────────────────────────────────────────
run_3() {
  need_root
  cp "$(dirname "$0")/99-obsensor-libusb.rules" /etc/udev/rules.d/
  udevadm control --reload && udevadm trigger
}

#──────────────────────────────────────────────────────────────────────────────
## 2-4. STEP 4 – ~/.bashrc 에 환경변수 포함
#──────────────────────────────────────────────────────────────────────────────
run_4() {
  log "[STEP 4] ~/.bashrc LD_LIBRARY_PATH 등록"
  as_user bash -c "grep -q robot_env.sh ~/.bashrc || echo 'source /etc/profile.d/robot_env.sh' >> ~/.bashrc"
}

#──────────────────────────────────────────────────────────────────────────────
## 2-5. STEP 5 – 바탕화면 단축키 (user)
#──────────────────────────────────────────────────────────────────────────────
run_5() {
  log "[STEP 5] 바탕화면 단축키 설치"

  # 0. 소유권/안전경로 선제 조치  ────────────────────────────────
  for repo in diagnosis slamnav2; do
      if [ -d "$HOME_DIR/$repo" ]; then
          sudo chown -R "$REAL_USER":"$REAL_USER" "$HOME_DIR/$repo"
          sudo -u "$REAL_USER" git config --global --add safe.directory "$HOME_DIR/$repo" || true
      fi
  done

  # 1. diagnosis 리포지토리
  if [ ! -d "$HOME_DIR/diagnosis" ]; then
      as_user git clone https://github.com/rainbow-mobile/diagnosis.git "$HOME_DIR/diagnosis"
  else
      as_user git -C "$HOME_DIR/diagnosis" pull
  fi

  # 2. slamnav2 리포지토리
  if [ ! -d "$HOME_DIR/slamnav2" ]; then
      as_user git clone https://github.com/rainbow-mobile/slamnav2.git "$HOME_DIR/slamnav2"
  else
      as_user git -C "$HOME_DIR/slamnav2" pull
  fi

  # 브랜치 선택
  cd "$USER_HOME/slamnav2"
  mapfile -t BRS < <(git branch -r | sed 's| *origin/||' | grep -v HEAD)
  log "[slamnav2] 원격 브랜치 목록:"
  for i in "${!BRS[@]}"; do
      idx=$((i+1))
      printf ' %2d) %s\n' "$idx" "${BRS[i]}"
  done
  read -rp "체크아웃할 번호: " n
  if [[ "$n" =~ ^[0-9]+$ ]] && (( n>=1 && n<=${#BRS[@]} )); then
      git checkout "${BRS[n-1]}"
  else
      echo "[WARN] 잘못된 번호, 브랜치 변경을 건너뜁니다."
  fi
  cd -

  #-------------------------------------------------------------------------#
  # 3. 단축키 및 실행 스크립트 복사
  #-------------------------------------------------------------------------#
  install -Dm755 "$SRC_DIR/slamnav2.sh"     "$USER_HOME/slamnav2.sh"
  install -Dm755 "$SRC_DIR/diagnostic.sh"   "$USER_HOME/diagnostic.sh"
  install -Dm644 "$SRC_DIR/SLAMNAV2.desktop"   "$DESKTOP_DIR/SLAMNAV2.desktop"
  install -Dm644 "$SRC_DIR/diagnostic.desktop" "$DESKTOP_DIR/diagnostic.desktop"
  gio set "$DESKTOP_DIR/SLAMNAV2.desktop"   metadata::trusted true 2>/dev/null || true
  gio set "$DESKTOP_DIR/diagnostic.desktop" metadata::trusted true 2>/dev/null || true

  log "단축키 설치 완료"
}


#──────────────────────────────────────────────────────────────────────────────
## 2-6. STEP 6 – TeamViewer (root)
#──────────────────────────────────────────────────────────────────────────────
run_6() {
  need_root; log "[STEP 6] TeamViewer 설치"
  ARCH=$(dpkg --print-architecture)
  TMP=/tmp/teamviewer.deb
  wget -qO "$TMP" "https://download.teamviewer.com/download/linux/teamviewer-host_${ARCH}.deb"
  apt-get install -y "$TMP"; rm -f "$TMP"
  sed -Ei '/^\[daemon]/,/^\[/{s/^#?WaylandEnable=.*/WaylandEnable=false/}' /etc/gdm3/custom.conf
}

#──────────────────────────────────────────────────────────────────────────────
## 3. 실행 루프
#──────────────────────────────────────────────────────────────────────────────
print_menu
mapfile -t STEPS < <(read_selection)

for n in "${STEPS[@]}"; do
  FN="run_$n"
  if declare -f "$FN" >/dev/null; then
    echo -e "\n=============================="
    echo   "실행: ${SCRIPTS[$n]}"
    echo   "=============================="
    "$FN"
  else
    echo "[WARN] 잘못된 번호: $n"
  fi
done

#──────────────────────────────────────────────────────────────────────────────
## 4. 설치 이후 소유권 재점검
#──────────────────────────────────────────────────────────────────────────────
log "소유권(root→$REAL_USER) 확인 중…"
chown -R "$REAL_USER":"$REAL_USER" \
  "$HOME_DIR"/{rplidar_sdk,OrbbecSDK,sick_safetyscanners_base,slamnav2,diagnosis} 2>/dev/null || true

log "설치 완료!  새 터미널을 열어 LD_LIBRARY_PATH 가 적용됐는지 확인하세요."

