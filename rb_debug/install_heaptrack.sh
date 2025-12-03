#!/bin/bash
set -e  # 에러 발생 시 즉시 중단

# 색상 정의 (출력 메시지용)
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}[INFO] 패키지 목록 업데이트 중...${NC}"
sudo apt update

echo -e "${GREEN}[INFO] Heaptrack 및 GUI 설치 시작...${NC}"
# -y 옵션: 설치 여부 질문에 자동으로 Yes 응답
sudo apt install -y heaptrack heaptrack-gui

# 설치 확인
if command -v heaptrack &> /dev/null; then
    echo -e "${GREEN}[SUCCESS] Heaptrack 설치가 완료되었습니다.${NC}"
    echo "실행 방법:"
    echo "  1. 데이터 수집: heaptrack <프로그램명>"
    echo "  2. GUI 분석:    heaptrack_gui <결과파일.zst>"
else
    echo -e "\033[0;31m[ERROR] 설치에 실패했습니다. 로그를 확인해주세요.${NC}"
    exit 1
fi
