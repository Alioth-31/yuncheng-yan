# 路线图

## 阶段 0：治理基线

- 建立 AGENTS、README、状态/架构/决策/路线图和 AI 交接文档。
- 固定操作日志格式和追加式检查。
- 接入 PreCommit Hook、PowerShell 治理测试和 GitHub Actions。
- 不创建业务代码，不安装本机 SDK，不写入凭证。

## 阶段 1：工程骨架

- 在独立批准后创建经典 uni-app Vue 3 + TypeScript CLI 骨架。
- 接入 Pinia、Lint、类型检查和单元测试。
- 落实本地优先 Repository 与 Platform Adapter 接口。

## 阶段 2：数据与平台冒烟

- 在凭证由用户提供并保存在本地忽略文件后，验证 LeanCloud Repository/Mapper。
- 在 HBuilderX、设备和 Android 工具由用户完成后，验证真机与 APK 流程。

## 待验证 SPIKE-001：经典 uni-app + LeanCloud Android 真机验证

状态：待验证，尚未执行或完成。

验证范围：在工程骨架、必要工具和凭证经独立批准后，验证 SDK 初始化、登录/会话、ACL、文件上传、离线计时、重连以及 APK 构建、安装与运行。

## 阶段 3：产品功能

- MVP 页面、LeanCloud 类/ACL、同步冲突和包名均须先从“待决”转为明确决策。
- 每个源提交追加一条 OP，并在 CI 中验证。
