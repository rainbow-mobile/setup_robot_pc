#!/bin/bash
# main.sh: 전체 모듈 실행 스크립트 (포그라운드 실행)
# 각 모듈을 별도 프로세스로 실행하여, 모듈 중 하나의 exit나 오류로 인해 전체 실행이 중단되지 않도록 합니다.

# 먼저 sudo 인증을 받아 sudo 세션을 갱신합니다.
sudo -v

# sudo 인증 유지 (인터랙티브 환경에서 실행)
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# 실행할 모듈 목록 (모든 모듈은 현재 디렉토리에 있다고 가정)
modules=(
  "module_system_update.sh"
  "module_system_config.sh"
  "module_swapfile.sh"
  "module_wireless_driver.sh"
  "module_slamnav2.sh"
  "module_teamviewer_install.sh"
  "module_teamviewer.sh"
  "module_orbbec.sh"
  "module_usb_serial.sh"
  "module_udev.sh"
  "module_screen.sh"
  "module_autologin.sh"
  "module_extra.sh"
  "module_lib.sh"
  "create_maps_folder.sh"
)

for mod in "${modules[@]}"; do
    if [ -f "$mod" ]; then
        echo "========================================"
        echo "실행 중: $mod"
        echo "========================================"
        # 각 모듈을 별도 프로세스로 실행합니다.
        bash "$mod"
        if [ $? -ne 0 ]; then
            echo "[$mod] 실행 중 오류 발생, 계속 진행합니다."
        fi
    else
        echo "[$mod] 파일을 찾을 수 없습니다."
    fi
done

# 최종 설치 결과 요약 및 재부팅 안내 (공유 환경이 필요하면 이 부분은 source 방식으로 수정)
if [ -f "summary_reboot.sh" ]; then
    echo "========================================"
    echo "최종 설치 결과 요약 및 재부팅 안내"
    echo "========================================"
    source ./summary_reboot.sh
else
    echo "summary_reboot.sh 파일을 찾을 수 없습니다."
fi

