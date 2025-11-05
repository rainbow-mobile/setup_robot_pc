#!/bin/bash
# 모든 Docker 관련 항목 제거 스크립트

set -e

echo "=== 모든 항목 제거 시작 ==="

# 컨테이너 중지 및 삭제
echo "컨테이너 중지 및 삭제 중..."
docker ps -aq | xargs -r docker rm -f 2>/dev/null || true
docker ps -a

# 이미지 삭제
echo "이미지 삭제 중..."
docker images -q | xargs -r docker rmi -f 2>/dev/null || true
docker images

# 볼륨 삭제 (선택사항)
read -p "볼륨도 삭제하시겠습니까? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker volume ls -q | xargs -r docker volume rm 2>/dev/null || true
fi

# 네트워크 삭제 (사용자 정의 네트워크만)
docker network prune -f

# Docker 제거 (선택사항)
read -p "Docker 자체를 제거하시겠습니까? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ "$EUID" -ne 0 ]; then 
        echo "Docker 제거는 sudo 권한이 필요합니다."
        exit 1
    fi
    
    systemctl stop docker 2>/dev/null || true
    apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null || true
    apt-get autoremove -y 2>/dev/null || true
    
    echo "✓ Docker 제거 완료"
fi

# 설치 디렉토리 삭제
INSTALL_DIR="$HOME/.local/share/docker_manager_appimage"
if [ -d "$INSTALL_DIR" ]; then
    read -p "설치 디렉토리 ($INSTALL_DIR)를 삭제하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$INSTALL_DIR"
        echo "✓ 설치 디렉토리 삭제 완료"
    fi
fi

echo "=== 제거 완료 ==="

