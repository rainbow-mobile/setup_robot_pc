#!/bin/bash
# module_network_ethernet.sh: enp2s0 이더넷 네트워크 설정 변경 스크립트
# IPv4 Method를 Manual로 변경하고, IPv4 주소를 192.168.2.2/24로 설정합니다.

# (선택 사항) 공통 로깅 기능 사용 시 common.sh를 소스할 수 있습니다.
# source ./common.sh

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
echo "IPv4 Method를 Manual로 변경합니다..."
sudo nmcli connection modify "$CONNECTION_NAME" ipv4.method manual

echo "IPv4 주소를 ${IPADDR}/${PREFIX} (Netmask: 255.255.255.0)로 설정합니다..."
sudo nmcli connection modify "$CONNECTION_NAME" ipv4.addresses ${IPADDR}/${PREFIX}

# (선택 사항) 기존에 설정된 게이트웨이나 DNS가 있다면 초기화할 수 있습니다.
sudo nmcli connection modify "$CONNECTION_NAME" ipv4.gateway ""
sudo nmcli connection modify "$CONNECTION_NAME" ipv4.dns ""

echo "변경사항 적용을 위해 연결을 재시작합니다..."
sudo nmcli connection down "$CONNECTION_NAME" && sudo nmcli connection up "$CONNECTION_NAME"

echo "네트워크 설정 변경 완료: $INTERFACE가 Manual IPv4로 ${IPADDR}/${PREFIX}로 설정되었습니다."

