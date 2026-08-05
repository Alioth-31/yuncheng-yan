[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('PreCommit', 'Ci')]
    [string]$Mode,

    [string]$BaseRef = 'origin/main'
)

$ErrorActionPreference = 'Stop'
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $scriptRoot '..'))
$logRelativePath = 'docs/operations/PROJECT_LOG.md'
$script:Violations = New-Object 'System.Collections.Generic.List[string]'

$requiredFiles = @(
    'README.md',
    'AGENTS.md',
    'CHANGELOG.md',
    '.gitignore',
    '.gitattributes',
    '.editorconfig',
    '.codex/config.toml',
    'docs/00_PROJECT_HOME.md',
    'docs/PROJECT_STATUS.md',
    'docs/ARCHITECTURE.md',
    'docs/DECISIONS.md',
    'docs/ROADMAP.md',
    'docs/AI_HANDOFF.md',
    'docs/tasks/TASK-0001_PROJECT_GOVERNANCE_BASELINE.md',
    'docs/operations/PROJECT_LOG.md',
    '.github/PULL_REQUEST_TEMPLATE.md',
    '.github/workflows/governance.yml',
    '.githooks/pre-commit',
    'scripts/Test-Governance.ps1',
    'scripts/Test-Governance.Tests.ps1',
    'scripts/Initialize-Clone.ps1'
)

function Add-Violation {
    param([string]$Message)
    [void]$script:Violations.Add($Message)
}

function ConvertTo-WindowsArgument {
    param([AllowNull()][string]$Value)
    if ($null -eq $Value) { return '""' }
    $escaped = $Value -replace '(\\*)"', '$1$1\"'
    $escaped = $escaped -replace '(\\+)$', '$1$1'
    return '"' + $escaped + '"'
}

function Invoke-GitProcess {
    param([Parameter(Mandatory = $true)][string[]]$Arguments)
    $gitCommand = Get-Command git -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $gitCommand) { $gitCommand = Get-Command git.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1 }
    if ($null -eq $gitCommand) { throw 'Git is required by the governance checks but was not found.' }

    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $gitCommand.Source
    $startInfo.Arguments = (($Arguments | ForEach-Object { ConvertTo-WindowsArgument -Value ([string]$_) }) -join ' ')
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    try {
        if ($null -ne $startInfo.PSObject.Properties['StandardOutputEncoding']) {
            $startInfo.StandardOutputEncoding = [System.Text.Encoding]::UTF8
            $startInfo.StandardErrorEncoding = [System.Text.Encoding]::UTF8
        }
    }
    catch { }

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo
    [void]$process.Start()
    $stdoutBytes = New-Object System.IO.MemoryStream
    $process.StandardOutput.BaseStream.CopyTo($stdoutBytes)
    $stderr = $process.StandardError.ReadToEnd()
    $process.WaitForExit()
    $stdout = [System.Text.Encoding]::UTF8.GetString($stdoutBytes.ToArray())
    $stdoutBytes.Dispose()
    return [pscustomobject]@{ ExitCode = $process.ExitCode; Stdout = $stdout; Stderr = $stderr }
}

function Invoke-GitChecked {
    param([string[]]$Arguments)
    $result = Invoke-GitProcess -Arguments $Arguments
    if ($result.ExitCode -ne 0) {
        $detail = ($result.Stderr + $result.Stdout).Trim()
        throw ("git command failed with exit code {0}: {1}" -f $result.ExitCode, $detail)
    }
    return $result.Stdout
}

function Invoke-GitOptional {
    param([string[]]$Arguments)
    return (Invoke-GitProcess -Arguments $Arguments)
}

