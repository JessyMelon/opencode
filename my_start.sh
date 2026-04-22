#!/bin/bash
#
# 快速启动入口（带默认公网/移动端参数）
#
# 用法:
#   ./my_start.sh                    # 启动前后端
#   ./my_start.sh mobile             # 启动移动端可访问模式
#   ./my_start.sh restart-mobile     # 重启并启用移动端可访问模式
#   ./my_start.sh status             # 查看服务状态
#   ./my_start.sh mobile-status      # 查看移动端访问状态和 URL
#

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMMAND="${1:-all}"

OPENCODE_PUBLIC_HOST="${OPENCODE_PUBLIC_HOST:-8.153.37.206}"
OPENCODE_PERMISSION_MODE="${OPENCODE_PERMISSION_MODE:-deferred-review}"
OPENCODE_BACKEND_SERVER_PORT="${OPENCODE_BACKEND_SERVER_PORT:-4096}"
OPENCODE_FRONTEND_PORT="${OPENCODE_FRONTEND_PORT:-3000}"

export NO_PROXY="127.0.0.1,localhost,::1,${OPENCODE_PUBLIC_HOST}${NO_PROXY:+,${NO_PROXY}}"
export no_proxy="127.0.0.1,localhost,::1,${OPENCODE_PUBLIC_HOST}${no_proxy:+,${no_proxy}}"

export OPENCODE_CORS_ORIGINS="${OPENCODE_CORS_ORIGINS:-http://${OPENCODE_PUBLIC_HOST}:${OPENCODE_FRONTEND_PORT}}"
export OPENCODE_BACKEND_SERVER_HOST="${OPENCODE_BACKEND_SERVER_HOST:-${OPENCODE_PUBLIC_HOST}}"
export OPENCODE_BACKEND_SERVER_PORT
export OPENCODE_FRONTEND_PORT
export OPENCODE_PERMISSION_MODE

if [[ "$COMMAND" == "mobile" || "$COMMAND" == "restart-mobile" ]]; then
    export OPENCODE_FRONTEND_HOST="${OPENCODE_FRONTEND_HOST:-0.0.0.0}"
    export OPENCODE_MOBILE_HOST="${OPENCODE_MOBILE_HOST:-${OPENCODE_PUBLIC_HOST}}"
    export OPENCODE_CORS_ORIGINS="${OPENCODE_CORS_ORIGINS:-http://${OPENCODE_PUBLIC_HOST}:${OPENCODE_FRONTEND_PORT}}"
fi

exec bash "${ROOT_DIR}/start-opencode.sh" "${COMMAND}"
