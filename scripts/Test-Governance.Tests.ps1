[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$productionScript = Join-Path $scriptRoot 'Test-Governance.ps1'
$preferredFixtureBase = 'D:\Codex\temp'
$fixtureBase = if (Test-Path -LiteralPath $preferredFixtureBase -PathType Container) {
    [System.IO.Path]::GetFullPath($preferredFixtureBase)
}
else {
    [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
}
$fixtureName = 'yuncheng-yan-governance-fixture-' + ([guid]::NewGuid().ToString('N'))
$fixture = Join-Path $fixtureBase $fixtureName
$script:FixtureBaselineCommit = $null

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Assert-ExitCode {
    param([int]$Actual, [int]$Expected, [string]$Name, [string]$Output)
    if ($Actual -ne $Expected) {
        throw ("{0}: expected exit code {1}, got {2}. Output: {3}" -f $Name, $Expected, $Actual, $Output.Trim())
    }
    Write-Host ("[PASS] {0} (exit {1})" -f $Name, $Actual)
}

function Assert-OutputContains {
    param([string]$Output, [string]$Pattern, [string]$Name)
    if ([string]::IsNullOrWhiteSpace($Output) -or ($Output -notmatch $Pattern)) {
        throw ("{0}: expected output to match /{1}/. Output: {2}" -f $Name, $Pattern, $Output.Trim())
    }
}

function Join-NativePath {
    param(
        [Parameter(Mandatory = $true)][string]$BasePath,
        [Parameter(Mandatory = $true)][string]$RelativePath
    )
    $path = $BasePath
    foreach ($segment in ($RelativePath -split '[\\/]')) {
        if ([string]::IsNullOrEmpty($segment) -or ($segment -eq '.')) { continue }
        $path = Join-Path -Path $path -ChildPath $segment
    }
    return $path
}

function Get-InvocationHost {
    $powershell = Get-Command powershell.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -ne $powershell) { return $powershell.Source }
    $pwsh = Get-Command pwsh -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -ne $pwsh) { return $pwsh.Source }
    throw 'No powershell.exe or pwsh was found for fixture tests.'
}

function Invoke-Governance {
    param([string]$Mode, [string]$BaseRef = '')
    $arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-NativePath -BasePath $fixture -RelativePath 'scripts/Test-Governance.ps1'), '-Mode', $Mode)
    if ($BaseRef) { $arguments += @('-BaseRef', $BaseRef) }
    $previousErrorAction = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = & (Get-InvocationHost) @arguments 2>&1
        return [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = ($output -join "`n") }
    }
    finally { $ErrorActionPreference = $previousErrorAction }
}

function Assert-SafeFixturePath {
    param([string]$Path)
    $base = [System.IO.Path]::GetFullPath($fixtureBase)
    $separator = [string][System.IO.Path]::DirectorySeparatorChar
    $alternateSeparator = [string][System.IO.Path]::AltDirectorySeparatorChar
    if (-not ($base.EndsWith($separator) -or $base.EndsWith($alternateSeparator))) { $base += $separator }
    $full = [System.IO.Path]::GetFullPath($Path)
    Assert-True $full.StartsWith($base, [System.StringComparison]::OrdinalIgnoreCase) 'Fixture path escaped the configured system temp base.'
    Assert-True ([System.IO.Path]::GetFileName($full) -eq $fixtureName) 'Fixture path did not retain its unique name.'
}

function Write-FixtureFile {
    param([string]$RelativePath, [string]$Content)
    $path = Join-NativePath -BasePath $fixture -RelativePath $RelativePath
    New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force | Out-Null
    Set-Content -LiteralPath $path -Value $Content -Encoding UTF8
}

