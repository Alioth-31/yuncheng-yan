# 路线图

## 阶段 0：治理与设计基线（已完成）

- 仓库治理、追加式操作日志、Hook 与 GitHub Actions 已建立。
- TASK-0101 产品 MVP 与 TASK-0301 身份、ACL、同步设计基线已合并。

## 阶段 1：工程骨架（当前）

- 固定经典 uni-app Vue 3 + TypeScript 模板、Node/npm 与依赖锁文件。
- 接入 Pinia、类型检查、ESLint、Vitest 和 H5 构建。
- 以独立依赖治理任务评估固定 DCloud/Vitest 依赖树的 audit 项，在升级前验证模板、测试和 H5 兼容性。
- 保持首页无业务、无 LeanCloud、无网络和无平台调用。
- 合并 TASK-0003 后，再以独立任务建立 Feature/Repository/Mapper/Platform Adapter 接口。

## 阶段 2：数据与平台冒烟（待批准）

- 先批准 LeanCloud 数据模型、三人可见性、逐资源 ACL 与逐实体冲突策略。
- 凭证只放本地忽略文件，由 Repository/Mapper 封装 LeanCloud。
- 用户准备 HBuilderX、Android 工具和设备后，再验证真机与 APK 流程。

## SPIKE-001：经典 uni-app + LeanCloud Android 真机验证

状态：待验证。范围包括 SDK 初始化、登录/会话、ACL、文件上传、离线计时、重连，以及 APK 构建、安装和运行。

## 阶段 3：产品功能

- 按 TASK-0101 的验收条件逐项实现身份入口、今日、专注、小队与我的。
- 每个源提交追加恰好一条 OP，并保持 Page → Feature/Use Case → Repository → Mapper → Platform Adapter。