function Normalize-Text {
    param([AllowNull()][string]$Text)
    if ($null -eq $Text) { return $null }
    $normalized = (($Text -replace "`r`n", "`n") -replace "`r", "`n")
    return $normalized.TrimStart([char]0xfeff)
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

function Read-Utf8File {
    param([string]$Path, [switch]$AllowMissing)
    try {
        $exists = Test-Path -LiteralPath $Path -PathType Leaf -ErrorAction Stop
    }
    catch {
        throw ("Cannot inspect file {0}: {1}" -f $Path, $_.Exception.Message)
    }
    if (-not $exists) {
        if ($AllowMissing) { return $null }
        throw ("Required file is missing while scanning: {0}" -f $Path)
    }
    try {
        return [System.Text.Encoding]::UTF8.GetString([System.IO.File]::ReadAllBytes($Path))
    }
    catch {
        throw ("Cannot read file {0}: {1}" -f $Path, $_.Exception.Message)
    }
}

function Get-GitTreeFileText {
    param([string]$Treeish, [string]$RelativePath, [switch]$AllowMissing)
    $null = Invoke-GitChecked -Arguments @('-C', $repoRoot, 'rev-parse', '--verify', ($Treeish + '^{commit}'))
    $listing = Invoke-GitChecked -Arguments @('-C', $repoRoot, 'ls-tree', '-r', '--name-only', $Treeish, '--', $RelativePath)
    $entries = @($listing -split '\r?\n' | Where-Object { $_ -and $_.Trim() })
    if ($entries -notcontains $RelativePath) {
        if ($AllowMissing) { return $null }
        throw ("Git tree {0} is missing required file {1}." -f $Treeish, $RelativePath)
    }
    return Invoke-GitChecked -Arguments @('-C', $repoRoot, 'show', ('{0}:{1}' -f $Treeish, $RelativePath))
}

function Get-GitIndexFileText {
    param([string]$RelativePath)
    $listing = Invoke-GitChecked -Arguments @('-C', $repoRoot, 'ls-files', '--stage', '--', $RelativePath)
    if ([string]::IsNullOrWhiteSpace($listing)) { return $null }
    return Invoke-GitChecked -Arguments @('-C', $repoRoot, 'show', (':{0}' -f $RelativePath))
}

function Get-HeadFileText {
    param([string]$RelativePath)
    return Get-GitTreeFileText -Treeish 'HEAD' -RelativePath $RelativePath -AllowMissing
}

function Get-BaseFileText {
    param([string]$Reference, [string]$RelativePath)
    return Get-GitTreeFileText -Treeish $Reference -RelativePath $RelativePath -AllowMissing
}

function Get-IndexFileText {
    param([string]$RelativePath)
    return Get-GitIndexFileText -RelativePath $RelativePath
}

function Get-CommitFileText {
    param([string]$Commit, [string]$RelativePath, [switch]$AllowMissing)
    return Get-GitTreeFileText -Treeish $Commit -RelativePath $RelativePath -AllowMissing:$AllowMissing
}

function Test-IndexPath {
    param([string]$RelativePath)
    $listing = Invoke-GitChecked -Arguments @('-C', $repoRoot, 'ls-files', '--stage', '--', $RelativePath)
    return (-not [string]::IsNullOrWhiteSpace($listing))
}

function Get-PathLines {
    param([string[]]$Arguments)
    $text = Invoke-GitChecked -Arguments $Arguments
    return @($text -split "`r?`n" | Where-Object { $_ -ne '' })
}

function Get-StagedPaths {
    return Get-PathLines -Arguments @('-C', $repoRoot, 'diff', '--cached', '--name-only', '--diff-filter=ACMR')
}

function Get-CiChangedPaths {
    param([string]$Reference)
    $changed = @()
    $diffText = Invoke-GitChecked -Arguments @('-C', $repoRoot, 'diff', '--name-only', '--diff-filter=ACMR', $Reference, '--')
    $changed += @($diffText -split '\r?\n' | Where-Object { $_ -ne '' })
    $untrackedText = Invoke-GitChecked -Arguments @('-C', $repoRoot, 'ls-files', '--others', '--exclude-standard')
    $changed += @($untrackedText -split '\r?\n' | Where-Object { $_ -ne '' })
    return @($changed | Where-Object { $_ } | Select-Object -Unique)
}

function Get-OpIds {
    param([AllowNull()][string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return @() }
    $matches = [regex]::Matches($Text, '(?im)^\s*##\s+(OP-\d{8}-\d{3})\s*$')
    return @($matches | ForEach-Object { $_.Groups[1].Value.ToUpperInvariant() })
}

function Get-UniqueValues {
    param([string[]]$Values)
    return @($Values | Where-Object { $_ } | Select-Object -Unique)
}

function Test-RequiredFields {
    param([string]$OpId, [string]$Text)
    $match = [regex]::Match($Text, '(?ims)^##\s+' + [regex]::Escape($OpId) + '\s*$.*?(?=^##\s+OP-|\z)')
    if (-not $match.Success) {
        Add-Violation ("Operation log {0} has no parseable entry block." -f $OpId)
        return
    }

    $cnTime = ([char]0x65f6 + [char]0x95f4)
    $cnTask = ([char]0x4efb + [char]0x52a1)
    $cnExecutor = ([char]0x6267 + [char]0x884c + [char]0x8005)
    $cnBranch = ([char]0x5206 + [char]0x652f)
    $cnApprovedStage = ([char]0x6279 + [char]0x51c6 + [char]0x9636 + [char]0x6bb5)
    $cnChanges = ([char]0x53d8 + [char]0x66f4)
    $cnFiles = ([char]0x6587 + [char]0x4ef6)
    $cnVerification = ([char]0x9a8c + [char]0x8bc1)
    $cnRisks = ([char]0x98ce + [char]0x9669)
    $cnNextStep = ([char]0x4e0b + [char]0x4e00 + [char]0x6b65)
    $fields = @(
        @($cnTime, 'Time'), @($cnTask, 'Task'), @($cnExecutor, 'Executor'),
        @($cnBranch, 'Branch'), @($cnApprovedStage, 'ApprovedStage'),
        @($cnChanges, 'Changes'), @($cnFiles, 'Files'),
        @($cnVerification, 'Verification'), @($cnRisks, 'Risks'),
        @($cnNextStep, 'NextStep')
    )
    foreach ($field in $fields) {
        $labelPattern = '(?:' + [regex]::Escape($field[0]) + '|' + [regex]::Escape($field[1]) + ')'
        $fieldMatch = [regex]::Match($match.Value, '(?im)^\s*[-*]?\s*' + $labelPattern + '\s*[:' + [char]0xff1a + ']\s*(\S.*)$')
        if (-not $fieldMatch.Success) { Add-Violation ("Operation log {0} is missing field {1}." -f $OpId, $field[1]) }
    }
}

function Test-AppendOnlyLog {
    param([AllowNull()][string]$OldText, [AllowNull()][string]$NewText, [string]$Context)
    if ($null -eq $NewText) {
        Add-Violation ("{0} is missing {1}." -f $Context, $logRelativePath)
        return
    }
    if ($null -eq $OldText) { return }
    $oldNormalized = Normalize-Text -Text $OldText
    $newNormalized = Normalize-Text -Text $NewText
    if (-not $newNormalized.StartsWith($oldNormalized, [System.StringComparison]::Ordinal)) {
        Add-Violation ("{0} PROJECT_LOG.md is not append-only; historical entries cannot be changed or deleted." -f $Context)
    }
}

function Test-ProjectLogChange {
    param(
        [AllowNull()][string]$OldText,
        [AllowNull()][string]$NewText,
        [string]$Context,
        [switch]$RequireExactlyOneNewOp,
        [switch]$RequireAtLeastOneNewOp
    )
    Test-AppendOnlyLog -OldText $OldText -NewText $NewText -Context $Context
    if ($null -eq $NewText) { return }

    $oldIds = Get-OpIds -Text (Normalize-Text -Text $OldText)
    $newIds = Get-OpIds -Text (Normalize-Text -Text $NewText)
    $uniqueOld = Get-UniqueValues -Values $oldIds
    $uniqueNew = Get-UniqueValues -Values $newIds
    if ($newIds.Count -ne $uniqueNew.Count) { Add-Violation ("{0} PROJECT_LOG.md contains duplicate OP identifiers." -f $Context) }

    $removedIds = @($uniqueOld | Where-Object { $uniqueNew -notcontains $_ })
    if ($removedIds.Count -gt 0) { Add-Violation ("{0} removed historical OP identifiers: {1}." -f $Context, ($removedIds -join ', ')) }

    $addedIds = @($uniqueNew | Where-Object { $uniqueOld -notcontains $_ })
    if ($RequireAtLeastOneNewOp -and $addedIds.Count -lt 1) { Add-Violation ("{0} must add at least one OP; found {1}." -f $Context, $addedIds.Count) }
    if ($RequireExactlyOneNewOp -and $addedIds.Count -ne 1) { Add-Violation ("{0} must add exactly one OP; found {1}." -f $Context, $addedIds.Count) }
    foreach ($opId in $addedIds) { Test-RequiredFields -OpId $opId -Text $NewText }
}

function Test-PlaceholderValue {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return $true }
    $clean = $Value.Trim().Trim('"', "'", '`', ';', ',')
    if ([string]::IsNullOrWhiteSpace($clean)) { return $true }
    $pending = ([char]0x5f85 + [char]0x51b3)
    $undecided = ([char]0x672a + [char]0x51b3 + [char]0x5b9a)
    $pendingShort = ([char]0x5f85 + [char]0x5b9a)
    $placeholders = @('todo', 'tbd', $pending, $undecided, $pendingShort, 'example', 'sample', 'dummy', 'changeme', 'replace-me', 'replace_me', 'your-token', 'your_token', 'your-master-key', 'your_master_key', 'your-app-id', 'your_app_id', 'your-app-key', 'your_app_key', 'none', 'null', 'undefined', '***')
    if ($placeholders -contains $clean.ToLowerInvariant()) { return $true }
    return ($clean -match '^(<|\$\{|\[).*(>|\}|\])$')
}

function Test-EnvExampleAssignments {
    param([string]$RelativePath, [string]$Text)
    if ([System.IO.Path]::GetFileName(($RelativePath -replace '\\', '/')) -ne '.env.example') { return }
    $lineNumber = 0
    $normalizedText = Normalize-Text -Text $Text
    foreach ($line in ($normalizedText -split "`n")) {
        $lineNumber++
        $trimmed = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed.StartsWith('#')) { continue }
        $assignment = [regex]::Match($trimmed, '^(?:export[ \t]+)?[A-Za-z_][A-Za-z0-9_]*[ \t]*=[ \t]*(.*)$')
        if (-not $assignment.Success) { continue }
        $value = $assignment.Groups[1].Value.Trim()
        if (-not (Test-PlaceholderValue -Value $value)) {
            Add-Violation ("File {0} contains a non-empty, non-placeholder .env.example value at line {1}." -f $RelativePath, $lineNumber)
        }
    }
}

