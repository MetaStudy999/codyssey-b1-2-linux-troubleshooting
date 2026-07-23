#!/usr/bin/env bash
set -euo pipefail

AGENT_HOME="${AGENT_HOME:-$HOME/agent-lab}"
ENV_FILE="${ENV_FILE:-$AGENT_HOME/env.sh}"
APP_PATH="${APP_PATH:-$AGENT_HOME/agent-leak-app}"

if [[ $EUID -eq 0 ]]; then
  echo "오류: root가 아닌 일반 사용자로 실행하세요." >&2
  exit 1
fi
if [[ ! -f "$ENV_FILE" ]]; then
  echo "오류: $ENV_FILE 없음. 먼저 bash scripts/setup.sh를 실행하세요." >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$ENV_FILE"

required=(AGENT_HOME AGENT_PORT AGENT_UPLOAD_DIR AGENT_KEY_PATH AGENT_LOG_DIR MEMORY_LIMIT CPU_MAX_OCCUPY MULTI_THREAD_ENABLE)
for name in "${required[@]}"; do
  if [[ -z "${!name:-}" ]]; then
    echo "오류: 필수 환경변수 $name 없음" >&2
    exit 1
  fi
done

[[ "$AGENT_PORT" == "15034" ]] || { echo "오류: AGENT_PORT는 15034여야 합니다." >&2; exit 1; }
[[ -x "$APP_PATH" ]] || { echo "오류: 실행 가능한 앱이 없습니다: $APP_PATH" >&2; exit 1; }
[[ -f "$AGENT_KEY_PATH/secret.key" ]] || { echo "오류: secret.key 없음" >&2; exit 1; }
mkdir -p "$AGENT_UPLOAD_DIR" "$AGENT_LOG_DIR"

log_file="$AGENT_LOG_DIR/agent-$(date +%Y%m%d-%H%M%S).log"
echo "실행 로그: $log_file"
"$APP_PATH" 2>&1 | tee "$log_file"
