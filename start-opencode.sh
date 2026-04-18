#!/bin/bash
#
# OpenCode 启动脚本
# 支持前后端分离部署
#
# 用法:
#   ./start-opencode.sh              # 启动前端和后端
#   ./start-opencode.sh backend      # 仅启动后端
#   ./start-opencode.sh frontend     # 仅启动前端
#   ./start-opencode.sh stop         # 停止所有服务
#   ./start-opencode.sh status       # 查看服务状态
#

set -e

# ==================== 配置区 ====================
# 项目根目录（可通过环境变量覆盖）
OPENCODE_PROJECT_ROOT="${OPENCODE_PROJECT_ROOT:-$(cd "$(dirname "$0")" && pwd)}"

# 后端配置
OPENCODE_BACKEND_HOST="${OPENCODE_BACKEND_HOST:-0.0.0.0}"
OPENCODE_BACKEND_PORT="${OPENCODE_BACKEND_PORT:-4096}"

# 前端配置
OPENCODE_FRONTEND_HOST="${OPENCODE_FRONTEND_HOST:-127.0.0.1}"
OPENCODE_FRONTEND_PORT="${OPENCODE_FRONTEND_PORT:-3000}"

# CORS 配置（允许的前端域名，多个用逗号分隔）
# 分离部署时需要设置前端访问地址，例如: http://11.166.14.24:3000
OPENCODE_CORS_ORIGINS="${OPENCODE_CORS_ORIGINS:-}"

# 后端服务器地址（前端连接后端时使用，支持分离部署）
# 默认连接本地后端，分离部署时设置为后端服务器地址
OPENCODE_BACKEND_SERVER_HOST="${OPENCODE_BACKEND_SERVER_HOST:-127.0.0.1}"
OPENCODE_BACKEND_SERVER_PORT="${OPENCODE_BACKEND_SERVER_PORT:-${OPENCODE_BACKEND_PORT}}"

# 日志目录
OPENCODE_LOG_DIR="${OPENCODE_LOG_DIR:-${OPENCODE_PROJECT_ROOT}/logs}"

# PID 文件目录
OPENCODE_PID_DIR="${OPENCODE_PID_DIR:-${OPENCODE_PROJECT_ROOT}/pids}"

# ==================== 工具函数 ====================
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ ERROR: $1" >&2
}

ensure_dir() {
    mkdir -p "$1"
}

check_bun() {
    if ! command -v bun &> /dev/null; then
        error "bun is not installed. Please install bun first: https://bun.sh/"
        exit 1
    fi
    log "✅ Found bun: $(bun --version)"
}

get_pid() {
    local pid_file="$1"
    if [[ -f "$pid_file" ]]; then
        cat "$pid_file"
    fi
}

is_process_running() {
    local pid="$1"
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
        return 0
    fi
    return 1
}

# ==================== 后端服务 ====================
start_backend() {
    local pid_file="${OPENCODE_PID_DIR}/backend.pid"
    local log_file="${OPENCODE_LOG_DIR}/backend.log"

    # 检查是否已运行
    local existing_pid=$(get_pid "$pid_file")
    if is_process_running "$existing_pid"; then
        log "⚠️  Backend is already running (PID: $existing_pid)"
        return 0
    fi

    log "🤖 Starting OpenCode backend on ${OPENCODE_BACKEND_HOST}:${OPENCODE_BACKEND_PORT}..."

    cd "${OPENCODE_PROJECT_ROOT}/packages/opencode"

    # 构建 CORS 参数
    local cors_args=""
    if [[ -n "$OPENCODE_CORS_ORIGINS" ]]; then
        IFS=',' read -ra CORS_ARRAY <<< "$OPENCODE_CORS_ORIGINS"
        for origin in "${CORS_ARRAY[@]}"; do
            cors_args="$cors_args --cors ${origin}"
        done
        log "   → CORS origins: $OPENCODE_CORS_ORIGINS"
    fi

    nohup bun run --conditions=browser ./src/index.ts serve \
        --hostname "${OPENCODE_BACKEND_HOST}" \
        --port "${OPENCODE_BACKEND_PORT}" \
        $cors_args \
        > "$log_file" 2>&1 < /dev/null &

    local backend_pid=$!
    echo "$backend_pid" > "$pid_file"

    log "   → Backend PID: $backend_pid"
    log "   → Backend Log: $log_file"

    # 等待服务启动
    sleep 3

    if is_process_running "$backend_pid"; then
        log "✅ Backend started successfully"
    else
        error "Backend failed to start. Check log: $log_file"
        return 1
    fi
}

