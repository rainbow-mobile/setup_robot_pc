#!/bin/bash
# module_orbbec.sh: 환경 변수 재적용 및 OrbbecSDK 경로 업데이트

source ./common.sh

echo "========================================"
echo "환경 변수 재적용 및 OrbbecSDK 경로 업데이트"
echo "========================================"

run_step "Update OrbbecSDK path in /etc/profile" \
    "grep 'OrbbecSDK/SDK/lib' /etc/profile &> /dev/null" \
    "sudo sh -c 'echo \"export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:/home/rainbow/OrbbecSDK/SDK/lib\" >> /etc/profile'"

run_step "Apply profile changes" \
    "true" \
    "source /etc/profile && source /etc/profile && sudo ldconfig && source ~/.bashrc"

