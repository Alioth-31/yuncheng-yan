# TASK-0005：README 技术路线与实现进度图

## 目标与基线

- 基线：`8e9aa0ddc746adf37f1358cd4710acbc34600846`
- 分支：`agent/TASK-0005-readme-roadmap-visual`
- 目标：把已批准的“分层架构蓝图 A”重建为仓库原生静态 SVG，并从 README 以可点击图片链接到 `docs/ROADMAP.md`。
- Git 边界：实施任务不暂存、提交、推送、创建 PR 或修改远端；总控负责后续 Review 与 Git 流程。

## 设计映射

- 固定白色 `1400 × 1150` viewBox，保证 GitHub 明暗主题下的画布和对比关系一致，并允许宿主页面响应式缩放。
- 顶部保留技术副标题、已完成/未完成/v0.2 图例和固定依赖方向 `Page -> Feature / Use Case -> Repository -> Mapper -> Platform Adapter`。
- 五层路线依次为治理与设计、工程与质量、领域与应用、数据与同步、页面与交付；底部独立显示 v0.2 延后区。
- 黑底白字只表示已经合入 `main` 的事实；白底黑字表示尚未完成；灰底虚线表示不属于 MVP 的延后能力。
- 对未确定内容使用“设计基线”“待批准”或“待审核”，不把 ACL、冲突、包名、签名、权限或 SDK 版本表述为已决定。

## 状态映射

| 层级 | 已完成 | 未完成 |
| --- | --- | --- |
| 治理与设计 | Git/GitHub 治理、产品 MVP 与页面流程、身份/ACL/同步设计基线、独立 Review | 无 |
| 工程与质量 | 便携 Node/npm wrapper、经典 uni-app Vue 3 + TypeScript + Pinia 骨架、质量门禁、Vitest 3.2.7 安全补丁 | 无 |
| 领域与应用 | `FocusSession` 最小专注领域模型 | 打卡领域、身份与业务 Use Case、业务 Pinia Store |
| 数据与同步 | 无 | Repository、本地持久化、Mapper、LeanCloud/ACL、同步状态机 |
| 页面与交付 | 应用启动与无业务骨架首页 | 今日、专注、小队、我的，以及 HBuilderX/Android、真机、发布参数和 APK 验收 |

## 文件与边界

- `README.md`：更新已合入任务、专注边界、Vitest/audit 事实，并新增可点击路线图及图例说明。
- `docs/assets/technology-roadmap.svg`：只使用标准 SVG 图形、文字、内部 marker 和内联样式；不含脚本、`foreignObject`、外部资源、data URL 或远程字体。
- `CHANGELOG.md`：记录 README 路线图和当前进度摘要。
- 本任务文档：记录授权、状态映射、验收与交接。
- `docs/operations/PROJECT_LOG.md`：只追加 `OP-20260823-003`。

本任务不修改 `docs/ROADMAP.md`、package/lock、源码、配置或任何产品规则，不接入 LeanCloud、HBuilderX、Android SDK、凭证、签名材料、APK/AAB 或真实用户数据。

## 验收与验证计划

1. 用 PowerShell XML parser 解析 SVG，并扫描禁止的脚本、`foreignObject`、外部 href、data/base64 URL 与远程字体。
2. 静态检查标题、技术副标题、图例、固定架构边界、五个层级、关键完成/未完成节点和 v0.2 延后区。
3. 检查 README 图片 alt text、SVG 相对路径、`docs/ROADMAP.md` 点击目标和状态说明。
4. 使用本机浏览器在仓库外渲染 PNG，并视觉检查遮挡、截断、箭头错位和中文乱码。
5. 运行 `git diff --check`、Governance dirty CI、操作日志前缀/唯一 OP、敏感信息、精确五文件范围、package/lock/源码/配置零差异及空索引检查。

## 验证记录

- PowerShell XML parser 解析根元素和 `0 0 1400 1150` viewBox 退出码 0；脚本、`foreignObject`、href、data/base64、外部资源与远程字体扫描退出码 0。
- 五层、固定边界、图例、10 个已完成节点、17 个未完成节点和 v0.2 延后区的内容/样式检查退出码 0；README alt text、图片/目标相对路径、章节顺序和事实检查退出码 0。
- Microsoft Edge headless 以隐藏等待进程渲染仓库外 `1400 × 1150` PNG，退出码 0；原始分辨率视觉检查未发现遮挡、截断、箭头错位或中文乱码。
- `git diff --check` 与未跟踪文件 whitespace 包装检查退出码 0；Governance dirty CI（`-BaseRef main`）退出码 0。
- 精确五文件范围、空 Git 索引、package/lock/源码/配置零差异、旧日志前缀、唯一 `OP-20260823-003` 和独立高置信敏感扫描均退出码 0。

完整命令、退出码、渲染证据和风险记录在仓库外 `D:\Codex\artifacts\intermediate\yunchengyan-phase2\TASK-0005-readme-roadmap-report.md`。
