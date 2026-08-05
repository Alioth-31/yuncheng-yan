# 项目状态

更新时间：2026-08-04

## 当前状态

- 项目阶段：项目阶段 0：治理基线。
- 当前执行门：阶段 2：文件生成与本地验证。
- 目标分支：`agent/TASK-0001-governance-baseline`。
- 当前状态：文件已生成，待只读审查、暂存和提交；本任务未执行暂存、提交或推送。
- 已回读的外部现状：`Alioth-31/yuncheng-yan` 当前公开（`isPrivate=false`）；产品仍三人私用；Ruleset 与合并限制待本 PR CI 成功后配置。
- `E:\yunchengyan` main 工作树不在本任务写入范围。

## 已确定

- 技术基线：经典 uni-app Vue 3、TypeScript、Pinia、LeanCloud、本地优先。
- 边界：Page → Feature/Use Case → Repository → Mapper → Platform Adapter。
- 页面不直连 LeanCloud；SDK 类型不越过 Repository/Mapper；平台能力走 Adapter。
- 仓库当前公开，但产品仍无公开注册并仅私下分发 APK；Ruleset 与合并限制待本 PR CI 成功后配置。

## 待决

包名、LeanCloud 类/ACL、同步冲突、MVP 页面、Android 签名和 SDK 版本均保持“待决”。

## 当前风险

- Node、HBuilderX、Android SDK/ADB 仍不属于本任务安装范围。
- GitHub 认证与远端设置不属于本任务写入范围。
- LeanCloud 真实配置、MasterKey 和 Android 签名材料未提供，也不得写入仓库。
