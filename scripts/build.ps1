param(
    [Parameter(Mandatory = $true)]
    [string]$StarsectorDir,

    [Parameter(Mandatory = $true)]
    [string]$OriginalJar,

    [string]$LunaLibJar = ""
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$outputDir = Join-Path $repoRoot "build\classes"

if (-not (Test-Path -LiteralPath $StarsectorDir)) {
    throw "找不到 Starsector 目录：$StarsectorDir"
}
if (-not (Test-Path -LiteralPath $OriginalJar)) {
    throw "找不到 2025 原版 JAR：$OriginalJar"
}
if ([string]::IsNullOrWhiteSpace($LunaLibJar)) {
    $LunaLibJar = Join-Path $StarsectorDir "mods\A-Lunalib\jars\LunaLib.jar"
}
if (-not (Test-Path -LiteralPath $LunaLibJar)) {
    throw "找不到 LunaLib JAR：$LunaLibJar"
}

$javac = Get-Command javac -ErrorAction Stop
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

$classPath = @(
    (Join-Path $StarsectorDir "starsector-core\starfarer.api.jar"),
    (Join-Path $StarsectorDir "starsector-core\starfarer_obf.jar"),
    $LunaLibJar,
    $OriginalJar
) -join ";"

$sourceFiles = @(
    (Join-Path $repoRoot "src\progsmod\plugin\ProgSMod.java"),
    (Join-Path $repoRoot "src\progsmod\data\campaign\LunaSModButton.java"),
    (Join-Path $repoRoot "src\progsmod\data\campaign\rulecmd\ui\plugins\ShipSelector.java")
)

& $javac.Source --release 17 -encoding UTF-8 -cp $classPath -d $outputDir @sourceFiles
if ($LASTEXITCODE -ne 0) {
    throw "javac 编译失败，退出码：$LASTEXITCODE"
}

Write-Host "编译完成：$outputDir"
