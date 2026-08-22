# TASK-0401：最小专注领域模型与结束判定

## 目标与基线

- 最终集成基线：`1f6e35f46898b56f0bf673f90b3f3c0d8eed34bc`
- 分支：`agent/TASK-0401-focus-domain-state-machine`
- 目标：在 `src/features/focus/domain/` 新增纯 TypeScript 的 `IDLE` / `RUNNING` 专注状态机，以时间戳计算已用时，并在用户主动结束时严格执行 60000 毫秒保存边界。
- Git 边界：实施任务不暂存、提交、推送或创建 PR；最终 Review 和 Git 流程由总控执行。

## 文件与职责

- `src/features/focus/domain/focus-session.ts`：领域状态、错误、结束结果、不可变记录和状态转换。
- `src/features/focus/domain/__tests__/focus-session.spec.ts`：真实对象行为测试及 `FocusRecord` readonly 类型门。
- `docs/focus/FOCUS_DOMAIN.md`：公开领域契约、阈值、错误与禁止范围。
- 本任务文档：实现范围、TDD 证据、验证与风险交接。
- 全局状态、架构、路线图、AI 交接、CHANGELOG：只回写已经实现的最小事实。
- `docs/operations/PROJECT_LOG.md`：只追加预分配的 `OP-20260823-002`。

## 公开接口计划

```ts
export type FocusStatus = 'IDLE' | 'RUNNING'
export type FocusDomainErrorCode =
  | 'ALREADY_RUNNING'
  | 'NOT_RUNNING'
  | 'TIMESTAMP_BEFORE_START'

export interface FocusRecord {
  readonly startedAt: number
  readonly completedAt: number
  readonly durationMs: number
}

export type FocusEndResult =
  | Readonly<{ kind: 'DISCARDED_SHORT_SESSION'; durationMs: number }>
  | Readonly<{ kind: 'COMPLETED'; record: FocusRecord }>

export class FocusSession {
  get status(): FocusStatus
  start(startedAt: number): void
  elapsed(now: number): number
  end(completedAt: number): FocusEndResult
}
```

## TDD 执行计划

1. 先新增领域测试，覆盖初始 `IDLE`、`start` 到 `RUNNING`、重复 start 拒绝、时间戳 elapsed、倒序时间无效、59999 毫秒丢弃、60000/60001 毫秒生成记录、`completedAt`/`durationMs` 精确值、结束回到 `IDLE`、运行时冻结和 readonly 编译门。
2. 只运行目标测试，确认因领域模块尚不存在而 RED，保留命令、退出码和预期失败原因。
3. 新增单个生产模块，以最少分支使目标测试 GREEN；不增加任何禁止能力或外部依赖。
4. 运行目标测试、type-check、lint 和完整测试，确认行为和类型门共同通过。
5. 更新任务授权的文档和唯一操作日志条目，再执行 fresh 全量验证、Governance fixtures、dirty CI、PowerShell parser、敏感/边界扫描与 Git diff 审计。

## 验收矩阵

| 行为 | 手算预期 |
| --- | --- |
| 新会话与 start | `IDLE -> RUNNING` |
| 重复 start | `ALREADY_RUNNING`，原会话继续 |
| `startedAt=1000, now=2500` | `elapsed=1500` |
| `now/completedAt < startedAt` | `TIMESTAMP_BEFORE_START` |
| `duration=59999` | `DISCARDED_SHORT_SESSION`，无记录 |
| `duration=60000` | `COMPLETED`，生成记录 |
| `duration=60001` | `COMPLETED`，生成记录 |
| 完成记录 | `startedAt`、`completedAt`、差值时长精确且 readonly / frozen |
| 依赖边界 | 生产模块无 import，不出现 `uni.*`、Pinia、LeanCloud、Repository 或 Adapter 依赖 |

## 明确禁止

不实现暂停/恢复、后台/杀进程/重启恢复、活动中主动放弃、短会话二次确认或取消恢复、单调时钟或平台时间适配、Repository、本地存储、LeanCloud、同步、页面、Pinia、统计聚合、科目、任务、备注、自动打卡。

## 验证记录

- TDD 从缺失模块开始 RED；重复 start、elapsed、倒序时间、59999、60000/60001、倒序 `completedAt`、不可变记录和 IDLE 非法动作均分别观察失败后才加入最小实现。
- readonly mutation 中，可写字段使 `vue-tsc` 以 3 个 TS2578 退出 1；恢复三个 readonly 字段后 type-check 退出 0。未冻结记录使 Vitest 退出 1；恢复 `Object.freeze` 后目标测试 9/9。
- 最终 fresh `npm ci` 退出 0；type-check、lint、test:run、build:h5、check、wrapper 实进程测试、Governance fixtures 与 `origin/main` dirty CI 均退出 0。完整 Vitest 为 2 个测试文件、12/12。
- 6 个 PowerShell 脚本解析错误为 0，Hook `sh -n` 退出 0；领域 TypeScript AST 解析错误、import 和越界标识命中均为 0。
- 范围审计确认授权变更恰好 10 个路径、旧日志前缀不变、`OP-20260823-002` 恰好 1 条、package 差异 0、`.agent` 路径 0、Git 索引为空；tracked/untracked diff whitespace 警告均为 0。

完整命令、退出码、关键输出、文件清单和自审结论见 `D:\Codex\artifacts\intermediate\yunchengyan-phase2\TASK-0401-focus-domain-report.md`。
