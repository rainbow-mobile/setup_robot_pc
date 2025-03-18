#!/bin/bash
# module_autologin.sh: GDM3 자동 로그인 설정

source ./common.sh

echo "========================================"
echo "자동 로그인 설정"
echo "========================================"

if [ -f /etc/gdm3/custom.conf ]; then
    echo "[Auto Login] /etc/gdm3/custom.conf 파일 수정 중..."
    sudo sed -i 's/^#\?AutomaticLoginEnable\s*=.*/AutomaticLoginEnable = true/' /etc/gdm3/custom.conf
    sudo sed -i "s/^#\?AutomaticLogin\s*=.*/AutomaticLogin = $USER/" /etc/gdm3/custom.conf
    echo "[Auto Login] 자동 로그인 설정 완료 (사용자: $USER)."
else
    echo "[Auto Login] /etc/gdm3/custom.conf 파일을 찾을 수 없습니다. 자동 로그인 설정을 건너뜁니다."
fi

