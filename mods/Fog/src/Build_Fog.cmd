@echo off
title Build and Deploy - Fog Mod
echo ========================================================
echo   Compilando e Implantando: FOG MOD
echo ========================================================

:: 1. Localiza a raiz do repositorio e executa a compilacao
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
    "$dir = '%~dp0'.TrimEnd('\');" ^
    "$root = $dir;" ^
    "while ($root -and !(Test-Path (Join-Path $root 'tools\build.ps1'))) { $parent = Split-Path -Parent $root; if ($parent -eq $root) { break }; $root = $parent };" ^
    "if (!(Test-Path (Join-Path $root 'tools\build.ps1'))) { Write-Error 'tools\build.ps1 nao encontrado!'; exit 1 };" ^
    "$buildTool = Join-Path $root 'tools\build.ps1';" ^
    "& $buildTool -ModName 'Fog' -Deploy;" ^
    "$packver = Join-Path $env:LOCALAPPDATA 'Tinkerlands\packver';" ^
    "if (Test-Path $packver) { $val = [int](Get-Content $packver -Raw).Trim(); Set-Content $packver ($val + 1); Write-Host ('Packver incrementado para: ' + ($val + 1)) -ForegroundColor Yellow };"

:: 2. Limpeza profunda da pasta temp de cache do jogo
if exist "%LOCALAPPDATA%\Tinkerlands\temp" (
    rd /s /q "%LOCALAPPDATA%\Tinkerlands\temp"
    mkdir "%LOCALAPPDATA%\Tinkerlands\temp"
    echo [OK] Pasta temp 100%% eliminada e recriada vazia!
)

echo.
echo ========================================================
echo FOG MOD compilado, implantado e cache limpo!
echo ========================================================
echo.
pause
