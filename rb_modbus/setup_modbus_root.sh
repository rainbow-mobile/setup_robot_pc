#!/usr/bin/env bash
###############################################################################
# setup_modbus_root_gui.sh (v7 - Fix Auth)
#  · 기능: Modbus RRS 설치 (Root 권한 + GUI)
#  · 해결: "Authorization required" 에러 해결을 위한 xhost 및 경로 자동 감지
###############################################################################
set -Eeuo pipefail

# === 공통 변수 ===
REAL_USER="${SUDO_USER:-$USER}"
# REAL_USER의 UID 구하기 (예: 1000)
REAL_UID=$(id -u "$REAL_USER")
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
log()  { printf "\033[1;36m[MODBUS-v7]\033[0m %s\n" "$*"; }
err()  { printf "\033[1;31m[에러]\033[0m %s\n" "$*"; }

# === 함수 1: 설치 (Root GUI + Auth Fix) ===
install_app() {
    log ">>> 설치 시작 (Authorization Fix 적용)..."

    # 1. Git Clone/Pull
    if [ ! -d "$APP_DIR" ]; then
        sudo -u "$REAL_USER" git clone "$REPO_URL" "$APP_DIR"
    else
        if [ -w "$APP_DIR" ]; then git -C "$APP_DIR" pull; else sudo -u "$REAL_USER" git -C "$APP_DIR" pull; fi
    fi

    # 권한 확인
    [ -f "$BIN_PATH" ] && chmod +x "$BIN_PATH" || { err "실행 파일 없음: $BIN_PATH"; exit 1; }

    # -----------------------------------------------------------
    # [핵심] X11 권한 문제 해결 (Authorization Fix)
    # -----------------------------------------------------------
    
    # 1) 올바른 Xauthority 파일 찾기
    # Ubuntu 최신 버전(GDM)은 /run/user/$UID/gdm/Xauthority 에 있을 확률이 높음
    if [ -f "/run/user/$REAL_UID/gdm/Xauthority" ]; then
        TARGET_XAUTH="/run/user/$REAL_UID/gdm/Xauthority"
        log "감지됨: GDM Xauthority ($TARGET_XAUTH)"
    elif [ -f "$HOME_DIR/.Xauthority" ]; then
        TARGET_XAUTH="$HOME_DIR/.Xauthority"
        log "감지됨: Home Xauthority ($TARGET_XAUTH)"
    else
        TARGET_XAUTH="$HOME_DIR/.Xauthority"
        log "주의: 인증 파일을 찾지 못해 기본값($TARGET_XAUTH)을 사용합니다."
    fi

    # 2) xhost 권한 허용 (현재 세션용)
    log "xhost: 로컬 Root 사용자에게 화면 접근 권한 부여 중..."
    # 이 명령은 반드시 '화면 주인(REAL_USER)' 권한으로 실행해야 함
    if sudo -u "$REAL_USER" xhost +SI:localuser:root >/dev/null 2>&1; then
        log "xhost 권한 부여 성공"
    else
        log "경고: xhost 명령 실패 (디스플레이가 없거나 권한 부족)"
    fi

    # 3) 재부팅 후에도 xhost 권한 유지되도록 .bashrc에 추가
    if ! grep -q "xhost +SI:localuser:root" "$BASHRC"; then
        log ".bashrc에 xhost 자동 실행 명령어 추가"
        echo "" >> "$BASHRC"
        echo "# [Modbus RRS] Root 서비스가 GUI를 띄울 수 있도록 허용" >> "$BASHRC"
        echo "xhost +SI:localuser:root >/dev/null 2>&1" >> "$BASHRC"
        chown "$REAL_USER:$REAL_USER" "$BASHRC"
    fi

    # -----------------------------------------------------------
    # 환경 파일 및 서비스 생성
    # -----------------------------------------------------------

    mkdir -p "$CONF_DIR" && chown "$REAL_USER:$REAL_USER" "$CONF_DIR"
    
    log "환경 파일 생성 (XAUTHORITY=$TARGET_XAUTH)"
    cat > "$ENV_FILE" <<EOF
# modbus_rrs 환경 설정 (Root GUI)
DISPLAY=:0
XAUTHORITY=$TARGET_XAUTH
QT_QPA_PLATFORM=xcb
# LD_LIBRARY_PATH=$APP_DIR:\$LD_LIBRARY_PATH
EOF
    chown "$REAL_USER:$REAL_USER" "$ENV_FILE"

    log "시스템 서비스 파일 작성: $SERVICE_PATH"
    sudo tee "$SERVICE_PATH" > /dev/null <<EOF
[Unit]
Description=Modbus RRS Service (Root with GUI)
After=graphical.target systemd-user-sessions.service

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=$APP_DIR
EnvironmentFile=$ENV_FILE

# 환경 변수 강제 지정 (파일 내용이 안 먹힐 경우 대비)
Environment=DISPLAY=:0
Environment=XAUTHORITY=$TARGET_XAUTH
Environment=QT_QPA_PLATFORM=xcb

ExecStart=$BIN_PATH
Restart=on-failure
RestartSec=3

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
    log "✅ 설치 완료!"
    log "   - 화면에 프로그램이 떴는지 확인하세요."
    log "   - 안 떴다면 터미널에 'xhost +SI:localuser:root' 를 입력하고"
    log "     'modbus-restart' 해보세요."
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
    sed -i '/xhost +SI:localuser:root/d' "$BASHRC"  # xhost 설정도 삭제
    sed -i '/^$/N;/^\n$/D' "$BASHRC"
    log "✅ 제거 완료!"
}

# === 메인 메뉴 ===
echo "==========================================="
echo "   Modbus RRS (Root + GUI v7)"
echo "==========================================="
echo " 1) 설치 (Install - Auth Fix)"
echo " 2) 제거 (Uninstall)"
echo "==========================================="
read -rp "선택 (1/2): " CHOICE
case "$CHOICE" in
    1) install_app ;;
    2) uninstall_app ;;
    *) err "잘못된 입력"; exit 1 ;;
esac
