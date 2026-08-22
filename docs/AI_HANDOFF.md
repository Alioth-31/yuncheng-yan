# AI 交接说明

## 当前任务

TASK-0003 在 `agent/TASK-0003-app-scaffold`、基线 `2c9f928f2f6bb70ee42248d8e6ad3403b4fb78c1` 上建立工程骨架。TASK-0101 与 TASK-0301 已合并到该基线。

实施 Agent 只写工作树，不暂存、提交、推送、创建 PR 或修改 Git/npm 持久配置；这些动作由控制任务另行批准和执行。

## 工具链

- 固定 Node：`D:\node-v22.23.1-win-x64`（22.23.1）
- 固定 npm：10.9.8
- 固定 Node 类型：`@types/node@20.16.13`（与 TypeScript 4.9.5、Vitest/Vite 类型链实测兼容）
- wrapper：`scripts/Invoke-ProjectNode.ps1 -Tool node|npm|npx [remaining arguments]`
- cache：工作树 `.npm-cache/`
- 模板：`dcloudio/uni-preset-vue@6fb81ac3c5736b8b0a83e667b3ed90223d458dd8`

所有项目 Node/npm/npx 命令都必须通过 wrapper。不要持久化 PATH、代理或 npm 配置，不要运行 `npm update` 或 `npm audit fix`。

## 当前实现

- `src/main.ts` 保留 `createSSRApp`，每次安装新的 Pinia。
- `src/stores/index.ts` 只有 `createAppPinia()`；测试证明两次调用不共享实例。
- `tsconfig.json` 不排除测试；`npm run check` 会让 `vue-tsc` 静态检查 `pinia.spec.ts` 后再执行 Vitest。
- 首页只显示“云程研”和“工程骨架已建立”。
- manifest AppID 为空，不含 Android permissions、包名、SDK 或签名。
- 尚无业务 store、LeanCloud、Repository、Mapper、Adapter、网络或 `uni.*` 调用。

## 审查与验证入口

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Invoke-ProjectNode.Tests.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Invoke-ProjectNode.ps1 -Tool npm ci
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Invoke-ProjectNode.ps1 -Tool npm run check
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Invoke-ProjectNode.ps1 -Tool npm run build:h5
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-Governance.Tests.ps1
```

完整 RED/GREEN 和验证证据见 `D:\Codex\artifacts\intermediate\yunchengyan-phase1\TASK-0003-app-scaffold-report.md`。

依赖审计保持已知而未盲升：总计 67；`--omit=dev` 为 45（0 critical、11 high）。Vitest 3.2.4 的 critical 对应 UI server 文件读取/执行路径；本项目没有启用 Vitest UI、API 或 Browser server，但仍需后续独立治理。

## 后续约束

不要把 TASK-0101/TASK-0301 的待决建议当成实现授权。LeanCloud 类/ACL、三人可见性、邀请码受控执行、逐实体冲突、Android 包名/签名/SDK 均需独立批准；H5 构建也不证明 Android 或真机可用。
