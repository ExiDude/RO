@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

title Ragnarok Core - 1-Klick-Test / Step 3 Gold Mobile
cd /d "%~dp0"
set "ROOT=%CD%"
set "LOGDIR=%ROOT%\test_logs"
set "PREFLIGHT_LOG=%LOGDIR%\preflight_latest.log"
set "SMOKE_LOG=%LOGDIR%\smoke_latest.log"
set "FORMULA_LOG=%LOGDIR%\pre_renewal_formulas_latest.log"
set "RUNTIME_LOG=%LOGDIR%\runtime_latest.log"
set "MOBILE_LOG=%LOGDIR%\mobile_portrait_latest.log"

if not exist "%LOGDIR%" mkdir "%LOGDIR%" >nul 2>&1

echo ============================================================
echo   RAGNAROK CORE - 1-KLICK-TEST / STEP 3 GOLD MOBILE
echo ============================================================
echo.

if not exist "%ROOT%\project.godot" (
    echo [FEHLER] project.godot wurde nicht gefunden.
    pause
    exit /b 10
)

echo [STATIC] Projektstruktur / JSON / Ressourcen / Datenvertraege ...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\tools\static_project_check.ps1"
if errorlevel 1 (
    echo [FEHLER] Statischer Projektcheck fehlgeschlagen.
    pause
    exit /b 37
)
echo.

if not exist "%ROOT%\assets\player_custom\idle\dir_0_0.png" (
    echo [FEHLER] Die lokale Benutzer-Spielfigur fehlt.
    echo Erwartet: assets\player_custom\idle\dir_0_0.png
    pause
    exit /b 12
)

if not exist "%ROOT%\assets\player_custom\walk\dir_6_3.png" (
    echo [FEHLER] Laufanimation der Benutzer-Spielfigur ist unvollstaendig.
    pause
    exit /b 13
)

if not exist "%ROOT%\assets\player_custom\attack\dir_6_2.png" (
    echo [FEHLER] Kampfanimation der Benutzer-Spielfigur ist unvollstaendig.
    pause
    exit /b 14
)

if not exist "%ROOT%\data\rathena\mobs\poring.json" (
    echo [FEHLER] rAthena-Monsterprofil fehlt: data\rathena\mobs\poring.json
    pause
    exit /b 15
)

if not exist "%ROOT%\data\rathena\loot\poring.json" (
    echo [FEHLER] rAthena-Drop-Tabelle fehlt: data\rathena\loot\poring.json
    pause
    exit /b 16
)

if not exist "%ROOT%\data\rathena\items\items.json" (
    echo [FEHLER] rAthena-Itemdaten fehlen: data\rathena\items\items.json
    pause
    exit /b 17
)

if not exist "%ROOT%\assets\ro_sprites\monsters\PORING\idle\dir_0\frames\frame_000.png" (
    echo [SETUP] Original-Poring-Sprites fehlen. Einmaliger lokaler Import startet ...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\tools\import_original_poring.ps1"
    if errorlevel 1 (
        echo [FEHLER] Original-Poring-Import fehlgeschlagen.
        echo Starte IMPORT_ORIGINAL_PORING.bat bei bestehender Internetverbindung erneut.
        pause
        exit /b 35
    )
)

if not exist "%ROOT%\assets\ro_sprites\monsters\PORING\dead\dir_7\frames\frame_000.png" (
    echo [FEHLER] Original-Poring-Animationssatz ist unvollstaendig.
    pause
    exit /b 36
)

if not exist "%ROOT%\systems\save\save_system.gd" (
    echo [FEHLER] Save-System fehlt: systems\save\save_system.gd
    pause
    exit /b 18
)

if not exist "%ROOT%\RESET_SAVE.bat" (
    echo [FEHLER] RESET_SAVE.bat fehlt.
    pause
    exit /b 19
)

if not exist "%ROOT%\data\maps\dev_town.json" (
    echo [FEHLER] Daten-Map fehlt: data\maps\dev_town.json
    pause
    exit /b 22
)

