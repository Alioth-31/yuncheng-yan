# 云程研 App

仓库：`Alioth-31/yuncheng-yan`

这是一个三人私用的考研辅助 App。产品不公开注册，仅通过私下分发 APK；仓库当前公开，但不代表产品、用户数据或凭证公开。Ruleset 与合并限制待本 PR CI 成功后配置。

## 当前基线

- 经典 uni-app（不是 uni-app x）
- Vue 3、TypeScript、Pinia
- LeanCloud；本地优先
- 页面不得直接调用 LeanCloud
- SDK 类型不得越过 Repository/Mapper
- 平台能力必须通过 Platform Adapter

当前提交只建立治理、文档和本地检查基线，不创建业务页面或业务代码。

## 分层边界

```text
Page -> Feature / Use Case -> Repository -> Mapper -> Platform Adapter
```

页面只消费 Feature/Use Case 暴露的应用类型；LeanCloud SDK 只能位于基础设施实现与 Mapper 内；本地存储优先于远端同步。

## 本地检查

在已安装 Git 的克隆目录运行：

```powershell
./scripts/Initialize-Clone.ps1
./scripts/Test-Governance.Tests.ps1
./scripts/Test-Governance.ps1 -Mode PreCommit
./scripts/Test-Governance.ps1 -Mode Ci -BaseRef origin/main
```

PreCommit 检查暂存索引；CI 检查工作树与相对基线的治理变更。脚本不依赖 Node、Pester 或任何真实凭证。

## 分支与 Hook 模式

短分支合入前必须 rebase 到目标基线，源分支不得包含 merge commit；治理 CI 会拒绝多父提交。`.githooks/pre-commit` 必须以 Git 索引模式 100755 保存；Windows 工作树执行位可能不可见，暂存前运行 `git update-index --chmod=+x .githooks/pre-commit`。

## 尚未决定

包名、LeanCloud 类与 ACL、同步冲突策略、具体 MVP 页面、Android 签名方式和 SDK 版本均为“待决”，不得在治理基线中臆定。

## 安全边界

真实 `.env`、LeanCloud MasterKey、GitHub token、Android 密码属性、签名文件、私钥、APK/AAB 均不得进入仓库。只提交无值的 `.env.example` 和文档说明。

本仓库不添加 LICENSE；仓库当前公开，但产品仍三人私用；Ruleset 与合并限制待本 PR CI 成功后配置。不引入业务依赖、不修改 GitHub 仓库设置、不提交或推送。
