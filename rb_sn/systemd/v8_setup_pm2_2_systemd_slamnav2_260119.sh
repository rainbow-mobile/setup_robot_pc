#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo -e "\033[1;31m[에러]\033[0m 이 스크립트는 root 권한이 필요합니다. 'sudo $0' 으로 실행해 주세요."
    exit 1
fi

# === 기본 설정 ===
USER_NAME="${SUDO_USER:-$USER}"
USER_ID="$(id -u "$USER_NAME")"
HOME_DIR="$(getent passwd "$USER_NAME" | cut -d: -f6)"
APP_DIR="$HOME_DIR/slamnav2"
BIN_PATH="$APP_DIR/bin/SLAMNAV2"

CONF_DIR="$HOME_DIR/.config/slamnav2"
ENV_FILE="$CONF_DIR/env"

SERVICE_NAME="slamnav2.service"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME"

# === 프린터 ===
log()  { printf "\033[1;36m[SLAMNAV2]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[경고]\033[0m %s\n" "$*"; }
err()  { printf "\033[1;31m[에러]\033[0m %s\n" "$*"; }

# ==========================================
# 1. 설치/업데이트 함수
# ==========================================
do_install() {
    log "설치 및 시스템 등록을 시작합니다..."

    # 1) 실행 파일 점검
    if [[ ! -x "$BIN_PATH" ]]; then
        err "실행 파일이 없습니다: $BIN_PATH"
        err "경로를 확인하거나 실행 권한이 있는지 확인해 주세요."
        exit 1
    fi

    # 2) pm2 정리
    if command -v pm2 >/dev/null 2>&1; then
        log "pm2에서 SLAMNAV2 프로세스 정리..."
        pm2 stop SLAMNAV2 >/dev/null 2>&1 || true
        pm2 delete SLAMNAV2 >/dev/null 2>&1 || true
    fi

    # 3) 기존 유저 서비스 정리
    local OLD_SERVICE="$HOME_DIR/.config/systemd/user/$SERVICE_NAME"
    if [[ -f "$OLD_SERVICE" ]]; then
        log "기존 유저 서비스를 제거합니다..."
        runuser -u "$USER_NAME" -- env XDG_RUNTIME_DIR="/run/user/$USER_ID" \
            systemctl --user stop slamnav2.service 2>/dev/null || true
        runuser -u "$USER_NAME" -- env XDG_RUNTIME_DIR="/run/user/$USER_ID" \
            systemctl --user disable slamnav2.service 2>/dev/null || true
        rm -f "$OLD_SERVICE"
        runuser -u "$USER_NAME" -- env XDG_RUNTIME_DIR="/run/user/$USER_ID" \
            systemctl --user daemon-reload 2>/dev/null || true
    fi

    # 4) 환경 설정
    mkdir -p "$CONF_DIR"
    SESSION_TYPE="${XDG_SESSION_TYPE:-x11}"

    # Wayland/X11 판별
    QT_PLATFORM="xcb"
    if [[ "$SESSION_TYPE" == "wayland" ]]; then QT_PLATFORM="wayland"; fi

    log "환경 파일 생성: $ENV_FILE"
    cat > "$ENV_FILE" <<EENV
LD_LIBRARY_PATH=$APP_DIR/bin/lib:$APP_DIR/bin:\$LD_LIBRARY_PATH
QT_PLUGIN_PATH=$APP_DIR/bin:\$QT_PLUGIN_PATH
XDG_DATA_DIRS=/usr/share:/usr/local/share:\$XDG_DATA_DIRS
XDG_SESSION_TYPE=$SESSION_TYPE
QT_QPA_PLATFORM=$QT_PLATFORM
XDG_RUNTIME_DIR=/run/user/$USER_ID
EENV

    # DISPLAY 변수 처리
    if [[ -n "${DISPLAY:-}" ]]; then echo "DISPLAY=$DISPLAY" >> "$ENV_FILE"; fi
    if [[ -n "${XAUTHORITY:-}" ]]; then echo "XAUTHORITY=$XAUTHORITY" >> "$ENV_FILE"; fi

    chown -R "$USER_NAME":"$USER_NAME" "$CONF_DIR"

    # 5) Systemd 시스템 서비스 생성
    log "systemd 시스템 서비스 작성..."
    cat > "$SERVICE_FILE" <<ESVC
[Unit]
Description=SLAMNAV2 (GUI, user session)
After=graphical-session.target network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$USER_NAME
Group=$USER_NAME
WorkingDirectory=$APP_DIR
EnvironmentFile=$ENV_FILE
ExecStartPre=/usr/bin/sleep 10
ExecStart=$APP_DIR/bin/SLAMNAV2
CPUAffinity=1-7
CPUSchedulingPolicy=fifo
CPUSchedulingPriority=50
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
ESVC

    chmod 644 "$SERVICE_FILE"

    # 6) 서비스 활성화
    log "서비스 등록 및 시작..."
    systemctl daemon-reload
    systemctl enable --now slamnav2.service

    # 7) Alias 및 함수 등록
    if ! grep -q "slamnav2-save" "$HOME_DIR/.bashrc"; then
        log "관리용 명령어(Alias & Function)를 ~/.bashrc에 추가합니다."

        cat >> "$HOME_DIR/.bashrc" <<'EOF'

# === SLAMNAV2 관리 도구 ===
alias slamnav2-status='systemctl status slamnav2.service --no-pager'
alias slamnav2-logs='journalctl -u slamnav2.service -f -o cat'
alias slamnav2-restart='sudo systemctl restart slamnav2.service'
alias slamnav2-stop='sudo systemctl stop slamnav2.service'

# 1. 비정상 종료 원인 분석 (화면 출력용)
alias slamnav2-why='echo "=== SYSTEMD STATUS ==="; systemctl status slamnav2.service; echo -e "\n=== RECENT LOGS (SYSTEM) ==="; journalctl -u slamnav2.service -n 50; echo -e "\n=== KERNEL ERRORS (OOM/SEGV) ==="; dmesg | tail -n 50 | grep -iE "kill|segfault|error|slamnav2"'

# 2. 로그 파일로 저장 (저장 경로: ~/slamnav2_logs)
slamnav2-save() {
    local log_dir="$HOME/slamnav2_logs"
    if [ ! -d "$log_dir" ]; then
        mkdir -p "$log_dir"
        echo "로그 저장 폴더 생성됨: $log_dir"
    fi

    local filename="$log_dir/slamnav2_log_$(date +%Y%m%d_%H%M%S).txt"
    echo "로그를 수집하여 '$filename' 파일로 저장합니다..."

    {
        echo "REPORT TIME: $(date)"
        echo "USER: $USER"
        echo "HOST: $(hostname)"
        echo "----------------------------------------"
        echo "=== SYSTEMD STATUS ==="
        systemctl status slamnav2.service
        echo -e "\n=== RECENT LOGS (Last 100 lines) ==="
        journalctl -u slamnav2.service -n 100 --no-pager
        echo -e "\n=== KERNEL ERRORS (dmesg) ==="
        dmesg | tail -n 100 | grep -iE "kill|segfault|error|slamnav2"
    } > "$filename"

    echo "✅ 저장 완료! -> $filename"
}
EOF
        log "새로운 명령어가 추가되었습니다."
    else
        warn "이미 ~/.bashrc에 slamnav2 설정이 있습니다."
        warn "변경사항을 완벽히 적용하려면 'vi ~/.bashrc'에서 slamnav2 관련 설정을 지운 후 다시 실행하거나, 직접 수정하세요."
    fi

    log "✅ 설치 완료!"
    log "터미널을 껐다 켜거나 'source ~/.bashrc'를 입력하세요."
}

# ==========================================
# 2. 삭제(Uninstall) 함수
# ==========================================
do_uninstall() {
    log "SLAMNAV2 서비스 제거..."
    systemctl stop slamnav2.service || true
    systemctl disable slamnav2.service || true

    rm -f "$SERVICE_FILE"
    rm -rf "$CONF_DIR"

    systemctl daemon-reload
    systemctl reset-failed || true

    echo
    warn "~/.bashrc의 alias/함수는 자동으로 삭제되지 않습니다."
    warn "직접 'vi ~/.bashrc'로 열어 slamnav2 관련 내용을 지워주세요."
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
