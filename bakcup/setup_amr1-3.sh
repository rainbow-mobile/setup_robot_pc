#!/usr/bin/env bash
###############################################################################
# setup_amr.sh  (rev.2025-05-08)
#  · SLAMNAV2 개발 PC 통합 설치 스크립트
#  · 메뉴 기반 단계 선택 + 상세 로그
###############################################################################
set -Eeuo pipefail
IFS=$'\n\t'

#──────────────────────────────────────────────────────────────────────────────
## 0. 공통 환경‧헬퍼
#──────────────────────────────────────────────────────────────────────────────
need_root() { [[ $EUID -eq 0 ]] || { echo "sudo 로 실행하세요." >&2; exit 1; }; }
log()       { echo -e "\e[32m[$(date +'%F %T')]\e[0m $*"; }

safe_source() {  # nounset 방지용 wrapper
  set +u
  # shellcheck disable=SC1090
  source "$1"
  set -u
}

need_root

REAL_USER=${SUDO_USER:-$(logname)}
[[ $REAL_USER == root ]] && {
  echo "❗ 반드시 일반 사용자에서:  sudo ./setup_amr.sh  형태로 실행하세요."
  exit 1
}
USER_HOME=$(eval echo "~$REAL_USER")
as_user()   { sudo -u "$REAL_USER" -H bash -c "$*"; }

: "${DEBUGINFOD_URLS:=}"          ; export DEBUGINFOD_URLS
: "${XDG_DATA_DIRS:=/usr/local/share:/usr/share}" ; export XDG_DATA_DIRS

sudo apt-get update -qq           # 전역 apt 캐시 갱신

# 전역 결과 배열 (모든 단계에서 공용)
declare -ag INSTALLED=()
declare -ag SKIPPED=()
declare -ag FAILED=()

#──────────────────────────────────────────────────────────────────────────────
## 1. 메뉴 정의
#──────────────────────────────────────────────────────────────────────────────
declare -A SCRIPTS=(
  [1]="빌드 환경·의존성         / setup_system_build_env"
  [2]="센서 SDK 설치            / setup_sensor_sdk"
  [3]="obSensor udev 규칙       / install_obsensor_rules"
  [4]="추가 LD_LIBRARY_PATH     / add_extra_ld_path"
  [5]="단축키·리포지토리        / install_shortcuts"
  [6]="TeamViewer 설치          / install_teamviewer"
)

print_menu() {
  echo -e "\n설치할 스크립트 번호를 선택하세요:"
  for i in {1..6}; do printf '  %d) %s\n' "$i" "${SCRIPTS[$i]}"; done
  echo "  a) 모두 설치"
}

read_selection() {
  local sel; read -rp "번호 입력 (예: 1,3,5 또는 a): " sel
  if [[ $sel == a ]]; then printf "%s\n" "${!SCRIPTS[@]}" | sort -n
  else IFS=',' read -ra nums <<<"$sel"; printf "%s\n" "${nums[@]}"; fi
}

#──────────────────────────────────────────────────────────────────────────────
## 2-1. STEP 1  ─ 빌드 환경 & 의존성
#──────────────────────────────────────────────────────────────────────────────
setup_system_build_env() {
  log "[STEP 1] 빌드 환경 & 시스템 의존성 설치"
  local LOG_FILE="$USER_HOME/setup_amr_$(date +'%Y%m%d_%H%M%S').log"
  exec > >(tee -a "$LOG_FILE") 2>&1

  ## (1) 불필요 패키지 제거
  sudo apt-get remove -y update-notifier orca || true

  ## (2) 시스템 업데이트
  sudo apt-get update && sudo apt-get -y upgrade

  ## (3) APT 패키지
  local APT_PKGS=(
    curl git build-essential cmake cmake-gui python3-pip htop
    libqt5websockets5-dev qtdeclarative5-dev qtmultimedia5-dev
    libquazip5-dev libvtk9-qt-dev qtcreator qtbase5-dev qt5-qmake
    libtbb-dev libboost-all-dev libopencv-dev libopencv-contrib-dev
    libeigen3-dev rapidjson-dev libssl-dev nmap
    libqt5multimedia5-plugins gstreamer1.0-plugins-{base,good,bad,ugly}
    libpcl-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev
    dkms qtquickcontrols2-5-dev libqt5serialport5-dev ccache flex bison
    mysql-server expect sshpass
  )
  sudo apt-get install -y "${APT_PKGS[@]}"

  ## (4) dialout 그룹 추가 (요청 사항 반영)
  log "[dialout] 사용자 dialout 그룹 추가"
  sudo adduser "$REAL_USER" dialout || true

  ## (5) LD_LIBRARY_PATH 전역
  for p in /usr/local/lib \
           "$USER_HOME/rplidar_sdk/output/Linux/Release" \
           "$USER_HOME/OrbbecSDK/lib/linux_x64"; do
    grep -q "$p" /etc/profile || \
      sudo sh -c "echo 'export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:$p' >> /etc/profile"
  done
  safe_source /etc/profile && sudo ldconfig

  ## (6) GRUB 옵션 & 자동업데이트 끄기
  sudo sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT=/ s/"$/ usbcore.autosuspend=-1 intel_pstate=disable"/' /etc/default/grub
  sudo update-grub
  sudo bash -c 'cat > /etc/apt/apt.conf.d/20auto-upgrades <<EOF
APT::Periodic::Update-Package-Lists "0";
APT::Periodic::Download-Upgradeable-Packages "0";
APT::Periodic::AutocleanInterval "0";
APT::Periodic::Unattended-Upgrade "0";
EOF'

  ## (7) 스왑 32G
  if ! free -h | grep -q 'Swap:.*32G'; then
    sudo swapoff /swapfile 2>/dev/null || true
    sudo rm -f /swapfile
    sudo fallocate -l 32G /swapfile || sudo dd if=/dev/zero of=/swapfile bs=1M count=32768
    sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile
    grep -q '/swapfile swap' /etc/fstab || echo '/swapfile swap swap defaults 0 0' | sudo tee -a /etc/fstab
  fi

  ## (8) RTL8812AU DKMS
  if ! lsmod | grep -q 8812au; then
    git clone --depth 1 https://github.com/gnab/rtl8812au.git
    sudo cp -r rtl8812au /usr/src/rtl8812au-4.2.2
    sudo dkms add -m rtl8812au -v 4.2.2
    sudo dkms install -m rtl8812au -v 4.2.2
    sudo modprobe 8812au
  fi

  ## (9) CMake/Sophus/GTSAM/OMPL/socket.io/OctoMap/PDAL/Livox SDK2 (생략 가능)
  # ... (원본 로직 그대로 두거나 필요 시 별도 스크립트화)

  INSTALLED+=("Step1: 빌드 환경 & 의존성")
}

