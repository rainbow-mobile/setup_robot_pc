#!/bin/bash

# FMS2 자동 실행 루프 스크립트
# 경로: ~/run_fms.sh

# FMS 바이너리가 있는 디렉토리로 이동
cd ~/fms || {
  echo "FMS 디렉토리로 이동 실패"; exit 1;
}

# LD_LIBRARY_PATH 설정
export LD_LIBRARY_PATH=$(pwd):$LD_LIBRARY_PATH

echo "[$(date '+%Y-%m-%d %H:%M:%S')] FMS2 자동 실행 스크립트 시작"

while true
do
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] FMS2 실행 중..."
    ./FMS2

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] FMS2가 종료되었습니다. 5초 후 재시작합니다."
    sleep 5
done

