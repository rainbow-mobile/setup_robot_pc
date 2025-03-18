#!/bin/bash
# module_extra.sh: 추가 환경 설정 (예: 추가 환경 변수 재적용 등)

source ./common.sh

echo "========================================"
echo "추가 환경 설정"
echo "========================================"

run_step "추가 환경 변수 재적용" \
    "true" \
    "sudo sh -c 'echo \"export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:/usr/local/lib\" >> /etc/profile' && sudo sh -c 'echo \"export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:\$HOME/rplidar_sdk/output/Linux/Release\" >> /etc/profile' && sudo sh -c 'echo \"export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:\$HOME/OrbbecSDK/lib/linux_x64\" >> /etc/profile' && source /etc/profile && sudo ldconfig"

