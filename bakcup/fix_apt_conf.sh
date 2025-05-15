#!/usr/bin/env bash
set -euo pipefail

FILE="/etc/apt/apt.conf.d/20auto-upgrades"
BACKUP="${FILE}.bak.$(date +%Y%m%d%H%M%S)"

#─────────────────────────────────────────────────────────────
# 1) root 권한 확인
#─────────────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
  echo ">> sudo로 다시 실행합니다..."
  exec sudo "$0" "$@"
fi

echo "============================================"
echo "🚑  APT 구문 오류 복구 스크립트 시작"
echo "    대상 파일 : $FILE"
echo "============================================"

#─────────────────────────────────────────────────────────────
# 2) 기존 파일 백업
#─────────────────────────────────────────────────────────────
if [[ -f "$FILE" ]]; then
  echo "📦  기존 파일 백업 → $BACKUP"
  cp "$FILE" "$BACKUP"
fi

#─────────────────────────────────────────────────────────────
# 3) 올바른 내용으로 재작성
#─────────────────────────────────────────────────────────────
cat > "$FILE" <<'EOF'
APT::Periodic::Update-Package-Lists "0";
APT::Periodic::Download-Upgradeable-Packages "0";
APT::Periodic::AutocleanInterval "0";
APT::Periodic::Unattended-Upgrade "0";
EOF

# (선택) Windows-CR 제거 가능성 대비
sed -i 's/\r$//' "$FILE"

echo "✅  새 설정 완료"

#─────────────────────────────────────────────────────────────
# 4) APT 구문 점검 & 업데이트 시험
#─────────────────────────────────────────────────────────────
echo -n "🔍  구문 점검 중... "
if apt-config dump >/dev/null; then
  echo "OK"
else
  echo "실패! 백업 파일($BACKUP)로 복원 후 직접 확인하세요."
  exit 1
fi

echo "🌐  sudo apt update 실행하여 최종 확인합니다..."
apt update

echo "🎉  모든 작업이 완료되었습니다."

