#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

need_root() { [[ $EUID -eq 0 ]] || { echo "sudo 로 실행하세요."; exit 1; }; }
need_root

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # 스크립트 위치
declare -A TARGETS=(
  [amr]="$DIR/setup_amr.sh"
  [mapper]="$DIR/setup_MAPPER_lvx.sh"
  [srv]="$DIR/setup_srv_h4-ultra.sh"
  [fms]="$DIR/setup_FMS2.sh"
)

echo "설치 유형을 선택하세요:"
select opt in "${!TARGETS[@]}" "quit"; do
  case "$opt" in
    quit)  echo "종료합니다."; break ;;
    amr|mapper|srv|fms)
          echo "[INFO] $opt 스크립트를 실행합니다…"
          bash "${TARGETS[$opt]}"
          break ;;
    *)    echo "잘못된 선택입니다." ;;
  esac
done