if not exist "%ROOT%\data\maps\south_field.json" (
    echo [FEHLER] Daten-Map fehlt: data\maps\south_field.json
    pause
    exit /b 23
)

if not exist "%ROOT%\world\maps\data_map.gd" (
    echo [FEHLER] DataMap-Runtime fehlt.
    pause
    exit /b 24
)

if not exist "%ROOT%\systems\player\player_hud.gd" (
    echo [FEHLER] Player-HUD fehlt: systems\player\player_hud.gd
    pause
    exit /b 25
)

if not exist "%ROOT%\systems\ui\ro_menu_bar.gd" (
    echo [FEHLER] RO-Menueleiste fehlt: systems\ui\ro_menu_bar.gd
    pause
    exit /b 27
)

if not exist "%ROOT%\systems\ui\ro_menu_bar.tscn" (
    echo [FEHLER] RO-Menueleiste-Szene fehlt.
    pause
    exit /b 28
)


if not exist "%ROOT%\systems\ui\ro_windows.gd" (
    echo [FEHLER] RO-Fenstersystem fehlt: systems\ui\ro_windows.gd
    pause
    exit /b 29
)

if not exist "%ROOT%\systems\ui\ro_windows.tscn" (
    echo [FEHLER] RO-Fensterszene fehlt: systems\ui\ro_windows.tscn
    pause
    exit /b 30
)


if not exist "%ROOT%\systems\equipment\equipment.gd" (
    echo [FEHLER] Equipment-System fehlt: systems\equipment\equipment.gd
    pause
    exit /b 31
)

if not exist "%ROOT%\systems\skills\skill_system.gd" (
    echo [FEHLER] Skill-System fehlt: systems\skills\skill_system.gd
    pause
    exit /b 32
)

if not exist "%ROOT%\systems\skills\skill_hotbar.tscn" (
    echo [FEHLER] Skill-Hotbar fehlt: systems\skills\skill_hotbar.tscn
    pause
    exit /b 33
)

if not exist "%ROOT%\data\rathena\skills\novice_skills.json" (
    echo [FEHLER] Novice-Skilldaten fehlen.
    pause
    exit /b 34
)

if not exist "%ROOT%\world\maps\map_ambience.gd" (
    echo [FEHLER] Map-Ambience fehlt: world\maps\map_ambience.gd
    pause
    exit /b 26
)

if not exist "%ROOT%\systems\mobile\mobile_camera.gd" (
    echo [FEHLER] MobileCamera fehlt: systems\mobile\mobile_camera.gd
    pause
    exit /b 38
)

if not exist "%ROOT%\systems\mobile\mobile_minimap.gd" (
    echo [FEHLER] Mobile-Minimap fehlt: systems\mobile\mobile_minimap.gd
    pause
    exit /b 39
)

set "GODOT="
for %%G in ("%ROOT%\Godot*_console.exe") do if not defined GODOT if exist "%%~fG" set "GODOT=%%~fG"
for %%G in ("%ROOT%\Godot*.exe") do if not defined GODOT if exist "%%~fG" set "GODOT=%%~fG"
if not defined GODOT for /f "delims=" %%G in ('where godot4.exe 2^>nul') do if not defined GODOT set "GODOT=%%G"
if not defined GODOT for /f "delims=" %%G in ('where godot.exe 2^>nul') do if not defined GODOT set "GODOT=%%G"
if not defined GODOT for %%G in ("%ProgramFiles%\Godot\Godot*_console.exe") do if exist "%%~fG" if not defined GODOT set "GODOT=%%~fG"
if not defined GODOT for %%G in ("%ProgramFiles%\Godot\Godot*.exe") do if exist "%%~fG" if not defined GODOT set "GODOT=%%~fG"
if not defined GODOT for %%G in ("%LOCALAPPDATA%\Programs\Godot\Godot*_console.exe") do if exist "%%~fG" if not defined GODOT set "GODOT=%%~fG"
if not defined GODOT for %%G in ("%LOCALAPPDATA%\Programs\Godot\Godot*.exe") do if exist "%%~fG" if not defined GODOT set "GODOT=%%~fG"
if not defined GODOT for /f "delims=" %%G in ('dir /b /s "%USERPROFILE%\Desktop\Godot*_console.exe" 2^>nul') do if not defined GODOT set "GODOT=%%G"
if not defined GODOT for /f "delims=" %%G in ('dir /b /s "%USERPROFILE%\Downloads\Godot*_console.exe" 2^>nul') do if not defined GODOT set "GODOT=%%G"
if not defined GODOT for /f "delims=" %%G in ('dir /b /s "%USERPROFILE%\Desktop\Godot*.exe" 2^>nul') do if not defined GODOT set "GODOT=%%G"
if not defined GODOT for /f "delims=" %%G in ('dir /b /s "%USERPROFILE%\Downloads\Godot*.exe" 2^>nul') do if not defined GODOT set "GODOT=%%G"

