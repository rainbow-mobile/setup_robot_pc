#!/bin/bash
# module_orbbec.sh: OrbbecSDK 관련 환경 변수 설정을 /etc/profile에 추가하고 적용하는 스크립트
# 추가할 내용:
#   export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/lib
#   export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/home/rainbow/rplidar_sdk/output/Linux/Release
#   export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/home/rainbow/OrbbecSDK/SDK/lib
#
# 이미 /etc/profile에 이 내용이 있다면 추가하지 않고 넘어갑니다.
# 변경사항 적용 후 /etc/profile을 두 번 소스하고, sudo ldconfig 실행, 그리고 ~/.bashrc도 소스합니다.
#
# 마지막에 추가로 install_udev_rules.sh 스크립트를 실행합니다.

source ./common.sh

echo "========================================"
echo "환경 변수 재적용 및 /etc/profile 업데이트 (OrbbecSDK 관련)"
echo "========================================"

# /etc/profile에 필요한 LD_LIBRARY_PATH 라인이 이미 존재하는지 확인
if grep -q '/usr/local/lib' /etc/profile && \
   grep -q '/home/rainbow/rplidar_sdk/output/Linux/Release' /etc/profile && \
   grep -q '/home/rainbow/OrbbecSDK/SDK/lib' /etc/profile; then
    log_msg "필요한 LD_LIBRARY_PATH 라인이 /etc/profile에 이미 존재합니다. 추가하지 않습니다."
else
    log_msg "LD_LIBRARY_PATH 라인이 /etc/profile에 존재하지 않으므로 추가합니다."
    sudo sh -c 'cat >> /etc/profile <<EOF
export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:/usr/local/lib
export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:/home/rainbow/rplidar_sdk/output/Linux/Release
export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:/home/rainbow/slamnav2
EOF'
fi

# 변경사항 적용: /etc/profile 두 번 소스, ldconfig 실행, ~/.bashrc 소스
run_step "Apply profile changes" \
    "true" \
    "source /etc/profile && source /etc/profile && sudo ldconfig && source ~/.bashrc"

echo "========================================"
echo "install_udev_rules.sh 스크립트 실행"
echo "========================================"

# install_udev_rules.sh 스크립트가 존재하면 실행, 없으면 건너뜁니다.
if [ -f "./install_udev_rules.sh" ]; then
    log_msg "install_udev_rules.sh 스크립트를 실행합니다."
    bash ./install_udev_rules.sh
    if [ $? -eq 0 ]; then
        log_msg "install_udev_rules.sh 실행 완료."
    else
        log_msg "install_udev_rules.sh 실행 중 오류 발생."
    fi
else
    log_msg "install_udev_rules.sh 파일이 존재하지 않습니다. 스크립트를 건너뜁니다."
fi

