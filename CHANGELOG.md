# Changelog

## Unreleased

- 新增纯 TypeScript 的最小专注领域状态机：仅含 `IDLE` / `RUNNING`、时间戳 elapsed、用户主动 end、60000 毫秒保存边界与不可变 `FocusRecord`。
- 以 Vitest 边界测试、运行时冻结断言和 `vue-tsc` readonly 类型门覆盖专注领域模型；未接入页面、Pinia、Repository、平台时间、本地存储或同步。
- 从固定 DCloud 模板提交建立经典 uni-app Vue 3 + TypeScript 工程骨架。
- 固定 Node/npm wrapper、依赖锁文件、TypeScript strict、ESLint、Vitest 与 H5 构建检查。
- 将 Vitest 从精确 `3.2.4` 升至精确 `3.2.7`，清除 `GHSA-5xrq-8626-4rwp` critical，不联动升级 Vite、DCloud、Vue 或 TypeScript。
- 精确 pin `@types/node@20.16.13`，使 TypeScript 4.9.5 静态检查同时覆盖 Vitest 测试源码。
- 接入每 app 独立 Pinia 工厂和最小静态首页；未接入 LeanCloud、Android 发布配置或业务能力。

## 0.0.0 - 2026-08-04

- 建立云程研 App 的仓库治理基线、分支/PR 约束、操作日志格式、敏感信息扫描、Hook 与 GitHub Actions 检查。
- 未加入 uni-app 业务代码、真实凭证、签名材料或 LICENSE。