if not defined GODOT (
    echo [STOP] Godot 4 wurde nicht automatisch gefunden.
    echo Kopiere deine Godot-4-EXE einmal in diesen Projektordner.
    pause
    exit /b 11
)

echo [OK] Godot gefunden:
echo      %GODOT%
echo.

echo [1/5] Editor-/Import-Check ...
if exist "%PREFLIGHT_LOG%" del /q "%PREFLIGHT_LOG%" >nul 2>&1
"%GODOT%" --headless --path "%ROOT%" --editor --quit --log-file "%PREFLIGHT_LOG%" >nul 2>&1
call :CHECKLOG "%PREFLIGHT_LOG%"
if errorlevel 1 goto :FAIL_PREFLIGHT
echo [PASS] Editor-/Import-Check
echo.

echo [2/5] Pre-Renewal-Formel-Selbsttest ...
if exist "%FORMULA_LOG%" del /q "%FORMULA_LOG%" >nul 2>&1
"%GODOT%" --headless --path "%ROOT%" --script "res://tests/pre_renewal_formula_selftest.gd" --log-file "%FORMULA_LOG%" >nul 2>&1
call :CHECKLOG "%FORMULA_LOG%"
if errorlevel 1 goto :FAIL_FORMULA
findstr /C:"[PRE-RE FORMULAS] PASS" "%FORMULA_LOG%" >nul 2>&1
if errorlevel 1 goto :FAIL_FORMULA
echo [PASS] Pre-Renewal-Formeln
echo.

echo [3/5] Headless-Smoke-Test ...
if exist "%SMOKE_LOG%" del /q "%SMOKE_LOG%" >nul 2>&1
"%GODOT%" --headless --path "%ROOT%" --quit-after 20 --log-file "%SMOKE_LOG%" >nul 2>&1
call :CHECKLOG "%SMOKE_LOG%"
if errorlevel 1 goto :FAIL_SMOKE
echo [PASS] Startszene laeuft ohne offensichtlichen Scriptfehler.
echo.

echo [4/5] Mobile-Portrait-Headless-Smoke-Test ...
if exist "%MOBILE_LOG%" del /q "%MOBILE_LOG%" >nul 2>&1
"%GODOT%" --headless --path "%ROOT%" --quit-after 20 --log-file "%MOBILE_LOG%" -- --mobile-demo >nul 2>&1
call :CHECKLOG "%MOBILE_LOG%"
if errorlevel 1 goto :FAIL_MOBILE
echo [PASS] Mobile-Portrait-Start ohne offensichtlichen Scriptfehler.
echo.

