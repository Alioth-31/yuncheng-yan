# 项目状态

更新时间：2026-08-23

## 当前阶段

- 阶段：阶段 3 产品功能的首个领域切片；尚未进入页面或数据接入。
- 分支：`agent/TASK-0401-focus-domain-state-machine`。
- 基线：`1f6e35f46898b56f0bf673f90b3f3c0d8eed34bc`。
- `TASK-0101`、`TASK-0301`、工程骨架与 `TASK-0004` Vitest 安全补丁已合并到 `main`。
- TASK-0401 已实现并验证最小专注领域模型与测试，待 PR 治理检查和合并。

## 已建立

- 固定 Node/npm wrapper、工作树级 npm cache 与精确版本门禁。
- 固定 DCloud 模板提交和平台包版本。
- TypeScript strict、ESLint Flat Config、Vitest node 测试与 H5 构建脚本。
- 精确 pin `@types/node@20.16.13`；现有 Pinia 测试同时由 `vue-tsc` 静态检查和 Vitest 执行。
- 精确 pin `vitest@3.2.7`；保持 Vite 5.2.8、vite-node 3.2.4、DCloud cohort、Vue 与 TypeScript 锁定结果不变。
- 每 app 独立 Pinia 工厂、唯一静态首页、空 AppID 与最小 manifest。
- 纯 TypeScript `FocusSession`：`IDLE` / `RUNNING`、显式时间戳 elapsed、用户主动 end、59999/60000 毫秒边界和不可变完成记录。

## 尚未实现

- TASK-0101 定义的身份入口及“今日、专注、小队、我的”业务页面；专注目前只有领域模型。
- Repository、Mapper、Platform Adapter 与本地同步基础设施。
- LeanCloud 接入、数据模型、ACL、凭证和真实环境验证。
- Android 包名、权限、SDK、签名、APK/AAB 与真机流程。

## 当前风险与关注点

- 固定依赖树有 66 个 npm audit 项（0 critical、13 high）；`--omit=dev` 后仍为 45 个（0 critical、11 high）。剩余项跨 DCloud/Vite 及其传递依赖，需按兼容 cohort 独立治理，不能使用 `npm audit fix` 或 broad overrides。
- H5 构建不能替代 HBuilderX、Android 或真机验证。
- LeanCloud 类/ACL、三人可见性、邀请码受控执行和逐实体冲突策略仍待批准。
- 专注时间戳由未来调用方提供；倒序时间只会作为领域输入无效，本任务未定义后台、进程恢复、单调时钟或 UI 恢复策略。
