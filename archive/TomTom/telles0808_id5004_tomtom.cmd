<# :
@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
title Build and Deploy - telles0808_id5004_tomtom
echo ========================================================
echo   Compilando e Implantando: telles0808_id5004_tomtom
echo ========================================================

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$scriptDir = $env:SCRIPT_DIR.TrimEnd('\'); Invoke-Expression ([System.IO.File]::ReadAllText('%~f0'))"

if exist "%LOCALAPPDATA%\Tinkerlands\temp" (
    rd /s /q "%LOCALAPPDATA%\Tinkerlands\temp"
    mkdir "%LOCALAPPDATA%\Tinkerlands\temp"
    echo [OK] Pasta temp 100%% eliminada e recriada vazia!
)

echo.
echo ========================================================
echo telles0808_id5004_tomtom compilado, implantado e cache limpo!
echo ========================================================
echo.
pause
goto :EOF
#>

$ModName = 'TomTom'
$ModId = 5004
$ModKey = 'telles0808_id5004_tomtom'
$ModFileName = 'telles0808_id5004_tomtom.mod'
$gmlFileName = 'telles0808_id5004_tomtom.gml'
$rootDir = Split-Path -Parent $scriptDir
$srcFile = Join-Path $scriptDir $gmlFileName
$targetDir = Join-Path $rootDir '04 - TomTom'

if (!(Test-Path $srcFile)) {
    Write-Error ("Arquivo fonte nao encontrado: " + $srcFile)
    exit 1
}

Write-Host ("Compilando " + $ModName + " como " + $ModFileName + " (ID: " + $ModId + ")...") -ForegroundColor Cyan

$gml = Get-Content $srcFile -Raw -Encoding UTF8
$encodedCode = $gml -replace '"', '%$%' -replace ',', '#$#' -replace "`r`n", '\n' -replace "`n", '\n' -replace "`r", '\n'

$exportDir = Join-Path $env:TEMP ("TinkerlandsBuild_" + $ModName)
$exportScriptsDir = Join-Path $exportDir 'scripts'

if (Test-Path $exportDir) { Remove-Item $exportDir -Recurse -Force }
New-Item -ItemType Directory -Path $exportScriptsDir -Force | Out-Null

$jsonExport = @"
{
	"id" : $ModId,
	"key" : "$ModKey",
	"event" : "E_CS_EVENT.None",
	"code" : "$encodedCode"
}
"@
$jsonExport | Set-Content (Join-Path $exportScriptsDir ($ModKey + ".json")) -Encoding UTF8

$infoJson = @"
{
	"name" : "$ModKey",
	"author" : "Telles0808",
	"version" : "1.0.0",
	"description" : "$ModName mod for Tinkerlands"
}
"@
$infoJson | Set-Content (Join-Path $exportDir "info.json") -Encoding UTF8

$tempZip = Join-Path $env:TEMP ($ModName + ".zip")
if (Test-Path $tempZip) { Remove-Item $tempZip -Force }

Push-Location $exportDir
Compress-Archive -Path "*" -DestinationPath $tempZip -Force
Pop-Location

if (!(Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
Get-ChildItem -Path $targetDir -Filter "*.mod" | Where-Object { $_.Name -ne $ModFileName } | Remove-Item -Force -ErrorAction SilentlyContinue

Copy-Item $tempZip (Join-Path $targetDir $ModFileName) -Force
Remove-Item $tempZip -Force
Remove-Item $exportDir -Recurse -Force

$candidatePaths = @(
    "C:\Games\Steam\steamapps\common\Tinkerlands\mods",
    "C:\Program Files (x86)\Steam\steamapps\common\Tinkerlands\mods",
    "C:\Program Files\Steam\steamapps\common\Tinkerlands\mods",
    "D:\SteamLibrary\steamapps\common\Tinkerlands\mods",
    "E:\SteamLibrary\steamapps\common\Tinkerlands\mods"
)

$steamMods = $null
foreach ($p in $candidatePaths) {
    if (Test-Path $p) { $steamMods = $p; break }
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
    # Remove old legacy .mod files for Radar and MapRadar
    Get-ChildItem -Path $steamMods -Filter "*radar*.mod"    | Where-Object { $_.Name -ne $ModFileName } | Remove-Item -Force -ErrorAction SilentlyContinue
    Get-ChildItem -Path $steamMods -Filter "*mapradar*.mod" | Where-Object { $_.Name -ne $ModFileName } | Remove-Item -Force -ErrorAction SilentlyContinue
    Get-ChildItem -Path $steamMods -Filter "Radar.mod"      | Remove-Item -Force -ErrorAction SilentlyContinue
    Get-ChildItem -Path $steamMods -Filter "MapRadar.mod"   | Remove-Item -Force -ErrorAction SilentlyContinue

    Copy-Item (Join-Path $targetDir $ModFileName) (Join-Path $steamMods $ModFileName) -Force
    Write-Host ("Implantado com sucesso em: " + (Join-Path $steamMods $ModFileName)) -ForegroundColor Green
}

$packver = Join-Path $env:LOCALAPPDATA 'Tinkerlands\packver'
if (Test-Path $packver) {
    $val = [int](Get-Content $packver -Raw).Trim()
    Set-Content $packver ($val + 1)
    Write-Host ("Packver incrementado para: " + ($val + 1)) -ForegroundColor Yellow
}
