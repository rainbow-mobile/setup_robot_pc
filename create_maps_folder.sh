#!/bin/bash
# create_maps_folder.sh: /home 디렉토리에 maps 폴더 생성 스크립트

TARGET_DIR="/home/maps"

if [ -d "$TARGET_DIR" ]; then
    echo "[$TARGET_DIR] 디렉토리가 이미 존재합니다."
else
    echo "[$TARGET_DIR] 디렉토리가 존재하지 않습니다. 생성합니다..."
    sudo mkdir -p "$TARGET_DIR"
    if [ $? -eq 0 ]; then
        echo "[$TARGET_DIR] 디렉토리가 성공적으로 생성되었습니다."
    else
        echo "[$TARGET_DIR] 디렉토리 생성에 실패했습니다."
    fi
fi