function Initialize-Fixture {
    New-Item -ItemType Directory -Path $fixture -Force | Out-Null
    $requiredFiles = @(
        'README.md', 'AGENTS.md', 'CHANGELOG.md', '.gitignore', '.gitattributes', '.editorconfig',
        '.codex/config.toml', 'docs/00_PROJECT_HOME.md', 'docs/PROJECT_STATUS.md', 'docs/ARCHITECTURE.md',
        'docs/DECISIONS.md', 'docs/ROADMAP.md', 'docs/AI_HANDOFF.md',
        'docs/tasks/TASK-0001_PROJECT_GOVERNANCE_BASELINE.md', 'docs/operations/PROJECT_LOG.md',
        '.github/PULL_REQUEST_TEMPLATE.md', '.github/workflows/governance.yml', '.githooks/pre-commit',
        'scripts/Test-Governance.ps1', 'scripts/Test-Governance.Tests.ps1', 'scripts/Initialize-Clone.ps1'
    )
    foreach ($required in $requiredFiles) { Write-FixtureFile -RelativePath $required -Content ("fixture: {0}`n" -f $required) }
    Write-FixtureFile -RelativePath 'docs/operations/PROJECT_LOG.md' -Content @'
# Project Operation Log

## OP-20260804-000
- Time: 2026-08-04T00:00:00+08:00
- Task: fixture baseline
- Executor: test
- Branch: main
- ApprovedStage: fixture
- Changes: establish fixture baseline
- Files: fixture
- Verification: fixture
- Risks: none
- NextStep: fixture
'@
    & git -C $fixture init -b main 2>$null | Out-Null
    & git -C $fixture config user.name 'Governance Fixture'
    & git -C $fixture config user.email 'governance-fixture@example.invalid'
    & git -C $fixture config core.autocrlf false
    & git -C $fixture add --all 2>$null
    & git -C $fixture update-index --chmod=+x -- '.githooks/pre-commit'
    & git -C $fixture commit -m 'fixture baseline' 2>$null | Out-Null
    & git -C $fixture branch 'origin/main'
    $script:FixtureBaselineCommit = (& git -C $fixture rev-parse HEAD).Trim()
}

function Reset-Fixture {
    if ([string]::IsNullOrWhiteSpace($script:FixtureBaselineCommit)) { throw 'Fixture baseline commit was not initialized.' }
    $currentBranch = (& git -C $fixture branch --show-current 2>$null).Trim()
    if ($currentBranch -ne 'main') { & git -C $fixture checkout -q --force main 2>$null | Out-Null }
    & git -C $fixture reset --hard $script:FixtureBaselineCommit 2>$null | Out-Null
    & git -C $fixture clean -fd 2>$null | Out-Null
    Copy-Item -LiteralPath $productionScript -Destination (Join-NativePath -BasePath $fixture -RelativePath 'scripts/Test-Governance.ps1') -Force
}

