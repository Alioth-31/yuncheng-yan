# TASK-0001：项目治理基线

## 目标

为“云程研 App”建立可审查、可复现、不会带入凭证的仓库治理基线。

## 范围

- 写入项目身份、架构边界、状态、路线图、AI 交接和变更日志文档。
- 写入 Git 忽略/属性/编辑器规则、Codex 并发配置。
- 写入 PowerShell 治理检查、非 Pester fixture 测试、POSIX Hook、克隆初始化脚本。
- 写入 GitHub Governance workflow 和 PR 模板。

## 明确不做

- 不创建 uni-app 业务代码、页面、Pinia store 或 LeanCloud Repository。
- 不安装 Node、HBuilderX、Android SDK、ADB 或任何依赖。
- 不写真实 appId/appKey、MasterKey、token、签名文件、个人隐私或 LICENSE。
- 不暂存、提交、推送、创建 PR 或修改 GitHub 仓库设置。
- 短分支必须 rebase，禁止以 merge commit 合入；`.githooks/pre-commit` 提交模式必须为 100755。

## 验收

- `Test-Governance.Tests.ps1` 覆盖缺日志、合格追加、删除历史日志、允许客户端标识、敏感暂存内容、`.env.example` 值和历史敏感提交回归场景。
- `Test-Governance.ps1` 提供 `PreCommit` 和 `Ci -BaseRef` 接口，PowerShell 5.1 可运行且无需 Node/Pester。
- Hook 优先使用 `powershell.exe`，其次 `pwsh`，无解释器时失败。
- CI 使用 `actions/checkout@v7.0.1`、`fetch-depth: 0`、`permissions: contents: read`。
- 每个源提交追加一条包含全部字段的 OP；本任务先追加 OP-20260804-001。
- CI 必须拒绝源分支 merge commit，并校验受控 Hook 的 Git 索引模式为 100755。
