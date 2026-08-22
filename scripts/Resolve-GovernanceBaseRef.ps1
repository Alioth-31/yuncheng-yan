[CmdletBinding()]
param(
    [string]$EventName,
    [string]$PullRequestBaseSha,
    [string]$PushBeforeSha,
    [string]$GitRef
)

$ErrorActionPreference = 'Stop'

switch ($EventName) {
    'pull_request' {
        $baseRef = $PullRequestBaseSha.Trim()
        if ([string]::IsNullOrWhiteSpace($baseRef)) {
            throw 'Pull request governance event requires PullRequestBaseSha.'
        }
        Write-Output $baseRef
        break
    }
    'push' {
        $ref = $GitRef.Trim()
        if ($ref -match '^refs/heads/agent/.+$') {
            Write-Output 'origin/main'
            break
        }
        if ($ref -ne 'refs/heads/main') {
            throw 'Governance push event uses an unsupported ref.'
        }

        $baseRef = $PushBeforeSha.Trim()
        if ([string]::IsNullOrWhiteSpace($baseRef)) {
            throw 'Main push governance event requires PushBeforeSha.'
        }
        if ($baseRef -match '^0+$') {
            Write-Output 'origin/main'
            break
        }
        Write-Output $baseRef
        break
    }
    default {
        throw 'Unsupported governance event.'
    }
}
