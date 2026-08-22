# TASK-0004：Vitest 依赖风险治理

## 范围与结论

- 基线：`2384968acd13205ad1496d6b26f505fa2b2b0aa4`
- 分支：`agent/TASK-0004-vitest-security-patch`
- 工具链：Node 22.23.1、npm 10.9.8、`scripts/Invoke-ProjectNode.ps1`
- 结论：将直接开发依赖 `vitest` 从精确 3.2.4 升至精确 3.2.7；不升级 Vite、DCloud、Vue、TypeScript，不使用 `npm audit fix` 或 overrides。

## 基线风险与可达性

锁定 npm 的基线 `npm audit --json` 报告 67 项：33 low、20 moderate、13 high、1 critical。唯一 critical 是直接开发依赖 `node_modules/vitest` 的 [GHSA-5xrq-8626-4rwp](https://github.com/advisories/GHSA-5xrq-8626-4rwp)，受影响范围 `<3.2.6`；当 Vitest UI/API/Browser server 监听时，Windows 路径处理可导致任意文件读取，并可借助写入和重跑能力执行脚本。

当前 `package.json` 的测试入口只调用 `vitest`/`vitest run`，`vitest.config.mts` 只配置 node 环境和 `src/**/*.spec.ts`，仓库没有 `--ui`、`--api`、Browser Mode 或远程 host 配置。因此该路径不通过受控默认命令到达；若开发者手工启用或向网络暴露这些 server 功能，3.2.4 仍会变为可达，不能把默认不可达当作保留漏洞版本的理由。

基线 `npm audit --omit=dev --json` 为 45 项：21 low、13 moderate、11 high、0 critical。Vitest 作为 devDependency 不进入 omit-dev 安装面，但 45 个生产依赖告警仍然存在；`--omit=dev` 只说明该 critical 的安装边界，不代表应用依赖树无风险。

## 最小修复

- `package.json` 与锁文件根条目只把 `vitest` pin 改为 3.2.7。
- npm 将已安装的 `@vitest/expect`、`runner`、`snapshot`、`spy`、`utils` 与 `mocker` 对齐到 3.2.7；`@vitest/pretty-format` 已在基线解析为 3.2.7。
- npm 仅重排 Vitest 子树内 `@vitest/mocker`、`estree-walker`、`magic-string` 的嵌套/去重位置，未升级这些普通传递依赖。
- Vite 保持 5.2.8；`vitest@3.2.7` 的实际依赖仍解析 `vite-node@3.2.4`。DCloud、Vue、TypeScript 及 `@types/node` 没有版本 diff。

## 修复结果与兼容性

- 修复后总审计为 66 项：33 low、20 moderate、13 high、0 critical；原 GHSA 条目不再出现。
- 修复后 `--omit=dev` 仍为 45 项：21 low、13 moderate、11 high、0 critical。
- `npm ci` 成功；聚焦 `npm ls` 退出码 0，Vitest 家族、Vite 与 vite-node 没有 `invalid` 或 peer 错误。
- TypeScript 4.9.5 与全树 `@types/node@20.16.13` 保持 dedupe，`type-check`、`lint`、Vitest 1/1 测试、聚合 `check` 均成功。
- `vitest.config.mts` 运行无 CJS/CommonJS 警告；H5 构建成功且未出现 `uni is not a function`。
- wrapper 真实进程测试继续证明 Node/npm/npx 版本、PATH、工作树 cache 与退出码隔离。
- 治理夹具与相对 `main` 的 dirty-worktree CI 均成功，操作日志仅新增预分配的 `OP-20260823-001`。

## 剩余风险与后续治理

剩余 66/45 项跨固定 DCloud cohort、Vite 5.2.8 及其传递依赖。后续任务应先按开发 server、构建链、H5、各小程序、App/Android 的实际入口做可达性分类，再把 DCloud 平台包与其 Vite 兼容范围作为一个 cohort 评估和回归；不得用自动修复、broad overrides 或单包盲升拆散模板版本约束。H5 通过也不能替代 HBuilderX、Android 和真机验证。
