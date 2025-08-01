#!/usr/bin/env bash
# analyze_fault_logs.sh
# 모든 fault_log/*.txt 파일에 대해 addr2line 결과를 붙여서 출력.

set -euo pipefail

EXEC="$HOME/slamnav2/SLAMNAV2"          # 메인 실행 파일
LOGDIR="$HOME/slamnav2/snlog/fault_log" # 로그 디렉터리

# 정규식: /path/to/module(+0xOFF)
regex='^([^[:space:]]+)\(\+0x([0-9a-fA-F]+)\)'

# fault_log 디렉터리에 *.txt 가 없으면 glob 자체가 그대로 남으므로,
# nullglob 옵션을 잠시 켜서 빈 리스트가 되도록 처리
shopt -s nullglob

for logfile in "$LOGDIR"/*.txt; do
    [[ -e "$logfile" ]] || { echo "No *.txt in $LOGDIR"; exit 1; }

    echo "============================================================"
    echo " LOGFILE : $logfile"
    echo "============================================================"

    while IFS= read -r line; do
        if [[ $line =~ $regex ]]; then
            module="${BASH_REMATCH[1]}"
            offset="0x${BASH_REMATCH[2]}"

            # 모듈 경로가 상대·파일명만 찍혔으면 메인 실행 파일로 간주
            [[ $module == /* ]] || module="$EXEC"

            map_out=$(addr2line -f -C -e "$module" "$offset" 2>/dev/null)

            func=$(echo "$map_out" | head -n1)
            src=$(echo "$map_out"  | tail -n1)

            printf "%s\n    ↳ %s (%s)\n" "$line" "$func" "$src"
        else
            echo "$line"
        fi
    done < "$logfile"

    echo            # 로그 간 공백
done

