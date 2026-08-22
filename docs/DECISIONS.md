# 决策记录

| 主题 | 当前决策 | 状态 |
| --- | --- | --- |
| uni-app 形态 | 使用经典 uni-app，不使用 uni-app x | 已确定 |
| UI/语言 | Vue 3 + TypeScript | 已确定 |
| 状态管理 | Pinia；每次创建 app 使用独立实例 | 已确定 |
| Node/npm | Node 22.23.1、npm 10.9.8，通过项目 wrapper 隔离调用 | 已确定 |
| Node 类型兼容 | 精确使用 `@types/node@20.16.13`，兼容模板 TypeScript 4.9.5 与 Vitest/Vite 类型链 | 已确定 |
| Vitest 安全补丁 | 精确使用 `vitest@3.2.7` 修复 `GHSA-5xrq-8626-4rwp`；保持 Vite 5.2.8、DCloud cohort、Vue 与 TypeScript 不变 | 已确定 |
| 测试静态门禁 | `src/**/*.spec.ts` 与生产源码共用 `vue-tsc`；`check` 不排除测试 | 已确定 |
| 工程模板 | `dcloudio/uni-preset-vue@6fb81ac3c5736b8b0a83e667b3ed90223d458dd8` | 已确定 |
| DCloud 平台包 | `3.0.0-5020420260813003` | 已确定 |
| 数据服务 | LeanCloud，Page 不得直连 | 已确定 |
| 数据策略 | 本地优先，同步由基础设施负责 | 已确定 |
| 分层边界 | Page → Feature/Use Case → Repository → Mapper → Platform Adapter | 已确定 |
| 产品范围 | TASK-0101 的四个主入口与 MVP 规则 | 已确定 |
| 身份/同步边界 | TASK-0301 的受控邀请码与本地优先原则 | 已确定 |
| 首页 | TASK-0003 仅显示工程骨架状态，不承载业务 | 已确定 |
| Android 包名、签名与 SDK | 待决 | 未决定 |
| LeanCloud 类、字段、逐资源 ACL | 待决 | 未决定 |
| 三人间数据可见性 | 待决 | 未决定 |
| 逐实体同步冲突与删除传播 | 待决 | 未决定 |
| MVP 视觉、统计指标及异常流程细节 | 待决 | 未决定 |
| LICENSE | 本仓库不添加 | 已确定 |

任何新决策先更新本文件，再修改实现；不得用模板默认值掩盖待决项。
