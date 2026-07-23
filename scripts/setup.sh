#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
  echo "오류: root가 아닌 일반 사용자로 실행하세요." >&2
  exit 1
fi

AGENT_HOME="${AGENT_HOME:-$HOME/agent-lab}"
mkdir -p "$AGENT_HOME/upload_files" "$AGENT_HOME/api_keys" "$AGENT_HOME/logs"
umask 077
printf '%s\n' 'agent_api_key_test' > "$AGENT_HOME/api_keys/secret.key"

cat > "$AGENT_HOME/env.sh" <<ENV
export AGENT_HOME="$AGENT_HOME"
export AGENT_PORT="15034"
export AGENT_UPLOAD_DIR="$AGENT_HOME/upload_files"
export AGENT_KEY_PATH="$AGENT_HOME/api_keys"
export AGENT_LOG_DIR="$AGENT_HOME/logs"
export MEMORY_LIMIT="256"
export CPU_MAX_OCCUPY="80"
export MULTI_THREAD_ENABLE="true"
ENV
chmod 600 "$AGENT_HOME/env.sh" "$AGENT_HOME/api_keys/secret.key"

echo "준비 완료: $AGENT_HOME"
echo "다음 명령: source \"$AGENT_HOME/env.sh\""
