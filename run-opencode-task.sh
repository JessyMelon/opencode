#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
PACKAGE_DIR="${ROOT_DIR}/packages/opencode"
MODE="${OPENCODE_PERMISSION_MODE:-deferred-review}"
SERVER_URL="${OPENCODE_SERVER_URL:-http://127.0.0.1:4096}"
RUN_DIR="${OPENCODE_RUN_DIR:-${ROOT_DIR}}"
PROMPT=""
PROMPT_FILE=""
TITLE=""
BACKGROUND=false
START_BACKEND=true
LOG_DIR="${OPENCODE_TASK_LOG_DIR:-${ROOT_DIR}/logs}"

usage() {
    cat <<'EOF'
Usage:
  ./run-opencode-task.sh [options] -- "your prompt"
  ./run-opencode-task.sh [options] --prompt-file prompt.txt

Options:
  --mode <mode>         supervised | deferred-review | unattended
  --server <url>        default: http://127.0.0.1:4096
  --dir <path>          working directory for the task
  --title <title>       optional session title
  --prompt-file <file>  read prompt from file
  --background          run task in background and write log
  --no-start            do not auto-start backend
  --help                show this help

Examples:
  ./run-opencode-task.sh --mode deferred-review -- "分析当前仓库并写入 coder-llm-wiki"
  ./run-opencode-task.sh --mode unattended --background --prompt-file ./task.txt
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --mode)
            MODE="$2"
            shift 2
            ;;
        --server)
            SERVER_URL="$2"
            shift 2
            ;;
        --dir)
            RUN_DIR="$2"
            shift 2
            ;;
        --title)
            TITLE="$2"
            shift 2
            ;;
        --prompt-file)
            PROMPT_FILE="$2"
            shift 2
            ;;
        --background)
            BACKGROUND=true
            shift
            ;;
        --no-start)
            START_BACKEND=false
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        --)
            shift
            PROMPT="$*"
            break
            ;;
        *)
            PROMPT="${PROMPT:+${PROMPT } }$1"
            shift
            ;;
    esac
done

if [[ -n "$PROMPT_FILE" ]]; then
    if [[ ! -f "$PROMPT_FILE" ]]; then
        echo "Prompt file not found: $PROMPT_FILE" >&2
        exit 1
    fi
    PROMPT="$(<"$PROMPT_FILE")"
fi

if [[ -z "${PROMPT// }" ]]; then
    usage
    exit 1
fi

mkdir -p "$LOG_DIR"

if [[ "$START_BACKEND" == true ]]; then
    OPENCODE_PERMISSION_MODE="$MODE" bash "${ROOT_DIR}/start-opencode.sh" backend
fi

cd "$PACKAGE_DIR"

ARGS=(run --attach "$SERVER_URL" --dir "$RUN_DIR" --dangerously-skip-permissions)

if [[ -n "$TITLE" ]]; then
    ARGS+=(--title "$TITLE")
fi

ARGS+=("$PROMPT")

if [[ "$BACKGROUND" == true ]]; then
    LOG_FILE="${LOG_DIR}/task-$(date +%Y%m%d-%H%M%S).log"
    nohup bun run --conditions=browser ./src/index.ts "${ARGS[@]}" > "$LOG_FILE" 2>&1 < /dev/null &
    PID=$!
    echo "$PID" > "${LOG_FILE}.pid"
    echo "Started background task"
    echo "PID: $PID"
    echo "Log: $LOG_FILE"
    exit 0
fi

exec bun run --conditions=browser ./src/index.ts "${ARGS[@]}"
