# OpenCode Usage Modes

本文档说明如何使用当前 `opencode/` 目录下的启动脚本和任务脚本，并给出不同 mode 的实际示例。

## 文件说明

- `start-opencode.sh`
  - 启动 OpenCode 前后端服务
- `my_start.sh`
  - 带默认公网访问参数的启动入口
- `run-opencode-task.sh`
  - 启动或复用 backend，并直接执行任务
- `task.txt`
  - 基于 `coder-llm-wiki` 的半托管启动任务模板
- `task-unattended-deep.txt`
  - 基于 `coder-llm-wiki` 的无人值守深跑任务模板

## 前提条件

如果要分析某个代码仓库，例如 `my_code/`，需要保证：

1. 目标仓库根目录下已经有 `coder-llm-wiki/`
2. `opencode/` 目录中的脚本可执行
3. 本机可正常运行 `bun`

目录结构示例：

```text
/home/admin/work/
├── opencode/
├── coder-llm-wiki/
└── my_code/
    ├── coder-llm-wiki/
    ├── src/
    └── ...
```

如果 `my_code/` 里还没有 `coder-llm-wiki/`，先复制进去：

```bash
cp -r /home/admin/work/coder-llm-wiki /home/admin/work/my_code/
```

## 三种 Mode

### 1. supervised

适合人工值守。

特点：

- 尽量保留人工确认
- 更适合边看边调
- 不适合长时间无人值守批处理

启动 backend：

```bash
cd /home/admin/work/opencode
OPENCODE_PERMISSION_MODE=supervised ./my_start.sh backend
```

运行任务：

```bash
./run-opencode-task.sh \
  --no-start \
  --mode supervised \
  --dir /home/admin/work/my_code \
  --prompt-file ./task.txt
```

### 2. deferred-review

适合半托管，推荐日常使用。

特点：

- 尽量连续执行
- 不主动问“下一步做什么”
- 待人工判断项优先写入 review 文档
- 比 `unattended` 更保守

启动 backend：

```bash
cd /home/admin/work/opencode
OPENCODE_PERMISSION_MODE=deferred-review ./my_start.sh backend
```

运行任务：

```bash
./run-opencode-task.sh \
  --no-start \
  --mode deferred-review \
  --dir /home/admin/work/my_code \
  --background \
  --prompt-file ./task.txt
```

适用场景：

- 想尽量自动跑
- 但不想完全放弃人工复核
- 适合首次初始化和日常增量维护

### 3. unattended

适合无人值守批处理。

特点：

- 自动放行更多能力
- 尽量持续推进直到达到步数上限或遇到硬阻塞
- 更适合夜间跑一批初始化和深度分析

启动 backend：

```bash
cd /home/admin/work/opencode
OPENCODE_PERMISSION_MODE=unattended ./my_start.sh backend
```

运行任务：

```bash
./run-opencode-task.sh \
  --no-start \
  --mode unattended \
  --dir /home/admin/work/my_code \
  --background \
  --prompt-file ./task-unattended-deep.txt
```

适用场景：

- 想让 `coder-llm-wiki` 从初始化一路推进到 module、flow、review、snapshot
- 想对一个仓库先无人值守跑一轮

## 推荐选择

如果你不知道该选哪个 mode：

1. 想人工盯着看：`supervised`
2. 想尽量自动但保留边界：`deferred-review`
3. 想后台尽可能跑完一整轮：`unattended`

## 示例：无人值守分析 `my_code/`

这是最常用的完整示例。

### 第一步：确保目标仓库有 `coder-llm-wiki`

```bash
cp -r /home/admin/work/coder-llm-wiki /home/admin/work/my_code/
```

### 第二步：启动 backend

```bash
cd /home/admin/work/opencode
OPENCODE_PERMISSION_MODE=unattended ./my_start.sh backend
```

### 第三步：后台跑深度任务

```bash
./run-opencode-task.sh \
  --no-start \
  --mode unattended \
  --dir /home/admin/work/my_code \
  --background \
  --prompt-file ./task-unattended-deep.txt
```

如果 backend 还没启动，也可以直接一条命令：

```bash
cd /home/admin/work/opencode
./run-opencode-task.sh \
  --mode unattended \
  --dir /home/admin/work/my_code \
  --background \
  --prompt-file ./task-unattended-deep.txt
```

## 输出和检查位置

任务运行后，重点检查：

- `my_code/coder-llm-wiki/00-meta/status-dashboard.md`
- `my_code/coder-llm-wiki/00-meta/progress.json`
- `my_code/coder-llm-wiki/00-meta/task-queue.json`
- `my_code/coder-llm-wiki/03-modules/`
- `my_code/coder-llm-wiki/04-flows/`
- `my_code/coder-llm-wiki/09-review/`
- `my_code/coder-llm-wiki/10-snapshots/`

后台模式下，脚本会输出日志文件路径，通常在：

```text
/home/admin/work/opencode/logs/task-YYYYMMDD-HHMMSS.log
```

查看日志：

```bash
less /home/admin/work/opencode/logs/task-YYYYMMDD-HHMMSS.log
```

## 任务模板选择

- `task.txt`
  - 半托管启动版
  - 适合初始化、增量推进
- `task-unattended-deep.txt`
  - 无人值守深跑版
  - 适合希望继续做 module、flow、review、snapshot 的场景

## 常用命令速查

查看服务状态：

```bash
cd /home/admin/work/opencode
./my_start.sh status
```

停止服务：

```bash
cd /home/admin/work/opencode
./my_start.sh stop
```

半托管跑一次：

```bash
cd /home/admin/work/opencode
./run-opencode-task.sh \
  --mode deferred-review \
  --dir /home/admin/work/my_code \
  --background \
  --prompt-file ./task.txt
```

无人值守深跑：

```bash
cd /home/admin/work/opencode
./run-opencode-task.sh \
  --mode unattended \
  --dir /home/admin/work/my_code \
  --background \
  --prompt-file ./task-unattended-deep.txt
```
