# TASK-0003：云程研 App 工程骨架

## 目标

在已合并的治理、TASK-0101 产品 MVP 与 TASK-0301 身份/同步设计基线上，建立可复现的经典 uni-app Vue 3 + TypeScript + Pinia 工程骨架，不实现业务或 LeanCloud。

## 固定来源与版本

- 基线：`2c9f928f2f6bb70ee42248d8e6ad3403b4fb78c1`
- 模板：`dcloudio/uni-preset-vue`
- 模板提交：`6fb81ac3c5736b8b0a83e667b3ed90223d458dd8`
- 模板工具：`degit@3.8.0`
- Node/npm：22.23.1 / 10.9.8
- DCloud 平台包：`3.0.0-5020420260813003`
- Pinia/Vitest/ESLint：3.0.4 / 3.2.4 / 9.39.2
- Node 类型：`@types/node@20.16.13`，精确 pin 并与 TypeScript 4.9.5 实测兼容

## 实施内容

1. 以真实进程测试驱动 `scripts/Invoke-ProjectNode.ps1`，隔离 Node、PATH 和 npm cache，并透传参数与退出码。
2. 从固定提交外部生成模板，只导入应用必要文件，保留仓库治理与文档。
3. 锁定 package、TypeScript strict、唯一 `@/* -> src/*` 别名、ESLint Flat Config 和 Vitest node 配置；生产源码与测试共用 `vue-tsc` 静态门禁。
4. 以测试驱动 `createAppPinia()`，确保每次创建 app 使用不同 Pinia 实例。
5. 提供单一静态首页与最小 manifest，不加入图片、业务状态、网络、平台调用或 Android 发布配置。

## 明确不做

- 不接入 LeanCloud，不创建业务 Feature/Repository/Mapper/Adapter。
- 不设置 AppID、Android 包名、权限、SDK、签名或凭证。
- 不安装 HBuilderX/Android SDK，不生成 APK/AAB。
- 不升级或替换固定版本，不运行 `npm update` 或 `npm audit fix`。
- 不暂存、提交、推送、创建 PR 或修改 Git/npm 持久配置。

## 验收

- wrapper 测试、type-check、lint、Vitest、H5 build、治理夹具与 dirty CI 均成功。
- mutation 验证证明错误的测试类型标注会使 `type-check`/`check` 非零，而 Vitest 仍能独立执行运行时断言。
- PowerShell 文件可解析，敏感信息与平台边界扫描无违规。
- `git diff --check` 成功，Git 索引为空，改动只在授权范围。

完整命令、退出码、关键输出、文件清单与自审记录在 `D:\Codex\artifacts\intermediate\yunchengyan-phase1\TASK-0003-app-scaffold-report.md`。
