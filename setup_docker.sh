#!/usr/bin/env bash
# install_docker_ubuntu.sh
# Ubuntu에 Docker CE를 설치하고 사용자 권한을 설정하는 스크립트
set -euo pipefail
IFS=$'\n\t'

# 스크립트를 root로 실행했는지 확인
if [[ $EUID -ne 0 ]]; then
  echo "❗ 이 스크립트는 sudo 또는 root 권한으로 실행해야 합니다." >&2
  exit 1
fi

# 로그인 사용자를 찾고 HOME 디렉터리 설정
REAL_USER=${SUDO_USER:-$(logname)}
USER_HOME=$(eval echo "~${REAL_USER}")

echo "🐳 Docker 설치 스크립트 시작"
echo "   대상 사용자: ${REAL_USER}"

# 1. 기존 Docker 설치 제거 (있는 경우)
echo "1) 기존 Docker 패키지 제거..."
apt remove -y docker docker-engine docker.io containerd runc >/dev/null 2>&1 || true

# 2. 필수 패키지 설치
echo "2) HTTPS 전송용 apt 패키지 설치..."
apt update -qq
apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# 3. Docker 공식 GPG 키 추가
echo "3) Docker 공식 GPG 키 등록..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  gpg --dearmor -o /etc/apt/keyrings/docker.gpg

chmod a+r /etc/apt/keyrings/docker.gpg

# 4. Docker 저장소 설정
echo "4) Docker apt 저장소 추가..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null

# 5. Docker CE 설치
echo "5) Docker Engine 설치..."
apt update -qq
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 6. Docker 서비스 활성화 및 시작
echo "6) Docker 서비스 활성화 및 시작..."
systemctl enable docker
systemctl start docker

# 7. docker 그룹에 사용자 추가
echo "7) '${REAL_USER}' 사용자를 'docker' 그룹에 추가..."
usermod -aG docker "${REAL_USER}"

# 8. 설치 확인
echo "8) 설치 확인: 'docker --version' 출력"
docker --version

echo
echo "✅ Docker 설치 및 설정이 완료되었습니다."
echo "   * 로그아웃 후 다시 로그인하면 sudo 없이 docker 명령을 사용할 수 있습니다."
echo "   * 설치된 Docker 버전을 꼭 확인해 주세요."

