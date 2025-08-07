#!/bin/bash
cd /home/odroid/slamnav2

# GUI 환경 보장
export DISPLAY=:0
export QT_QPA_PLATFORM=xcb

# 라이브러리 경로 설정 (필요시 경로 추가)
#export LD_LIBRARY_PATH=/usr/local/lib:/opt/opencv/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/home/odroid/slamnav2:$LD_LIBRARY_PATH


# 실행
exec ./SLAMNAV2

