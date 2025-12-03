# setup_robot_pc

--- 
### Ubuntu 22.04/5이 설치된 PC 기준

-  SLAMNAV2 개발환경 및 구동을 위한 스크립트
1. setup_system_build_env_s100-2.sh
2. setup_sensor2.sh
3. setup_programs_slamanv_shortcut.sh
4. set_teamviewer.sh
5. install_udev_rules.sh
---
### Note
- 개발환경이 아니라면, 2번은 skip 가능.
- 순차적으로 진행할것.
- 1번에서 설치 항목에서 실패하는것들이 있다면, 1번 스크립트를 다시 실행. (개발환경 PC의 경우 USB관련 설정에 관한 실패는 skip가능)
--- 

# 패키지 설치 및 모듈 사용법

### rb_modbus - 신규 생성
    
    setup_modbus_root.sh
    
    - 모드버스 설치 및 자동 실행
    - 모드버스 프로그램 관리 명령어
        - modbus-status
        - modbus-logs
        - modbus-restart
        - modbus-stop
        - modbus-start
        
### rb_sn - SLAMNAV2 관련 설치
    
    vx_setup_slamnav2_xxxxxx.sh
    
    - light - target: 로봇 최소한을 위한 설치
    - full - target : build를 위한 설치
    
### rb_sn/system
    
    vx_setup_pm2_2_systemd_slamnav2_xxxxxx.sh

    - pm2를 제거하고 systemd에서 관리 시작 (설치 / 제거)
    - SLAMNAV2 관리 명령어
        - slamnav2-status
        - slamnav2-logs
        - slamnav2-restart
        - slamnav2-stop
        - slamnav2-save
            - “/home/rainbow/slamnav2_logs” 경로에 파일 생성
            - 최근 100줄에 대해서 저장
