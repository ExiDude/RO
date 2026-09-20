@echo off
setlocal EnableExtensions
chcp 65001 >nul
title Ragnarok Core - Step 3 Gold Installer
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0APPLY_STEP3.ps1"
set "RC=%ERRORLEVEL%"
echo.
if "%RC%"=="0" (
  echo [OK] Step 3 Gold wurde gebaut.
) else (
  echo [FEHLER] Step 3 Gold konnte nicht fertiggestellt werden. Code %RC%.
)
pause
exit /b %RC%
