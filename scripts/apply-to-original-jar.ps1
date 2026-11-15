param(
    [Parameter(Mandatory = $true)]
    [string]$OriginalJar,

    [string]$OutputJar = "",

    [string]$ClassesDir = ""
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot

if (-not (Test-Path -LiteralPath $OriginalJar)) {
    throw "找不到 2025 原版 JAR：$OriginalJar"
}
if ([string]::IsNullOrWhiteSpace($OutputJar)) {
    $OutputJar = Join-Path $repoRoot "dist\Progressive S-Mods.jar"
}
if ([string]::IsNullOrWhiteSpace($ClassesDir)) {
    $ClassesDir = Join-Path $repoRoot "prebuilt\classes"
}
if (-not (Test-Path -LiteralPath $ClassesDir)) {
    throw "找不到预编译覆盖类目录：$ClassesDir"
}

$outputParent = Split-Path -Parent $OutputJar
if (-not [string]::IsNullOrWhiteSpace($outputParent)) {
    New-Item -ItemType Directory -Force -Path $outputParent | Out-Null
}

Copy-Item -LiteralPath $OriginalJar -Destination $OutputJar -Force

$jar = Get-Command jar -ErrorAction Stop
& $jar.Source uf $OutputJar -C $ClassesDir .
if ($LASTEXITCODE -ne 0) {
    throw "jar 更新失败，退出码：$LASTEXITCODE"
}

$hash = (Get-FileHash -LiteralPath $OutputJar -Algorithm SHA256).Hash
Write-Host "输出 JAR：$OutputJar"
Write-Host "SHA-256：$hash"