try {
    Assert-SafeFixturePath -Path $fixture
    Assert-True (Test-Path -LiteralPath $fixtureBase -PathType Container) 'The selected system temp base does not exist.'
    if (-not (Test-Path -LiteralPath $productionScript -PathType Leaf)) {
        throw ("RED: production script is intentionally missing: {0}" -f $productionScript)
    }

    Initialize-Fixture
    Copy-Item -LiteralPath $productionScript -Destination (Join-NativePath -BasePath $fixture -RelativePath 'scripts/Test-Governance.ps1') -Force

    Remove-Item -LiteralPath (Join-NativePath -BasePath $fixture -RelativePath 'docs/operations/PROJECT_LOG.md') -Force
    & git -C $fixture add -u -- 'docs/operations/PROJECT_LOG.md' 2>$null
    $result = Invoke-Governance -Mode PreCommit
    Assert-ExitCode -Actual $result.ExitCode -Expected 1 -Name 'missing PROJECT_LOG fails' -Output $result.Output
    Assert-OutputContains -Output $result.Output -Pattern 'PROJECT_LOG' -Name 'missing PROJECT_LOG reason'

    Reset-Fixture
    Add-Content -LiteralPath (Join-NativePath -BasePath $fixture -RelativePath 'docs/operations/PROJECT_LOG.md') -Value @'

## OP-20260804-001
- Time: 2026-08-04T00:01:00+08:00
- Task: qualified append
- Executor: test
- Branch: agent/test
- ApprovedStage: stage 2
- Changes: append one operation entry
- Files: docs/operations/PROJECT_LOG.md
- Verification: fixture
- Risks: none
- NextStep: review
'@
    & git -C $fixture add 'docs/operations/PROJECT_LOG.md' 2>$null
    $result = Invoke-Governance -Mode PreCommit
    Assert-ExitCode -Actual $result.ExitCode -Expected 0 -Name 'qualified append passes' -Output $result.Output

    Reset-Fixture
    Write-FixtureFile -RelativePath 'docs/operations/PROJECT_LOG.md' -Content @'
# Project Operation Log
'@
    & git -C $fixture add 'docs/operations/PROJECT_LOG.md' 2>$null
    $result = Invoke-Governance -Mode PreCommit
    Assert-ExitCode -Actual $result.ExitCode -Expected 1 -Name 'deleted historical log entry fails' -Output $result.Output
    Assert-OutputContains -Output $result.Output -Pattern 'append-only|historical|removed' -Name 'deleted historical log reason'

    Reset-Fixture
    Add-Content -LiteralPath (Join-NativePath -BasePath $fixture -RelativePath 'docs/operations/PROJECT_LOG.md') -Value @'

## OP-20260804-001
- Time: 2026-08-04T00:02:00+08:00
- Task: client identifier scan allow-list
- Executor: test
- Branch: agent/test
- ApprovedStage: stage 2
- Changes: verify public client identifiers are not treated as secrets
- Files: docs/client-config.txt
- Verification: fixture
- Risks: none
- NextStep: review
'@
    Write-FixtureFile -RelativePath 'docs/client-config.txt' -Content "appId=public-client-id-example`nappKey=public-client-key-example`n"
    & git -C $fixture add 'docs/operations/PROJECT_LOG.md' 'docs/client-config.txt' 2>$null
    $result = Invoke-Governance -Mode PreCommit
    Assert-ExitCode -Actual $result.ExitCode -Expected 0 -Name 'LeanCloud appId/appKey values allowed' -Output $result.Output

    Reset-Fixture
    & git -C $fixture checkout -q -b side 2>$null | Out-Null
    Assert-ExitCode -Actual $LASTEXITCODE -Expected 0 -Name 'merge fixture side branch' -Output ''
    Add-Content -LiteralPath (Join-NativePath -BasePath $fixture -RelativePath 'docs/operations/PROJECT_LOG.md') -Value @'

## OP-20260804-001
- Time: 2026-08-04T00:02:30+08:00
- Task: merge commit regression
- Executor: test
- Branch: side
- ApprovedStage: stage 2
- Changes: create a legal side-branch operation before merge rejection
- Files: docs/side.txt
- Verification: fixture
- Risks: none
- NextStep: review
'@
    Write-FixtureFile -RelativePath 'docs/side.txt' -Content 'side branch'
    & git -C $fixture add 'docs/operations/PROJECT_LOG.md' 'docs/side.txt' 2>$null
    & git -C $fixture commit -m 'fixture side branch' 2>$null | Out-Null
    Assert-ExitCode -Actual $LASTEXITCODE -Expected 0 -Name 'merge fixture side commit' -Output ''
    & git -C $fixture checkout -q --force main 2>$null | Out-Null
    Assert-ExitCode -Actual $LASTEXITCODE -Expected 0 -Name 'merge fixture main checkout' -Output ''
    & git -C $fixture merge --quiet --no-ff side -m 'fixture merge commit' 2>$null | Out-Null
    Assert-ExitCode -Actual $LASTEXITCODE -Expected 0 -Name 'merge fixture merge commit' -Output ''
    Copy-Item -LiteralPath $productionScript -Destination (Join-NativePath -BasePath $fixture -RelativePath 'scripts/Test-Governance.ps1') -Force
    $result = Invoke-Governance -Mode Ci -BaseRef 'origin/main'
    Assert-ExitCode -Actual $result.ExitCode -Expected 1 -Name 'merge commit is rejected' -Output $result.Output
    Assert-OutputContains -Output $result.Output -Pattern 'merge commit|rebased' -Name 'merge commit rejection reason'

    Reset-Fixture
    Add-Content -LiteralPath (Join-NativePath -BasePath $fixture -RelativePath 'docs/operations/PROJECT_LOG.md') -Value @'

## OP-20260804-001
- Time: 2026-08-04T00:02:45+08:00
- Task: hook mode regression
- Executor: test
- Branch: agent/test
- ApprovedStage: stage 2
- Changes: verify the controlled Hook mode is executable
- Files: .githooks/pre-commit
- Verification: fixture
- Risks: none
- NextStep: review
'@
    & git -C $fixture add 'docs/operations/PROJECT_LOG.md' 2>$null
    & git -C $fixture update-index --chmod=-x -- '.githooks/pre-commit'
    $result = Invoke-Governance -Mode PreCommit
    Assert-ExitCode -Actual $result.ExitCode -Expected 1 -Name 'hook mode 100644 is rejected' -Output $result.Output
    Assert-OutputContains -Output $result.Output -Pattern '100755|Hook' -Name 'hook mode rejection reason'

    Reset-Fixture
    $result = Invoke-Governance -Mode Ci -BaseRef 'origin/missing-base'
    Assert-ExitCode -Actual $result.ExitCode -Expected 1 -Name 'invalid CI base ref fails closed' -Output $result.Output
    Assert-OutputContains -Output $result.Output -Pattern 'git command failed|missing-base' -Name 'invalid CI base ref reason'

    Reset-Fixture
    Remove-Item -LiteralPath (Join-NativePath -BasePath $fixture -RelativePath 'docs/operations/PROJECT_LOG.md') -Force
    & git -C $fixture add -u -- 'docs/operations/PROJECT_LOG.md'
    & git -C $fixture commit -m 'fixture deleted operation log' 2>$null | Out-Null
    Assert-ExitCode -Actual $LASTEXITCODE -Expected 0 -Name 'deleted log commit' -Output ''
    $result = Invoke-Governance -Mode Ci -BaseRef 'origin/main'
    Assert-ExitCode -Actual $result.ExitCode -Expected 1 -Name 'missing committed log fails closed' -Output $result.Output
    Assert-OutputContains -Output $result.Output -Pattern 'missing required file|PROJECT_LOG' -Name 'missing committed log reason'

    Reset-Fixture
    $fakeToken = ('gh' + 'p_123456789012345678901234567890123456')
    Add-Content -LiteralPath (Join-NativePath -BasePath $fixture -RelativePath 'docs/operations/PROJECT_LOG.md') -Value @'

## OP-20260804-001
- Time: 2026-08-04T00:03:00+08:00
- Task: sensitive staged content
- Executor: test
- Branch: agent/test
- ApprovedStage: stage 2
- Changes: verify sensitive assignment detection
- Files: docs/leak.txt
- Verification: fixture
- Risks: none
- NextStep: review
'@
    Write-FixtureFile -RelativePath 'docs/leak.txt' -Content ("GITHUB_TOKEN={0}{1}SESSION_TOKEN=not-a-placeholder{1}" -f $fakeToken, [Environment]::NewLine)
    & git -C $fixture add 'docs/operations/PROJECT_LOG.md' 'docs/leak.txt' 2>$null
    $result = Invoke-Governance -Mode PreCommit
    Assert-ExitCode -Actual $result.ExitCode -Expected 1 -Name 'sensitive staged content fails' -Output $result.Output
    Assert-OutputContains -Output $result.Output -Pattern 'GitHub token|secret assignment|token' -Name 'sensitive staged content reason'
    Assert-OutputContains -Output $result.Output -Pattern 'high-confidence secret assignment' -Name 'SESSION_TOKEN assignment reason'

    Reset-Fixture
    Add-Content -LiteralPath (Join-NativePath -BasePath $fixture -RelativePath 'docs/operations/PROJECT_LOG.md') -Value @'

## OP-20260804-001
- Time: 2026-08-04T00:04:00+08:00
- Task: invalid env example
- Executor: test
- Branch: agent/test
- ApprovedStage: stage 2
- Changes: verify env example values are placeholders
- Files: .env.example
- Verification: fixture
- Risks: none
- NextStep: review
'@
    Write-FixtureFile -RelativePath '.env.example' -Content ("# fixture{0}VITE_LEANCLOUD_APP_ID=not-a-placeholder{0}" -f [Environment]::NewLine)
    & git -C $fixture add 'docs/operations/PROJECT_LOG.md' '.env.example' 2>$null
    $result = Invoke-Governance -Mode PreCommit
    Assert-ExitCode -Actual $result.ExitCode -Expected 1 -Name 'non-placeholder env example fails' -Output $result.Output
    Assert-OutputContains -Output $result.Output -Pattern '\.env\.example|non-empty|placeholder' -Name 'non-placeholder env example reason'

    Reset-Fixture
    $historyToken = ('gh' + 'p_987654321098765432109876543210987654')
    Add-Content -LiteralPath (Join-NativePath -BasePath $fixture -RelativePath 'docs/operations/PROJECT_LOG.md') -Value @'

## OP-20260804-001
- Time: 2026-08-04T00:05:00+08:00
- Task: historical secret introduction
- Executor: test
- Branch: agent/test
- ApprovedStage: stage 2
- Changes: introduce a staged token for regression coverage
- Files: docs/history-leak.txt
- Verification: fixture
- Risks: none
- NextStep: remove
'@
    Write-FixtureFile -RelativePath 'docs/history-leak.txt' -Content ("GITHUB_TOKEN={0}{1}" -f $historyToken, [Environment]::NewLine)
    & git -C $fixture add 'docs/operations/PROJECT_LOG.md' 'docs/history-leak.txt' 2>$null
    & git -C $fixture commit -m 'fixture secret introduction' 2>$null | Out-Null
    Assert-ExitCode -Actual $LASTEXITCODE -Expected 0 -Name 'historical secret introduction commit' -Output ''

    Add-Content -LiteralPath (Join-NativePath -BasePath $fixture -RelativePath 'docs/operations/PROJECT_LOG.md') -Value @'

## OP-20260804-002
- Time: 2026-08-04T00:06:00+08:00
- Task: historical secret deletion
- Executor: test
- Branch: agent/test
- ApprovedStage: stage 2
- Changes: remove the previously introduced token
- Files: docs/history-leak.txt
- Verification: fixture
- Risks: none
- NextStep: review
'@
    Remove-Item -LiteralPath (Join-NativePath -BasePath $fixture -RelativePath 'docs/history-leak.txt') -Force
    & git -C $fixture add -u -- 'docs/history-leak.txt'
    & git -C $fixture add 'docs/operations/PROJECT_LOG.md'
    & git -C $fixture commit -m 'fixture secret deletion' 2>$null | Out-Null
    Assert-ExitCode -Actual $LASTEXITCODE -Expected 0 -Name 'historical secret deletion commit' -Output ''

    $result = Invoke-Governance -Mode Ci -BaseRef 'origin/main'
    Assert-ExitCode -Actual $result.ExitCode -Expected 1 -Name 'historical secret remains blocked' -Output $result.Output
    Assert-OutputContains -Output $result.Output -Pattern 'GitHub token|secret' -Name 'historical secret reason'

    Write-Host '[PASS] governance fixture test suite'
    exit 0
}
catch {
    Write-Output ("TEST FAILURE: {0}" -f $_.Exception.ToString())
    exit 1
}
finally {
    if (Test-Path -LiteralPath $fixture) {
        $resolvedFixture = [System.IO.Path]::GetFullPath($fixture)
        $resolvedBase = [System.IO.Path]::GetFullPath($fixtureBase)
        $separator = [string][System.IO.Path]::DirectorySeparatorChar
        $alternateSeparator = [string][System.IO.Path]::AltDirectorySeparatorChar
        if (-not ($resolvedBase.EndsWith($separator) -or $resolvedBase.EndsWith($alternateSeparator))) { $resolvedBase += $separator }
        if ($resolvedFixture.StartsWith($resolvedBase, [System.StringComparison]::OrdinalIgnoreCase) -and [System.IO.Path]::GetFileName($resolvedFixture) -eq $fixtureName) {
            Remove-Item -LiteralPath $resolvedFixture -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
