# 路线图

## 阶段 0：治理与设计基线（已完成）

- 仓库治理、追加式操作日志、Hook 与 GitHub Actions 已建立。
- TASK-0101 产品 MVP 与 TASK-0301 身份、ACL、同步设计基线已合并。

## 阶段 1：工程骨架（已完成）

- 固定经典 uni-app Vue 3 + TypeScript 模板、Node/npm 与依赖锁文件。
- 接入 Pinia、类型检查、ESLint、Vitest 和 H5 构建。
- TASK-0004 已以精确 Vitest 3.2.7 patch 清除唯一 critical，并保持现有模板、测试、Vite 与 H5 兼容性。
- 剩余 DCloud/Vite audit 项按版本一致的 cohort 另立治理任务，先做可达性和多平台兼容验证，不使用自动修复或 broad overrides。
- 保持首页无业务、无 LeanCloud、无网络和无平台调用。
- 工程骨架与 TASK-0004 安全补丁已合并；后续分层接口继续按独立任务和实际需求建立。

## 阶段 2：数据与平台冒烟（待批准）

- 先批准 LeanCloud 数据模型、三人可见性、逐资源 ACL 与逐实体冲突策略。
- 凭证只放本地忽略文件，由 Repository/Mapper 封装 LeanCloud。
- 用户准备 HBuilderX、Android 工具和设备后，再验证真机与 APK 流程。

## SPIKE-001：经典 uni-app + LeanCloud Android 真机验证

状态：待验证。范围包括 SDK 初始化、登录/会话、ACL、文件上传、离线计时、重连，以及 APK 构建、安装和运行。

## 阶段 3：产品功能（已启动）

- 按 TASK-0101 的验收条件逐项实现身份入口、今日、专注、小队与我的。
- TASK-0401 先建立无页面、无存储、无平台依赖的最小专注领域状态机和 60000 毫秒结束判定。
- 专注页面、Use Case、持久化、同步、后台与进程恢复必须分别获得后续任务授权，不从领域模型隐式扩张。
- 每个源提交追加恰好一条 OP，并保持 Page → Feature/Use Case → Repository → Mapper → Platform Adapter。