echo [5/5] Manueller Stats-/Combat-/Mobile-Regressionstest startet.
echo       1. Statusfenster Alt+A: STR/AGI/VIT/INT/DEX/LUK + Statuspunkte pruefen.
echo       2. Lv1 Startwerte: STR 9 / AGI 9 / VIT 1 / INT 1 / DEX 9 / LUK 1.
echo       3. Knife [4]: ATK-Anzeige 19~27; Cotton Shirt [1]: DEF 1+1.
echo       4. Lv1 HP/SP: 40/11; HIT/FLEE: 10/10; Dagger ASPD: 138.
echo       5. SOUTH FIELD: sechs Porings, 1440x1920 und vier Kollisionsblocker pruefen.
echo       6. Original Poring: Idle/Walk/Attack/Hurt/Dead in 8 Richtungen.
echo       7. Poring angreifen: Retaliation/Chase; Play Dead muss Aggro abbrechen.
echo       8. Poring HP 50 / 50; Kill gibt 2 Base EXP + 1 Job EXP.
echo       9. Bodendrop: AI 02 muss looten; getragene Beute beim Tod wieder abwerfen.
echo      10. Apple 16-22 HP / Red Herb 18-28 HP per Doppelklick pruefen.
echo      11. Knife [4] ATK +17 / Cotton Shirt [1] DEF +1 pruefen.
echo      12. F1-F9 nur Hotbar; F11 Save; F12 Load.
echo      13. Base Lv.1 braucht 9 EXP; Novice Job Lv.1 braucht 10 Job EXP.
echo      14. Skills, Equipment, Inventar, Mapwechsel, Target-HUD und Save regressiv pruefen.
echo      15. Keine Sprite-Unschaerfe: Nearest-Filter, Schatten und Silhouette pruefen.
echo      16. START_MOBILE_DEMO.bat: echte Portrait-Darstellung 720x1280 pruefen.
echo      17. Kamera folgt weich; Spieler bleibt an Kartenraendern korrekt sichtbar.
echo      18. Safe-Area: HUD/Minimap/Hotbar duerfen Notch und Systemleisten nicht schneiden.
echo      19. Touch: Boden = Laufen; Gegner = Auto-Approach/Auto-Attack; keine Doppelausloesung.
echo      20. Mobile-Minimap, Ziel/Abbrechen/Angriff und Horror-ill-South-Field pruefen.
echo       Danach Spielfenster schliessen.
echo.
echo.
echo.
if exist "%RUNTIME_LOG%" del /q "%RUNTIME_LOG%" >nul 2>&1
"%GODOT%" --path "%ROOT%" --log-file "%RUNTIME_LOG%" --verbose
set "RUN_RC=%ERRORLEVEL%"
call :CHECKLOG "%RUNTIME_LOG%"
set "LOG_RC=%ERRORLEVEL%"

set "RUN_BAD=0"
if not "%RUN_RC%"=="0" set "RUN_BAD=1"
if not "%LOG_RC%"=="0" set "RUN_BAD=1"

echo.
echo ============================================================
if "%RUN_BAD%"=="0" (
    echo   TESTERGEBNIS: PASS
    echo   Keine offensichtlichen Godot-/Scriptfehler gefunden.
) else (
    echo   TESTERGEBNIS: FEHLER GEFUNDEN
    start "" notepad.exe "%RUNTIME_LOG%"
)
echo ============================================================
echo Logs: %LOGDIR%
echo.
pause
exit /b %RUN_BAD%

:CHECKLOG
set "CHECKFILE=%~1"
if not exist "%CHECKFILE%" exit /b 1
findstr /i /c:"SCRIPT ERROR" /c:"Parse Error" /c:"Parser Error" /c:"Invalid call" /c:"Failed loading" /c:"Cannot load" /c:"ERROR:" "%CHECKFILE%" >nul 2>&1
if not errorlevel 1 exit /b 1
exit /b 0

:FAIL_PREFLIGHT
echo [FEHLER] Editor-/Import-Check fehlgeschlagen.
start "" notepad.exe "%PREFLIGHT_LOG%"
pause
exit /b 20

:FAIL_FORMULA
echo [FEHLER] Pre-Renewal-Formel-Selbsttest fehlgeschlagen.
start "" notepad.exe "%FORMULA_LOG%"
pause
exit /b 22

:FAIL_MOBILE
echo [FEHLER] Mobile-Portrait-Smoke-Test fehlgeschlagen.
start "" notepad.exe "%MOBILE_LOG%"
pause
exit /b 23

:FAIL_SMOKE
echo [FEHLER] Headless-Smoke-Test fehlgeschlagen.
start "" notepad.exe "%SMOKE_LOG%"
pause
exit /b 21