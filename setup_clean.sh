#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# 루트 권한 확인
need_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "▶ 이 스크립트는 sudo 권한으로 실행해야 합니다."
    exit 1
  fi
}

# 로그 출력 함수
log() {
  echo -e "\e[32m[$(date +'%F %T')]\e[0m $*"
}

# 시작
need_root

log "1. /etc/apt/sources.list 백업 및 CD-ROM 항목 비활성화"
cp /etc/apt/sources.list /etc/apt/sources.list.bak
sed -i.bak '/^deb cdrom:/s/^/#/' /etc/apt/sources.list

log "2. APT 캐시 정리"
apt-get clean

log "3. 패키지 인덱스 완전 삭제"
rm -rf /var/lib/apt/lists/*

log "4. 깨진 패키지 설정 복구 및 의존성 확인"
dpkg --configure -a
apt-get install -f -y

log "5. 필수 리포지토리( universe, multiverse ) 활성화"
if ! dpkg -l | grep -qw software-properties-common; then
  apt-get update -qq
  apt-get install -y software-properties-common
fi
add-apt-repository -y universe
add-apt-repository -y multiverse

log "6. 레포지토리 정보 업데이트"
apt-get update -y --allow-releaseinfo-change

log "7. 시스템 업그레이드 (선택 사항)"
apt-get upgrade -y

log "완료: 이후 'sudo apt update' 시 발생하던 오류를 방지하기 위한 사전 설정이 모두 적용되었습니다."

