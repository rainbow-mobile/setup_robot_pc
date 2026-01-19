#!/usr/bin/env bash
set -euo pipefail

# === 기본 설정 ===
USER_NAME="$(whoami)"
HOME_DIR="$HOME"
APP_DIR="$HOME_DIR/slamnav2"
BIN_PATH="$APP_DIR/run_app.sh"

CONF_DIR="$HOME_DIR/.config/slamnav2"
ENV_FILE="$CONF_DIR/env"

USR_SD_DIR="$HOME_DIR/.config/systemd/user"
SERVICE_NAME="slamnav2.service"
SERVICE_FILE="$USR_SD_DIR/$SERVICE_NAME"

# === 프린터 ===
log()  { printf "\033[1;36m[SLAMNAV2]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[경고]\033[0m %s\n" "$*"; }
err()  { printf "\033[1;31m[에러]\033[0m %s\n" "$*"; }

# === 유저 서비스 제어 함수 (Sudo 제거) ===
run_systemctl() {
    # 유저 서비스이므로 sudo 없이 현재 유저 권한으로 실행
    systemctl --user "$@"
}

# ==========================================
# 1. 설치/업데이트 함수
# ==========================================
do_install() {
    log "설치 및 시스템 등록을 시작합니다..."

    # 1) 실행 파일 점검
    if [[ ! -f "$BIN_PATH" ]]; then
        err "실행 파일이 없습니다: $BIN_PATH"
        exit 1
    fi
    chmod +x "$BIN_PATH"

    # 2) pm2 정리 (기존 방식 호환)
    if command -v pm2 >/dev/null 2>&1; then
        log "pm2에서 SLAMNAV2 프로세스 정리..."
        pm2 stop SLAMNAV2 >/dev/null 2>&1 || true
        pm2 delete SLAMNAV2 >/dev/null 2>&1 || true
    fi

    # 3) 환경 설정
    mkdir -p "$CONF_DIR"
    SESSION_TYPE="${XDG_SESSION_TYPE:-x11}"
    QT_PLATFORM="xcb"
    if [[ "$SESSION_TYPE" == "wayland" ]]; then QT_PLATFORM="wayland"; fi

    log "환경 파일 생성: $ENV_FILE"
    cat > "$ENV_FILE" <<EENV
LD_LIBRARY_PATH=$APP_DIR:\$LD_LIBRARY_PATH
QT_PLUGIN_PATH=$APP_DIR:\$QT_PLUGIN_PATH
XDG_DATA_DIRS=/usr/share:/usr/local/share:\$XDG_DATA_DIRS
XDG_SESSION_TYPE=$SESSION_TYPE
QT_QPA_PLATFORM=$QT_PLATFORM
EENV
    
    if [[ -n "${DISPLAY:-}" ]]; then echo "DISPLAY=$DISPLAY" >> "$ENV_FILE"; fi
    if [[ -n "${XAUTHORITY:-}" ]]; then echo "XAUTHORITY=$XAUTHORITY" >> "$ENV_FILE"; fi

    # 4) Systemd 유저 서비스 작성
    mkdir -p "$USR_SD_DIR"
    log "systemd 유저 서비스 작성..."
    cat > "$SERVICE_FILE" <<ESVC
[Unit]
Description=SLAMNAV2 (GUI, user session)
After=graphical-session.target network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=$APP_DIR
EnvironmentFile=$ENV_FILE
ExecStartPre=/usr/bin/sleep 10
ExecStart=$BIN_PATH
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
ESVC

    chmod 644 "$SERVICE_FILE"

    # 5) 서비스 활성화 (Linger만 sudo 필요할 수 있음)
    log "서비스 등록 및 시작..."
    sudo loginctl enable-linger "$USER_NAME" || warn "Linger 설정 실패 (수동 확인 필요)"
    
    run_systemctl daemon-reload
    run_systemctl enable "$SERVICE_NAME"
    run_systemctl restart "$SERVICE_NAME"

    # 6) Alias 등록
    if ! grep -q "slamnav2-save" "$HOME_DIR/.bashrc"; then
        log "관리용 명령어를 ~/.bashrc에 추가합니다."
        cat >> "$HOME_DIR/.bashrc" <<'EOF'

# === SLAMNAV2 관리 도구 ===
alias slamnav2-status='systemctl --user status slamnav2.service --no-pager'
alias slamnav2-logs='journalctl --user -u slamnav2.service -f -o cat'
alias slamnav2-restart='systemctl --user restart slamnav2.service'
alias slamnav2-stop='systemctl --user stop slamnav2.service'
EOF
    fi

    log "✅ 설치 완료!"
    log "터미널을 다시 열거나 'source ~/.bashrc'를 실행하세요."
}

# ==========================================
# 2. 삭제(Uninstall) 함수
# ==========================================
do_uninstall() {
    log "SLAMNAV2 서비스 제거..."
    run_systemctl stop "$SERVICE_NAME" || true
    run_systemctl disable "$SERVICE_NAME" || true
    rm -f "$SERVICE_FILE"
    run_systemctl daemon-reload
    run_systemctl reset-failed || true
    log "✅ 서비스 제거 완료."
}

# ==========================================
# 메인 메뉴
# ==========================================
echo "========================================"
echo "   SLAMNAV2 Systemd Service Manager"
echo "========================================"
PS3="작업 선택: "
options=("설치/업데이트" "서비스 제거" "종료")
select opt in "${options[@]}"; do
    case $opt in
        "설치/업데이트") do_install; break ;;
        "서비스 제거") do_uninstall; break ;;
        "종료") exit 0 ;;
        *) echo "잘못된 선택입니다." ;;
    esac
done