stop_backend() {
    local pid_file="${OPENCODE_PID_DIR}/backend.pid"
    local pid=$(get_pid "$pid_file")

    if [[ -z "$pid" ]]; then
        log "ℹ️  Backend is not running (no PID file)"
        return 0
    fi

    if is_process_running "$pid"; then
        log "🛑 Stopping backend (PID: $pid)..."
        kill "$pid" 2>/dev/null || true
        sleep 2

        if is_process_running "$pid"; then
            log "⚠️  Force killing backend..."
            kill -9 "$pid" 2>/dev/null || true
        fi
        log "✅ Backend stopped"
    else
        log "ℹ️  Backend is not running"
    fi

    rm -f "$pid_file"
}

# ==================== 前端服务 ====================
start_frontend() {
    local pid_file="${OPENCODE_PID_DIR}/frontend.pid"
    local log_file="${OPENCODE_LOG_DIR}/frontend.log"

    # 检查是否已运行
    local existing_pid=$(get_pid "$pid_file")
    if is_process_running "$existing_pid"; then
        log "⚠️  Frontend is already running (PID: $existing_pid)"
        return 0
    fi

    log "🎨 Starting OpenCode frontend on ${OPENCODE_FRONTEND_HOST}:${OPENCODE_FRONTEND_PORT}..."
    log "   → Connecting to backend at ${OPENCODE_BACKEND_SERVER_HOST}:${OPENCODE_BACKEND_SERVER_PORT}"

    cd "${OPENCODE_PROJECT_ROOT}/packages/app"

    nohup env \
        VITE_OPENCODE_SERVER_HOST="${OPENCODE_BACKEND_SERVER_HOST}" \
        VITE_OPENCODE_SERVER_PORT="${OPENCODE_BACKEND_SERVER_PORT}" \
        bun run --bun ./node_modules/.bin/vite \
        --host "${OPENCODE_FRONTEND_HOST}" \
        --port "${OPENCODE_FRONTEND_PORT}" \
        > "$log_file" 2>&1 < /dev/null &

    local frontend_pid=$!
    echo "$frontend_pid" > "$pid_file"

    log "   → Frontend PID: $frontend_pid"
    log "   → Frontend Log: $log_file"

    # 等待服务启动
    sleep 3

    if is_process_running "$frontend_pid"; then
        log "✅ Frontend started successfully"
        log "   → Access URL: http://${OPENCODE_FRONTEND_HOST}:${OPENCODE_FRONTEND_PORT}"
    else
        error "Frontend failed to start. Check log: $log_file"
        return 1
    fi
}

stop_frontend() {
    local pid_file="${OPENCODE_PID_DIR}/frontend.pid"
    local pid=$(get_pid "$pid_file")

    if [[ -z "$pid" ]]; then
        log "ℹ️  Frontend is not running (no PID file)"
        return 0
    fi

    if is_process_running "$pid"; then
        log "🛑 Stopping frontend (PID: $pid)..."
        kill "$pid" 2>/dev/null || true
        sleep 2

        if is_process_running "$pid"; then
            log "⚠️  Force killing frontend..."
            kill -9 "$pid" 2>/dev/null || true
        fi
        log "✅ Frontend stopped"
    else
        log "ℹ️  Frontend is not running"
    fi

    rm -f "$pid_file"
}

