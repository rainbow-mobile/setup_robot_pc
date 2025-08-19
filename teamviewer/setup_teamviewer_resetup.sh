#!/usr/bin/env bash
# setup_teamviewer_clean.sh (개선판)
set -Eeuo pipefail
IFS=$'\n\t'

log(){ echo -e "\e[32m[$(date +'%F %T')]\e[0m $*"; }
need_root(){ if [[ $EUID -ne 0 ]]; then echo "sudo로 실행하세요." >&2; exit 1; fi; }

is_installed(){
  # dpkg-query로 확정 판정 (둘 중 하나라도 설치되어 있으면 true)
  dpkg-query -W -f='${Status}\n' teamviewer-host 2>/dev/null | grep -q 'install ok installed' || \
  dpkg-query -W -f='${Status}\n' teamviewer 2>/dev/null | grep -q 'install ok installed'
}

stop_disable_service(){
  systemctl stop teamviewerd.service 2>/dev/null || true
  systemctl disable teamviewerd.service 2>/dev/null || true
}

install_deb(){
  local deb="$1"
  # 로컬 .deb 설치는 dpkg + 의존성 해결이 가장 확실
  dpkg -i "$deb" || apt-get -f install -y
}

need_root

log "[1단계] 기존 팀뷰어 설치 확인 및 제거..."
if is_installed; then
  log "기존 팀뷰어가 감지되었습니다. 데몬 중지 및 패키지 제거를 진행합니다..."
  stop_disable_service
  apt-get purge -y "teamviewer*" || true
  apt-get autoremove -y || true
  log "기존 팀뷰어 제거 완료."
else
  log "설치된 팀뷰어가 없습니다."
fi

log "[2단계] 최신 버전의 팀뷰어 설치..."
ARCH=$(dpkg --print-architecture)   # amd64 / arm64 등
TMP_DEB="/tmp/teamviewer_latest.deb"
# 공식 호스트 패키지 URL (ARCH에 따라 파일명 달라짐)
URL="https://download.teamviewer.com/download/linux/teamviewer-host_${ARCH}.deb"

log "${ARCH} 아키텍처용 패키지 다운로드..."
if wget -qO "$TMP_DEB" "$URL"; then
  log "다운로드 완료. 패키지 설치 진행..."
  install_deb "$TMP_DEB"
  rm -f "$TMP_DEB"
else
  log "오류: 다운로드 실패. 네트워크/방화벽을 확인하세요."
  exit 1
fi

log "팀뷰어 설치가 완료되었습니다."

log "[3단계] (옵션) Wayland 비활성화: GDM3 환경에서만 적용"
CONF_FILE="/etc/gdm3/custom.conf"
if systemctl is-enabled gdm3 >/dev/null 2>&1 || systemctl is-active gdm3 >/dev/null 2>&1; then
  if [[ -f "$CONF_FILE" ]]; then
    if grep -Eq '^[[:space:]]*#?[[:space:]]*WaylandEnable=false' "$CONF_FILE"; then
      sed -i 's/^[[:space:]]*#\?[[:space:]]*WaylandEnable=false/WaylandEnable=false/' "$CONF_FILE"
    else
      # [daemon] 섹션 아래에 추가 (없으면 섹션 생성)
      grep -q '^\[daemon\]' "$CONF_FILE" || echo "[daemon]" >> "$CONF_FILE"
      awk '1; /^\[daemon\]$/ && !x {print "WaylandEnable=false"; x=1}' "$CONF_FILE" > "${CONF_FILE}.new" && mv "${CONF_FILE}.new" "$CONF_FILE"
    fi
    log "GDM3 Wayland 비활성화 적용 완료 ($CONF_FILE)."
  else
    log "GDM3 설정 파일이 없어 Wayland 설정은 건너뜁니다."
  fi
else
  log "현재 디스플레이 매니저가 GDM3가 아니므로 Wayland 설정은 건너뜁니다."
fi

log "[4단계] 팀뷰어 데몬 활성화 및 재시작..."
systemctl enable --now teamviewerd.service 2>/dev/null || true
systemctl restart teamviewerd.service 2>/dev/null || true

# 설치/서비스 상태 요약 출력
echo "---- 상태 요약 ----"
dpkg-query -W -f='${Package} ${Version} ${Status}\n' 'teamviewer*' 2>/dev/null || true
systemctl is-enabled teamviewerd.service 2>/dev/null || true
systemctl is-active teamviewerd.service 2>/dev/null || true

log "팀뷰어 설치 및 설정이 모두 완료되었습니다! ✅"

