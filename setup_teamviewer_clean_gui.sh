#!/usr/bin/env bash

# setup_teamviewer_full.sh
# 기존 TeamViewer 제거 후, Full GUI 버전 설치 스크립트

set -Eeuo pipefail
IFS=$'\n\t'

log() {
    echo -e "\e[34m[$(date +'%F %T')]\e[0m $*"
}

need_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "⚠️  반드시 root 권한(sudo)으로 실행해야 합니다." >&2
        exit 1
    fi
}

need_root

log "[1단계] 기존 TeamViewer 제거..."
if dpkg -l | grep -q teamviewer; then
    systemctl stop teamviewerd.service 2>/dev/null || true
    apt-get purge -y "*teamviewer*"
    apt-get autoremove -y
    rm -rf ~/.config/teamviewer
    log "TeamViewer가 제거되었습니다."
else
    log "설치된 TeamViewer가 없습니다."
fi

log "[2단계] Full GUI 버전 다운로드 및 설치..."
ARCH=$(dpkg --print-architecture)
URL="https://download.teamviewer.com/download/linux/teamviewer_${ARCH}.deb"
TMP_DEB="/tmp/teamviewer_full.deb"

log "TeamViewer Full 버전 다운로드 중..."
wget -qO "$TMP_DEB" "$URL" || { echo "❌ 다운로드 실패"; exit 1; }

log "설치 중..."
apt-get install -y "$TMP_DEB" || { echo "❌ 설치 실패"; exit 1; }
rm -f "$TMP_DEB"
log "✅ 설치 완료!"

log "[3단계] teamviewerd.service 시작 중..."
systemctl enable --now teamviewerd.service
systemctl status teamviewerd.service --no-pager

log "🎉 이제 'teamviewer' 명령으로 GUI를 실행할 수 있습니다!"

