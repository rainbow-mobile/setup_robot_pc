#!/usr/bin/env bash
set -euo pipefail

USER_NAME="$(whoami)"
HOME_DIR="$HOME"
APP_DIR="$HOME_DIR/slamnav2"
BIN_PATH="$APP_DIR/run_app.sh"
CONF_DIR="$HOME_DIR/.config/slamnav2"
ENV_FILE="$CONF_DIR/env"
USR_SD_DIR="$HOME_DIR/.config/systemd/user"
SERVICE_NAME="slamnav2.service"
SERVICE_FILE="$USR_SD_DIR/$SERVICE_NAME"

log()  { printf "\033[1;36m[SLAMNAV2]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[경고]\033[0m %s\n" "$*"; }

do_install() {
    log "설치 및 시스템 등록을 시작합니다..."
    
    if [[ ! -f "$BIN_PATH" ]]; then
        printf "\033[1;31m[에러]\033[0m %s\n" "실행 파일이 없습니다: $BIN_PATH"; exit 1
    fi
    chmod +x "$BIN_PATH"

    mkdir -p "$CONF_DIR" "$USR_SD_DIR"
    
    log "환경 파일 생성..."
    cat > "$ENV_FILE" <<EENV
LD_LIBRARY_PATH=$APP_DIR:\$LD_LIBRARY_PATH
QT_PLUGIN_PATH=$APP_DIR:\$QT_PLUGIN_PATH
XDG_SESSION_TYPE=${XDG_SESSION_TYPE:-x11}
DISPLAY=${DISPLAY:-:0}
EENV

    log "systemd 유저 서비스 작성..."
    cat > "$SERVICE_FILE" <<ESVC
[Unit]
Description=SLAMNAV2 Service
After=graphical-session.target

[Service]
Type=simple
WorkingDirectory=$APP_DIR
EnvironmentFile=$ENV_FILE
ExecStart=$BIN_PATH
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
ESVC

    sudo loginctl enable-linger "$USER_NAME"
    systemctl --user daemon-reload
    systemctl --user enable "$SERVICE_NAME"
    systemctl --user restart "$SERVICE_NAME"
    log "✅ 설치 완료! 'slamnav2-logs'로 확인하세요."
}

# 실행부 생략 (기존 메뉴 구조 유지)
do_install
