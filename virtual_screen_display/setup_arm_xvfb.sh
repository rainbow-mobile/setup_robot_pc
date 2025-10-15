#!/bin/bash

# 이 스크립트는 ARM 기반 시스템에서 Xvfb 가상 디스플레이 환경을 설정하거나 제거합니다.

# --- 함수 정의 ---

# ARM 환경 설치 함수
install_arm_setup() {
    # 1단계: Xvfb 설치
    echo "Xvfb를 설치합니다..."
    sudo apt update
    sudo apt install -y xvfb

    # 2단계: 애플리케이션 실행 스크립트 생성
    echo "SLAMNAV2 실행 스크립트를 ~/slamnav2/slamnav2.sh 경로에 생성합니다..."
    mkdir -p ~/slamnav2

    cat > ~/slamnav2/slamnav2.sh <<'EOF'
#!/bin/bash
export DISPLAY=:99
cd ~/slamnav2
if [ -f "./SLAMNAV2" ]; then
    ./SLAMNAV2
else
    echo "오류: ~/slamnav2 디렉토리에서 SLAMNAV2 실행 파일을 찾을 수 없습니다." >&2
    exit 1
fi
EOF

    chmod +x ~/slamnav2/slamnav2.sh
    echo "~/slamnav2/slamnav2.sh 스크립트 생성 및 실행 권한 부여 완료."

    # 3단계: PM2로 애플리케이션 관리
    echo "PM2로 SLAMNAV2 스크립트를 관리하도록 설정합니다..."
    if ! command -v pm2 &> /dev/null; then
        echo "pm2를 찾을 수 없습니다. 먼저 Node.js와 npm을 설치한 후 'sudo npm install pm2 -g' 명령어로 pm2를 설치해주세요."
        exit 1
    fi

    pm2 delete SLAMNAV2 || echo "삭제할 기존 프로세스가 없습니다. 계속 진행합니다."
    pm2 start ~/slamnav2/slamnav2.sh --name SLAMNAV2
    pm2 save
    echo "부팅 시 PM2가 자동으로 시작되도록 설정합니다..."
    echo "PM2 자동 실행 설정을 완료하려면, 아래 'pm2 startup' 명령어가 출력하는 명령어를 복사하여 실행해주세요."
    pm2 startup

    # 4단계: Xvfb를 위한 systemd 서비스 생성
    echo "부팅 시 Xvfb가 자동으로 실행되도록 systemd 서비스를 생성합니다..."
    CURRENT_USER=$(whoami)
    echo "Xvfb 서비스의 실행 사용자를 '$CURRENT_USER'로 설정합니다."

    sudo tee /etc/systemd/system/xvfb.service > /dev/null <<EOF
[Unit]
Description=Virtual X Display for Headless Applications
After=network.target

[Service]
ExecStart=/usr/bin/Xvfb :99 -screen 0 1280x1024x24
Restart=always
User=${CURRENT_USER}
Environment=DISPLAY=:99

[Install]
WantedBy=multi-user.target
EOF

    echo "systemd 데몬을 다시 로드합니다..."
    sudo systemctl daemon-reexec
    sudo systemctl daemon-reload

    echo "xvfb.service를 활성화하고 시작합니다..."
    sudo systemctl enable xvfb.service
    sudo systemctl start xvfb.service

    echo "xvfb 서비스 상태를 확인합니다..."
    systemctl status xvfb.service

    echo "ARM 환경 설치가 완료되었습니다."
}

# ARM 환경 제거 함수
uninstall_arm_setup() {
    echo "ARM 가상 환경 제거를 시작합니다..."

    # 1단계: PM2에서 애플리케이션 제거
    if command -v pm2 &> /dev/null; then
        echo "PM2에서 SLAMNAV2 프로세스를 중지하고 삭제합니다..."
        pm2 stop SLAMNAV2 || true
        pm2 delete SLAMNAV2 || true
        pm2 save
        echo "PM2 설정을 저장했습니다."
    else
        echo "PM2가 설치되어 있지 않아 관련 작업을 건너뜁니다."
    fi

    # 2단계: Xvfb systemd 서비스 제거
    echo "xvfb systemd 서비스를 중지하고 비활성화합니다..."
    sudo systemctl stop xvfb.service || true
    sudo systemctl disable xvfb.service || true

    echo "/etc/systemd/system/xvfb.service 파일을 삭제합니다..."
    sudo rm -f /etc/systemd/system/xvfb.service

    echo "systemd 데몬을 다시 로드합니다..."
    sudo systemctl daemon-reexec
    sudo systemctl daemon-reload

    # 3단계: 생성된 스크립트 파일 제거
    echo "~/slamnav2/slamnav2.sh 실행 스크립트를 삭제합니다..."
    rm -f ~/slamnav2/slamnav2.sh

    # 4단계: Xvfb 패키지 제거 (사용자 확인)
    read -p "Xvfb 패키지를 시스템에서 제거하시겠습니까? (y/N) " confirm_remove
    if [[ "$confirm_remove" =~ ^[yY]([eE][sS])?$ ]]; then
        echo "Xvfb 패키지를 제거합니다..."
        sudo apt-get remove --purge -y xvfb
    else
        echo "Xvfb 패키지를 제거하지 않았습니다."
    fi

    echo "제거 작업이 완료되었습니다."
}


# --- 메인 스크립트 실행 ---

# 명령어 실행 중 오류가 발생하면 즉시 스크립트를 종료합니다.
set -e

echo "ARM Xvfb 가상 모니터 및 PM2 관리 설정을 시작합니다."
echo "원하는 작업을 선택해주세요:"
select choice in "설치 (Install)" "삭제 (Uninstall)" "취소 (Cancel)"; do
    case $choice in
        "설치 (Install)")
            install_arm_setup
            break
            ;;
        "삭제 (Uninstall)")
            uninstall_arm_setup
            break
            ;;
        "취소 (Cancel)")
            echo "작업을 취소했습니다."
            break
            ;;
        *)
            echo "잘못된 선택입니다. 1, 2, 3 중에서 선택해주세요."
            ;;
    esac
done


