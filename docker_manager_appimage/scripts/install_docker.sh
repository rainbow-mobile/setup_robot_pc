#!/bin/bash
# Docker 설치 스크립트
# Ubuntu 및 Windows (WSL)에서 Docker를 설치합니다.

set -e

echo "=== Docker 설치 시작 ==="

# OS 확인
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS_TYPE="linux"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    OS_TYPE="windows"
else
    echo "지원하지 않는 OS: $OSTYPE"
    exit 1
fi

# Docker가 이미 설치되어 있는지 확인
if command -v docker &> /dev/null; then
    echo "✓ Docker가 이미 설치되어 있습니다."
    docker --version
    exit 0
fi

# Linux (Ubuntu/WSL) 설치
if [ "$OS_TYPE" == "linux" ]; then
    echo "Linux에서 Docker 설치 중..."
    
    # sudo 권한 확인
    if [ "$EUID" -ne 0 ]; then 
        echo "이 스크립트는 sudo 권한으로 실행해야 합니다."
        exit 1
    fi
    
    # 기존 Docker 제거
    apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # 필수 패키지 설치
    apt-get update -qq
    apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    
    # Docker GPG 키 추가
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
        gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    
    # Docker 저장소 추가
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Docker 설치
    apt-get update -qq
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Docker 서비스 시작
    systemctl enable docker
    systemctl start docker
    
    # 현재 사용자를 docker 그룹에 추가
    REAL_USER=${SUDO_USER:-$USER}
    if [ -n "$REAL_USER" ] && [ "$REAL_USER" != "root" ]; then
        usermod -aG docker "$REAL_USER"
        echo "✓ 사용자 '$REAL_USER'를 docker 그룹에 추가했습니다."
        echo "  로그아웃 후 다시 로그인하면 sudo 없이 docker를 사용할 수 있습니다."
    fi
    
    echo "✓ Docker 설치 완료"
    docker --version

# Windows (Docker Desktop)
elif [ "$OS_TYPE" == "windows" ]; then
    echo "Windows에서는 Docker Desktop을 설치해야 합니다."
    echo "다음 링크에서 Docker Desktop을 다운로드하세요:"
    echo "https://www.docker.com/products/docker-desktop"
    echo ""
    echo "또는 WSL2를 사용하는 경우, Linux 설치 방법을 따르세요."
    exit 1
fi

echo "=== Docker 설치 완료 ==="

