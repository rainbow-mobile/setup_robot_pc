#!/bin/bash
# module_orbbec.sh: 환경 변수 재적용 및 /etc/profile 업데이트 (OrbbecSDK, rplidar_sdk, /usr/local/lib 경로 추가)

source ./common.sh

echo "========================================"
echo "환경 변수 재적용 및 /etc/profile 업데이트"
echo "========================================"

# /etc/profile에 필요한 LD_LIBRARY_PATH 라인이 이미 있는지 확인합니다.
# 세 가지 라인 모두 존재하면 건너뛰고, 하나라도 없으면 추가합니다.
run_step "Append LD_LIBRARY_PATH to /etc/profile" \
    "grep '/usr/local/lib' /etc/profile && grep '/home/rainbow/rplidar_sdk/output/Linux/Release' /etc/profile && grep '/home/rainbow/OrbbecSDK/SDK/lib' /etc/profile" \
    "sudo sh -c 'cat >> /etc/profile <<EOF
export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:/usr/local/lib
export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:/home/rainbow/rplidar_sdk/output/Linux/Release
export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:/home/rainbow/OrbbecSDK/SDK/lib
EOF'"

# 프로파일 변경사항 적용: /etc/profile 두 번 소스, ldconfig 실행, ~/.bashrc 소스
run_step "Apply profile changes" \
    "true" \
    "source /etc/profile && source /etc/profile && sudo ldconfig && source ~/.bashrc"

