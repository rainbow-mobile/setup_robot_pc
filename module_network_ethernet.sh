#!/bin/bash
# module_network_ethernet.sh: enp2s0 이더넷 네트워크 설정 변경 스크립트
# IPv4 Method를 Manual로 변경하고, IPv4 주소를 192.168.2.2/24로 설정합니다.

INTERFACE="enp2s0"
IPADDR="192.168.2.2"
PREFIX="24"  # 24는 255.255.255.0 (netmask)에 해당합니다.

# 활성화된 네트워크 연결 중 enp2s0 인터페이스에 해당하는 연결 이름을 찾습니다.
CONNECTION_NAME=$(nmcli -t -f NAME,DEVICE connection show --active | grep ":${INTERFACE}$" | cut -d: -f1)

if [ -z "$CONNECTION_NAME" ]; then
    echo "[$INTERFACE] 관련 활성화된 네트워크 연결을 찾을 수 없습니다. 수동으로 확인해 주세요."
    exit 1
fi

echo "[$INTERFACE] 연결 이름: $CONNECTION_NAME"

echo "IPv4 Method를 Manual로 변경하고, IPv4 주소를 ${IPADDR}/${PREFIX}로 설정합니다..."
sudo nmcli connection modify "$CONNECTION_NAME" \
    ipv4.method manual \
    ipv4.addresses "${IPADDR}/${PREFIX}" \
    ipv4.gateway "" \
    ipv4.dns "" \
    ipv4.ignore-auto-dns yes

echo "변경사항 적용을 위해 연결을 재시작합니다..."
sudo nmcli connection down "$CONNECTION_NAME" && sudo nmcli connection up "$CONNECTION_NAME"

echo "현재 IPv4 설정:"
nmcli -f ipv4.method,ipv4.addresses connection show "$CONNECTION_NAME"

