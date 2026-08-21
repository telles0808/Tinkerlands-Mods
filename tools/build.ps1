param(
    [string]$ModName = "Radar",
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

Write-Host "Compiling $ModName..." -ForegroundColor Cyan

$gml = Get-Content $srcFile -Raw -Encoding UTF8
$encodedCode = $gml -replace '"', '%$%' -replace ',', '#$#' -replace "`r`n", '\n' -replace "`n", '\n' -replace "`r", '\n'

$exportDir = "$env:TEMP\TinkerlandsBuild_$ModName"
$exportScriptsDir = "$exportDir\scripts"

if (Test-Path $exportDir) { Remove-Item $exportDir -Recurse -Force }
New-Item -ItemType Directory -Path $exportScriptsDir -Force | Out-Null

$jsonExport = @"
{
	"id" : 5001,
	"key" : "$ModName@$($ModName.ToLower())",
	"event" : "E_CS_EVENT.None",
	"code" : "$encodedCode"
}
"@
$jsonExport | Set-Content "$exportScriptsDir\$ModName@$($ModName.ToLower()).json" -Encoding UTF8

$infoJson = @"
{
	"name" : "$ModName",
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

Copy-Item $tempZip "$distDir\$ModName.mod" -Force
Copy-Item $tempZip "$releasesDir\$ModName.mod" -Force
Remove-Item $tempZip
Remove-Item $exportDir -Recurse -Force

Write-Host "Successfully compiled to $distDir\$ModName.mod and $releasesDir\$ModName.mod" -ForegroundColor Green

if ($Deploy) {
    # 1. Check known Steam paths
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

    # 2. Check Steam registry if still not found
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
        Copy-Item "$distDir\$ModName.mod" "$steamMods\$($ModName.ToLower()).mod" -Force
        Write-Host "Deployed to $steamMods\$($ModName.ToLower()).mod" -ForegroundColor Yellow
    } else {
        Write-Host "Steam mods directory not found automatically. Please check candidate paths." -ForegroundColor DarkYellow
    }
}
