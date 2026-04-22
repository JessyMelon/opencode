# OpenCode Mobile Web RFC

## Summary

本文档定义 OpenCode Web 前端在移动端上的改造方案。

目标是在不影响当前桌面 Web 显示和交互的前提下，为 `md` 以下断点提供一套更适合手机浏览器的 UI 壳层与交互模型。

核心结论：

- 保留当前 desktop shell
- 新增 mobile shell
- 复用现有数据流、状态管理和业务逻辑
- 优先改造导航、review 入口、composer 和临时面板层级

## Motivation

当前 OpenCode Web 前端在手机上可用，但体验不佳，主要问题包括：

- 侧栏仍沿用桌面布局思路，抽屉打开后信息层级混乱
- 顶部按钮密度过高，触控目标偏小
- 会话区和更改区的切换方式更像桌面压缩版，而不是移动端界面
- 输入区占用高度较大，模型、Agent、Variant 控件长期常驻
- 安全区、键盘弹起和底部浮层之间缺少统一适配
- debug bar 在小屏上会遮挡关键交互区域

## Goals

1. 不影响当前桌面 Web 布局和交互
2. 为 `md` 以下断点提供独立的移动端 UI 壳层
3. 尽量复用现有数据流、状态管理和业务逻辑
4. 把移动端交互调整为更符合单列、触控、临时面板的模式

## Non-Goals

- 不重写整个会话页业务逻辑
- 不改变桌面端 sidebar、review panel、composer 的默认行为
- 不在第一阶段处理所有桌面功能的移动端等价映射

## Design Constraints

1. `session` 页继续作为单一的数据与状态编排层，移动端不要复制会话页业务逻辑
2. 移动端优先通过壳层、面板和包装组件改造，不重写消息流、review 数据和会话状态来源
3. 所有移动端布局切换使用同一断点来源，避免在不同组件中混用 `md`、`xl` 等规则
4. safe area、键盘弹起和可视视口高度统一收敛到共享能力，不在多个组件中各自处理

## Proposal

### Overall Strategy

采用“新增 mobile shell，不破坏 desktop shell”的方式实现。

具体原则：

- 桌面端继续使用现有页面结构
- 在移动端断点下切换到专用外层容器
- 复用现有数据、消息流、review 数据、session 状态
- 仅替换外层导航、侧栏、输入区和操作入口的呈现方式

补充原则：

- `session.tsx` 仍负责会话数据、消息流、tab、review、followup 等状态编排
- 移动端优先新增轻量壳层与包装组件，而不是复制一套新的 session 页面逻辑
- 先统一断点与 viewport 适配，再做具体 UI 改造，避免后续出现重复分支和局部补丁

### Recommended Architecture

建议优先新增以下移动端组件或页面壳：

- `packages/app/src/pages/mobile/mobile-layout.tsx`
- `packages/app/src/pages/mobile/mobile-shell.tsx`
- `packages/app/src/pages/mobile/mobile-composer.tsx`
- `packages/app/src/pages/mobile/mobile-review-sheet.tsx`

第一阶段不建议一开始就新增完整的 `mobile-session-shell.tsx`。如果后续发现 `session.tsx` 内的视图分支已经明显影响维护，再把移动端会话壳层进一步拆出。

`mobile-sidebar-sheet` 也不必先独立为完整数据组件，可以先基于现有 sidebar 数据与 `layout.mobileSidebar` 状态做移动端包装。

桌面端继续沿用：

- `packages/app/src/pages/layout.tsx`
- `packages/app/src/pages/session.tsx`

切换原则：

- `md` 及以上：走当前桌面布局
- `md` 以下：走移动端专用布局壳层

### Breakpoint And Viewport Strategy

这是移动端改造的前置步骤，应先于具体 UI 改造落地。

#### Unified Breakpoint

- 使用单一的移动端断点来源，推荐统一为 `md` 分界
- 布局壳、sidebar、header、review、composer、debug bar 都应依赖同一套断点判断
- 不建议在不同区域混用 CSS 断点和局部 `createMediaQuery` 逻辑，导致平板和小桌面设备表现不一致

