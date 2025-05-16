#!/usr/bin/env bash
###############################################################################
# run_rdk_install.sh
# · rainbow-deploy-kit 디렉터리로 이동한 뒤 S100 옵션으로 install.sh 실행
###############################################################################
set -Eeuo pipefail

# 이 스크립트가 놓인 위치를 기준으로 경로 계산
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$SCRIPT_DIR/rainbow-deploy-kit"

# rainbow-deploy-kit 디렉터리 존재 여부 확인
if [[ ! -d "$DEPLOY_DIR" ]]; then
  echo "❌ rainbow-deploy-kit 디렉터리를 찾을 수 없습니다: $DEPLOY_DIR" >&2
  exit 1
fi

echo "📂 cd $DEPLOY_DIR"
cd "$DEPLOY_DIR"

echo "🚀 bash install.sh --fo=/S100 S100"
bash install.sh --fo=/S100 S100

