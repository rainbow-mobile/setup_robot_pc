#!/usr/bin/env bash
set -euo pipefail

# ===== 기본 변수 =====
USER_NAME="${SUDO_USER:-$USER}"
UID_NUM="$(id -u "$USER_NAME")"
HOME_DIR="$(getent passwd "$USER_NAME" | cut -d: -f6)"
APP_DIR="$HOME_DIR/slamnav2"
BIN_PATH="$APP_DIR/SLAMNAV2"

CONF_DIR="$HOME_DIR/.config/slamnav2"
ENV_FILE="$CONF_DIR/env"

USR_SD_DIR="$HOME_DIR/.config/systemd/user"
SERVICE_FILE="$USR_SD_DIR/slamnav2.service"
WRAPPER="$APP_DIR/run_with_env.sh"

SERVICE_NAME="slamnav2.service"

log()  { printf "\033[1;36m[SLAMNAV2]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[경고]\033[0m %s\n" "$*"; }
err()  { printf "\033[1;31m[에러]\033[0m %s\n" "$*"; }

ensure_user_systemd() {
  export XDG_RUNTIME_DIR="/run/user/${UID_NUM}"
  if [[ ! -d "$XDG_RUNTIME_DIR" ]]; then
    warn "XDG_RUNTIME_DIR(${XDG_RUNTIME_DIR})가 없어 user systemd가 비활성일 수 있음."
    warn "그래도 진행 후 실패 시 그래픽 로그인 세션에서 다시 시도하거나 'loginctl enable-linger $USER'를 사용하세요."
  fi
}

pm2_cleanup() {
  if command -v pm2 >/dev/null 2>&1; then
    log "pm2에서 SLAMNAV2만 정리..."
    pm2 stop SLAMNAV2 >/dev/null 2>&1 || true
    pm2 delete SLAMNAV2 >/dev/null 2>&1 || true
    # <-- 요청 반영: 삭제 상태를 dump에 반영
    if pm2 save >/dev/null 2>&1; then
      log "pm2 save 완료 (다른 pm2 앱은 그대로 유지됩니다)."
    else
      warn "pm2 save 실패(무시). 필요 시 수동으로 'pm2 save'를 실행하세요."
    fi
  else
    warn "pm2 명령을 찾지 못해 pm2 정리는 건너뜀."
  fi
}

make_env() {
  mkdir -p "$CONF_DIR"
  local session="${XDG_SESSION_TYPE:-}"
  local disp="${DISPLAY:-}"
  local xauth="${XAUTHORITY:-$HOME_DIR/.Xauthority}"
  local platform=""

  case "$session" in
    x11)     platform="xcb"; disp="${disp:-:0}" ;;
    wayland) platform="wayland" ;;
    *)       platform="xcb"; disp="${disp:-:0}" ;;
  esac

  log "환경파일 생성: $ENV_FILE"
  cat > "$ENV_FILE" <<EENV
# 자동 생성됨: SLAMNAV2 GUI 실행 환경
LD_LIBRARY_PATH=$APP_DIR:\$LD_LIBRARY_PATH
QT_PLUGIN_PATH=$APP_DIR:\$QT_PLUGIN_PATH
XDG_DATA_DIRS=/usr/share:/usr/local/share:\$XDG_DATA_DIRS

XDG_SESSION_TYPE=${session:-x11}
QT_QPA_PLATFORM=$platform
EENV

  if [[ -n "$disp" ]]; then echo "DISPLAY=$disp" >> "$ENV_FILE"; fi
  if [[ -n "$xauth" && -f "$xauth" ]]; then echo "XAUTHORITY=$xauth" >> "$ENV_FILE"; fi
}

make_wrapper() {
  cat > "$WRAPPER" <<'WRAP'
#!/usr/bin/env bash
set -e
echo "[ENV] DISPLAY=$DISPLAY"
echo "[ENV] XAUTHORITY=$XAUTHORITY"
echo "[ENV] XDG_SESSION_TYPE=$XDG_SESSION_TYPE"
echo "[ENV] XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR"
echo "[ENV] DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS"
echo "[ENV] QT_QPA_PLATFORM=$QT_QPA_PLATFORM"
echo "[ENV] LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
exec "$(dirname "$0")/SLAMNAV2" "$@"
WRAP
  chmod +x "$WRAPPER"
}

