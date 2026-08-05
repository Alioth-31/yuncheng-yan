# 架构约束

## 基线

经典 uni-app（不是 uni-app x）、Vue 3、TypeScript、Pinia、LeanCloud、本地优先。

## 固定边界

```text
Page -> Feature / Use Case -> Repository -> Mapper -> Platform Adapter
```

### Page

负责展示、路由入口和用户事件转发。Page 不得导入 LeanCloud SDK、LeanCloud SDK 类型、远端 Repository 实现或直接调用 `uni.*` 平台能力。

### Feature / Use Case

编排一个用户可理解的动作，消费应用层接口和领域类型，不感知 LeanCloud 对象或平台 API。

### Repository

定义和实现应用所需的数据契约。Repository 对外只暴露领域/应用类型，不暴露 `AV.Object`、查询对象或 SDK 错误类型。

### Mapper

在 LeanCloud SDK 类型与领域/传输类型之间做显式转换。Mapper 是 SDK 类型的边界；字段缺失、默认值和版本兼容在此处理。

### Platform Adapter

封装 `uni.*`、本地存储、设备、文件和网络等平台能力。上层只依赖 Adapter 接口，便于 H5、Android 和测试替换。

## 本地优先

读取先保证本地可用，写入先落本地，再由基础设施安排同步。同步冲突策略当前为“待决”，不能在页面中隐式实现。

## 安全边界

- MasterKey 永不进入客户端、仓库、日志或 CI 输出。
- LeanCloud appId/appKey 在尚未决定时只保留无值示例。
- 真实凭证、签名材料和用户数据不属于源代码。
