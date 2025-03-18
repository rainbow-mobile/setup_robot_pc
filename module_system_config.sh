#!/bin/bash
# module_system_config.sh: LD_LIBRARY_PATH, GRUB 설정, 자동 업데이트 비활성화

source ./common.sh

echo "========================================"
echo "2. 시스템 환경 설정"
echo "========================================"

# LD_LIBRARY_PATH 추가
run_step "LD_LIBRARY_PATH (/usr/local/lib)" \
    "grep '/usr/local/lib' /etc/profile &> /dev/null" \
    "sudo sh -c 'echo \"export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:/usr/local/lib\" >> /etc/profile'"

run_step "LD_LIBRARY_PATH (rplidar_sdk)" \
    "grep 'rplidar_sdk/output/Linux/Release' /etc/profile &> /dev/null" \
    "sudo sh -c 'echo \"export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:\$HOME/rplidar_sdk/output/Linux/Release\" >> /etc/profile'"

run_step "LD_LIBRARY_PATH (OrbbecSDK)" \
    "grep 'OrbbecSDK/lib/linux_x64' /etc/profile &> /dev/null" \
    "sudo sh -c 'echo \"export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:\$HOME/OrbbecSDK/lib/linux_x64\" >> /etc/profile'"

# 프로필 재적용 및 ldconfig
if source /etc/profile && sudo ldconfig; then
    INSTALLED+=("프로필 재적용 및 ldconfig")
else
    FAILED+=("프로필 재적용 및 ldconfig")
fi

# GRUB 설정: USB 전원 관리 해제, intel_pstate 비활성화
run_step "GRUB 설정" \
    "grep 'usbcore.autosuspend=-1 intel_pstate=disable' /etc/default/grub &> /dev/null" \
    "sudo sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT=/ s/\"$/ usbcore.autosuspend=-1 intel_pstate=disable\"/' /etc/default/grub && sudo update-grub"

# 자동 업데이트 비활성화
run_step "자동 업데이트 비활성화" \
    "grep 'APT::Periodic::Update-Package-Lists \"0\"' /etc/apt/apt.conf.d/20auto-upgrades &> /dev/null" \
    "sudo sh -c 'cat > /etc/apt/apt.conf.d/20auto-upgrades <<EOF
APT::Periodic::Update-Package-Lists \"0\";
APT::Periodic::Download-Upgradeable-Packages \"0\";
APT::Periodic::AutocleanInterval \"0\";
APT::Periodic::Unattended-Upgrade \"0\";
EOF' && sudo sed -i 's/^Prompt=.*/Prompt=never/' /etc/update-manager/release-upgrades && gsettings set com.ubuntu.update-notifier regular-auto-launch-interval 0"

