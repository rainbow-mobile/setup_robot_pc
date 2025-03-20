#!/bin/bash
# module_clear.sh: 설치 완료 후 시스템 정리 스크립트
# - $HOME/Documents, $HOME/Downloads, 그리고 Trash(~/.local/share/Trash) 내의 모든 폴더 삭제
# - Firefox 캐시 삭제 및 Firefox 방문 기록(History) 삭제

echo "========================================"
echo "시스템 정리: Documents, Downloads, Trash 내의 폴더 삭제"
echo "========================================"

# Documents 내의 모든 폴더 삭제
if [ -d "$HOME/Documents" ]; then
    echo "[$HOME/Documents] 내의 모든 폴더 삭제 중..."
    find "$HOME/Documents" -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} \;
    echo "[$HOME/Documents] 정리 완료."
else
    echo "[$HOME/Documents] 디렉토리가 존재하지 않습니다."
fi

# Downloads 내의 모든 폴더 삭제
if [ -d "$HOME/Downloads" ]; then
    echo "[$HOME/Downloads] 내의 모든 폴더 삭제 중..."
    find "$HOME/Downloads" -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} \;
    echo "[$HOME/Downloads] 정리 완료."
else
    echo "[$HOME/Downloads] 디렉토리가 존재하지 않습니다."
fi

# Trash 폴더 (일반적으로 ~/.local/share/Trash) 내의 모든 폴더 삭제
if [ -d "$HOME/.local/share/Trash" ]; then
    echo "[~/.local/share/Trash] 내의 모든 폴더 삭제 중..."
    find "$HOME/.local/share/Trash" -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} \;
    echo "[~/.local/share/Trash] 정리 완료."
else
    echo "Trash 디렉토리(~/.local/share/Trash)가 존재하지 않습니다."
fi

echo "========================================"
echo "Firefox 캐시 삭제"
echo "========================================"

# Firefox 캐시 삭제 (일반적으로 $HOME/.cache/mozilla/firefox 에 위치)
if [ -d "$HOME/.cache/mozilla/firefox" ]; then
    echo "Firefox 캐시 삭제 중..."
    rm -rf "$HOME/.cache/mozilla/firefox"
    echo "Firefox 캐시 삭제 완료."
else
    echo "Firefox 캐시 디렉토리가 존재하지 않습니다."
fi

echo "========================================"
echo "Firefox 방문 기록 삭제 (Clear Recent History)"
echo "========================================"

# sqlite3가 설치되어 있는지 확인
if ! command -v sqlite3 &> /dev/null; then
    echo "sqlite3이 설치되어 있지 않습니다. sudo apt-get install sqlite3 로 설치하세요."
    exit 1
fi

# Firefox 프로필 루트 디렉토리 (일반적으로 $HOME/.mozilla/firefox)
PROFILE_ROOT="$HOME/.mozilla/firefox"

if [ ! -d "$PROFILE_ROOT" ]; then
    echo "Firefox 프로필 디렉토리를 찾을 수 없습니다: $PROFILE_ROOT"
else
    echo "Firefox 프로필 디렉토리: $PROFILE_ROOT"
    # .default* 패턴을 가진 프로필 디렉토리 목록 추출
    profiles=( $(find "$PROFILE_ROOT" -maxdepth 1 -type d -name "*.default*" -printf "%f\n") )
    if [ ${#profiles[@]} -eq 0 ]; then
        echo "Firefox 프로필을 찾을 수 없습니다."
    else
        for profile in "${profiles[@]}"; do
            PROFILE_DIR="$PROFILE_ROOT/$profile"
            PLACES_DB="$PROFILE_DIR/places.sqlite"
            if [ -f "$PLACES_DB" ]; then
                echo "[$profile] 프로필의 방문 기록 삭제 중..."
                sqlite3 "$PLACES_DB" "DELETE FROM moz_historyvisits;"
                sqlite3 "$PLACES_DB" "UPDATE moz_places SET visit_count=0, last_visit_date=NULL WHERE visit_count>0;"
                if [ $? -eq 0 ]; then
                    echo "[$profile] 방문 기록 삭제 완료."
                else
                    echo "[$profile] 방문 기록 삭제 실패."
                fi
            else
                echo "[$profile] 프로필에 places.sqlite 파일이 존재하지 않습니다."
            fi
        done
    fi
fi

echo "시스템 정리 완료."

