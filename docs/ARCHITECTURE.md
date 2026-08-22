# 架构约束

## 技术基线

工程使用经典 uni-app（不是 uni-app x）、Vue 3、TypeScript、Pinia 与 npm。DCloud 模板固定到 `dcloudio/uni-preset-vue@6fb81ac3c5736b8b0a83e667b3ed90223d458dd8`，DCloud 平台包固定为 `3.0.0-5020420260813003`。

模板 TypeScript 实际解析为 4.9.5；为使 Vitest/Vite 的 Node 类型链也能进入同一个 `vue-tsc` program，项目精确 pin `@types/node@20.16.13`。生产源码与 `src/**/*.spec.ts` 共用 `tsconfig.json`，不以排除测试来绕过静态错误。

当前只建立应用启动、单页和测试工具链。LeanCloud、本地 Repository、同步状态机与 Platform Adapter 尚未实现。

## 依赖方向

```text
Page -> Feature / Use Case -> Repository -> Mapper -> Platform Adapter
```

### Page

只负责展示、路由入口和用户事件转发。不得导入 LeanCloud SDK、远端 Repository 实现或直接调用 `uni.*`。

### Feature / Use Case

编排用户动作，消费应用接口和领域类型，不感知 LeanCloud 对象或平台 API。

### Repository

定义数据契约并向上返回领域/应用类型，不暴露 `AV.Object`、查询对象或 SDK 错误类型。读取以本地可用为先，同步不是 Page 的职责。

### Mapper

在 LeanCloud SDK 表示与领域/传输类型间显式转换。字段缺失、默认值和兼容规则只能在获得数据模型批准后实现。

### Platform Adapter

封装 `uni.*`、设备、文件、网络与本地存储。上层只依赖 Adapter 接口。

## 当前骨架

- `src/main.ts` 每次 `createApp()` 都创建并安装独立 Pinia 实例，避免 SSR/多实例共享状态。
- `src/stores/index.ts` 只提供 Pinia 工厂，不含业务 store。
- `src/pages/index/index.vue` 是无状态骨架页，不调用网络、LeanCloud 或平台 API。
- `@/* -> src/*` 是唯一项目别名；Vitest 使用 node 环境，测试源码同时接受 `vue-tsc` 静态检查和 Vitest 运行时执行。

## 安全与平台边界

- MasterKey 永不进入客户端、仓库、日志或 CI 输出。
- `manifest.json` 不设置 Android permissions、包名、SDK、签名或真实 AppID。
- 真实凭证、签名材料、APK/AAB 和用户数据不属于源代码。
