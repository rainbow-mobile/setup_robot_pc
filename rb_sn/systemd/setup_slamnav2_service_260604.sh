#!/usr/bin/env bash
###############################################################################
# setup_slamnav2_service_260604.sh
#
#  목적: 이미 설치된 ~/slamnav2/run.sh 를 systemd "system" 서비스로 등록하여
#        부팅 시 SLAMNAV2(GUI)를 자동 실행한다.
#        (의존성/SDK 설치는 하지 않음 — 등록/관리 전용)
#
#  run.sh 는 LD_LIBRARY_PATH(=libs) 와 bin/SLAMNAV2 실행만 처리하므로,
#  GUI 환경(DISPLAY/XAUTHORITY/QT_QPA_PLATFORM/XDG_RUNTIME_DIR)은 유닛이 주입한다.
#
#  전제: GUI 앱이므로 "자동로그인"이 활성화되어 그래픽 세션이 떠 있어야 한다.
###############################################################################
set -euo pipefail

# === root 권한 확인 =========================================================
if [[ $EUID -ne 0 ]]; then
    echo -e "\033[1;31m[에러]\033[0m 이 스크립트는 root 권한이 필요합니다. 'sudo $0' 으로 실행해 주세요."
    exit 1
fi

# === 기본 설정 ==============================================================
USER_NAME="${SUDO_USER:-$USER}"
USER_ID="$(id -u "$USER_NAME")"
HOME_DIR="$(getent passwd "$USER_NAME" | cut -d: -f6)"
APP_DIR="$HOME_DIR/slamnav2"
RUN_SH="$APP_DIR/run.sh"

CONF_DIR="$HOME_DIR/.config/slamnav2"
ENV_FILE="$CONF_DIR/env"

SERVICE_NAME="slamnav2.service"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME"

# === 프린터 =================================================================
log()  { printf "\033[1;36m[SLAMNAV2]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[경고]\033[0m %s\n" "$*"; }
err()  { printf "\033[1;31m[에러]\033[0m %s\n" "$*"; }

# ==========================================
# 자동 감지 헬퍼
# ==========================================

# CPU affinity 문자열 계산: 코어0은 시스템용으로 비우고 1..(N-1) 사용.
# 코어가 1개뿐이면 빈 문자열(=affinity 설정 생략).
detect_affinity() {
    local ncores
    ncores="$(nproc)"
    if [[ "$ncores" -gt 1 ]]; then
        echo "1-$((ncores - 1))"
    else
        echo ""
    fi
}

# 활성 그래픽 세션의 DISPLAY 감지. 실패 시 :0.
detect_display() {
    local sid suser sdisp
    # 1) loginctl 로 사용자 세션의 Display 속성 조회
    for sid in $(loginctl list-sessions --no-legend 2>/dev/null | awk '{print $1}'); do
        suser="$(loginctl show-session "$sid" -p Name --value 2>/dev/null || true)"
        [[ "$suser" == "$USER_NAME" ]] || continue
        sdisp="$(loginctl show-session "$sid" -p Display --value 2>/dev/null || true)"
        if [[ -n "$sdisp" ]]; then
            echo "$sdisp"
            return 0
        fi
    done
    # 2) who 출력에서 (:N) 토큰 추출
    sdisp="$(who 2>/dev/null | awk 'match($0,/\(:[0-9]+(\.[0-9]+)?\)/){d=substr($0,RSTART+1,RLENGTH-2); print d; exit}')"
    if [[ -n "$sdisp" ]]; then
        echo "$sdisp"
        return 0
    fi
    # 3) 기본값
    echo ":0"
}

# XAUTHORITY 경로 감지. gdm 런타임 경로 우선, 없으면 홈의 .Xauthority.
detect_xauthority() {
    local candidates=(
        "/run/user/$USER_ID/gdm/Xauthority"
        "$HOME_DIR/.Xauthority"
    )
    local x
    for x in "${candidates[@]}"; do
        [[ -f "$x" ]] && { echo "$x"; return 0; }
    done
    # 둘 다 아직 없으면(세션 기동 전 등) gdm 경로를 기본값으로
    echo "/run/user/$USER_ID/gdm/Xauthority"
}

