#!/bin/bash
# Docker 설치 스크립트
# 스크립트 실행 중 오류 발생 시 종료
set -e

# 패키지 목록 업데이트
sudo apt-get update

# Docker 설치에 필요한 패키지 설치
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common

# Docker 공식 GPG 키 추가
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Docker 저장소 추가 (Ubuntu 릴리즈 버전에 따라 자동 설정)
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# 패키지 목록 다시 업데이트
sudo apt-get update

# Docker 엔진 설치
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

