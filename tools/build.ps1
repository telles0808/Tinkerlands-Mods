param(
    [string]$ModName = "TomTom",
    [switch]$Deploy = $false
)

$rootDir = Split-Path -Parent $PSScriptRoot
$srcFile = "$rootDir\mods\$ModName\src\$ModName.gml"
$distDir = "$rootDir\mods\$ModName\dist"
$releasesDir = "$rootDir\releases"

if (!(Test-Path $srcFile)) {
    Write-Error "Source file not found: $srcFile"
    exit 1
}

$modLower = $ModName.ToLower()

$modIdMap = @{
    "Fog" = 5001;
    "RealClock" = 5002;
    "BO" = 5003;
    "TomTom" = 5004
}

$modId = 5004
if ($modIdMap.ContainsKey($ModName)) {
    $modId = $modIdMap[$ModName]
}

$modKey = "telles0808_id$($modId)_$modLower"
$modFileName = "$modKey.mod"

Write-Host "Compiling $ModName as $modFileName (ID: $modId)..." -ForegroundColor Cyan

$gml = Get-Content $srcFile -Raw -Encoding UTF8
$encodedCode = $gml -replace '"', '%$%' -replace ',', '#$#' -replace "`r`n", '\n' -replace "`n", '\n' -replace "`r", '\n'

$exportDir = "$env:TEMP\TinkerlandsBuild_$ModName"
$exportScriptsDir = "$exportDir\scripts"

if (Test-Path $exportDir) { Remove-Item $exportDir -Recurse -Force }
New-Item -ItemType Directory -Path $exportScriptsDir -Force | Out-Null

$jsonExport = @"
{
	"id" : $modId,
	"key" : "$modKey",
	"event" : "E_CS_EVENT.None",
	"code" : "$encodedCode"
}
"@
$jsonExport | Set-Content "$exportScriptsDir\$modKey.json" -Encoding UTF8

$infoJson = @"
{
	"name" : "$modKey",
	"author" : "Telles0808",
	"version" : "1.0.0",
	"description" : "$ModName mod for Tinkerlands"
}
"@
$infoJson | Set-Content "$exportDir\info.json" -Encoding UTF8

$tempZip = "$env:TEMP\$ModName.zip"
if (Test-Path $tempZip) { Remove-Item $tempZip -Force }

Push-Location $exportDir
Compress-Archive -Path "*" -DestinationPath $tempZip -Force
Pop-Location

New-Item -ItemType Directory -Path $distDir -Force | Out-Null
New-Item -ItemType Directory -Path $releasesDir -Force | Out-Null

Copy-Item $tempZip "$distDir\$modFileName" -Force
Copy-Item $tempZip "$distDir\$ModName.mod" -Force
Copy-Item $tempZip "$releasesDir\$modFileName" -Force
Copy-Item $tempZip "$releasesDir\$ModName.mod" -Force
Remove-Item $tempZip -Force
Remove-Item $exportDir -Recurse -Force

Write-Host "Successfully compiled to $distDir\$modFileName and $releasesDir\$modFileName" -ForegroundColor Green

if ($Deploy) {
    $candidatePaths = @(
        "C:\Games\Steam\steamapps\common\Tinkerlands\mods",
        "C:\Program Files (x86)\Steam\steamapps\common\Tinkerlands\mods",
        "C:\Program Files\Steam\steamapps\common\Tinkerlands\mods",
        "D:\SteamLibrary\steamapps\common\Tinkerlands\mods",
        "E:\SteamLibrary\steamapps\common\Tinkerlands\mods"
    )

    $steamMods = $null
    foreach ($p in $candidatePaths) {
        if (Test-Path $p) {
            $steamMods = $p
            break
        }
    }

    if (!$steamMods) {
        try {
            $steamReg = Get-ItemProperty -Path "HKCU:\Software\Valve\Steam" -ErrorAction SilentlyContinue
            if ($steamReg -and $steamReg.SteamPath) {
                $regMods = Join-Path $steamReg.SteamPath "steamapps\common\Tinkerlands\mods"
                if (Test-Path $regMods) { $steamMods = $regMods }
            }
        } catch {}
    }

    if ($steamMods -and (Test-Path $steamMods)) {
        Copy-Item "$distDir\$modFileName" "$steamMods\$modFileName" -Force
        Write-Host "Deployed to $steamMods\$modFileName" -ForegroundColor Green
    } else {
        Write-Host "Steam mods directory not found automatically. Please check candidate paths." -ForegroundColor DarkYellow
    }
}
