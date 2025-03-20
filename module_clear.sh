#!/bin/bash
# cleanup.sh: 설치 완료 후 시스템 정리 스크립트
# - $HOME/Documents, $HOME/Downloads, 그리고 Trash(~/ .local/share/Trash) 내의 모든 폴더 삭제
# - Firefox 캐시(방문 기록 캐시)를 삭제합니다.

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
echo "Firefox 방문 기록 캐시 삭제"
echo "========================================"

# Firefox 캐시(방문 기록 캐시) 삭제
# Firefox의 캐시는 보통 $HOME/.cache/mozilla/firefox 에 위치합니다.
if [ -d "$HOME/.cache/mozilla/firefox" ]; then
    echo "Firefox 캐시 삭제 중..."
    rm -rf "$HOME/.cache/mozilla/firefox"
    echo "Firefox 캐시 삭제 완료."
else
    echo "Firefox 캐시 디렉토리가 존재하지 않습니다."
fi

echo "시스템 정리 완료."

