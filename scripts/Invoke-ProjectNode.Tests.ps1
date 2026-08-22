[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $scriptRoot '..'))
$wrapperPath = Join-Path $scriptRoot 'Invoke-ProjectNode.ps1'

function Assert-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Invoke-Wrapper {
    param([Parameter(Mandatory = $true)][string[]]$WrapperArguments)

    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $wrapperPath @WrapperArguments 2>&1 | Out-String
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    return [pscustomobject]@{
        ExitCode = $exitCode
        Output = $output.Trim()
    }
}

try {
    Assert-True -Condition (Test-Path -LiteralPath $wrapperPath -PathType Leaf) -Message 'Production wrapper is missing.'

    $outerPath = $env:Path
    $nodeVersion = Invoke-Wrapper -WrapperArguments @('-Tool', 'node', '--version')
    Assert-True -Condition ($nodeVersion.ExitCode -eq 0) -Message "node --version failed: $($nodeVersion.Output)"
    Assert-True -Condition ($nodeVersion.Output -eq 'v22.23.1') -Message "Unexpected Node version: $($nodeVersion.Output)"

    $npmVersion = Invoke-Wrapper -WrapperArguments @('-Tool', 'npm', '--version')
    Assert-True -Condition ($npmVersion.ExitCode -eq 0) -Message "npm --version failed: $($npmVersion.Output)"
    Assert-True -Condition ($npmVersion.Output -eq '10.9.8') -Message "Unexpected npm version: $($npmVersion.Output)"

    $npxVersion = Invoke-Wrapper -WrapperArguments @('-Tool', 'npx', '--version')
    Assert-True -Condition ($npxVersion.ExitCode -eq 0) -Message "npx --version failed: $($npxVersion.Output)"
    Assert-True -Condition ($npxVersion.Output -eq '10.9.8') -Message "Unexpected npx version: $($npxVersion.Output)"

    $expectedCache = [System.IO.Path]::GetFullPath((Join-Path $repoRoot '.npm-cache'))
    $cacheResult = Invoke-Wrapper -WrapperArguments @('-Tool', 'node', '-e', "process.stdout.write(process.env.npm_config_cache || '')")
    Assert-True -Condition ($cacheResult.ExitCode -eq 0) -Message "cache probe failed: $($cacheResult.Output)"
    Assert-True -Condition ($cacheResult.Output -eq $expectedCache) -Message "Unexpected npm cache: $($cacheResult.Output)"

    $expectedPathPrefix = @(
        [System.IO.Path]::GetFullPath('D:\node-v22.23.1-win-x64'),
        [System.IO.Path]::GetFullPath((Join-Path $repoRoot 'node_modules\.bin'))
    ) -join [System.IO.Path]::PathSeparator
    $pathResult = Invoke-Wrapper -WrapperArguments @('-Tool', 'node', '-e', "process.stdout.write(process.env.Path.split(';').slice(0, 2).join(';'))")
    Assert-True -Condition ($pathResult.ExitCode -eq 0) -Message "PATH probe failed: $($pathResult.Output)"
    Assert-True -Condition ($pathResult.Output -eq $expectedPathPrefix) -Message "Unexpected child PATH prefix: $($pathResult.Output)"

    $positionalResult = Invoke-Wrapper -WrapperArguments @('-Tool', 'node', '-p', 'process.argv[1]', 'forwarded-value')
    Assert-True -Condition ($positionalResult.ExitCode -eq 0) -Message "positional argument probe failed: $($positionalResult.Output)"
    Assert-True -Condition ($positionalResult.Output -eq 'forwarded-value') -Message "Unexpected positional argument: $($positionalResult.Output)"

    $npmPositionalResult = Invoke-Wrapper -WrapperArguments @('-Tool', 'npm', 'prefix', '--')
    Assert-True -Condition ($npmPositionalResult.ExitCode -eq 0) -Message "npm positional and double-dash argument probe failed: $($npmPositionalResult.Output)"
    Assert-True -Condition ($npmPositionalResult.Output -eq $repoRoot) -Message "Unexpected npm prefix: $($npmPositionalResult.Output)"

    $nonzeroResult = Invoke-Wrapper -WrapperArguments @('-Tool', 'node', '-e', 'process.exit(37)')
    Assert-True -Condition ($nonzeroResult.ExitCode -eq 37) -Message "Expected exit code 37, got $($nonzeroResult.ExitCode): $($nonzeroResult.Output)"

    $invalidToolResult = Invoke-Wrapper -WrapperArguments @('-Tool', 'invalid-tool', '--version')
    Assert-True -Condition ($invalidToolResult.ExitCode -ne 0) -Message 'Invalid tool unexpectedly succeeded.'
    Assert-True -Condition ($env:Path -ceq $outerPath) -Message 'Outer PATH changed after wrapper execution.'

    Write-Host '[PASS] project Node wrapper real-process tests'
    exit 0
}
catch {
    Write-Output ("TEST FAILURE: {0}" -f $_.Exception.Message)
    exit 1
}
