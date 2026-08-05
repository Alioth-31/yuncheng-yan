[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $scriptRoot '..'))

function Invoke-Git {
    param([string[]]$Arguments)
    & git -C $repoRoot @Arguments
    if ($LASTEXITCODE -ne 0) { throw ("git command failed: {0}" -f ($Arguments -join ' ')) }
}

try {
    $gitCommand = Get-Command git -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $gitCommand) { $gitCommand = Get-Command git.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1 }
    if ($null -eq $gitCommand) { throw 'Git is required.' }
    $null = & git -C $repoRoot rev-parse --show-toplevel
    if ($LASTEXITCODE -ne 0) { throw 'The current directory is not a Git worktree.' }

    Invoke-Git -Arguments @('config', 'core.hookspath', '.githooks')
    Invoke-Git -Arguments @('config', 'pull.ff', 'only')
    Invoke-Git -Arguments @('config', 'fetch.prune', 'true')

    $hookPath = Join-Path (Join-Path $repoRoot '.githooks') 'pre-commit'
    if (-not (Test-Path -LiteralPath $hookPath -PathType Leaf)) { throw 'The pre-commit hook is missing.' }
    $hookValue = (& git -C $repoRoot config --get core.hookspath).Trim()
    if ($hookValue -ne '.githooks') { throw ("core.hookspath verification failed: {0}" -f $hookValue) }

    $gh = Get-Command gh.exe -ErrorAction SilentlyContinue
    if ($null -ne $gh) {
        & $gh.Source --version | Select-Object -First 1
    }
    else {
        Write-Warning 'gh was not found; GitHub authentication remains user-owned and was not changed.'
    }

    Write-Host 'Clone-local Git settings and governance hook verified.'
    exit 0
}
catch {
    Write-Error ("Initialize-Clone failed: {0}" -f $_.Exception.Message)
    exit 1
}
