# 云程研 App 工程协作规则

## 项目身份与范围

- 官方名：云程研 App。
- 仓库：`Alioth-31/yuncheng-yan`。
- 产品仅供三人私用，无公开注册，APK 私下分发。
- 仓库当前公开，但产品仍三人私用；公开不等于产品、账号、用户数据或配置公开。Ruleset 与合并限制待本 PR CI 成功后配置。
- 本仓库不添加 LICENSE；不要擅自补充版权、隐私政策或公开服务承诺。

## 技术基线

经典 uni-app（不是 uni-app x）、Vue 3、TypeScript、Pinia、LeanCloud、本地优先。

固定边界：

```text
Page -> Feature / Use Case -> Repository -> Mapper -> Platform Adapter
```

- Page 不得直接调用 LeanCloud。
- LeanCloud SDK 只能由 Repository/Mapper 所在基础设施封装；SDK 类型不得越过 Repository/Mapper。
- `uni.*`、设备、文件、网络等平台能力必须通过 Platform Adapter。
- 本地数据是首要可用来源；同步是基础设施职责，不由页面编排。

## 分支、PR 与 Review

- 禁止直接在 `main` 上开发或提交。
- 使用短生命周期分支，例如 `agent/TASK-0001-governance-baseline` 或 `feat/<topic>`。
- 短分支合入前必须 rebase 到目标基线；源分支禁止 merge commit，治理 CI 会拒绝多父提交。
- 所有合入均通过指向 `main` 的 PR；不得创建或修改 GitHub 设置，除非用户明确授权。
- Review 默认只读：可以阅读 diff、运行本地检查和提出意见，不得自动改文件、暂存、提交、推送或修改远端。
- 未经用户明确授权，不得使用 `--no-verify`；若获得授权，必须在任务日志与 PR 说明中记录理由。
- 禁止创建、提交或依赖 `.agent` 文件或目录。

## 操作日志

- 每个源提交必须追加恰好一条 `OP-YYYYMMDD-NNN` 到 `docs/operations/PROJECT_LOG.md`。
- 日志只能追加，不能改写或删除历史条目。
- 每条 OP 必须包含：时间、任务、执行者、分支、批准阶段、变更、文件、验证、风险、下一步。
- 治理脚本会在 PreCommit 检查暂存索引，在 CI 检查相对基线的新增 OP 与源提交数。

## 隐私与凭证

- 禁止提交真实 `.env`、token、MasterKey、签名文件、私钥、证书、APK/AAB、Android 密码属性、个人隐私和用户数据。
- `.env.example` 只能保留无值或明确占位符；文档中提及“MasterKey”本身不构成凭证。
- 本治理基线不写 appId/appKey；未来经独立决策的客户端标识不应被通用敏感扫描误拦截。真实秘密仍不得提交。
- 不在日志、Issue、PR 或终端输出中回显秘密。

## 变更纪律

- 先读任务说明、现有文档和工作树状态，再修改目标文件。
- 不安装 Node、HBuilderX、Android SDK，不创建业务代码，除非任务明确授权。
- 只运行与任务相关的本地验证；完整命令和退出码写入任务交接或操作日志。
- `.githooks/pre-commit` 必须以 Git 索引模式 100755 提交；Windows 工作树的执行位不可靠，暂存前由根任务执行 `git update-index --chmod=+x .githooks/pre-commit`。
- 任何超出任务范围的系统、远端或凭证操作先停下并请求授权。
