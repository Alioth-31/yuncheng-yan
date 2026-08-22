# 项目状态

更新时间：2026-08-23

## 当前阶段

- 阶段：阶段 1，工程骨架依赖治理。
- 分支：`agent/TASK-0004-vitest-security-patch`。
- 基线：`2384968acd13205ad1496d6b26f505fa2b2b0aa4`。
- `TASK-0101`、`TASK-0301` 与 `TASK-0003` 已合并。
- TASK-0004 已将 Vitest 精确升级至 3.2.7 并清除唯一 critical，待控制任务最终审查、提交与 PR。

## 已建立

- 固定 Node/npm wrapper、工作树级 npm cache 与精确版本门禁。
- 固定 DCloud 模板提交和平台包版本。
- TypeScript strict、ESLint Flat Config、Vitest node 测试与 H5 构建脚本。
- 精确 pin `@types/node@20.16.13`；现有 Pinia 测试同时由 `vue-tsc` 静态检查和 Vitest 执行。
- 精确 pin `vitest@3.2.7`；保持 Vite 5.2.8、vite-node 3.2.4、DCloud cohort、Vue 与 TypeScript 锁定结果不变。
- 每 app 独立 Pinia 工厂、唯一静态首页、空 AppID 与最小 manifest。

## 尚未实现

- TASK-0101 定义的身份入口及“今日、专注、小队、我的”业务页面。
- Repository、Mapper、Platform Adapter 与本地同步基础设施。
- LeanCloud 接入、数据模型、ACL、凭证和真实环境验证。
- Android 包名、权限、SDK、签名、APK/AAB 与真机流程。

## 当前风险与关注点

- 固定依赖树有 66 个 npm audit 项（0 critical、13 high）；`--omit=dev` 后仍为 45 个（0 critical、11 high）。剩余项跨 DCloud/Vite 及其传递依赖，需按兼容 cohort 独立治理，不能使用 `npm audit fix` 或 broad overrides。
- H5 构建不能替代 HBuilderX、Android 或真机验证。
- LeanCloud 类/ACL、三人可见性、邀请码受控执行和逐实体冲突策略仍待批准。
