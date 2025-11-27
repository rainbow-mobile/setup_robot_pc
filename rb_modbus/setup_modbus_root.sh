#!/usr/bin/env bash
###############################################################################
# setup_modbus_root.sh (v3)
#  · 기능: Modbus RRS 프로그램 설치 (Root 권한 Systemd 서비스) 또는 제거
#  · 주의: 실행 파일은 항상 Root(sudo) 권한으로 실행됩니다.
###############################################################################
set -Eeuo pipefail

# === 공통 변수 설정 ===
# 스크립트를 sudo로 실행했더라도 원래 사용자(SUDO_USER)의 홈 경로를 찾음
REAL_USER="${SUDO_USER:-$USER}"
HOME_DIR="$(getent passwd "$REAL_USER" | cut -d: -f6)"

# 경로 변수
REPO_URL="https://github.com/rainbow-mobile/modbus_rrs.git"
APP_DIR="$HOME_DIR/modbus_rrs"
BIN_NAME="app_modbus_rrs"
BIN_PATH="$APP_DIR/$BIN_NAME"

# 설정 파일 (유저 홈에 두되, root가 읽음)
CONF_DIR="$HOME_DIR/.config/modbus_rrs"
ENV_FILE="$CONF_DIR/env"

# Systemd 경로 (시스템 서비스는 /etc/systemd/system)
SERVICE_NAME="modbus_rrs.service"
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"

# Alias 등록 파일
BASHRC="$HOME_DIR/.bashrc"
ALIAS_MARKER="# Modbus RRS Aliases (Root)"

# === 로그 함수 ===
log()  { printf "\033[1;36m[MODBUS-ROOT]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[경고]\033[0m %s\n" "$*"; }
err()  { printf "\033[1;31m[에러]\033[0m %s\n" "$*"; }

# === 함수 1: 설치 (Install) ===
install_app() {
    log ">>> 설치 프로세스를 시작합니다 (Root 권한 모드)..."

    # 1. 소스코드 다운로드/업데이트
    # 폴더 소유권은 일반 사용자($REAL_USER)로 유지하여 git 관리 용이하게 함
    if [ ! -d "$APP_DIR" ]; then
        log "리포지토리 클론: $REPO_URL"
        sudo -u "$REAL_USER" git clone "$REPO_URL" "$APP_DIR"
    else
        log "리포지토리 업데이트 (git pull)"
        # 권한 문제 방지를 위해 안전하게 처리
        if [ -w "$APP_DIR" ]; then
            git -C "$APP_DIR" pull
        else
            sudo -u "$REAL_USER" git -C "$APP_DIR" pull
        fi
    fi

    # 실행 권한 확인
    if [ -f "$BIN_PATH" ]; then
        chmod +x "$BIN_PATH"
    else
        err "실행 파일이 없습니다: $BIN_PATH"
        exit 1
    fi

    # 2. 환경 설정 파일 생성
    # 유저 홈에 만들지만, 내용은 root가 읽어서 실행함
    mkdir -p "$CONF_DIR"
    chown "$REAL_USER:$REAL_USER" "$CONF_DIR"
    
    cat > "$ENV_FILE" <<EOF
# modbus_rrs 환경 설정 (Root 실행)
# LD_LIBRARY_PATH=$APP_DIR:\$LD_LIBRARY_PATH
EOF
    chown "$REAL_USER:$REAL_USER" "$ENV_FILE"

    # 3. Systemd 시스템 서비스 파일 생성 (/etc/systemd/system)
    # User=root 를 명시하거나 생략하면 기본적으로 root로 실행됨
    log "시스템 서비스 파일 작성: $SERVICE_PATH"
    
    sudo tee "$SERVICE_PATH" > /dev/null <<EOF
[Unit]
Description=Modbus RRS Service (Running as Root)
After=network.target

[Service]
Type=simple
# Root 권한으로 실행
User=root
Group=root

WorkingDirectory=$APP_DIR
EnvironmentFile=$ENV_FILE
ExecStart=$BIN_PATH

Restart=on-failure
RestartSec=3
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    # 4. 서비스 등록 및 실행
    log "서비스 등록 및 시작 중..."
    
    sudo systemctl daemon-reload
    sudo systemctl enable "$SERVICE_NAME"
    sudo systemctl restart "$SERVICE_NAME"

    # 5. Alias 등록 (일반 유저의 .bashrc에 등록하되, 명령어는 sudo 포함)
    if ! grep -q "$ALIAS_MARKER" "$BASHRC"; then
        log "~/.bashrc에 관리용 alias 추가"
        cat >> "$BASHRC" <<EOF

$ALIAS_MARKER
# Root 서비스이므로 sudo가 필요합니다
alias modbus-status='sudo systemctl status $SERVICE_NAME --no-pager'
alias modbus-logs='sudo journalctl -u $SERVICE_NAME -f -o cat'
alias modbus-restart='sudo systemctl restart $SERVICE_NAME'
alias modbus-stop='sudo systemctl stop $SERVICE_NAME'
alias modbus-start='sudo systemctl start $SERVICE_NAME'
EOF
        chown "$REAL_USER:$REAL_USER" "$BASHRC"
    fi

    echo
    log "✅ 설치 완료! (서비스 상태: modbus-status)"
    log "   ※ 주의: 이 서비스는 Root 권한으로 실행됩니다."
}

