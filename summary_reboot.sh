#!/bin/bash
# summary_reboot.sh: 설치 결과 요약 및 재부팅 안내

source ./common.sh

echo "========================================"
echo "설치 요약"
echo "========================================"
echo "설치 완료된 항목:"
for item in "${INSTALLED[@]}"; do
    echo " - $item"
done

echo "이미 설치되어 건너뛴 항목:"
for item in "${SKIPPED[@]}"; do
    echo " - $item"
done

echo "설치 실패한 항목:"
for item in "${FAILED[@]}"; do
    echo " - $item"
done

echo "========================================"
echo "모든 작업이 완료되었습니다."
echo "※ 주의: USB 시리얼 설정의 변경사항(특히 dialout 그룹 추가)은 재부팅 후 적용됩니다."
read -p "재부팅하려면 엔터키를 누르세요..."
sudo reboot

