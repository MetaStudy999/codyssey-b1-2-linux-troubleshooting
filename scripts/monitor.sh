#!/usr/bin/env bash
set -euo pipefail

name="agent-leak-app"
interval=5
output="monitor-$(date +%Y%m%d-%H%M%S).csv"
pid=""

usage() {
  echo "사용법: $0 [--pid PID | --name NAME] [--interval SEC] [--output FILE]"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pid) pid="${2:-}"; shift 2 ;;
    --name) name="${2:-}"; shift 2 ;;
    --interval) interval="${2:-}"; shift 2 ;;
    --output) output="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "알 수 없는 옵션: $1" >&2; usage; exit 2 ;;
  esac
done

[[ "$interval" =~ ^[1-9][0-9]*$ ]] || { echo "interval은 1 이상의 정수여야 합니다." >&2; exit 2; }

if [[ -z "$pid" ]]; then
  pid="$(pgrep -n -f "$name" || true)"
fi
[[ "$pid" =~ ^[0-9]+$ ]] || { echo "대상 PID를 찾지 못했습니다." >&2; exit 1; }
kill -0 "$pid" 2>/dev/null || { echo "PID $pid가 실행 중이 아닙니다." >&2; exit 1; }

mkdir -p "$(dirname "$output")"
if [[ ! -s "$output" ]]; then
  echo "timestamp,pid,cpu_percent,mem_percent,rss_kb,vsz_kb,threads,state,elapsed,command" > "$output"
fi

echo "PID $pid 관제 시작 → $output (중지: Ctrl+C)"
while kill -0 "$pid" 2>/dev/null; do
  timestamp="$(date --iso-8601=seconds)"
  row="$(ps -p "$pid" -o pid=,pcpu=,pmem=,rss=,vsz=,nlwp=,stat=,etime=,comm= | awk -v ts="$timestamp" '{
    printf "%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n", ts,$1,$2,$3,$4,$5,$6,$7,$8,$9
  }')"
  [[ -n "$row" ]] && echo "$row" | tee -a "$output"
  sleep "$interval"
done
echo "프로세스 종료 감지: PID $pid"
