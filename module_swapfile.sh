#!/bin/bash
# module_swapfile.sh: 스왑파일 설정

source ./common.sh

echo "========================================"
echo "3. 스왑파일 설정"
echo "========================================"

run_step "스왑파일 설정" \
    "free -h | grep -q 'Swap:.*32G'" \
    "sudo swapoff /swapfile &> /dev/null || true && \
    sudo rm -f /swapfile && \
    sudo fallocate -l 32G /swapfile || sudo dd if=/dev/zero of=/swapfile bs=1M count=32768 && \
    sudo chmod 600 /swapfile && \
    sudo mkswap /swapfile && \
    sudo swapon /swapfile && \
    grep -q '/swapfile swap' /etc/fstab || echo '/swapfile swap swap defaults 0 0' | sudo tee -a /etc/fstab"

