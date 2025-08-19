#!/usr/bin/env bash
# uninstall_nomachine.sh — NoMachine 완전 삭제(잔여 파일/계정/서비스 포함)
set -Eeuo pipefail
IFS=$'\n\t'

log(){ echo -e "\e[32m[$(date +'%F %T')]\e[0m $*"; }
need_root(){ if [[ $EUID -ne 0 ]]; then echo "sudo로 실행하세요." >&2; exit 1; fi; }
graceful_shutdown(){
  # 가능하면 우아하게 종료
  if [[ -x /usr/NX/bin/nxserver ]]; then
    /usr/NX/bin/nxserver --shutdown 2>/dev/null || true
  fi
}

svc_stop_disable(){
  systemctl stop nxserver.service 2>/dev/null || true
  systemctl disable nxserver.service 2>/dev/null || true
}

pkg_purge(){
  # Debian/Ubuntu
  if command -v dpkg >/dev/null 2>&1; then
    if dpkg-query -W -f='${Status}\n' nomachine 2>/dev/null | grep -q 'install ok installed'; then
      apt-get purge -y nomachine || true
    fi
    dpkg -P nomachine 2>/dev/null || true
    apt-get autoremove -y || true
  # RHEL/CentOS/Fedora
  elif command -v rpm >/dev/null 2>&1; then
    if rpm -q nomachine >/dev/null 2>&1; then
      (command -v dnf >/dev/null && dnf remove -y nomachine) || yum remove -y nomachine || true
    fi
  fi

  # 혹시 snap으로 설치된 경우(드묾)
  if command -v snap >/dev/null 2>&1; then
    snap list 2>/dev/null | grep -iq nomachine && snap remove nomachine || true
  fi
}

kill_leftovers(){
  # 남은 프로세스 정리
  for p in nxserver nxnode nxclient; do
    pkill -x "$p" 2>/dev/null || true
  done
}

remove_residuals(){
  # 표준 설치/로그/설정 경로
  rm -rf /usr/NX /etc/NX /var/NX 2>/dev/null || true
  rm -rf /var/log/NX /var/log/nx* 2>/dev/null || true
  # Desktop 파일/아이콘(있으면)
  rm -f /usr/share/applications/nomachine*.desktop 2>/dev/null || true
  rm -rf /usr/share/icons/hicolor/*/apps/nomachine* 2>/dev/null || true
  # systemd 유닛 잔여물
  rm -f /etc/systemd/system/nxserver.service /lib/systemd/system/nxserver.service 2>/dev/null || true
  systemctl daemon-reload || true
  # apt 소스(드물게 생성되는 경우)
  rm -f /etc/apt/sources.list.d/nomachine*.list 2>/dev/null || true
}

remove_user_group(){
  # nx 전용 계정/그룹 삭제(존재 시)
  if getent passwd nx >/dev/null; then
    userdel -r nx 2>/dev/null || true
  fi
  getent group nx >/dev/null && groupdel nx 2>/dev/null || true
}

show_summary(){
  echo "---- 삭제 확인 ----"
  command -v nxserver >/dev/null 2>&1 && echo "nxserver 바이너리: 남아있음(❌)" || echo "nxserver 바이너리: 없음(✅)"
  systemctl status nxserver.service >/dev/null 2>&1 && echo "서비스: 남아있음(❌)" || echo "서비스: 없음(✅)"
  if command -v dpkg >/dev/null 2>&1; then
    dpkg -l 2>/dev/null | grep -q '^ii  nomachine ' && echo "패키지: 남아있음(❌)" || echo "패키지: 없음(✅)"
  elif command -v rpm >/dev/null 2>&1; then
    rpm -q nomachine >/dev/null 2>&1 && echo "패키지: 남아있음(❌)" || echo "패키지: 없음(✅)"
  fi
  echo "-------------------"
}

main(){
  need_root
  log "[1/6] NoMachine 종료 시도"
  graceful_shutdown

  log "[2/6] 서비스 중지/비활성화"
  svc_stop_disable

  log "[3/6] 패키지 제거"
  pkg_purge

  log "[4/6] 남은 프로세스 정리"
  kill_leftovers

  log "[5/6] 잔여 파일/유닛/설정 제거"
  remove_residuals

  log "[6/6] nx 계정/그룹 제거"
  remove_user_group

  show_summary
  log "NoMachine 완전 삭제 완료 ✅"
}

main "$@"

