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

do_install() {
    log "설치 및 GUI/권한 최적화를 시작합니다..."

    if [[ ! -f "$BIN_PATH" ]]; then
        err "실행 파일이 없습니다: $BIN_PATH"
        exit 1
    fi
    chmod +x "$BIN_PATH"

    # [1] Xauthority 경로 감지
    TARGET_XAUTH="$HOME_DIR/.Xauthority"
    [ -f "/run/user/$REAL_UID/gdm/Xauthority" ] && TARGET_XAUTH="/run/user/$REAL_UID/gdm/Xauthority"
    log "감지된 XAUTH 경로: $TARGET_XAUTH"

    # [2] 환경 파일 생성 (변수 확장 제거, 고정 경로 사용)
    mkdir -p "$CONF_DIR"
    cat > "$ENV_FILE" <<EOF
DISPLAY=:0
XAUTHORITY=$TARGET_XAUTH
XDG_RUNTIME_DIR=/run/user/$REAL_UID
QT_QPA_PLATFORM=xcb
# 라이브러리 경로 직접 기입 (Systemd는 ${} 확장을 지원하지 않음)
LD_LIBRARY_PATH=$APP_DIR:$APP_DIR/bin:$APP_DIR/bin/lib:/usr/local/lib:/usr/lib
EOF

    # [3] Systemd 유저 서비스 작성 (Native RT 및 Affinity 설정)
    mkdir -p "$USR_SD_DIR"
    log "systemd 유저 서비스 작성 중 (RT Priority 및 Affinity 적용)..."
    cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=SLAMNAV2 Service
After=graphical-session.target

[Service]
Type=simple
WorkingDirectory=$APP_DIR
EnvironmentFile=$ENV_FILE
ExecStartPre=/usr/bin/sleep 2
ExecStart=$BIN_PATH

# 성능 및 우선순위 설정 (sudo taskset/chrt 대체)
CPUAffinity=1-7
CPUSchedulingPolicy=fifo
CPUSchedulingPriority=50
# RT 우선순위 권한 허용
LimitRTPRIO=99

Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF

    # [4] 서비스 활성화
    sudo loginctl enable-linger "$USER_NAME"
    systemctl --user daemon-reload
    systemctl --user enable "$SERVICE_NAME"
    systemctl --user restart "$SERVICE_NAME"

    log "✅ 설정 완료! 'systemctl --user status $SERVICE_NAME'로 확인하세요."
}

do_install