# ==========================================
# 1. 설치/업데이트
# ==========================================
do_install() {
    log "SLAMNAV2 systemd 서비스 등록을 시작합니다..."

    # 1) run.sh 점검
    if [[ ! -f "$RUN_SH" ]]; then
        err "run.sh 를 찾을 수 없습니다: $RUN_SH"
        err "로봇에 ~/slamnav2 가 설치되어 있는지, 경로가 맞는지 확인해 주세요."
        exit 1
    fi
    if [[ ! -x "$RUN_SH" ]]; then
        log "run.sh 에 실행 권한이 없어 추가합니다: chmod +x"
        chmod +x "$RUN_SH"
    fi

    # 2) 기존 pm2 프로세스 정리
    if command -v pm2 >/dev/null 2>&1; then
        log "pm2 에서 SLAMNAV2 프로세스 정리..."
        pm2 stop SLAMNAV2 >/dev/null 2>&1 || true
        pm2 delete SLAMNAV2 >/dev/null 2>&1 || true
    fi

    # 3) 기존 user 서비스 정리(과거 유저 서비스 방식 잔재)
    local OLD_USER_SERVICE="$HOME_DIR/.config/systemd/user/$SERVICE_NAME"
    if [[ -f "$OLD_USER_SERVICE" ]]; then
        log "과거 user 서비스를 제거합니다..."
        runuser -u "$USER_NAME" -- env XDG_RUNTIME_DIR="/run/user/$USER_ID" \
            systemctl --user stop "$SERVICE_NAME" 2>/dev/null || true
        runuser -u "$USER_NAME" -- env XDG_RUNTIME_DIR="/run/user/$USER_ID" \
            systemctl --user disable "$SERVICE_NAME" 2>/dev/null || true
        rm -f "$OLD_USER_SERVICE"
        runuser -u "$USER_NAME" -- env XDG_RUNTIME_DIR="/run/user/$USER_ID" \
            systemctl --user daemon-reload 2>/dev/null || true
    fi

    # 4) 기존 system 서비스가 떠 있으면 멈춤(재설치 멱등성)
    if systemctl list-unit-files "$SERVICE_NAME" >/dev/null 2>&1; then
        systemctl stop "$SERVICE_NAME" 2>/dev/null || true
    fi

    # 5) GUI 환경 자동 감지
    local DISPLAY_VAL XAUTH_VAL AFFINITY
    DISPLAY_VAL="$(detect_display)"
    XAUTH_VAL="$(detect_xauthority)"
    AFFINITY="$(detect_affinity)"
    log "감지 결과 → DISPLAY=$DISPLAY_VAL, XAUTHORITY=$XAUTH_VAL, CPUAffinity=${AFFINITY:-(생략)}"

    if [[ ! -f "$XAUTH_VAL" ]]; then
        warn "XAUTHORITY 파일이 아직 없습니다: $XAUTH_VAL"
        warn "그래픽 세션(자동로그인)이 떠 있어야 생성됩니다. 부팅 후 서비스 재시작으로 복구될 수 있습니다."
    fi

    # 6) 환경 파일 생성 (GUI 환경만; LD_LIBRARY_PATH 는 run.sh 가 처리)
    log "환경 파일 생성: $ENV_FILE"
    mkdir -p "$CONF_DIR"
    cat > "$ENV_FILE" <<EENV
DISPLAY=$DISPLAY_VAL
XAUTHORITY=$XAUTH_VAL
QT_QPA_PLATFORM=xcb
XDG_RUNTIME_DIR=/run/user/$USER_ID
EENV
    chown -R "$USER_NAME":"$USER_NAME" "$CONF_DIR"

    # 7) systemd 시스템 서비스 유닛 생성
    log "systemd 시스템 서비스 작성: $SERVICE_FILE"
    local AFFINITY_LINE=""
    [[ -n "$AFFINITY" ]] && AFFINITY_LINE="CPUAffinity=$AFFINITY"

    cat > "$SERVICE_FILE" <<ESVC
[Unit]
Description=SLAMNAV2 (GUI autostart)
After=graphical.target network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$USER_NAME
Group=$USER_NAME
WorkingDirectory=$APP_DIR
EnvironmentFile=$ENV_FILE
ExecStartPre=/usr/bin/sleep 10
ExecStart=$RUN_SH
${AFFINITY_LINE}
CPUSchedulingPolicy=fifo
CPUSchedulingPriority=50
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=graphical.target
ESVC
    chmod 644 "$SERVICE_FILE"

    # 8) 서비스 등록 및 시작(업데이트 시 새 설정 반영을 위해 restart)
    log "서비스 등록 및 시작..."
    systemctl daemon-reload
    systemctl enable "$SERVICE_NAME"
    systemctl restart "$SERVICE_NAME"

    # 9) 관리용 Alias/함수 등록
    if ! grep -q "slamnav2-save" "$HOME_DIR/.bashrc" 2>/dev/null; then
        log "관리용 명령어(Alias & Function)를 ~/.bashrc 에 추가합니다."
        cat >> "$HOME_DIR/.bashrc" <<'EOF'

# === SLAMNAV2 관리 도구 ===
alias slamnav2-status='systemctl status slamnav2.service --no-pager'
alias slamnav2-logs='journalctl -u slamnav2.service -f -o cat'
alias slamnav2-restart='sudo systemctl restart slamnav2.service'
alias slamnav2-stop='sudo systemctl stop slamnav2.service'

# 비정상 종료 원인 분석(화면 출력용)
alias slamnav2-why='echo "=== SYSTEMD STATUS ==="; systemctl status slamnav2.service; echo -e "\n=== RECENT LOGS (SYSTEM) ==="; journalctl -u slamnav2.service -n 50; echo -e "\n=== KERNEL ERRORS (OOM/SEGV) ==="; dmesg | tail -n 50 | grep -iE "kill|segfault|error|slamnav2"'

# 로그 파일로 저장(저장 경로: ~/slamnav2_logs)
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
        chown "$USER_NAME":"$USER_NAME" "$HOME_DIR/.bashrc" 2>/dev/null || true
        log "새로운 명령어가 추가되었습니다."
    else
        warn "이미 ~/.bashrc 에 slamnav2 관리 설정이 있습니다. 추가를 건너뜁니다."
    fi

    echo
    log "✅ 설치 완료!"
    log "상태 확인:  systemctl status $SERVICE_NAME"
    log "로그 보기:  journalctl -u $SERVICE_NAME -f"
    log "alias 적용: 새 터미널을 열거나 'source ~/.bashrc' 실행"
    warn "GUI 자동실행은 '자동로그인'이 켜져 있어야 화면에 표시됩니다."
}

