#!/bin/bash
# module_network_ethernet.sh: 두 이더넷 인터페이스 설정 스크립트
# enp2s0: IPv4 주소 192.168.2.2/24
# enp1s0: IPv4 주소 192.168.1.5/24

configure_interface() {
    local interface="$1"
    local ipaddr="$2"
    local prefix="$3"

    echo "[$interface] 인터페이스 설정 중: IP ${ipaddr}/${prefix}"
    
    # 활성화된 연결 중 해당 인터페이스에 해당하는 연결 이름 추출
    local connection_name
    connection_name=$(nmcli -t -f NAME,DEVICE connection show --active | grep ":${interface}$" | cut -d: -f1)

    if [ -z "$connection_name" ]; then
        echo "[$interface] 활성화된 연결을 찾을 수 없습니다. 수동으로 확인해 주세요."
        return 1
    fi

    echo "[$interface] 연결 이름: $connection_name"

    # IPv4 설정: Manual 방식, 지정된 IP 주소, 게이트웨이 및 DNS 초기화, 자동 DNS 무시
    sudo nmcli connection modify "$connection_name" \
        ipv4.method manual \
        ipv4.addresses "${ipaddr}/${prefix}" \
        ipv4.gateway "" \
        ipv4.dns "" \
        ipv4.ignore-auto-dns yes

    echo "[$interface] 설정 변경 후 연결 재시작..."
    sudo nmcli connection down "$connection_name" && sudo nmcli connection up "$connection_name"

    echo "[$interface] 현재 IPv4 설정:"
    nmcli -f ipv4.method,ipv4.addresses connection show "$connection_name"
    echo "----------------------------------------"
}

# enp2s0 설정: 192.168.2.2/24
configure_interface "enp2s0" "192.168.2.2" "24"

# enp1s0 설정: 192.168.1.5/24 (netmask는 enp2s0와 동일하게 /24)
configure_interface "enp1s0" "192.168.1.5" "24"

echo "두 인터페이스의 네트워크 설정이 완료되었습니다."

