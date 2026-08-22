@echo off
title Build and Deploy - All Mods
echo ========================================================
echo   Compilando e Implantando TODOS os Mods
echo ========================================================

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
    "$rootDir = Split-Path -Parent '%~dp0'.TrimEnd('\');" ^
    "$buildTool = Join-Path $rootDir 'tools\build.ps1';" ^
    "if (!(Test-Path $buildTool)) { Write-Error 'tools\build.ps1 nao encontrado!'; exit 1 };" ^
    "Write-Host '--- 1/4: Compilando BO ---' -ForegroundColor Cyan;" ^
    "& $buildTool -ModName 'BO' -Deploy;" ^
    "Write-Host '--- 2/4: Compilando Radar ---' -ForegroundColor Cyan;" ^
    "& $buildTool -ModName 'Radar' -Deploy;" ^
    "Write-Host '--- 3/4: Compilando RealClock ---' -ForegroundColor Cyan;" ^
    "& $buildTool -ModName 'RealClock' -Deploy;" ^
    "Write-Host '--- 4/4: Compilando Fog ---' -ForegroundColor Cyan;" ^
    "& $buildTool -ModName 'Fog' -Deploy;" ^
    "$packver = Join-Path $env:LOCALAPPDATA 'Tinkerlands\packver';" ^
    "if (Test-Path $packver) { $val = [int](Get-Content $packver -Raw).Trim(); Set-Content $packver ($val + 1); Write-Host ('Packver incrementado para: ' + ($val + 1)) -ForegroundColor Yellow };"

if exist "%LOCALAPPDATA%\Tinkerlands\temp" (
    rd /s /q "%LOCALAPPDATA%\Tinkerlands\temp"
    mkdir "%LOCALAPPDATA%\Tinkerlands\temp"
    echo [OK] Pasta temp 100%% eliminada e recriada vazia!
)

echo.
echo ========================================================
echo TODOS os Mods compilados, implantados e cache limpo!
echo ========================================================
echo.
pause
