## 变更说明

<!-- 用中文说明目标、范围和不包含的内容。默认不涉及业务或远端设置。 -->

## 验证

- [ ] `scripts/Test-Governance.Tests.ps1`
- [ ] `scripts/Test-Governance.ps1 -Mode PreCommit`
- [ ] `scripts/Test-Governance.ps1 -Mode Ci -BaseRef origin/main`
- [ ] 其他命令和退出码已记录

## 安全与边界

- [ ] 未提交 `.env`、token、MasterKey、Android 密码、私钥、证书或签名文件
- [ ] 页面没有直连 LeanCloud，SDK 类型未越过 Repository/Mapper
- [ ] 平台能力仍通过 Platform Adapter
- [ ] 没有使用未经授权的 `--no-verify`
- [ ] 没有创建或提交 `.agent`

## 操作日志

- [ ] 每个源提交追加恰好一条完整 OP
- [ ] `docs/operations/PROJECT_LOG.md` 只追加未改写历史
