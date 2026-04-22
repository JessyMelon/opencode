# OpenCode Mobile Web Plan

本文档记录 OpenCode Web 前端在移动端上的改造方向，目标是在不影响当前桌面 Web 显示和交互的前提下，补充一套更适合手机浏览器的界面方案。

## 背景

当前 OpenCode Web 前端在手机上可用，但体验不佳，主要问题包括：

- 侧栏仍沿用桌面布局思路，抽屉打开后信息层级混乱
- 顶部按钮密度过高，触控目标偏小
- 会话区和更改区的切换方式更像桌面压缩版，而不是移动端界面
- 输入区占用高度较大，模型、Agent、Variant 控件长期常驻
- 安全区、键盘弹起和底部浮层之间缺少统一适配
- debug bar 在小屏上会遮挡关键交互区域

## 目标

1. 不影响当前桌面 Web 布局和交互
2. 为 `md` 以下断点提供独立的移动端 UI 壳层
3. 尽量复用现有数据流、状态管理和业务逻辑
4. 把移动端交互调整为更符合单列、触控、临时面板的模式

## 非目标

- 不重写整个会话页业务逻辑
- 不改变桌面端 sidebar、review panel、composer 的默认行为
- 不在第一阶段处理所有桌面功能的移动端等价映射

## 总体策略

采用“新增 mobile shell，不破坏 desktop shell”的方式实现。

具体原则：

- 桌面端继续使用现有页面结构
- 在移动端断点下切换到专用外层容器
- 复用现有数据、消息流、review 数据、session 状态
- 仅替换外层导航、侧栏、输入区和操作入口的呈现方式

## 推荐架构

建议新增以下移动端组件或页面壳：

- `packages/app/src/pages/mobile/mobile-layout.tsx`
- `packages/app/src/pages/mobile/mobile-session-shell.tsx`
- `packages/app/src/pages/mobile/mobile-sidebar-sheet.tsx`
- `packages/app/src/pages/mobile/mobile-composer.tsx`
- `packages/app/src/pages/mobile/mobile-review-sheet.tsx`

桌面端继续沿用：

- `packages/app/src/pages/layout.tsx`
- `packages/app/src/pages/session.tsx`

切换原则：

- `md` 及以上：走当前桌面布局
- `md` 以下：走移动端专用布局壳层

## 现有问题与改造点

### 1. 侧栏

现状：

- 移动端侧栏仍复用桌面双栏结构
- 展开后仍然是 rail + panel 组合
- 主内容仍然在后方可见，层级不清晰

涉及文件：

- `packages/app/src/pages/layout.tsx`
- `packages/app/src/pages/layout/sidebar-shell.tsx`

建议：

- 手机端不要复用双栏 sidebar
- 改成单层全屏或大宽度 sheet
- 顶部放 workspace 切换和“新建会话”
- 中间直接显示 session 列表
- 设置和帮助移到底部或右上角 overflow 菜单

### 2. 顶部栏

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

### 3. 会话与更改切换

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

### 4. 输入区

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

### 5. 安全区、键盘与浮层

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

## 移动端信息架构建议

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

## 建议实施顺序

### 第一阶段：最小可落地版本

目标：在不破坏桌面端的前提下明显改善手机体验。

建议先做：

1. 新增移动端容器和断点切换
2. 新增 mobile sidebar sheet
3. 新增 mobile header
4. 精简 mobile composer
5. 小屏隐藏 debug bar

第一阶段先不重做 review 内部结构，只优化入口和层级。

### 第二阶段：深入优化

建议继续做：

1. 新增 mobile review 全屏 sheet
2. 新增模型、Agent、Variant 的参数面板
3. 统一 safe area 和键盘弹起联动
4. 优化移动端页面切换和返回路径

## 为什么这个方案不会影响桌面端

原因如下：

- 桌面端组件和布局路径保持不变
- 移动端走独立 UI 壳层
- 复用现有数据和业务逻辑，减少桌面组件深度修改
- 响应式切换点清晰，避免在同一组件中堆积过多条件分支

## 风险点

主要风险有：

1. session 页面状态较多，移动端壳层要避免复制业务逻辑
2. `PromptInput` 当前偏桌面化，移动端应优先包装而不是深改
3. review/file panel 当前与桌面布局关系较深，拆成移动端独立视图时需要做状态解耦

## 推荐结论

推荐采用“mobile shell + desktop shell 并存”的方案。

不建议直接在当前桌面布局上继续堆叠移动端样式补丁，因为那会让后续维护和交互一致性越来越差。

最稳妥的落地方式是：

- 桌面端保持现状
- 移动端新增专用壳层
- 第一阶段先解决层级、导航和输入区问题
- 第二阶段再做 review 与参数面板的移动端重构
