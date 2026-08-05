# AI 交接说明

## 工作范围

本任务只建立云程研 App 的治理文件、检查脚本、Hook 和 GitHub Actions。不得创建 uni-app 业务代码，不得安装 Node/HBuilderX/Android SDK，不得写入任何真实凭证，不得修改 GitHub 设置。本写入任务不执行暂存或提交；后续暂存、提交、推送和 PR 由根任务依据用户授权控制。

## 目标工作树

- 路径：`E:\yunchengyan-worktrees\TASK-0001-governance-baseline`
- 分支：`agent/TASK-0001-governance-baseline`
- 主工作树：`E:\yunchengyan`，禁止写入

## 已实现文件

治理文件见任务说明中的精确清单。核心检查入口：

```powershell
./scripts/Test-Governance.Tests.ps1
./scripts/Test-Governance.ps1 -Mode PreCommit
./scripts/Test-Governance.ps1 -Mode Ci -BaseRef origin/main
```

## 交接动作

1. 在未暂存状态下审阅工作树内容、未跟踪清单、README 变化和日志 OP-20260804-001；不要只看分支 diff。
2. 由根任务在用户授权下控制暂存、提交、推送 Draft PR；本写入任务不执行这些动作。
3. 后续工程骨架必须遵守 ARCHITECTURE.md；页面不得直连 LeanCloud。
4. 先决定包名、LeanCloud 类/ACL、同步冲突、MVP 页面、Android 签名和 SDK 版本，再进入业务实现。
