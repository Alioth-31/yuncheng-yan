# AI 交接说明

## 当前任务

TASK-0004 在 `agent/TASK-0004-vitest-security-patch`、基线 `2384968acd13205ad1496d6b26f505fa2b2b0aa4` 上只处理 Vitest 安全补丁。TASK-0101、TASK-0301 与 TASK-0003 已合并到该基线。

实施 Agent 只写工作树，不暂存、提交、推送、创建 PR 或修改 Git/npm 持久配置；这些动作由控制任务另行批准和执行。

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
- 尚无业务 store、LeanCloud、Repository、Mapper、Adapter、网络或 `uni.*` 调用。

## 审查与验证入口

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Invoke-ProjectNode.Tests.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Invoke-ProjectNode.ps1 -Tool npm ci
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Invoke-ProjectNode.ps1 -Tool npm audit --json
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Invoke-ProjectNode.ps1 -Tool npm audit --omit=dev --json
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Invoke-ProjectNode.ps1 -Tool npm run check
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Invoke-ProjectNode.ps1 -Tool npm run build:h5
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-Governance.Tests.ps1
```

完整 RED/GREEN 和验证证据见 `D:\Codex\artifacts\intermediate\yunchengyan-phase1\TASK-0004-vitest-security-report.md`。

基线总审计 67 项时，唯一 critical 是 `vitest@3.2.4` 的 `GHSA-5xrq-8626-4rwp`；默认脚本和配置未启用其 UI/API/Browser server，但手工启用这些开发入口仍会形成可达路径。精确升级至 3.2.7 后总审计为 66 项（0 critical、13 high）；`--omit=dev` 前后均为 45 项（0 critical、11 high）。剩余风险需按 DCloud/Vite cohort 独立治理，不得运行 `npm audit fix`、broad overrides 或无验证的联动升级。

## 后续约束

不要把 TASK-0101/TASK-0301 的待决建议当成实现授权。LeanCloud 类/ACL、三人可见性、邀请码受控执行、逐实体冲突、Android 包名/签名/SDK 均需独立批准；H5 构建也不证明 Android 或真机可用。