# === 함수 2: 제거 (Uninstall) ===
uninstall_app() {
    log ">>> 제거 프로세스를 시작합니다..."

    # 1. 서비스 중지 및 비활성화 (Root 권한)
    log "Systemd 서비스 중지..."
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        sudo systemctl stop "$SERVICE_NAME"
    fi
    if systemctl is-enabled --quiet "$SERVICE_NAME"; then
        sudo systemctl disable "$SERVICE_NAME"
    fi

    # 2. 서비스 파일 삭제
    if [ -f "$SERVICE_PATH" ]; then
        sudo rm -f "$SERVICE_PATH"
        log "서비스 파일 삭제됨: $SERVICE_PATH"
        sudo systemctl daemon-reload
    fi

    # 3. 프로그램 및 설정 폴더 삭제
    # (선택: 프로그램 소스까지 지울지 물어보거나 그냥 지움. 여기선 모두 삭제)
    if [ -d "$APP_DIR" ]; then
        sudo rm -rf "$APP_DIR"
        log "프로그램 폴더 삭제됨: $APP_DIR"
    fi
    if [ -d "$CONF_DIR" ]; then
        sudo rm -rf "$CONF_DIR"
        log "설정 폴더 삭제됨: $CONF_DIR"
    fi

    # 4. .bashrc Alias 삭제
    log ".bashrc에서 Alias 제거 중..."
    # 마커 및 관련 줄 삭제
    sed -i "/$ALIAS_MARKER/d" "$BASHRC"
    sed -i '/alias modbus-status/d' "$BASHRC"
    sed -i '/alias modbus-logs/d' "$BASHRC"
    sed -i '/alias modbus-restart/d' "$BASHRC"
    sed -i '/alias modbus-stop/d' "$BASHRC"
    sed -i '/alias modbus-start/d' "$BASHRC"
    # 빈 줄 정리
    sed -i '/^$/N;/^\n$/D' "$BASHRC"

    echo
    log "✅ 제거 완료! (Systemd 서비스 및 파일이 삭제되었습니다.)"
}

# === 메인 메뉴 ===
echo "==========================================="
echo "   Modbus RRS (Root) 관리 스크립트"
echo "==========================================="
echo " 1) 설치 (Install - Runs as Root)"
echo " 2) 제거 (Uninstall)"
echo "==========================================="
read -rp "선택번호 입력 (1/2): " CHOICE

case "$CHOICE" in
    1)
        install_app
        ;;
    2)
        read -rp "정말 제거하시겠습니까? (y/N): " CONFIRM
        if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
            uninstall_app
        else
            log "취소되었습니다."
        fi
        ;;
    *)
        err "잘못된 입력입니다."
        exit 1
        ;;
esac