# ==========================================
# 2. 삭제(Uninstall)
# ==========================================
do_uninstall() {
    log "SLAMNAV2 서비스 제거..."
    systemctl stop "$SERVICE_NAME" 2>/dev/null || true
    systemctl disable "$SERVICE_NAME" 2>/dev/null || true

    rm -f "$SERVICE_FILE"
    rm -rf "$CONF_DIR"

    systemctl daemon-reload
    systemctl reset-failed 2>/dev/null || true

    echo
    warn "~/.bashrc 의 alias/함수는 자동으로 삭제되지 않습니다."
    warn "직접 'vi ~/.bashrc' 로 열어 'SLAMNAV2 관리 도구' 블록을 지워주세요."
    log "✅ 서비스 제거 완료."
}

# ==========================================
# 메인 메뉴
# ==========================================
echo "========================================"
echo "   SLAMNAV2 Systemd Service Manager"
echo "   (run.sh 기반 / 부팅 GUI 자동실행)"
echo "========================================"
PS3="작업 선택: "
options=("설치/업데이트" "서비스 제거" "종료")
select opt in "${options[@]}"; do
    case "${opt:-}" in
        "설치/업데이트") do_install; break ;;
        "서비스 제거")   do_uninstall; break ;;
        "종료")          exit 0 ;;
        *) echo "잘못된 선택입니다." ;;
    esac
done
