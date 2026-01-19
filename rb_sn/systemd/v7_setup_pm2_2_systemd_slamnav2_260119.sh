#!/usr/bin/env bash
set -Eeuo pipefail

# === 기본 설정 ===
USER_NAME="$(whoami)"
REAL_UID=$(id -u "$USER_NAME")
HOME_DIR="$HOME"
APP_DIR="$HOME_DIR/slamnav2"
BIN_PATH="$APP_DIR/run_app.sh"

CONF_DIR="$HOME_DIR/.config/slamnav2"
ENV_FILE="$CONF_DIR/env"
USR_SD_DIR="$HOME_DIR/.config/systemd/user"
SERVICE_NAME="slamnav2.service"
SERVICE_FILE="$USR_SD_DIR/$SERVICE_NAME"
BASHRC="$HOME_DIR/.bashrc"

log()  { printf "\033[1;36m[SLAMNAV2-v9]\033[0m %s\n" "$*"; }
err()  { printf "\033[1;31m[에러]\033[0m %s\n" "$*"; }

# ==========================================
# 1. 설치 및 GUI 권한 설정
# ==========================================
do_install() {
    log "설치 및 GUI 권한 최적화를 시작합니다..."

    # [1] 실행 파일 권한 확인
    if [[ ! -f "$BIN_PATH" ]]; then
        err "실행 파일이 없습니다: $BIN_PATH"
        exit 1
    fi
    chmod +x "$BIN_PATH"

    # [2] Xauthority 파일 경로 자동 감지 (Modbus 방식 참고)
    if [ -f "/run/user/$REAL_UID/gdm/Xauthority" ]; then
        TARGET_XAUTH="/run/user/$REAL_UID/gdm/Xauthority"
    elif [ -f "$HOME_DIR/.Xauthority" ]; then
        TARGET_XAUTH="$HOME_DIR/.Xauthority"
    else
        TARGET_XAUTH="$HOME_DIR/.Xauthority"
    fi
    log "감지된 XAUTH 경로: $TARGET_XAUTH"

    # [3] xhost 권한 부여 (로컬 유저 허용)
    if command -v xhost >/dev/null 2>&1; then
        xhost +SI:localuser:"$USER_NAME" >/dev/null 2>&1 || true
        
        # .bashrc에 자동 실행 등록
        if ! grep -q "xhost +SI:localuser:$USER_NAME" "$BASHRC"; then
            echo "xhost +SI:localuser:$USER_NAME >/dev/null 2>&1" >> "$BASHRC"
        fi
    fi

    # [4] 환경 파일 생성 (GUI 변수 포함)
    mkdir -p "$CONF_DIR"
    log "환경 파일 생성 중: $ENV_FILE"
    cat > "$ENV_FILE" <<EOF
DISPLAY=:0
XAUTHORITY=$TARGET_XAUTH
XDG_RUNTIME_DIR=/run/user/$REAL_UID
QT_QPA_PLATFORM=xcb
LD_LIBRARY_PATH=$APP_DIR:$APP_DIR/bin:\${LD_LIBRARY_PATH:-}
EOF

    # [5] Systemd 유저 서비스 작성
    mkdir -p "$USR_SD_DIR"
    log "systemd 유저 서비스 작성 중..."
    cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=SLAMNAV2 Service with GUI Auth
After=graphical-session.target

[Service]
Type=simple
WorkingDirectory=$APP_DIR
EnvironmentFile=$ENV_FILE
# GUI 세션이 완전히 준비될 때까지 대기
ExecStartPre=/usr/bin/sleep 5
ExecStart=$BIN_PATH
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF

    # [6] 서비스 활성화
    sudo loginctl enable-linger "$USER_NAME"
    systemctl --user daemon-reload
    systemctl --user enable "$SERVICE_NAME"
    systemctl --user restart "$SERVICE_NAME"

    log "✅ 설정 완료! 'slamnav2-logs'로 상태를 확인하세요."
}

# 메인 실행부
do_install
