#!/bin/bash
cd /home/rainbow/fms2

# GUI 환경 보장
export DISPLAY=:99
export QT_QPA_PLATFORM=xcb

# 라이브러리 경로 설정 (필요시 경로 추가)
#export LD_LIBRARY_PATH=/usr/local/lib:/opt/opencv/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/home/rainbow/fms2:$LD_LIBRARY_PATH


# 실행
exec ./FMS2

