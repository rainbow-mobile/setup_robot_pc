#!/usr/bin/env bash
NET=10.108.1          # <-- 필요한 경우 변경
IF=wlan0               # <-- 스캔하는 인터페이스 (Wi-Fi면 wlan0 등) / eth0 : 유선

USED=$(mktemp)
ALL=$(mktemp)
FREE=$(mktemp)

# 1) 1차 : nmap ARP Ping
sudo nmap -sn -n -PR -oG - $NET.0/24         \
  | awk '/Up$/{print $2}'                    \
  | sort -u > "$USED"

# 2) 전체 /24 목록
seq 1 254 | sed "s/^/$NET./" > "$ALL"

# 3) 2차 교차검증 (ping + arping)
while read -r IP; do
  if grep -qF "$IP" "$USED"; then
      continue      # 이미 사용중으로 판정
  fi

  # (a) ping 1회
  ping -c1 -W1 "$IP" &>/dev/null
  if [ $? -eq 0 ]; then
      continue      # ICMP 응답 → 사용 중
  fi

  # (b) arping 1회 (동일 브로드캐스트-도메인일 때만)
  sudo arping -c1 -w1 -I "$IF" "$IP" &>/dev/null
  if [ $? -eq 0 ]; then
      continue      # ARP 응답 → 사용 중
  fi

  # 두 테스트 모두 실패 → 미사용 후보
  echo "$IP"
done < "$ALL" | sort -t . -k4,4n > "$FREE"

echo "▼ 최종 미사용 IP"
cat "$FREE"