function Test-SensitiveContent {
    param([string]$RelativePath, [string]$Text)
    if ($null -eq $Text) { return }
    Test-EnvExampleAssignments -RelativePath $RelativePath -Text $Text
    $rules = @(
        [pscustomobject]@{ Pattern = '(?im)-----BEGIN\s+(?:[A-Z0-9]+\s+)?(?:PRIVATE KEY|CERTIFICATE)-----'; Message = 'PEM private key or certificate content' },
        [pscustomobject]@{ Pattern = '(?i)\bgh[pousr]_[A-Za-z0-9_]{20,}\b'; Message = 'GitHub token' },
        [pscustomobject]@{ Pattern = '(?i)\bgithub_pat_[A-Za-z0-9_]{20,}\b'; Message = 'GitHub token' }
    )
    foreach ($rule in $rules) {
        if ([regex]::IsMatch($Text, $rule.Pattern)) { Add-Violation ("File {0} contains {1}." -f $RelativePath, $rule.Message) }
    }

    $assignmentPatterns = @(
        [pscustomobject]@{ Pattern = '(?im)^[ \t]*(?:GH_TOKEN|GITHUB_TOKEN)[ \t]*[:=][ \t]*["'']?([^ \t\r\n"''#]+)'; Message = 'GitHub token configuration' },
        [pscustomobject]@{ Pattern = '(?im)^[ \t]*(?:storePassword|keyPassword|android\.injected\.signing\.(?:store|key)\.password)[ \t]*[:=][ \t]*["'']?([^ \t\r\n"''#]+)'; Message = 'Android signing password property' },
        [pscustomobject]@{ Pattern = '(?im)^[ \t]*(?:[A-Z][A-Z0-9_]*_)?(?:TOKEN|SECRET|PASSWORD|PASSWD|PWD)(?:_[A-Z0-9_]+)?[ \t]*[:=][ \t]*["'']?([^ \t\r\n"''#;,]+)'; Message = 'high-confidence secret assignment' },
        [pscustomobject]@{ Pattern = '(?im)\b(?:master[_-]?key)\b[ \t]*[:=][ \t]*["'']?([^ \t\r\n"'';,]+)'; Message = 'LeanCloud MasterKey value' },
        [pscustomobject]@{ Pattern = '(?im)\bsetMasterKey[ \t]*\([ \t]*["'']([^"'']+)["'']'; Message = 'LeanCloud MasterKey value' }
    )
    foreach ($rule in $assignmentPatterns) {
        $matches = [regex]::Matches($Text, $rule.Pattern)
        foreach ($match in $matches) {
            $value = $match.Groups[1].Value
            if (-not (Test-PlaceholderValue -Value $value)) { Add-Violation ("File {0} contains {1}." -f $RelativePath, $rule.Message) }
        }
    }
}

