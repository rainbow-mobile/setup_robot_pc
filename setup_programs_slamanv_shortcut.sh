#!/bin/bash
# setup_diagnosis_and_slamnav2.sh
# 진단 단축키 복사 및 slamnav2 리포지토리 클론/업데이트 후 브랜치 체크아웃 작업
# 중간에 오류가 발생해도 계속 진행하며, 마지막에 요약하여 출력합니다.

# ─── 0. 스크립트 기준 위치로 이동 ───────────────────────────
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

# 전역 배열 (설치 완료, 건너뛴 항목, 실패한 항목)
INSTALLED=()
SKIPPED=()
FAILED=()

# 단계 실행 함수 (이미 존재하면 건너뛰고, 오류 발생 시 FAILED에 기록)
run_step() {
    local name="$1"
    local check_cmd="$2"
    local install_cmd="$3"
    
    echo ">> [$name] 진행..."
    if eval "$check_cmd"; then
        echo "   [$name] 이미 설치(설정)되어 있어 건너뜁니다."
        SKIPPED+=("$name")
    else
        echo "   [$name] 설치/설정 중..."
        if eval "$install_cmd"; then
            echo "   [$name] 설치/설정 완료."
            INSTALLED+=("$name")
        else
            echo "   [$name] 설치/설정 실패!"
            FAILED+=("$name")
        fi
    fi
    echo "----------------------------------------"
}

# 실행 시작 시간 기록 및 종료 시 경과 시간 출력 (trap 사용)
start_time=$(date +%s)
trap 'end_time=$(date +%s); elapsed=$((end_time - start_time)); echo "총 실행 시간: $elapsed 초"' EXIT


########################################
# 0. git clone 
########################################
echo "========================================"
echo "0. git clone"
echo "========================================"

# git이 설치되지 않은 경우 자동으로 설치 (이미 설치되어 있으면 건너뜁니다)
echo "[Pre-setup] git 설치 중..."
sudo apt-get install git -y


########################################
# 1. diagnosis 리포지토리 작업 (설치 경로: $HOME/diagnosis)
########################################
echo "========================================"
echo "1. diagnosis 리포지토리 작업"
echo "========================================"
# 진단 리포지토리를 $HOME/diagnosis 경로에 클론합니다.
if [ ! -d "$HOME/diagnosis" ]; then
    echo "[diagnosis] 리포지토리 클론 중..."
    git clone https://github.com/rainbow-mobile/diagnosis.git "$HOME/diagnosis"
else
    echo "[diagnosis] 리포지토리가 이미 존재합니다. 최신 상태로 업데이트합니다."
    cd "$HOME/diagnosis" && git pull && cd -
fi

########################################
# 2. slamnav2 리포지토리 작업 (설치 경로: $HOME/slamnav2)
########################################
echo "========================================"
echo "2. slamnav2 리포지토리 작업"
echo "========================================"

if [ ! -d "$HOME/slamnav2" ]; then
    echo "[slamnav2] 리포지토리 클론 중..."
    if git clone https://github.com/rainbow-mobile/slamnav2.git "$HOME/slamnav2"; then
        INSTALLED+=("slamnav2 클론")
    else
        echo "[slamnav2] 클론 실패!"
        FAILED+=("slamnav2 클론")
    fi
else
    echo "[slamnav2] 리포지토리가 이미 존재합니다. 최신 상태로 업데이트합니다."
    if cd "$HOME/slamnav2" && git pull; then
        INSTALLED+=("slamnav2 업데이트")
    else
        echo "[slamnav2] 업데이트 실패!"
        FAILED+=("slamnav2 업데이트")
    fi
    cd "$HOME"
fi

cd "$HOME/slamnav2"

echo "[slamnav2] 원격 브랜치 목록:"
remote_branches=($(git branch -r | sed 's/ *origin\///' | grep -v 'HEAD'))
for i in "${!remote_branches[@]}"; do
    echo "$((i+1)). ${remote_branches[i]}"
done

read -p "체크아웃할 브랜치 번호를 선택하세요: " branch_number
if ! [[ "$branch_number" =~ ^[0-9]+$ ]] || [ "$branch_number" -lt 1 ] || [ "$branch_number" -gt "${#remote_branches[@]}" ]; then
    echo "잘못된 번호입니다."
    FAILED+=("slamnav2 브랜치 선택")
else
    selected_branch=${remote_branches[$((branch_number-1))]}
    echo "[slamnav2] 선택된 브랜치: $selected_branch"
    if git checkout "$selected_branch"; then
        INSTALLED+=("slamnav2 브랜치 체크아웃 ($selected_branch)")
    else
        FAILED+=("slamnav2 브랜치 체크아웃 ($selected_branch)")
    fi
fi
cd "$HOME"

echo "[slamnav2] slamnav2 리포지토리 작업 완료."


########################################
# 3. 진단 단축키 복사 작업
########################################
echo "========================================"
echo "3. 진단 단축키 복사 작업"
echo "========================================"

# ▼▼▼ ❶ 실제 사용자 HOME 결정 ---------------------------------
# sudo 로 실행하면 $HOME=/root 이 되므로,
# SUDO_USER 가 있으면 그 사용자의 홈 디렉터리를 가져옵니다.
if [ -n "$SUDO_USER" ]; then
    USER_HOME="$(eval echo "~$SUDO_USER")"
else
    USER_HOME="$HOME"
fi

