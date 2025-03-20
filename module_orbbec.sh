#!/bin/bash
# module_orbbec.sh: OrbbecSDK 관련 환경 변수 설정을 /etc/profile에 추가하고 적용하는 스크립트
# 추가할 내용:
#   export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/lib
#   export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/home/rainbow/rplidar_sdk/output/Linux/Release 
#   export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/home/rainbow/OrbbecSDK/SDK/lib
#
# 적용 후, /etc/profile을 두 번 소스하고, sudo ldconfig 실행, 그리고 ~/.bashrc도 소스합니다.

source ./common.sh

echo "========================================"
echo "환경 변수 재적용 및 /etc/profile 업데이트 (OrbbecSDK 관련)"
echo "========================================"

# /etc/profile 파일에 필요한 LD_LIBRARY_PATH 라인이 모두 추가되어 있는지 확인합니다.
# 만약 하나라도 없으면 아래 내용을 추가합니다.
run_step "Append LD_LIBRARY_PATH to /etc/profile" \
    "grep '/usr/local/lib' /etc/profile && grep '/home/rainbow/rplidar_sdk/output/Linux/Release' /etc/profile && grep '/home/rainbow/slamnav2' /etc/profile" \
    "sudo sh -c 'cat >> /etc/profile <<EOF
export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:/usr/local/lib
export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:/home/rainbow/rplidar_sdk/output/Linux/Release
export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:/home/rainbow/slamnav2
EOF'"

# 변경사항을 즉시 적용합니다.
run_step "Apply profile changes" \
    "true" \
    "source /etc/profile && source /etc/profile && sudo ldconfig && source ~/.bashrc"

