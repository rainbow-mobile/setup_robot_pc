#!/bin/bash
# main2.sh: 전체 모듈 실행 스크립트 (포그라운드 실행)
# 각 모듈을 별도 프로세스로 실행하여, 모듈 중 하나의 exit나 오류로 인해 전체 실행이 중단되지 않도록 합니다.
# 만약 설치 실패한 모듈이 하나라도 있다면, "sudo dpkg --configure -a"를 실행한 후 실패한 모듈만 다시 설치합니다.

# 먼저 sudo 인증을 받아 sudo 세션을 갱신합니다.
sudo -v

# sudo 인증 유지 (인터랙티브 환경에서 실행)
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# 실행할 모듈 목록 (모든 모듈은 현재 디렉토리에 있다고 가정)
modules=(
  #"module_teamviewer.sh"
  "module_system_update.sh"
  "module_system_config.sh"
  "module_swapfile.sh"
  "module_wireless_driver.sh"
  "module_orbbec.sh"
  "module_usb_serial.sh"
  "module_udev.sh"
  "module_screen.sh"
  "module_extra.sh"
  "module_lib.sh"
  "create_maps_folder.sh"
  "module_slamnav2_lite.sh"
  "module_program.sh"
  
)

# 배열에 실패한 모듈 이름을 저장
failedModules=()

for mod in "${modules[@]}"; do
    if [ -f "$mod" ]; then
        echo "========================================"
        echo "실행 중: $mod"
        echo "========================================"
        # 각 모듈을 별도 프로세스로 실행합니다.
        bash "$mod"
        ret=$?
        if [ $ret -ne 0 ]; then
            echo "[$mod] 실행 중 오류 발생 (종료 코드: $ret), 계속 진행합니다."
            failedModules+=("$mod")
        fi
    else
        echo "[$mod] 파일을 찾을 수 없습니다."
    fi
done

# 실패한 모듈이 하나라도 있다면 dpkg 설정 재구성 후 재실행
if [ ${#failedModules[@]} -ne 0 ]; then
    echo "========================================"
    echo "설치 실패한 모듈이 있으므로, sudo dpkg --configure -a 를 실행합니다."
    echo "========================================"
    sudo dpkg --configure -a

    echo "=========================

