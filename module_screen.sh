#!/bin/bash
# module_screen.sh: GNOME 및 X 환경의 화면 blank(절전) 옵션 비활성화

source ./common.sh

echo "========================================"
echo "화면 blank(절전) 옵션 비활성화"
echo "========================================"

echo "[Power Saving] GNOME 및 전원 관리 설정 변경..."
gsettings set org.gnome.desktop.session idle-delay 0
gsettings set org.gnome.desktop.screensaver idle-activation-enabled false
gsettings set org.gnome.desktop.screensaver lock-enabled false

gsettings set org.gnome.settings-daemon.plugins.power sleep-display-ac 0
gsettings set org.gnome.settings-daemon.plugins.power sleep-display-battery 0

echo "[Power Saving] 화면 blank 옵션이 'never'로 설정되었습니다."

if [ -z "$DISPLAY" ]; then
    echo "DISPLAY 환경 변수가 설정되지 않아 xset 명령어 건너뜁니다."
    SKIPPED+=("xset 화면 blank 옵션 (DISPLAY 없음)")
else
    if xset s off && xset -dpms && xset s noblank; then
        INSTALLED+=("xset 화면 blank 옵션 비활성화")
    else
        FAILED+=("xset 화면 blank 옵션 비활성화 실패")
    fi
fi

