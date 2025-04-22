#!/bin/bash
# ~/.bashrc 에 LD_LIBRARY_PATH 경로를 추가하는 스크립트

BASHRC="$HOME/.bashrc"
PATHS=(
  "export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:/home/rainbow/slamnav2"
  "export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:/home/rainbow/fms2"
)

for line in "${PATHS[@]}"; do
  # 이미 동일한 라인이 있는지 확인 후, 없으면 추가
  if ! grep -Fxq "$line" "$BASHRC"; then
    echo "$line" >> "$BASHRC"
    echo "추가됨: $line"
  else
    echo "이미 존재함: $line"
  fi
done

echo "완료! 변경사항을 적용하려면 다음을 실행하세요:"
echo "  source ~/.bashrc"