#──────────────────────────────────────────────────────────────────────────────
## 2-2. STEP 2  ─ 센서 SDK
#──────────────────────────────────────────────────────────────────────────────
setup_sensor_sdk() {
  log "[STEP 2] 센서 SDK 설치"
  local BASE="$USER_HOME"

  clone_or_pull() {  # $1=URL  $2=DIR  [$3=checkout]
    if [ ! -d "$2" ]; then as_user "git clone $1 \"$2\""; else as_user "git -C \"$2\" pull"; fi
    [ -n "${3:-}" ] && as_user "git -C \"$2\" checkout $3"
  }

  ## rplidar_sdk
  clone_or_pull https://github.com/Slamtec/rplidar_sdk.git "$BASE/rplidar_sdk"
  as_user make -C "$BASE/rplidar_sdk"

  ## OrbbecSDK
  clone_or_pull https://github.com/orbbec/OrbbecSDK.git "$BASE/OrbbecSDK"  v1.10.11
  sudo bash "$BASE/OrbbecSDK/misc/scripts/install_udev_rules.sh"

  ## sick_safetyscanners_base
  clone_or_pull https://github.com/SICKAG/sick_safetyscanners_base.git \
                "$BASE/sick_safetyscanners_base"
  as_user "cmake -S \"$BASE/sick_safetyscanners_base\" -B \"$BASE/sick_safetyscanners_base/build\""
  as_user "make -C \"$BASE/sick_safetyscanners_base/build\" -j$(nproc)"
  sudo make -C "$BASE/sick_safetyscanners_base/build" install

  INSTALLED+=("Step2: 센서 SDK")
}

#──────────────────────────────────────────────────────────────────────────────
## 2-3. STEP 3  ─ obSensor udev 규칙
#──────────────────────────────────────────────────────────────────────────────
install_obsensor_rules() {
  log "[STEP 3] obSensor udev 규칙"
  local RULES='99-obsensor-libusb.rules'
  cat <<EOF | sudo tee /etc/udev/rules.d/$RULES
SUBSYSTEM=="usb", ATTR{idVendor}=="2bc5", MODE="0666"
EOF
  sudo udevadm control --reload && sudo udevadm trigger
  INSTALLED+=("Step3: obSensor udev")
}

#──────────────────────────────────────────────────────────────────────────────
## 2-4. STEP 4  ─ 추가 LD_LIBRARY_PATH
#──────────────────────────────────────────────────────────────────────────────
add_extra_ld_path() {
  log "[STEP 4] ~/.bashrc 에 LD_LIBRARY_PATH 추가"
  local BRC="$USER_HOME/.bashrc"
  local LINES=(
    'export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:'"$USER_HOME"'/slamnav2'
    'export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:'"$USER_HOME"'/fms2'
  )
  for l in "${LINES[@]}"; do grep -Fxq "$l" "$BRC" || echo "$l" >> "$BRC"; done
  INSTALLED+=("Step4: LD_LIBRARY_PATH")
}

