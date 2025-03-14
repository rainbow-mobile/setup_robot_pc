#!/bin/bash
set -e

# --- 진단 리포지토리 작업 (설치 경로: $HOME/diagnosis) ---
if [ ! -d "$HOME/diagnosis" ]; then
    echo "[diagnosis] 리포지토리 클론 중..."
    git clone https://github.com/rainbow-mobile/diagnosis.git "$HOME/diagnosis"
else
    echo "[diagnosis] 리포지토리가 이미 존재합니다. 최신 상태로 업데이트합니다."
    cd "$HOME/diagnosis" && git pull && cd -
fi

# 바탕화면 경로 설정 (영어 환경: ~/Desktop, 한글 환경: ~/바탕화면)
DESKTOP_DIR="$HOME/Desktop"
if [ ! -d "$DESKTOP_DIR" ]; then
    if [ -d "$HOME/바탕화면" ]; then
        DESKTOP_DIR="$HOME/바탕화면"
    else
        echo "바탕화면 디렉토리를 찾을 수 없습니다. DESKTOP_DIR 변수를 확인하세요."
        exit 1
    fi
fi

# diagnosis 리포지토리 내 .desktop 파일을 바탕화면으로 복사
echo "[diagnosis] SLAMNAV2.desktop과 diagnositc.desktop 파일을 바탕화면으로 복사합니다."
cp "$HOME/diagnosis/SLAMNAV2.desktop" "$DESKTOP_DIR/"
cp "$HOME/diagnosis/diagnositc.desktop" "$DESKTOP_DIR/"

# diagnosis 리포지토리 내 스크립트 파일을 홈으로 복사
echo "[diagnosis] diagnositc.sh와 slamnav2.sh 파일을 홈 디렉토리로 복사합니다."
cp "$HOME/diagnosis/diagnositc.sh" "$HOME/"
cp "$HOME/diagnosis/slamnav2.sh" "$HOME/"

# .desktop 파일의 아이콘 잠금(자물쇠)을 터미널 명령으로 해제
echo "[diagnosis] .desktop 파일의 잠금을 해제합니다."
gio set "$DESKTOP_DIR/SLAMNAV2.desktop" metadata::trusted true
gio set "$DESKTOP_DIR/diagnositc.desktop" metadata::trusted true

echo "[diagnosis] 진단 리포지토리 작업 완료."

# --- slamnav2 리포지토리 작업 (설치 경로: $HOME/slamnav2) ---
if [ ! -d "$HOME/slamnav2" ]; then
    echo "[slamnav2] 리포지토리 클론 중..."
    git clone https://github.com/rainbow-mobile/slamnav2.git "$HOME/slamnav2"
else
    echo "[slamnav2] 리포지토리가 이미 존재합니다. 최신 상태로 업데이트합니다."
    cd "$HOME/slamnav2" && git pull && cd -
fi

cd "$HOME/slamnav2"

echo "[slamnav2] 원격 브랜치 목록:"
# 원격 브랜치 목록을 가져와 번호로 출력
remote_branches=($(git branch -r | sed 's/ *origin\///' | grep -v 'HEAD'))
for i in "${!remote_branches[@]}"; do
    echo "$((i+1)). ${remote_branches[i]}"
done

# 사용자에게 번호 입력 받기
read -p "체크아웃할 브랜치 번호를 선택하세요: " branch_number

if ! [[ "$branch_number" =~ ^[0-9]+$ ]] || [ "$branch_number" -lt 1 ] || [ "$branch_number" -gt "${#remote_branches[@]}" ]; then
    echo "잘못된 번호입니다."
    exit 1
fi

selected_branch=${remote_branches[$((branch_number-1))]}
echo "[slamnav2] 선택된 브랜치: $selected_branch"

git checkout "$selected_branch"
cd "$HOME"

echo "[slamnav2] slamnav2 리포지토리 작업 완료."
