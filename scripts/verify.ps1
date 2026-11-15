param(
    [Parameter(Mandatory = $true)]
    [string]$PatchedJar,

    [string]$StarsectorDir = ""
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot

if (-not (Test-Path -LiteralPath $PatchedJar)) {
    throw "找不到待验证 JAR：$PatchedJar"
}

$javap = Get-Command javap -ErrorAction Stop
$jar = Get-Command jar -ErrorAction Stop

$entries = & $jar.Source tf $PatchedJar
if ($LASTEXITCODE -ne 0) {
    throw "JAR 无法读取。"
}

$requiredClasses = @(
    "progsmod/plugin/ProgSMod.class",
    "progsmod/data/campaign/LunaSModButton.class",
    "progsmod/data/campaign/rulecmd/ui/plugins/ShipSelector.class"
)
foreach ($className in $requiredClasses) {
    if ($entries -notcontains $className) {
        throw "JAR 缺少类：$className"
    }
}

$pluginInfo = & $javap.Source -classpath $PatchedJar -p progsmod.plugin.ProgSMod
if (($pluginInfo -join "`n") -notmatch "clearPersistentSelectedShipMemory") {
    throw "未找到载入清理方法。"
}

$selectorInfo = & $javap.Source -classpath $PatchedJar -p -c progsmod.data.campaign.rulecmd.ui.plugins.ShipSelector
if (($selectorInfo -join "`n") -match '\$selectedShip') {
    throw "ShipSelector 仍包含 $selectedShip 写入逻辑。"
}

$buttonInfo = & $javap.Source -classpath $PatchedJar -p -c progsmod.data.campaign.LunaSModButton
if (($buttonInfo -join "`n") -match '\$selectedShip') {
    throw "LunaSModButton 仍包含 $selectedShip 写入逻辑。"
}

if (-not [string]::IsNullOrWhiteSpace($StarsectorDir)) {
    $gameJava = Join-Path $StarsectorDir "jre\bin\java.exe"
    if (-not (Test-Path -LiteralPath $gameJava)) {
        throw "找不到游戏自带 Java：$gameJava"
    }
}

Write-Host "验证通过：$PatchedJar"