make_service_exec() {
  local exec_line="$1"
  mkdir -p "$USR_SD_DIR"
  log "유저 서비스 작성: $SERVICE_FILE"
  cat > "$SERVICE_FILE" <<ESVC
[Unit]
Description=SLAMNAV2 (GUI, user session)
After=graphical-session.target
Wants=graphical-session.target

[Service]
WorkingDirectory=%h/slamnav2
EnvironmentFile=%h/.config/slamnav2/env
ExecStart=${exec_line}
Restart=on-failure
RestartSec=2
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
ESVC
  chown -R "$USER_NAME":"$USER_NAME" "$CONF_DIR" "$USR_SD_DIR"
}

enable_and_start() {
  ensure_user_systemd
  sudo -u "$USER_NAME" XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" systemctl --user daemon-reload
  sudo -u "$USER_NAME" XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" systemctl --user enable --now "$SERVICE_NAME"
}

status_cmd() {
  ensure_user_systemd
  systemctl --user status "$SERVICE_NAME" --no-pager || true
}

logs_cmd() {
  ensure_user_systemd
  journalctl --user -u "$SERVICE_NAME" -f
}

restart_cmd() {
  ensure_user_systemd
  systemctl --user restart "$SERVICE_NAME"
  status_cmd
}

stop_cmd() {
  ensure_user_systemd
  systemctl --user stop "$SERVICE_NAME" || true
  status_cmd
}

uninstall_cmd() {
  ensure_user_systemd
  systemctl --user disable --now "$SERVICE_NAME" 2>/dev/null || true
  rm -f "$SERVICE_FILE"
  rm -f "$ENV_FILE"
  log "서비스/환경파일 제거 완료(실행 바이너리/앱 폴더는 유지)."
}

debug_on() {
  make_wrapper
  sed -i 's#ExecStart=%h/slamnav2/SLAMNAV2#ExecStart=%h/slamnav2/run_with_env.sh#' "$SERVICE_FILE" || true
  enable_and_start
  status_cmd
}

debug_off() {
  sed -i 's#ExecStart=%h/slamnav2/run_with_env.sh#ExecStart=%h/slamnav2/SLAMNAV2#' "$SERVICE_FILE" || true
  enable_and_start
  status_cmd
}

install_all() {
  if [[ ! -x "$BIN_PATH" ]]; then
    err "실행 파일이 없습니다: $BIN_PATH"
    exit 1
  fi
  pm2_cleanup
  make_env
  make_service_exec "%h/slamnav2/SLAMNAV2"
  enable_and_start

  # === alias 등록 ===
  if ! grep -q "slamnav2-logs" "$HOME_DIR/.bashrc"; then
    log "alias 등록을 ~/.bashrc에 추가합니다."
    cat >> "$HOME_DIR/.bashrc" <<'ALIAS'
# SLAMNAV2 systemd 관리용 alias
alias slamnav2-logs='journalctl --user -u slamnav2.service -f'
alias slamnav2-status='systemctl --user status slamnav2.service --no-pager'
alias slamnav2-restart='systemctl --user restart slamnav2.service'
ALIAS
  fi

  log "설치/등록/시작 + alias 등록 완료!"
  echo " - 상태:   slamnav2-status"
  echo " - 로그:   slamnav2-logs"
  echo " - 재시작: slamnav2-restart"
}

case "${1:-install}" in
  install)     install_all ;;
  status)      status_cmd ;;
  logs)        logs_cmd ;;
  restart)     restart_cmd ;;
  stop)        stop_cmd ;;
  uninstall)   uninstall_cmd ;;
  debug-on)    debug_on ;;
  debug-off)   debug_off ;;
  *)
    echo "사용법: $0 [install|status|logs|restart|stop|uninstall|debug-on|debug-off]"
    exit 1
    ;;
esac

