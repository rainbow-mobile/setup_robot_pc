#!/bin/bash
# module_teamviewer.sh: TeamViewer 설정 리셋

source ./common.sh

echo "========================================"
echo "TeamViewer 리셋"
echo "========================================"

run_step "TeamViewer 리셋" \
    "test ! -f /etc/teamviewer/global.conf" \
    "sudo teamviewer --daemon stop && sudo rm -f /etc/teamviewer/global.conf && sudo rm -rf ~/.config/teamviewer/ && sudo teamviewer --daemon start"

