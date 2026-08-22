$ErrorActionPreference = 'Stop'
$rawArguments = @($args)
if (($rawArguments.Count -lt 2) -or ($rawArguments[0] -ine '-Tool')) {
    throw 'Usage: Invoke-ProjectNode.ps1 -Tool node|npm|npx [remaining arguments]'
}

$Tool = [string]$rawArguments[1]
if ($Tool -notin @('node', 'npm', 'npx')) {
    throw "Unsupported Tool '$Tool'. Expected node, npm, or npx."
}

$toolArguments = @()
if ($rawArguments.Count -gt 2) {
    $toolArguments = @($rawArguments[2..($rawArguments.Count - 1)])
}

$nodeRoot = [System.IO.Path]::GetFullPath('D:\node-v22.23.1-win-x64')
$nodeExecutable = Join-Path $nodeRoot 'node.exe'
$expectedNodeVersion = 'v22.23.1'
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $scriptRoot '..'))

if (-not (Test-Path -LiteralPath $nodeExecutable -PathType Leaf)) {
    throw "Required Node executable is missing: $nodeExecutable"
}

$actualNodeVersion = (& $nodeExecutable --version 2>&1 | Out-String).Trim()
$versionExitCode = $LASTEXITCODE
if (($versionExitCode -ne 0) -or ($actualNodeVersion -ne $expectedNodeVersion)) {
    throw "Required Node version is $expectedNodeVersion, but '$actualNodeVersion' was detected."
}

$toolExecutable = switch ($Tool) {
    'node' { $nodeExecutable }
    'npm' { Join-Path $nodeRoot 'npm.cmd' }
    'npx' { Join-Path $nodeRoot 'npx.cmd' }
}

if (-not (Test-Path -LiteralPath $toolExecutable -PathType Leaf)) {
    throw "Required tool is missing: $toolExecutable"
}

$originalPath = $env:Path
$cacheVariableExisted = Test-Path -LiteralPath 'Env:npm_config_cache'
$originalCache = $env:npm_config_cache
$projectBin = [System.IO.Path]::GetFullPath((Join-Path $repoRoot 'node_modules\.bin'))
$projectCache = [System.IO.Path]::GetFullPath((Join-Path $repoRoot '.npm-cache'))
$toolExitCode = 1

try {
    $env:Path = @($nodeRoot, $projectBin, $originalPath) -join [System.IO.Path]::PathSeparator
    $env:npm_config_cache = $projectCache
    & $toolExecutable @toolArguments
    $toolExitCode = $LASTEXITCODE
}
finally {
    $env:Path = $originalPath
    if ($cacheVariableExisted) {
        $env:npm_config_cache = $originalCache
    }
    else {
        Remove-Item -LiteralPath 'Env:npm_config_cache' -ErrorAction SilentlyContinue
    }
}

exit $toolExitCode
