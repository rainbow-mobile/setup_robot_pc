#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# 0. root 확인
[[ $(id -u) -eq 0 ]] || { echo "sudo 로 실행하세요."; exit 1; }

echo "🔧 1) sources.list 백업 → /etc/apt/sources.list.bak_https"
cp /etc/apt/sources.list /etc/apt/sources.list.bak_https

echo "🔄 2) 모든 http:// → https:// 로 치환"
sed -E -i 's|http://([^ ]+ubuntu)|https://\1|g' /etc/apt/sources.list

# 3) /etc/apt/sources.list.d/*.list 안의 서드파티 레포도 동일 처리
for f in /etc/apt/sources.list.d/*.list; do
  [[ -f "$f" ]] || continue
  cp "$f" "${f}.bak_https"
  sed -E -i 's|http://([^ ]+)|https://\1|g' "$f"
done

echo "🚫 4) /etc/apt/apt.conf.d/99nocache 생성 (캐시 무효화)"
cat >/etc/apt/apt.conf.d/99nocache <<'EOF'
Acquire::http::No-Cache "true";
Acquire::https::No-Cache "true";
Acquire::Retries "3";
EOF

echo "🧹 5) 캐시/인덱스 정리"
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "🔄 6) 패키지 리스트 갱신 (HTTPS)"
apt-get update

echo "✅ HTTPS 전환 및 캐시 무효화 완료!"