建议做法：

- 抽取统一的布局断点能力，例如 `isMobileLayout`
- 由外层 layout 和 session 页面共同消费
- 需要响应式分支时优先复用这套判断，而不是在组件内部各自定义一套条件

#### Unified Viewport And Safe Area

- 统一处理 `env(safe-area-inset-top)`
- 统一处理 `env(safe-area-inset-bottom)`
- 统一处理 `100dvh`
- 统一处理 `visualViewport`

建议做法：

- 提供共享的 viewport/safe-area 能力，输出顶部 inset、底部 inset、可视高度、键盘相关状态
- `mobile shell`、底部输入区、全屏 sheet、顶部栏统一消费这些值
- 不在 sidebar、composer、review sheet、debug bar 中分别实现各自的键盘和安全区适配

### UX Changes

#### 1. 侧栏

现状：

- 移动端侧栏仍复用桌面双栏结构
- 展开后仍然是 rail + panel 组合
- 主内容仍然在后方可见，层级不清晰

涉及文件：

- `packages/app/src/pages/layout.tsx`
- `packages/app/src/pages/layout/sidebar-shell.tsx`

建议：

- 手机端不要复用双栏 sidebar 视觉结构
- 改成单层全屏或大宽度 sheet
- 顶部放 workspace 切换和“新建会话”
- 中间直接显示 session 列表
- 设置和帮助移到底部或右上角 overflow 菜单

补充优化：

- 第一阶段优先复用现有 sidebar 数据与排序逻辑，只替换移动端容器和层级
- 侧栏开关状态继续复用现有 layout context，不新增第二套移动端 sidebar 状态
- 先解决信息层级和触控问题，不在第一阶段重做 workspace/project 的业务行为

#### 2. 顶部栏

现状：

- 手机端顶部按钮较多
- 按钮尺寸更适合桌面点击，不适合触控
- 搜索、状态、终端等操作同时暴露，密度过高

涉及文件：

- `packages/app/src/components/titlebar.tsx`
- `packages/app/src/components/session/session-header.tsx`

建议：

- 手机上精简为三段式：左侧菜单，中间标题，右侧少量高频操作
- 其余功能进入 `...` 菜单
- 提高触控区域到接近 40 至 44px
- 统一适配顶部 safe area

补充优化：

- 先收敛高频动作，避免把桌面端所有入口继续投射到移动端顶部栏
- 顶部栏不承担 review、终端、设置、搜索等全部入口，非高频动作统一进入 overflow
- 如果标题栏当前已承载桌面窗口行为，移动端应独立处理，避免桌面交互语义污染移动端结构

#### 3. 会话与更改切换

现状：

- 手机端当前仍使用顶部 tab 在“会话 / 更改”之间切换
- 表达方式更像桌面面板压缩，不像移动端主次分层

涉及文件：

- `packages/app/src/pages/session.tsx`
- `packages/app/src/pages/session/session-side-panel.tsx`

建议：

- 默认主视图只显示消息流
- “更改 / review” 进入独立的全屏 sheet 或全屏页面
- review/file diff 不再和主会话处于同一页面层级的硬切换关系

补充优化：

- 移动端的 review 应视为第二层页面状态，而不是桌面 tab 的压缩映射
- 可以采用全屏 sheet，也可以采用明确的路由态或查询参数表达当前是否进入 review
- 核心是让“当前是否在 review 视图中”有单一状态来源，不继续绑定桌面侧栏 tab 语义

#### 4. 输入区

现状：

- 输入框默认高度较大
- 底部 tray 长期显示 Agent、Model、Variant 等控件
- 手机上会压缩消息阅读区域

涉及文件：

- `packages/app/src/components/prompt-input.tsx`
- `packages/app/src/pages/session/composer/session-composer-region.tsx`

建议：

- 手机上默认只显示输入框、附件按钮、发送按钮
- Agent、Model、Variant 收进底部参数面板
- 降低默认输入区域高度
- 统一为底部输入区增加 safe area 适配

补充优化：

