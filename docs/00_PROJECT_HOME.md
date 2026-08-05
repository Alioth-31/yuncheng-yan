# 项目首页

## 身份

- 官方名：云程研 App
- 仓库：`Alioth-31/yuncheng-yan`
- 用途：三人私用考研辅助 App；无公开注册，APK 私下分发

## 当前阶段

项目阶段 0 为治理基线；当前执行门为阶段 2：文件生成与本地验证。这里不包含业务页面、LeanCloud 真实配置、Android 签名或发布产物。

## 入口文档

- [项目状态](PROJECT_STATUS.md)
- [架构约束](ARCHITECTURE.md)
- [决策记录](DECISIONS.md)
- [路线图](ROADMAP.md)
- [AI 交接](AI_HANDOFF.md)
- [任务说明](tasks/TASK-0001_PROJECT_GOVERNANCE_BASELINE.md)
- [操作日志](operations/PROJECT_LOG.md)

## 最小验证

```powershell
./scripts/Test-Governance.Tests.ps1
./scripts/Test-Governance.ps1 -Mode PreCommit
./scripts/Test-Governance.ps1 -Mode Ci -BaseRef origin/main
```

PreCommit 需要治理文件已进入暂存索引；本阶段实施任务禁止暂存，因此在未暂存工作树上预期会报告缺失索引文件。
