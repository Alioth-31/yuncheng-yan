# 项目状态

更新时间：2026-08-22

## 当前阶段

- 阶段：阶段 1，工程骨架。
- 分支：`agent/TASK-0003-app-scaffold`。
- 基线：`2c9f928f2f6bb70ee42248d8e6ad3403b4fb78c1`。
- `TASK-0101` 产品 MVP 与 `TASK-0301` 身份/ACL/同步设计已合并。
- TASK-0003 已生成经典 uni-app Vue 3 + TypeScript + Pinia 骨架，待控制任务审查、暂存、提交与 PR。

## 已建立

- 固定 Node/npm wrapper、工作树级 npm cache 与精确版本门禁。
- 固定 DCloud 模板提交和平台包版本。
- TypeScript strict、ESLint Flat Config、Vitest node 测试与 H5 构建脚本。
- 精确 pin `@types/node@20.16.13`；现有 Pinia 测试同时由 `vue-tsc` 静态检查和 Vitest 执行。
- 每 app 独立 Pinia 工厂、唯一静态首页、空 AppID 与最小 manifest。

## 尚未实现

- TASK-0101 定义的身份入口及“今日、专注、小队、我的”业务页面。
- Repository、Mapper、Platform Adapter 与本地同步基础设施。
- LeanCloud 接入、数据模型、ACL、凭证和真实环境验证。
- Android 包名、权限、SDK、签名、APK/AAB 与真机流程。

## 当前风险与关注点

- 固定依赖树有 67 个 npm audit 项；`--omit=dev` 后为 45 个（0 critical、11 high）。Vitest 3.2.4 的 1 个 critical 影响未启用的 UI/API/Browser server 路径，但版本仍需独立依赖治理，不能在本任务中盲升。
- H5 构建不能替代 HBuilderX、Android 或真机验证。
- LeanCloud 类/ACL、三人可见性、邀请码受控执行和逐实体冲突策略仍待批准。