function Test-SensitivePath {
    param([string]$RelativePath)
    $normalized = $RelativePath.Replace('\', '/')
    $name = [System.IO.Path]::GetFileName($normalized)
    if (($name -eq '.env') -or (($name.StartsWith('.env.')) -and ($name -ne '.env.example'))) { Add-Violation ("Environment file is forbidden: {0}; only .env.example is allowed." -f $RelativePath) }
    if ($name -match '^(?:local|key)\.properties$') { Add-Violation ("Android private properties file is forbidden: {0}." -f $RelativePath) }
    if ($name -match '(?i)\.(?:jks|keystore|p12|pfx|pem|key|crt|cer|der|csr|apk|aab)$') { Add-Violation ("Signing material or APK/AAB output is forbidden: {0}." -f $RelativePath) }
    if ($name -match '(?i)^(?:id_(?:rsa|dsa|ecdsa|ed25519)|private[_-]?key|credentials?|secrets?)') { Add-Violation ("Credential or private-key file is forbidden: {0}." -f $RelativePath) }
    if ($normalized -match '(?i)(^|/)(?:credentials?|secrets?|keystores?|certificates?)(/|$)') { Add-Violation ("Credential directory is forbidden: {0}." -f $RelativePath) }
}

function Test-ChangedFilesForSecrets {
    param([string[]]$Paths, [switch]$FromIndex)
    foreach ($relativePath in @($Paths | Select-Object -Unique)) {
        if ([string]::IsNullOrWhiteSpace($relativePath)) { continue }
        if ($FromIndex) { $text = Get-IndexFileText -RelativePath $relativePath }
        else { $text = Read-Utf8File -Path (Join-NativePath -BasePath $repoRoot -RelativePath $relativePath) }
        if ($null -eq $text) { continue }
        Test-SensitivePath -RelativePath $relativePath
        Test-SensitiveContent -RelativePath $relativePath -Text $text
    }
}

function Get-CommitParents {
    param([string]$Commit)
    $line = Invoke-GitChecked -Arguments @('-C', $repoRoot, 'rev-list', '--parents', '-n', '1', $Commit)
    $parts = @($line.Trim() -split '\s+' | Where-Object { $_ })
    if ($parts.Count -lt 2) { return @() }
    return @($parts | Select-Object -Skip 1)
}

function Get-CommitParent {
    param([string]$Commit)
    $parents = @(Get-CommitParents -Commit $Commit)
    if ($parents.Count -eq 0) { return $null }
    return $parents[0]
}

function Get-SourceCommits {
    param([string]$Reference)
    $text = Invoke-GitChecked -Arguments @('-C', $repoRoot, 'rev-list', '--reverse', ('{0}..HEAD' -f $Reference))
    return @($text -split "`r?`n" | Where-Object { $_ -and $_.Trim() })
}

function Get-CommitChangedPaths {
    param([string]$Commit, [AllowNull()][string]$Parent)
    if ([string]::IsNullOrWhiteSpace($Parent)) {
        $result = Invoke-GitChecked -Arguments @('-C', $repoRoot, 'diff-tree', '--root', '--no-commit-id', '--name-only', '-r', '--no-renames', $Commit, '--')
    }
    else {
        $result = Invoke-GitChecked -Arguments @('-C', $repoRoot, 'diff', '--name-only', '--no-renames', $Parent, $Commit, '--')
    }
    return @($result -split "`r?`n" | Where-Object { $_ -and $_.Trim() } | Select-Object -Unique)
}

function Test-CommitChangedFilesForSecrets {
    param([string]$Commit, [AllowNull()][string]$Parent)
    foreach ($relativePath in (Get-CommitChangedPaths -Commit $Commit -Parent $Parent)) {
        $text = Get-CommitFileText -Commit $Commit -RelativePath $relativePath -AllowMissing
        if ($null -eq $text) { continue }
        Test-SensitivePath -RelativePath $relativePath
        Test-SensitiveContent -RelativePath $relativePath -Text $text
    }
}

function Test-SourceCommitHistory {
    param([string]$Reference, [switch]$AllowMultipleOps)
    $commits = @(Get-SourceCommits -Reference $Reference)
    $allowMultipleForCommit = $AllowMultipleOps -and ($commits.Count -eq 1)
    foreach ($commit in $commits) {
        $parents = @(Get-CommitParents -Commit $commit)
        if ($parents.Count -gt 1) {
            Add-Violation ("Commit {0} is a merge commit; source branches must be rebased and must not contain merge commits." -f $commit)
            Test-CommitChangedFilesForSecrets -Commit $commit -Parent $parents[0]
            continue
        }
        $parent = if ($parents.Count -eq 0) { $null } else { $parents[0] }
        $oldLog = if ([string]::IsNullOrWhiteSpace($parent)) { $null } else { Get-CommitFileText -Commit $parent -RelativePath $logRelativePath -AllowMissing }
        $newLog = Get-CommitFileText -Commit $commit -RelativePath $logRelativePath
        $context = ('Commit {0}' -f $commit)
        Test-ProjectLogChange -OldText $oldLog -NewText $newLog -Context $context -RequireAtLeastOneNewOp -RequireExactlyOneNewOp:(-not $allowMultipleForCommit)
        Test-CommitChangedFilesForSecrets -Commit $commit -Parent $parent
    }
    return $commits.Count
}

function Test-RequiredFiles {
    param([switch]$FromIndex)
    foreach ($relativePath in $requiredFiles) {
        $present = if ($FromIndex) { Test-IndexPath -RelativePath $relativePath } else { Test-Path -LiteralPath (Join-NativePath -BasePath $repoRoot -RelativePath $relativePath) -PathType Leaf }
        if (-not $present) {
            $where = if ($FromIndex) { 'index' } else { 'worktree' }
            Add-Violation ("Required governance file is missing ({0}): {1}." -f $where, $relativePath)
        }
    }
}

function Test-HookMode {
    param([ValidateSet('Index', 'Head')][string]$Source)
    $hookRelativePath = '.githooks/pre-commit'
    if ($Source -eq 'Index') {
        $entry = Invoke-GitChecked -Arguments @('-C', $repoRoot, 'ls-files', '--stage', '--', $hookRelativePath)
    }
    else {
        $entry = Invoke-GitChecked -Arguments @('-C', $repoRoot, 'ls-tree', 'HEAD', '--', $hookRelativePath)
    }
    if ([string]::IsNullOrWhiteSpace($entry)) {
        Add-Violation ("Controlled hook is missing from the {0}; expected mode 100755: {1}." -f $Source, $hookRelativePath)
        return
    }
    $mode = ($entry -split '\s+')[0]
    if ($mode -ne '100755') {
        Add-Violation ("Controlled hook has mode {0} in the {1}; expected 100755: {2}." -f $mode, $Source, $hookRelativePath)
    }
}

function Test-PreCommit {
    Test-RequiredFiles -FromIndex
    Test-HookMode -Source Index
    Test-ChangedFilesForSecrets -Paths (Get-StagedPaths) -FromIndex
    Test-ProjectLogChange -OldText (Get-HeadFileText -RelativePath $logRelativePath) -NewText (Get-IndexFileText -RelativePath $logRelativePath) -Context 'PreCommit' -RequireExactlyOneNewOp
}

function Test-Ci {
    $null = Invoke-GitChecked -Arguments @('-C', $repoRoot, 'rev-parse', '--verify', ($BaseRef + '^{commit}'))
    Test-RequiredFiles
    $isMainPush = [string]::Equals($env:GITHUB_REF, 'refs/heads/main', [System.StringComparison]::OrdinalIgnoreCase)
    $sourceCommitCount = Test-SourceCommitHistory -Reference $BaseRef -AllowMultipleOps:$isMainPush
    if ($sourceCommitCount -gt 0) {
        Test-HookMode -Source Head
        if ($isMainPush) { Write-Host '[INFO] Main push: allowing one or more OP entries in the squash integration commit.' }
        return
    }

    $status = Invoke-GitChecked -Arguments @('-C', $repoRoot, 'status', '--porcelain', '--untracked-files=all')
    if ([string]::IsNullOrWhiteSpace($status)) {
        Add-Violation ("CI found no source commits relative to {0}; local precheck requires a dirty worktree or a pushed commit range." -f $BaseRef)
        return
    }

    Test-ChangedFilesForSecrets -Paths (Get-CiChangedPaths -Reference $BaseRef)
    $oldLog = Get-BaseFileText -Reference $BaseRef -RelativePath $logRelativePath
    $currentLog = Read-Utf8File -Path (Join-NativePath -BasePath $repoRoot -RelativePath $logRelativePath)
    Test-ProjectLogChange -OldText $oldLog -NewText $currentLog -Context ('Local dirty CI precheck relative to {0}' -f $BaseRef) -RequireExactlyOneNewOp
    Write-Host '[INFO] Local dirty worktree precheck: treating the pending change set as one source commit.'
}

try {
    $repoProbe = Invoke-GitOptional -Arguments @('-C', $repoRoot, 'rev-parse', '--show-toplevel')
    if ($repoProbe.ExitCode -ne 0) { throw 'The current directory is not inside a Git worktree.' }
    if ($Mode -eq 'PreCommit') { Test-PreCommit } else { Test-Ci }
    if ($script:Violations.Count -gt 0) {
        foreach ($violation in $script:Violations) { Write-Output ("ERROR: {0}" -f $violation) }
        exit 1
    }
    Write-Host ("[PASS] Governance {0} checks passed." -f $Mode)
    exit 0
}
catch {
    Write-Output ("ERROR: Governance check failed: {0}" -f $_.Exception.ToString())
    exit 1
}
