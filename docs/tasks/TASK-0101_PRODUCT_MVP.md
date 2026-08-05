# TASK-0101：产品需求与页面交互

## 目标

在不创建业务代码的前提下，形成可审阅、可测试的云程研 App MVP 产品范围、页面流程和验收条件。

## 范围

- 确认三人私用、无公开注册、APK 私下分发的产品边界。
- 定义邀请码首次注册、账号密码登录与保持登录。
- 定义“今日”“专注”“小队”“我的”四个主入口的 MVP 职责。
- 固化专注、短会话、记录删除、每日打卡和本地时间统计规则。
- 区分 MVP、v0.2 或以后能力与待决项。
- 记录经典 uni-app Vue 3、TypeScript、Pinia、LeanCloud、本地优先及固定分层边界，但不做工程实现。

## 明确不做

- 不创建或修改业务代码、工程配置、LeanCloud 配置或凭证。
- 不实现独立留言、笔记、错题、附件、排行榜、公开注册或番茄钟。
- 不自行决定账号校验、计时异常恢复、打卡状态、统计指标、同步冲突、LeanCloud 类/ACL 等未确认事项。
- 不修改 `docs/PROJECT_STATUS.md`、`docs/ROADMAP.md`、`docs/DECISIONS.md` 或 `CHANGELOG.md`；由后续事实回写任务统一更新。
- 本任务不暂存、不提交、不推送、不创建 PR、不修改 Git 设置，也不触碰 `main`。

## 交付文件

| 文件 | 内容 |
| --- | --- |
| `docs/product/MVP_SCOPE.md` | MVP 边界、已确认规则、延后项和待决项 |
| `docs/product/PAGE_FLOWS.md` | 首次进入、登录、快速开始、计时结束、短会话放弃、打卡、统计和删除确认流程 |
| `docs/product/ACCEPTANCE_CRITERIA.md` | 可转化为测试的验收条件与边界值 |
| `docs/tasks/TASK-0101_PRODUCT_MVP.md` | 本任务范围、交付、验证、风险与后续依赖 |
| `docs/operations/PROJECT_LOG.md` | 仅追加 `OP-20260805-001` |

## 关键结论

- MVP 身份入口只有一次性邀请码注册与既有账号密码登录；邀请码由负责人线下预置，客户端不管理邀请码。
- 专注采用正计时；少于 1 分钟必须提示并放弃，达到 1 分钟可保存；完成时长不可编辑。
- 打卡与专注相互独立，每人每天手动一次，内容为状态加可选 0–140 字。
- 专注统计采用设备本地完成时刻，提供日、周、月视图，周一至周日为一周。
- 历史专注记录只能由创建者在确认后删除。

## 验证计划

生成文档后仅运行不会改变 Git 索引的检查：

```powershell
git diff --check
git status --short
git diff --stat
```

- `git diff --check` 用于发现空白错误。
- `git status --short` 用于确认只有授权文件发生未暂存变更。
- `git diff --stat` 写入交接报告，用于汇总已跟踪文件变更；新文件另按状态清单报告。
- 完整命令与退出码写入 `D:\Codex\artifacts\intermediate\yunchengyan-phase1\TASK-0101-report.md`。

## 风险

- 账号规则、计时异常处理、打卡跨日边界、统计展示和同步策略尚未确定，进入实现前需要独立决策。
- `docs/DECISIONS.md`、`docs/PROJECT_STATUS.md` 和路线图本任务不更新，在后续事实回写前可能仍显示“MVP 页面待决”的旧状态。
- 本任务只形成文档，不验证 HBuilderX、Android、LeanCloud 或真机行为。

## 后续依赖

1. 控制线程与用户审阅并批准本任务文档。
2. 后续事实回写任务统一更新状态、路线图与决策记录，避免并行冲突。
3. 对待决项形成明确产品或技术决策，尤其是身份校验、计时异常、打卡跨日、统计指标、同步冲突与 LeanCloud 类/ACL。
4. 工程实现必须继续遵守 Page → Feature / Use Case → Repository → Mapper → Platform Adapter，并为本文件引用的验收条件建立测试。

## 当前交接状态

文件生成，待用户批准暂存。本任务停在未暂存、未提交状态。
