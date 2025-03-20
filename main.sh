#!/bin/bash
# main.sh: 전체 모듈 실행 스크립트

# nohup 체크: 스크립트가 백그라운드에서 실행되고 있지 않다면 재실행
if [ "${NOHUP_EXECUTED}" != "true" ]; then
    echo "스크립트를 백그라운드에서 안전하게 실행합니다..."
    export NOHUP_EXECUTED=true
    nohup bash "$0" > setup_log.txt 2>&1 &
    echo "설치가 백그라운드에서 진행됩니다."
    echo "로그 확인: tail -f setup_log.txt"
    exit 0
fi

# 공통 모듈: 각 모듈은 개별적으로 common.sh를 소스하지만, 전체 실행 환경을 위해 한 번 로드해도 좋습니다.
source ./common.sh

# 모듈 실행 (각 모듈은 동일 셸에서 실행되어 결과 배열을 공유)
source ./module_system_update.sh
source ./module_system_config.sh
source ./module_swapfile.sh
source ./module_wireless_driver.sh
#source ./module_slamnav2.sh

# 팀뷰어 설치 (TeamViewer 설치 모듈)
source ./module_teamviewer_install.sh

# 팀뷰어 리셋 및 Wayland 설정 변경 모듈
source ./module_teamviewer.sh

source ./module_orbbec.sh
source ./module_usb_serial.sh
source ./module_udev.sh
source ./module_screen.sh
source ./module_autologin.sh
source ./module_extra.sh

# 최종 설치 결과 요약 및 재부팅 안내 모듈
source ./summary_reboot.sh

