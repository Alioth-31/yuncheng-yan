# AI 交接说明

## 当前任务

TASK-0401 在 `agent/TASK-0401-focus-domain-state-machine`、基线 `1f6e35f46898b56f0bf673f90b3f3c0d8eed34bc` 上建立最小专注领域状态机。TASK-0101、TASK-0301、TASK-0003 与 TASK-0004 已合并到该基线。

实施 Agent 只写工作树，不暂存、提交、推送、创建 PR 或修改 Git/npm 持久配置；最终 Review 与 Git/PR 流程由总控执行。

## 工具链

- 固定 Node：`D:\node-v22.23.1-win-x64`（22.23.1）
- 固定 npm：10.9.8
- 固定 Vitest：3.2.7（Vite 5.2.8、vite-node 3.2.4 保持不变）
- 固定 Node 类型：`@types/node@20.16.13`（与 TypeScript 4.9.5、Vitest/Vite 类型链实测兼容）
- wrapper：`scripts/Invoke-ProjectNode.ps1 -Tool node|npm|npx [remaining arguments]`
- cache：工作树 `.npm-cache/`
- 模板：`dcloudio/uni-preset-vue@6fb81ac3c5736b8b0a83e667b3ed90223d458dd8`

所有项目 Node/npm/npx 命令都必须通过 wrapper。不要持久化 PATH、代理或 npm 配置，不要运行 `npm update` 或 `npm audit fix`。

## 当前实现

- `src/main.ts` 保留 `createSSRApp`，每次安装新的 Pinia。
- `src/stores/index.ts` 只有 `createAppPinia()`；测试证明两次调用不共享实例。
- `tsconfig.json` 不排除测试；`npm run check` 会让 `vue-tsc` 静态检查 `pinia.spec.ts` 后再执行 Vitest。
- `vitest.config.mts` 只启用 node 环境和 `src/**/*.spec.ts`，未启用 UI、API 或 Browser server。
- 首页只显示“云程研”和“工程骨架已建立”。
- manifest AppID 为空，不含 Android permissions、包名、SDK 或签名。
- `src/features/focus/domain/focus-session.ts` 无 import，仅定义 `IDLE` / `RUNNING`、`start`、时间戳 `elapsed` 和用户主动 `end`。
- 59999 毫秒结束返回无记录的 `DISCARDED_SHORT_SESSION`；60000 与 60001 毫秒均返回 `COMPLETED`。
- `FocusRecord` 只含 readonly 的 `startedAt`、`completedAt`、`durationMs`，并由 `Object.freeze` 在运行时冻结。
- `now` 或 `completedAt` 早于 `startedAt` 时抛 `TIMESTAMP_BEFORE_START`，不结束当前会话，也不定义 UI 恢复。
- 领域实现不依赖 `uni.*`、Pinia、LeanCloud、Repository、Adapter、本地存储、同步或页面。
- 尚无业务 store、LeanCloud、Repository、Mapper、Platform Adapter、网络或页面级 `uni.*` 调用。

## TDD 与审查入口

专注测试覆盖 start、重复 start、elapsed、倒序时间、59999 丢弃、60000/60001 生成、完成字段、结束回到 IDLE、运行时冻结、readonly 编译门和 IDLE 非法动作。完整 RED/GREEN 证据与最终命令见：

`D:\Codex\artifacts\intermediate\yunchengyan-phase2\TASK-0401-focus-domain-report.md`

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Invoke-ProjectNode.ps1 -Tool npm ci
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Invoke-ProjectNode.ps1 -Tool npm audit --json
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Invoke-ProjectNode.ps1 -Tool npm audit --omit=dev --json
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Invoke-ProjectNode.ps1 -Tool npm run type-check
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Invoke-ProjectNode.ps1 -Tool npm run lint
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Invoke-ProjectNode.ps1 -Tool npm run test:run
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Invoke-ProjectNode.ps1 -Tool npm run build:h5
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Invoke-ProjectNode.ps1 -Tool npm run check
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Invoke-ProjectNode.Tests.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-Governance.Tests.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-Governance.ps1 -Mode Ci -BaseRef origin/main
```

依赖补丁证据见 `D:\Codex\artifacts\intermediate\yunchengyan-phase1\TASK-0004-vitest-security-report.md`；专注领域 RED/GREEN 与最终验证证据见 `D:\Codex\artifacts\intermediate\yunchengyan-phase2\TASK-0401-focus-domain-report.md`。

基线总审计 67 项时，唯一 critical 是 `vitest@3.2.4` 的 `GHSA-5xrq-8626-4rwp`；默认脚本和配置未启用其 UI/API/Browser server，但手工启用这些开发入口仍会形成可达路径。精确升级至 3.2.7 后总审计为 66 项（0 critical、13 high）；`--omit=dev` 前后均为 45 项（0 critical、11 high）。剩余风险需按 DCloud/Vite cohort 独立治理，不得运行 `npm audit fix`、broad overrides 或无验证的联动升级。
## 后续约束

TASK-0401 没有授权暂停/恢复、后台/杀进程/重启恢复、活动中主动放弃、短会话二次确认或取消恢复、单调时钟、平台时间 Adapter、Repository、持久化、LeanCloud、同步、页面/Pinia、统计聚合、科目/任务/备注或自动打卡。后续任务只能消费本领域契约，不得把这些排除项解释为已决定。
