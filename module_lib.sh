#!/bin/bash
# module_lib.sh: 라이브러리 관련 도구 설치 모듈
# htop과 net-tools를 설치합니다.

source ./common.sh

echo "========================================"
echo "라이브러리 모듈: htop 및 net-tools 설치"
echo "========================================"

# htop 설치: 이미 설치되어 있으면 건너뜁니다.
run_step "htop 설치" \
    "dpkg -s htop &> /dev/null" \
    "sudo apt-get install htop -y"

# net-tools 설치: 이미 설치되어 있으면 건너뜁니다.
run_step "net-tools 설치" \
    "dpkg -s net-tools &> /dev/null" \
    "sudo apt-get install net-tools -y"

