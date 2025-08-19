#!/usr/bin/env bash
###############################################################################
# run_rdk_install.sh
# · /home/*/rainbow-deploy-kit 디렉터리를 찾아 S100 옵션으로 install.sh 실행
###############################################################################
set -Eeuo pipefail

# ─── 1) 기본 경로: 현재 사용자 홈 ────────────────────────────────
DEPLOY_DIR="$HOME/rainbow-deploy-kit"

# ─── 2) 없으면 /home 하위(최대 2단계)에서 검색 ──────────────────
if [[ ! -d "$DEPLOY_DIR" ]]; then
  DEPLOY_DIR=$(find /home -maxdepth 2 -type d -name rainbow-deploy-kit 2>/dev/null | head -n 1 || true)
fi

# ─── 3) 최종 확인 ───────────────────────────────────────────────
if [[ -z "$DEPLOY_DIR" || ! -d "$DEPLOY_DIR" ]]; then
  echo "❌ /home 경로에서 rainbow-deploy-kit 디렉터리를 찾을 수 없습니다." >&2
  exit 1
fi

echo "📂 cd $DEPLOY_DIR"
cd "$DEPLOY_DIR"

echo "🚀 sudo bash install.sh --fo=/S100 S100"
sudo bash install.sh --fo=/S100 S100