# ==================== 状态检查 ====================
show_status() {
    log "📊 OpenCode Service Status"
    log "========================"

    # 后端状态
    local backend_pid=$(get_pid "${OPENCODE_PID_DIR}/backend.pid")
    if is_process_running "$backend_pid"; then
        log "✅ Backend:  Running (PID: $backend_pid) on ${OPENCODE_BACKEND_HOST}:${OPENCODE_BACKEND_PORT}"
    else
        log "❌ Backend:  Not running"
    fi

    # 前端状态
    local frontend_pid=$(get_pid "${OPENCODE_PID_DIR}/frontend.pid")
    if is_process_running "$frontend_pid"; then
        log "✅ Frontend: Running (PID: $frontend_pid) on ${OPENCODE_FRONTEND_HOST}:${OPENCODE_FRONTEND_PORT}"
        log "   → Access URL: http://${OPENCODE_FRONTEND_HOST}:${OPENCODE_FRONTEND_PORT}"
    else
        log "❌ Frontend: Not running"
    fi
}

# ==================== 主入口 ====================
main() {
    local command="${1:-all}"

    # 确保目录存在
    ensure_dir "$OPENCODE_LOG_DIR"
    ensure_dir "$OPENCODE_PID_DIR"

    case "$command" in
        backend)
            check_bun
            start_backend
            ;;
        frontend)
            check_bun
            start_frontend
            ;;
        all)
            check_bun
            start_backend
            start_frontend
            log ""
            show_status
            ;;
        stop)
            stop_backend
            stop_frontend
            ;;
        stop-backend)
            stop_backend
            ;;
        stop-frontend)
            stop_frontend
            ;;
        restart)
            stop_backend
            stop_frontend
            sleep 2
            check_bun
            start_backend
            start_frontend
            log ""
            show_status
            ;;
        status)
            show_status
            ;;
        *)
            echo "Usage: $0 {backend|frontend|all|stop|stop-backend|stop-frontend|restart|status}"
            echo ""
            echo "Commands:"
            echo "  backend       - Start backend only"
            echo "  frontend      - Start frontend only"
            echo "  all           - Start both backend and frontend (default)"
            echo "  stop          - Stop all services"
            echo "  stop-backend  - Stop backend only"
            echo "  stop-frontend - Stop frontend only"
            echo "  restart       - Restart all services"
            echo "  status        - Show service status"
            echo ""
            echo "Environment Variables:"
            echo "  OPENCODE_PROJECT_ROOT        - Project root directory"
            echo "  OPENCODE_BACKEND_HOST        - Backend listen host (default: 0.0.0.0)"
            echo "  OPENCODE_BACKEND_PORT        - Backend listen port (default: 4096)"
            echo "  OPENCODE_FRONTEND_HOST       - Frontend listen host (default: 127.0.0.1)"
            echo "  OPENCODE_FRONTEND_PORT       - Frontend listen port (default: 3000)"
            echo "  OPENCODE_BACKEND_SERVER_HOST - Backend server host for frontend (default: 127.0.0.1)"
            echo "  OPENCODE_BACKEND_SERVER_PORT - Backend server port for frontend (default: OPENCODE_BACKEND_PORT)"
            echo "  OPENCODE_CORS_ORIGINS        - CORS allowed origins, comma separated (e.g. http://11.166.14.24:3000)"
            echo "  OPENCODE_LOG_DIR             - Log directory"
            echo "  OPENCODE_PID_DIR             - PID files directory"
            echo ""
            echo "Examples:"
            echo "  # Start all services"
            echo "  ./start-opencode.sh"
            echo ""
            echo "  # Start with custom ports"
            echo "  OPENCODE_BACKEND_PORT=8080 OPENCODE_FRONTEND_PORT=5173 ./start-opencode.sh"
            echo ""
            echo "  # Separate deployment - Backend server (with CORS)"
            echo "  OPENCODE_BACKEND_HOST=0.0.0.0 OPENCODE_BACKEND_PORT=4096 \\"
            echo "  OPENCODE_CORS_ORIGINS=http://11.166.14.24:3000 \\"
            echo "  ./start-opencode.sh backend"
            echo ""
            echo "  # Separate deployment - Frontend server (connecting to remote backend)"
            echo "  OPENCODE_BACKEND_SERVER_HOST=11.166.14.24 OPENCODE_BACKEND_SERVER_PORT=4096 \\"
            echo "  OPENCODE_FRONTEND_HOST=0.0.0.0 OPENCODE_FRONTEND_PORT=3000 \\"
            echo "  ./start-opencode.sh frontend"
            exit 1
            ;;
    esac
}

main "$@"

