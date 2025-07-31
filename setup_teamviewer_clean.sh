#!/usr/bin/env bash

# setup_teamviewer.sh
# 이 스크립트는 기존 팀뷰어를 제거하고 최신 버전을 다시 설치합니다.

set -Eeuo pipefail
IFS=$'\n\t'

#--- 보조 함수 ---#
log() {
    # 로그 메시지를 시간과 함께 출력하는 함수
    echo -e "\e[32m[$(date +'%F %T')]\e[0m $*"
}

need_root() {
    # 스크립트가 root 권한으로 실행되었는지 확인하는 함수
    if [[ $EUID -ne 0 ]]; then
        echo "오류: 이 스크립트는 반드시 sudo 명령어로 실행해야 합니다." >&2
        exit 1
    fi
}

#--- 메인 로직 ---#
need_root

# 1. 기존 팀뷰어 제거
log "[1단계] 기존 팀뷰어 설치 확인 및 제거..."
if dpkg -l | grep -q "teamviewer"; then
    log "기존 팀뷰어가 발견되었습니다. 데몬을 중지하고 패키지를 삭제합니다..."
    systemctl stop teamviewerd.service 2>/dev/null || true
    apt-get purge -y "*teamviewer*"
    apt-get autoremove -y
    log "이전 버전의 팀뷰어가 성공적으로 제거되었습니다."
else
    log "설치된 팀뷰어가 없습니다."
fi

# 2. 팀뷰어 설치
log "[2단계] 최신 버전의 팀뷰어 설치..."
ARCH=$(dpkg --print-architecture) # 시스템 아키텍처 탐지 (예: amd64, arm64)
URL="https://download.teamviewer.com/download/linux/teamviewer-host_${ARCH}.deb"
TMP_DEB="/tmp/teamviewer_latest.deb"

log "${ARCH} 아키텍처용 팀뷰어를 다운로드합니다..."
if wget -qO "$TMP_DEB" "$URL"; then
    log "다운로드 완료. 패키지를 설치합니다..."
    apt-get install -y "$TMP_DEB"
    rm -f "$TMP_DEB"
    log "팀뷰어 설치가 완료되었습니다."
else
    log "오류: 팀뷰어 다운로드에 실패했습니다. 인터넷 연결을 확인해주세요."
    exit 1
fi

# 3. Wayland 비활성화를 위한 GDM3 설정
log "[3단계] GDM3 설정을 변경하여 Wayland를 비활성화합니다..."
CONF_FILE="/etc/gdm3/custom.conf"

if grep -Eq '^[[:space:]]*#?[[:space:]]*WaylandEnable=false' "$CONF_FILE"; then
    # 해당 라인이 주석 처리되었거나 이미 있다면, 주석을 제거하여 활성화합니다.
    sed -i 's/^[[:space:]]*#\?[[:space:]]*WaylandEnable=false/WaylandEnable=false/' "$CONF_FILE"
else
    # 해당 라인이 없다면 [daemon] 섹션 아래에 추가합니다.
    sed -i '/^\[daemon\]/a WaylandEnable=false' "$CONF_FILE"
fi
log "GDM3 설정 파일($CONF_FILE)이 업데이트되었습니다."

# 4. 팀뷰어 데몬 활성화 및 재시작
log "[4단계] 팀뷰어 데몬을 활성화하고 재시작합니다..."
systemctl enable --now teamviewerd.service
systemctl restart teamviewerd.service

log "팀뷰어 설치 및 설정이 모두 완료되었습니다! ✅"
