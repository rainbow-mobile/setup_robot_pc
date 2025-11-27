#!/usr/bin/env bash
###############################################################################
# setup_modbus_root_gui.sh (v6 - GUI)
#  · 기능: Modbus RRS 설치 (Root 권한 + GUI 활성화)
#  · 특징: Root 서비스가 사용자 화면(:0)에 UI를 출력하도록 설정
###############################################################################
set -Eeuo pipefail

# === 공통 변수 ===
REAL_USER="${SUDO_USER:-$USER}"
HOME_DIR="$(getent passwd "$REAL_USER" | cut -d: -f6)"
REPO_URL="https://github.com/rainbow-mobile/modbus_rrs.git"
APP_DIR="$HOME_DIR/modbus_rrs"
BIN_NAME="app_modbus_rrs"
BIN_PATH="$APP_DIR/$BIN_NAME"

CONF_DIR="$HOME_DIR/.config/modbus_rrs"
ENV_FILE="$CONF_DIR/env"
SERVICE_NAME="modbus_rrs.service"
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"
BASHRC="$HOME_DIR/.bashrc"
ALIAS_MARKER="# Modbus RRS Aliases (Root)"

# === 로그 함수 ===
log()  { printf "\033[1;36m[MODBUS-GUI]\033[0m %s\n" "$*"; }
err()  { printf "\033[1;31m[에러]\033[0m %s\n" "$*"; }

# === 함수 1: 설치 (Root GUI 모드) ===
install_app() {
    log ">>> 설치 시작 (Root 권한 + UI 표시 모드)..."

    # 1. Git Clone/Pull
    if [ ! -d "$APP_DIR" ]; then
        sudo -u "$REAL_USER" git clone "$REPO_URL" "$APP_DIR"
    else
        if [ -w "$APP_DIR" ]; then git -C "$APP_DIR" pull; else sudo -u "$REAL_USER" git -C "$APP_DIR" pull; fi
    fi

    # 권한 확인
    [ -f "$BIN_PATH" ] && chmod +x "$BIN_PATH" || { err "실행 파일 없음: $BIN_PATH"; exit 1; }

    # 2. 환경 설정 파일 생성 (GUI 설정 핵심)
    # Root가 실행하지만, 화면은 사용자($REAL_USER)의 것을 사용하도록 설정합니다.
    mkdir -p "$CONF_DIR" && chown "$REAL_USER:$REAL_USER" "$CONF_DIR"
    
    log "환경 파일 생성 (DISPLAY=:0 설정 포함)"
    cat > "$ENV_FILE" <<EOF
# modbus_rrs 환경 설정 (Root GUI)
# UI 표시를 위한 필수 설정
DISPLAY=:0
XAUTHORITY=$HOME_DIR/.Xauthority
QT_QPA_PLATFORM=xcb
# 필요시 라이브러리 경로 주석 해제
# LD_LIBRARY_PATH=$APP_DIR:\$LD_LIBRARY_PATH
EOF
    chown "$REAL_USER:$REAL_USER" "$ENV_FILE"

    # 3. Systemd 서비스 파일 작성
    log "시스템 서비스 파일 작성: $SERVICE_PATH"
    
    sudo tee "$SERVICE_PATH" > /dev/null <<EOF
[Unit]
Description=Modbus RRS Service (Root with GUI)
# 화면(그래픽 세션)이 준비된 후에 시작
After=graphical.target systemd-user-sessions.service

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=$APP_DIR
EnvironmentFile=$ENV_FILE

# Qt/GUI 관련 환경 변수 재확인
Environment=DISPLAY=:0
Environment=XAUTHORITY=$HOME_DIR/.Xauthority
Environment=QT_QPA_PLATFORM=xcb

ExecStart=$BIN_PATH
Restart=on-failure
RestartSec=3

StandardOutput=journal
StandardError=journal

[Install]
WantedBy=graphical.target
EOF

    # 4. 서비스 재시작
    log "서비스 등록 및 재시작..."
    sudo systemctl daemon-reload
    sudo systemctl enable "$SERVICE_NAME"
    sudo systemctl restart "$SERVICE_NAME"

    # 5. Alias 등록
    if ! grep -q "$ALIAS_MARKER" "$BASHRC"; then
        cat >> "$BASHRC" <<EOF

$ALIAS_MARKER
alias modbus-status='sudo systemctl status $SERVICE_NAME --no-pager'
alias modbus-logs='sudo journalctl -u $SERVICE_NAME -f -o cat'
alias modbus-restart='sudo systemctl restart $SERVICE_NAME'
alias modbus-stop='sudo systemctl stop $SERVICE_NAME'
alias modbus-start='sudo systemctl start $SERVICE_NAME'
EOF
    fi

    echo
    log "✅ 설치 완료! (화면에 UI가 뜨는지 확인하세요)"
    log "   ※ 주의: 로그인 화면이 잠겨있거나 로그아웃 상태면 실행에 실패할 수 있습니다."
}

# === 함수 2: 제거 ===
uninstall_app() {
    log ">>> 제거 시작..."
    systemctl is-active --quiet "$SERVICE_NAME" && sudo systemctl stop "$SERVICE_NAME"
    systemctl is-enabled --quiet "$SERVICE_NAME" && sudo systemctl disable "$SERVICE_NAME"
    [ -f "$SERVICE_PATH" ] && sudo rm -f "$SERVICE_PATH" && sudo systemctl daemon-reload
    [ -d "$APP_DIR" ] && sudo rm -rf "$APP_DIR"
    [ -d "$CONF_DIR" ] && sudo rm -rf "$CONF_DIR"
    sed -i "/$ALIAS_MARKER/d" "$BASHRC"
    sed -i '/alias modbus-/d' "$BASHRC"
    sed -i '/^$/N;/^\n$/D' "$BASHRC"
    log "✅ 제거 완료!"
}

# === 메인 메뉴 ===
echo "==========================================="
echo "   Modbus RRS (Root + GUI) 관리"
echo "==========================================="
echo " 1) 설치 (Install - GUI Mode)"
echo " 2) 제거 (Uninstall)"
echo "==========================================="
read -rp "선택 (1/2): " CHOICE
case "$CHOICE" in
    1) install_app ;;
    2) uninstall_app ;;
    *) err "잘못된 입력"; exit 1 ;;
esac