- 第一阶段优先包装 `PromptInput`，不直接深改其内部结构
- 通过移动端 composer wrapper 控制按钮显隐、参数面板入口和底部布局
- 参数面板作为独立 sheet 处理，避免继续把 `PromptInput` 做成复杂的桌面/移动混合组件

#### 5. 安全区、键盘与浮层

现状：

- terminal panel 已使用 `visualViewport`
- 但主布局、composer、mobile sidebar 尚未形成统一适配
- debug bar 在小屏上会遮挡输入区

涉及文件：

- `packages/app/src/pages/layout.tsx`
- `packages/app/src/components/titlebar.tsx`
- `packages/app/src/components/prompt-input.tsx`
- `packages/app/src/components/debug-bar.tsx`

建议：

- 统一适配：
  - `env(safe-area-inset-top)`
  - `env(safe-area-inset-bottom)`
  - `100dvh`
  - `visualViewport`
- 键盘弹起时重新计算消息区和输入区高度
- 小屏默认隐藏 debug bar，或改为可展开入口

补充优化：

- 不建议仅用局部样式补丁处理键盘遮挡，应由统一 viewport 层驱动布局更新
- debug bar 在移动端不应参与主布局占位
- 开发环境下可改为悬浮入口 + bottom sheet，生产环境默认隐藏

### Information Architecture

移动端建议改为四层结构：

1. 顶部栏
2. 主消息区
3. 底部输入区
4. 临时面板（sheet / drawer）

临时面板承载：

- 会话列表
- review / changes
- 模型和 Agent 参数
- 设置 / 帮助

这能减少桌面式多栏并列带来的拥挤感。

补充建议：

- 临时面板应尽量共用一套展示范式，减少不同 drawer、sheet、popover 的交互差异
- review、参数面板、设置面板的进入和返回路径应保持一致
- 移动端返回路径应优先遵循“关闭当前临时面板，再返回主消息区”的层级规则

## Implementation Plan

### Phase 1: Minimum Viable Mobile Shell

目标：在不破坏桌面端的前提下明显改善手机体验。

建议先做：

1. 统一移动端断点判断
2. 统一 viewport、safe area 与键盘弹起能力
3. 新增移动端容器和断点切换
4. 基于现有 sidebar 状态实现 mobile sidebar sheet
5. 新增 mobile header
6. 精简 mobile composer wrapper
7. 小屏隐藏 debug bar 或改为可展开入口

第一阶段先不重做 review 内部结构，只优化入口和层级。

### Phase 2: Deeper Mobile Refinement

建议继续做：

1. 新增 mobile review 全屏 sheet
2. 新增模型、Agent、Variant 的参数面板
3. 统一 review 视图状态表达，必要时拆为路由态或独立页面态
4. 优化移动端页面切换和返回路径
5. 评估是否需要进一步拆出 `mobile-session-shell.tsx`

## Why This Should Not Affect Desktop

原因如下：

- 桌面端组件和布局路径保持不变
- 移动端走独立 UI 壳层
- 复用现有数据和业务逻辑，减少桌面组件深度修改
- 响应式切换点清晰，避免在同一组件中堆积过多条件分支

## Risks

主要风险有：

1. session 页面状态较多，移动端壳层要避免复制业务逻辑
2. `PromptInput` 当前偏桌面化，移动端应优先包装而不是深改
3. review/file panel 当前与桌面布局关系较深，拆成移动端独立视图时需要做状态解耦
4. 如果断点策略不统一，平板、小桌面和折叠屏场景会出现布局切换不一致
5. 如果 safe area 和键盘适配继续分散在组件内部，后续维护成本会快速上升

## Decision

推荐采用“mobile shell + desktop shell 并存”的方案。

不建议直接在当前桌面布局上继续堆叠移动端样式补丁，因为那会让后续维护和交互一致性越来越差。

最稳妥的落地方式是：

- 桌面端保持现状
- 移动端新增专用壳层
- 第一阶段先统一断点与视口能力，再解决层级、导航和输入区问题
- 第二阶段再做 review 与参数面板的移动端重构
- 只有在 `session.tsx` 的视图分支复杂度明显增加时，再考虑拆出完整的 mobile session shell
