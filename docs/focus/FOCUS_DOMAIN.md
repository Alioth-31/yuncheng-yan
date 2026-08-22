# 专注领域模型

## 目的

本模型只定义一段正计时专注在内存中的最小生命周期和用户主动结束时的领域判定。它为后续 Feature / Use Case 提供纯 TypeScript 领域能力，不负责页面、持久化、同步或平台时间来源。

## 状态与公开接口

`FocusSession` 新建后处于 `IDLE`，只存在以下两个状态：

- `IDLE`：没有活动会话；
- `RUNNING`：保存本次会话的 `startedAt` 毫秒时间戳。

公开接口固定为：

```ts
type FocusStatus = 'IDLE' | 'RUNNING'

new FocusSession()
session.status
session.start(startedAt)
session.elapsed(now)
session.end(completedAt)
```

调用方必须显式传入时间戳；领域模型不读取系统时钟，也不依赖 `uni.*` 或其他平台能力。

## 状态转换与判定

| 当前状态 | 动作 | 条件 | 结果 |
| --- | --- | --- | --- |
| `IDLE` | `start(startedAt)` | 任意 `number` 时间戳 | 转为 `RUNNING` 并保存 `startedAt` |
| `RUNNING` | `start(startedAt)` | 任意 | 拒绝为 `ALREADY_RUNNING`，状态不变 |
| `RUNNING` | `elapsed(now)` | `now >= startedAt` | 返回 `now - startedAt`，状态不变 |
| `RUNNING` | `elapsed(now)` | `now < startedAt` | 拒绝为 `TIMESTAMP_BEFORE_START`，状态不变 |
| `RUNNING` | `end(completedAt)` | `completedAt < startedAt` | 拒绝为 `TIMESTAMP_BEFORE_START`，状态不变 |
| `RUNNING` | `end(completedAt)` | 时长 `< 60000` 毫秒 | 转为 `IDLE`，返回 `DISCARDED_SHORT_SESSION`，不生成记录 |
| `RUNNING` | `end(completedAt)` | 时长 `>= 60000` 毫秒 | 转为 `IDLE`，返回 `COMPLETED` 和不可变 `FocusRecord` |
| `IDLE` | `elapsed(now)` 或 `end(completedAt)` | 任意 | 拒绝为 `NOT_RUNNING`，状态不变 |

短会话结果只携带 `durationMs`，没有 `record` 字段。完成结果中的 `FocusRecord` 只包含：

```ts
interface FocusRecord {
  readonly startedAt: number
  readonly completedAt: number
  readonly durationMs: number
}
```

`durationMs` 等于 `completedAt - startedAt`。`completedAt` 原样保留，供未来统计按完成时刻归属；本模型不计算日期、周或月。

## 输入错误边界

`now` 或 `completedAt` 早于活动会话的 `startedAt` 时，仅判定为领域输入无效。模型不定义提示文案、页面跳转、计时恢复或其他 UI 策略。无效调用不会完成当前会话。

## 明确不包含

本任务不加入暂停/恢复、后台或进程生命周期恢复、活动中主动放弃、短会话二次确认或取消恢复、单调时钟、Platform Adapter、Repository、本地存储、LeanCloud、同步、页面、Pinia、统计聚合、科目、任务、备注或自动打卡。
