#cat > ~/setup_slamnav2_systemd.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

# === 기본 설정 ===
USER_NAME="${SUDO_USER:-$USER}"
HOME_DIR="$(getent passwd "$USER_NAME" | cut -d: -f6)"
APP_DIR="$HOME_DIR/slamnav2"
BIN_PATH="$APP_DIR/SLAMNAV2"

CONF_DIR="$HOME_DIR/.config/slamnav2"
ENV_FILE="$CONF_DIR/env"

USR_SD_DIR="$HOME_DIR/.config/systemd/user"
SERVICE_FILE="$USR_SD_DIR/slamnav2.service"

# === 프린터 ===
log()  { printf "\033[1;36m[SLAMNAV2]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[경고]\033[0m %s\n" "$*"; }
err()  { printf "\033[1;31m[에러]\033[0m %s\n" "$*"; }

# === 점검 ===
if [[ ! -x "$BIN_PATH" ]]; then
  err "실행 파일이 없습니다: $BIN_PATH"
  err "경로를 확인하거나 빌드를 먼저 완료해 주세요."
  exit 1
fi

# === 1) pm2에서 SLAMNAV2만 정리 ===
if command -v pm2 >/dev/null 2>&1; then
  log "pm2에서 SLAMNAV2 프로세스 정리 시도..."
  # 이름으로 정리(없어도 오류없이 통과)
  pm2 stop SLAMNAV2 >/dev/null 2>&1 || true
  pm2 delete SLAMNAV2 >/dev/null 2>&1 || true
  log "pm2 정리 완료 (다른 pm2 앱은 건드리지 않음)."
else
  warn "pm2 명령을 찾을 수 없습니다. pm2 정리는 건너뜁니다."
fi

# === 2) GUI 세션 감지 및 환경파일 생성 ===
mkdir -p "$CONF_DIR"

SESSION_TYPE="${XDG_SESSION_TYPE:-}"
DISPLAY_VAL="${DISPLAY:-}"
XAUTH_VAL="${XAUTHORITY:-$HOME_DIR/.Xauthority}"
QT_PLATFORM=""

case "$SESSION_TYPE" in
  x11)
    DISPLAY_VAL="${DISPLAY_VAL:-:0}"
    QT_PLATFORM="xcb"
    ;;
  wayland)
    # Wayland에서는 보통 DISPLAY/XAUTHORITY 설정이 없어도 동작
    QT_PLATFORM="wayland"
    ;;
  *)
    # 알 수 없는 경우: 보수적으로 Xorg 가정
    DISPLAY_VAL="${DISPLAY_VAL:-:0}"
    QT_PLATFORM="xcb"
    ;;
esac

log "환경 파일 생성: $ENV_FILE"
cat > "$ENV_FILE" <<EENV
# 자동 생성: SLAMNAV2 GUI 실행 환경
# 라이브러리/플러그인 경로(실행 폴더에 .so와 플러그인이 함께 있을 때)
LD_LIBRARY_PATH=$APP_DIR:\$LD_LIBRARY_PATH
QT_PLUGIN_PATH=$APP_DIR:\$QT_PLUGIN_PATH
XDG_DATA_DIRS=/usr/share:/usr/local/share:\$XDG_DATA_DIRS

# GUI 세션 관련
XDG_SESSION_TYPE=${SESSION_TYPE:-x11}
QT_QPA_PLATFORM=$QT_PLATFORM
EENV

# DISPLAY/XAUTHORITY는 값이 있을 때만 기록(Wayland 순정 환경은 비워둠)
if [[ -n "$DISPLAY_VAL" ]]; then
  echo "DISPLAY=$DISPLAY_VAL" >> "$ENV_FILE"
fi
if [[ -n "$XAUTH_VAL" && -f "$XAUTH_VAL" ]]; then
  echo "XAUTHORITY=$XAUTH_VAL" >> "$ENV_FILE"
fi

# 디버깅용(필요시 주석 해제)
# echo "QT_DEBUG_PLUGINS=1" >> "$ENV_FILE"

# === 3) systemd 유저 서비스 생성 ===
# 25/09/16 issue : sensor & PDU data 안받아와지는 이슈 해결용
mkdir -p "$USR_SD_DIR"
log "systemd 유저 서비스 작성: $SERVICE_FILE"
cat > "$SERVICE_FILE" <<ESVC
[Unit]
Description=SLAMNAV2 (GUI, user session)
After=multi-user.target
After=network-online.target remote-fs.target
After=systemd-udev-settle.service
After=graphical-session.target

[Service]
ExecStartPre=/bin/bash -c 'if [ ! -f /tmp/slamnav2_started ]; then sleep 15; touch /tmp/slamnav2_started; fi'
Type=simple
WorkingDirectory=%h/slamnav2
EnvironmentFile=%h/.config/slamnav2/env
ExecStart=%h/slamnav2/SLAMNAV2
Restart=on-failure
RestartSec=2
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
ESVC

# === 4) 권한/소유권 정리 ===
chown -R "$USER_NAME":"$USER_NAME" "$CONF_DIR" "$USR_SD_DIR"

# === 5) 서비스 등록 및 즉시 시작 ===
# 25/09/16 issue : sensor & PDU data 안받아와지는 이슈 해결용
log "user systemd를 로그인 세션 없이도 계속 돌리는 명령어"
loginctl enable-linger "$USER_NAME"
log "systemd 유저 데몬 리로드"
sudo -u "$USER_NAME" XDG_RUNTIME_DIR="/run/user/$(id -u "$USER_NAME")" systemctl --user daemon-reload

log "서비스 enable & start"
sudo -u "$USER_NAME" XDG_RUNTIME_DIR="/run/user/$(id -u "$USER_NAME")" systemctl --user enable --now slamnav2.service


# === alias 등록 ===
  if ! grep -q "slamnav2-logs" "$HOME_DIR/.bashrc"; then
    log "alias 등록을 ~/.bashrc에 추가합니다."
    cat >> "$HOME_DIR/.bashrc" <<'ALIAS'
# SLAMNAV2 systemd 관리용 alias
alias slamnav2-logs='journalctl --user -u slamnav2.service -f'
alias slamnav2-status='systemctl --user status slamnav2.service --no-pager'
alias slamnav2-restart='systemctl --user restart slamnav2.service'
alias slamnav2-stop='systemctl --user stop slamnav2.service'
ALIAS
  fi

  log "설치/등록/시작 + alias 등록 완료!"
  echo " - 상태:   slamnav2-status"
  echo " - 로그:   slamnav2-logs"
  echo " - 재시작: slamnav2-restart"


# === 6) 요약/도움말 ===
log "설치 완료!"
echo
echo " - 상태 확인:   systemctl --user status slamnav2.service"
echo " - 실시간 로그: journalctl --user -u slamnav2.service -f"
echo
echo "문제가 있으면 아래를 확인하세요:"
echo " 1) xcb/wayland 관련 패키지:  sudo apt install -y xauth libxcb-cursor0 libxcb-xinerama0 libxkbcommon-x11-0 libgl1 libx11-xcb1"
echo " 2) DISPLAY/XAUTHORITY가 필요한 Xorg 환경인지:  echo \$XDG_SESSION_TYPE"
echo " 3) 의존 라이브러리:  cd $APP_DIR && ldd ./SLAMNAV2 | grep 'not found' || echo 'OK'"
EOF

chmod +x ~/setup_slamnav2_systemd.sh
echo "생성됨: ~/setup_slamnav2_systemd.sh"
echo "실행:   bash ~/setup_slamnav2_systemd.sh"