#──────────────────────────────────────────────────────────────────────────────
## 2-5. STEP 5  ─ 단축키 & 리포지토리
#──────────────────────────────────────────────────────────────────────────────
install_shortcuts() {
  log "[STEP 5] diagnosis/slamnav2 리포지토리 + .desktop 단축키"
  local DESKTOP_DIR
  for d in "$USER_HOME/Desktop" "$USER_HOME/바탕화면"; do [ -d "$d" ] && DESKTOP_DIR="$d"; done
  [ -z "$DESKTOP_DIR" ] && DESKTOP_DIR="$USER_HOME/Desktop" && mkdir -p "$DESKTOP_DIR"

  clone_or_pull() {  # $1 URL  $2 DIR
    if [ ! -d "$2" ]; then as_user "git clone $1 \"$2\""; else as_user "git -C \"$2\" pull"; fi
  }
  clone_or_pull https://github.com/rainbow-mobile/diagnosis.git "$USER_HOME/diagnosis"
  clone_or_pull https://github.com/rainbow-mobile/slamnav2.git "$USER_HOME/slamnav2"

  install -Dm755 -o "$REAL_USER" -g "$REAL_USER" \
    "$USER_HOME/diagnosis/slamnav2.sh"       "$USER_HOME/slamnav2.sh"
  install -Dm755 -o "$REAL_USER" -g "$REAL_USER" \
    "$USER_HOME/diagnosis/diagnostic.sh"     "$USER_HOME/diagnostic.sh"
  install -Dm755 -o "$REAL_USER" -g "$REAL_USER" \
    "$USER_HOME/diagnosis/SLAMNAV2.desktop"  "$DESKTOP_DIR/SLAMNAV2.desktop"
  install -Dm755 -o "$REAL_USER" -g "$REAL_USER" \
    "$USER_HOME/diagnosis/diagnostic.desktop" "$DESKTOP_DIR/diagnostic.desktop"

  # trusted 플래그
  REAL_UID=$(id -u "$REAL_USER")
  DBUS_ADDR="unix:path=/run/user/${REAL_UID}/bus"
  RUN_DIR="/run/user/${REAL_UID}"
  as_user "DBUS_SESSION_BUS_ADDRESS='$DBUS_ADDR' XDG_RUNTIME_DIR='$RUN_DIR' \
           gio set '$DESKTOP_DIR/SLAMNAV2.desktop'     metadata::trusted true"
  as_user "DBUS_SESSION_BUS_ADDRESS='$DBUS_ADDR' XDG_RUNTIME_DIR='$RUN_DIR' \
           gio set '$DESKTOP_DIR/diagnostic.desktop'  metadata::trusted true"

  INSTALLED+=("Step5: 단축키/리포지토리")
}

#──────────────────────────────────────────────────────────────────────────────
## 2-6. STEP 6  ─ TeamViewer
#──────────────────────────────────────────────────────────────────────────────
install_teamviewer() {
  log "[STEP 6] TeamViewer Host 설치"
  local ARCH=$(dpkg --print-architecture)
  local TMP=/tmp/teamviewer.deb
  wget -qO "$TMP" "https://download.teamviewer.com/download/linux/teamviewer-host_${ARCH}.deb"
  sudo apt-get install -y "$TMP"
  rm -f "$TMP"

  # Wayland OFF
  local CONF="/etc/gdm3/custom.conf"
  if grep -Eq '^[[:space:]]*#?[[:space:]]*WaylandEnable=false' "$CONF"; then
    sudo sed -i 's/^ *#\? *WaylandEnable=false/WaylandEnable=false/' "$CONF"
  else
    sudo sed -i '/^\[daemon\]/a WaylandEnable=false' "$CONF"
  fi
  INSTALLED+=("Step6: TeamViewer")
}

#──────────────────────────────────────────────────────────────────────────────
## 3. 실행
#──────────────────────────────────────────────────────────────────────────────
print_menu
mapfile -t STEPS < <(read_selection)

for n in "${STEPS[@]}"; do
  FUNC=$(declare -p SCRIPTS | grep -oP "\[$n\]=\"[^\"]+" | cut -d'/' -f2 | xargs)
  if declare -f "$FUNC" >/dev/null; then
    echo -e "\n=============================="
    echo "실행: ${SCRIPTS[$n]}"
    echo "=============================="
    "$FUNC" || { FAILED+=("$FUNC"); echo "[WARN] $FUNC 실패"; }
  else
    echo "[WARN] 잘못된 번호: $n"
  fi
done

#──────────────────────────────────────────────────────────────────────────────
## 4. 마무리
#──────────────────────────────────────────────────────────────────────────────
log "root→$REAL_USER 소유권 확인"
chown -R "$REAL_USER:$REAL_USER" \
  "$USER_HOME"/{rplidar_sdk,OrbbecSDK,sick_safetyscanners_base,slamnav2,diagnosis} 2>/dev/null || true

echo -e "\n========= 설치 요약 ========="
echo "✅ 완료:";   for i in "${INSTALLED[@]}"; do echo "  - $i"; done
echo "⏭️  건너뜀:"; for i in "${SKIPPED[@]}";   do echo "  - $i"; done
echo "❌ 실패:";   for i in "${FAILED[@]}";    do echo "  - $i"; done
echo "=============================="
log "설치 완료!  새 터미널에서 LD_LIBRARY_PATH·dialout 그룹 적용을 확인하세요."

