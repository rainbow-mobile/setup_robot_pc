#!/bin/bash
# main.sh: 전체 모듈 실행 스크립트 (포그라운드 실행)

# 먼저 sudo 인증을 받아 sudo 세션을 갱신합니다.
sudo -v

# sudo 인증 유지 (백그라운드 실행 없이 인터랙티브 환경에서 실행)
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# 공통 모듈 로드
source ./common.sh

# 모듈 실행 (각 모듈은 동일 셸에서 실행되어 결과 배열을 공유)
source ./module_system_update.sh
source ./module_system_config.sh
source ./module_swapfile.sh
source ./module_wireless_driver.sh
source ./module_slamnav2.sh

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

# 라이브러리 설치
source ./module_lib.sh

# maps폴더 생성
source ./create_maps_folder.sh

# 최종 설치 결과 요약 및 재부팅 안내 모듈
source ./summary_reboot.sh

