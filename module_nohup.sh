#!/bin/bash
# module_nohup.sh: 스크립트가 이미 백그라운드 실행 중인지 검사

if [ "${NOHUP_EXECUTED}" != "true" ]; then
    echo "스크립트를 백그라운드에서 안전하게 실행합니다..."
    export NOHUP_EXECUTED=true
    nohup bash "$0" > setup_log.txt 2>&1 &
    echo "설치가 백그라운드에서 진행됩니다."
    echo "로그 확인: tail -f setup_log.txt"
    exit 0
fi