# 소스 디렉토리 결정: 우선 $HOME/diagnosis, 없으면 /home/rainbow/diagnosis
if [ -d "$HOME/diagnosis" ]; then
    sourceDir="$HOME/diagnosis"
elif [ -d "/home/rainbow/diagnosis" ]; then
    sourceDir="/home/rainbow/diagnosis"
else
    echo "진단 프로그램 디렉토리가 존재하지 않습니다: $HOME/diagnosis 또는 /home/rainbow/diagnosis"
    FAILED+=("진단 프로그램 디렉토리 없음")
fi

if [ -n "$sourceDir" ]; then
    # 바탕화면 경로 설정 (영어 환경: ~/Desktop, 한글 환경: ~/바탕화면)
    #DESKTOP_DIR="$HOME/Desktop"
    #if [ ! -d "$DESKTOP_DIR" ]; then
    #    if [ -d "$HOME/Desktop" ]; then
    #        DESKTOP_DIR="$HOME/Desktop"
    #    else
    #        echo "바탕화면 디렉토리를 찾을 수 없습니다. DESKTOP_DIR 변수를 확인하세요."
    #        FAILED+=("바탕화면 디렉토리 없음")
    #        exit 1
    #    fi
    #fi

    DESKTOP_DIR="$(xdg-user-dir DESKTOP 2>/dev/null || true)"

    if [ -z "$DESKTOP_DIR" ] || [ ! -d "$DESKTOP_DIR" ]; then
        for try in "$USER_HOME/Desktop" "$USER_HOME/바탕화면"; do
            if [ -d "$try" ]; then
                DESKTOP_DIR="$try"
                break
            fi
        done
    fi

    if [ -z "$DESKTOP_DIR" ] || [ ! -d "$DESKTOP_DIR" ]; then
        echo "바탕화면 디렉토리를 찾을 수 없습니다. DESKTOP_DIR 변수를 확인하세요."
        FAILED+=("바탕화면 디렉토리 없음")
        exit 1
    fi
    echo "[diagnosis] 바탕화면 경로: $DESKTOP_DIR"
    
    # 1. 쉘 스크립트 복사: slamnav2.sh와 diagnostic.sh (주의: 파일명이 'diagnostic'로 되어있어야 합니다.)
    echo "[diagnosis] 단축키 복사를 진행합니다."
    destShellDir="$HOME"
    if [ -f "$sourceDir/slamnav2.sh" ] && [ -f "$sourceDir/diagnostic.sh" ]; then
        rm -f "$destShellDir/slamnav2.sh" "$destShellDir/diagnostic.sh"
        if cp "$sourceDir/slamnav2.sh" "$destShellDir/" && cp "$sourceDir/diagnostic.sh" "$destShellDir/"; then
            INSTALLED+=("쉘 스크립트 복사")
        else
            FAILED+=("쉘 스크립트 복사")
        fi
    else
        echo "[diagnosis] 원본 쉘 스크립트 파일이 존재하지 않습니다: $sourceDir/slamnav2.sh 또는 $sourceDir/diagnostic.sh"
        FAILED+=("원본 쉘 스크립트 파일 없음")
    fi

    # 2. 데스크탑 단축키 복사: SLAMNAV2.desktop와 diagnostic.desktop
    if [ -f "$sourceDir/SLAMNAV2.desktop" ] && [ -f "$sourceDir/diagnostic.desktop" ]; then
        rm -f "$DESKTOP_DIR/SLAMNAV2.desktop" "$DESKTOP_DIR/diagnostic.desktop"
        if cp "$sourceDir/SLAMNAV2.desktop" "$DESKTOP_DIR/" && cp "$sourceDir/diagnostic.desktop" "$DESKTOP_DIR/"; then
            INSTALLED+=("데스크탑 단축키 복사")
        else
            FAILED+=("데스크탑 단축키 복사")
        fi
    else
        echo "[diagnosis] 원본 데스크탑 파일이 존재하지 않습니다: $sourceDir/SLAMNAV2.desktop 또는 $sourceDir/diagnostic.desktop"
        FAILED+=("원본 데스크탑 파일 없음")
    fi

    # 3. 데스크탑 파일 잠금 해제: 파일 존재 확인 후 gio set 실행
    echo "[diagnosis] 데스크탑 단축키 잠금 해제 시도..."
    if [ -f "$DESKTOP_DIR/SLAMNAV2.desktop" ]; then
        if gio set "$DESKTOP_DIR/SLAMNAV2.desktop" metadata::trusted true; then
            INSTALLED+=("SLAMNAV2.desktop 잠금 해제")
        else
            FAILED+=("SLAMNAV2.desktop 잠금 해제")
        fi
    else
        echo "[diagnosis] $DESKTOP_DIR/SLAMNAV2.desktop 파일이 존재하지 않습니다."
        FAILED+=("SLAMNAV2.desktop 파일 없음")
    fi

    if [ -f "$DESKTOP_DIR/diagnostic.desktop" ]; then
        if gio set "$DESKTOP_DIR/diagnostic.desktop" metadata::trusted true; then
            INSTALLED+=("diagnostic.desktop 잠금 해제")
        else
            FAILED+=("diagnostic.desktop 잠금 해제")
        fi
    else
        echo "[diagnosis] $DESKTOP_DIR/diagnostic.desktop 파일이 존재하지 않습니다."
        FAILED+=("diagnostic.desktop 파일 없음")
    fi
fi


########################################
# 최종 요약 및 오류 출력
########################################
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

