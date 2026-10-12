@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul 2>&1
title Meshal Fix Toolkit

rem ------------------------------------------------------------------
rem  COLORS (ANSI escape codes, Windows 10/11 console)
rem ------------------------------------------------------------------
set "ESC="
for /F "delims=#" %%E in ('"prompt #$E# & for %%E in (1) do rem"') do set "ESC=%%E"
set "gold=%ESC%[38;5;220m"
set "cC=%gold%"
set "cG=%ESC%[92m"
set "cE=%ESC%[91m"
set "cY=%ESC%[93m"
set "cW=%ESC%[97m"
set "cD=%ESC%[90m"
set "cX=%ESC%[0m"

rem ------------------------------------------------------------------
rem  1. BASIC SETTINGS
rem ------------------------------------------------------------------
set "VER=1.0"
set "SCRIPT=%~f0"
set "SCRIPT_DIR=%~dp0"

rem ------------------------------------------------------------------
rem  2. ADMINISTRATOR CHECK - relaunch elevated (UAC) if needed
rem ------------------------------------------------------------------
fltmc >nul 2>&1
if not "%errorlevel%"=="0" (
    echo.
    echo   Administrator rights are required. Asking Windows for permission - UAC...
    powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "try { Start-Process -FilePath '%SCRIPT%' -Verb RunAs -ErrorAction Stop; exit 0 } catch { exit 1 }" <nul >nul 2>&1
    if errorlevel 1 (
        echo.
        echo   Elevation was cancelled or failed.
        echo   Right-click FixToolkit.bat and choose Run as administrator.
        pause
    )
    exit /b
)
cd /d "%SCRIPT_DIR%" >nul 2>&1

rem ------------------------------------------------------------------
rem  3. TOOLS FOLDER, DOWNLOAD LINKS AND TEMP FILES
rem  (Percent signs in links are doubled on purpose: %%20 becomes %20)
rem ------------------------------------------------------------------
set "FT_OUT=%TEMP%\FixToolkit_ps_out.txt"
set "TOOLS_DIR=%SCRIPT_DIR%Tools"
set "TRON_URL=https://bmrf.org/repos/tron/Tron%%20v12.0.8%%20(2025-01-09).exe"
set "TRON_SUMS_URL=https://bmrf.org/repos/tron/sha256sums.txt"
set "DDU_URL=https://download.wagnardsoft.com/DDU/DDU%%20v18.1.6.1_setup.exe"
set "DDU_PAGE=https://www.wagnardsoft.com/display-driver-uninstaller-ddu"
set "NVCI_URL=https://www.techpowerup.com/download/techpowerup-nvcleanstall/"
set "NVCI_ALT_URL=https://sourceforge.net/projects/nvcleanstall/files/NVCleanstall_1.19.0.exe/download"
rem  DDU tutorial images (Gaming Fixes, option 8) - raw links from the GitHub repository (Tutorial folder)
set "DDU_GUIDE_BASE=https://raw.githubusercontent.com/iMeshall/MeshalFix/main/Tutorial/DDU"
set "DDU_GUIDE_AR_URL=%DDU_GUIDE_BASE%/Arabic.png"
set "DDU_GUIDE_EN_URL=%DDU_GUIDE_BASE%/Englisgh.png"
rem  Official driver pages for AMD and Intel cards (Gaming Fixes, option 8, step 2)
rem  NVCleanstall tutorial images (Gaming Fixes, option 8, step 2). Image 1 has two languages, images 2 and 3 are shared
set "NV_GUIDE_BASE=https://raw.githubusercontent.com/iMeshall/MeshalFix/main/Tutorial/Nvcleanstall"
set "NV_GUIDE_AR_URL=%NV_GUIDE_BASE%/Arabic.png"
set "NV_GUIDE_EN_URL=%NV_GUIDE_BASE%/English.png"
set "NV_GUIDE_2_URL=%NV_GUIDE_BASE%/2.png"
set "NV_GUIDE_3_URL=%NV_GUIDE_BASE%/3.png"
set "AMD_DRV_URL=https://www.amd.com/en/support/download/drivers.html"
set "INTEL_DRV_URL=https://www.intel.com/content/www/us/en/support/detect.html"

rem ------------------------------------------------------------------
rem  4. DESKTOP PATH, DATE, WINDOWS VERSION, LOG FILE
rem  (InvariantCulture is used so Hijri / Arabic calendars never break dates)
rem ------------------------------------------------------------------
set "DESKTOP=%USERPROFILE%\Desktop"
set "TODAY="
set "WINVER=Windows"
set "FT_PS=$o=Get-CimInstance Win32_OperatingSystem; [Environment]::GetFolderPath([Environment+SpecialFolder]::Desktop); (Get-Date).ToString('yyyy-MM-dd', [cultureinfo]::InvariantCulture); $o.Caption + ' build ' + $o.BuildNumber"
call :psx
set "FT_N=0"
for /f "usebackq delims=" %%L in ("%FT_OUT%") do (
    set /a FT_N+=1
    if !FT_N! EQU 1 set "DESKTOP=%%L"
    if !FT_N! EQU 2 set "TODAY=%%L"
    if !FT_N! EQU 3 set "WINVER=%%L"
)
if not defined TODAY set "TODAY=today"
set "LOGDIR=%DESKTOP%\MeshalFix_Logs"
if not exist "%LOGDIR%" mkdir "%LOGDIR%" >nul 2>&1
set "LOGFILE=%LOGDIR%\log_%TODAY%.txt"
set "RP_DONE="
set "RP_OK=0"
set "ALLMODE="
echo(
call :banner
echo(                         %cC%Meshal FIX TOOLKIT%cX%
echo(        %cW%Repair and troubleshooting tools for Windows 10 and 11.%cX%
echo(
echo(        ● %cC%GitHub:%cX% https://github.com/iMeshall
echo(        ● %cC%Discord:%cX% lqgm
echo(
set "INTRO_CONTINUE="
set /p "INTRO_CONTINUE=%cD%  Press Enter to continue...%cX%"
echo(
call :log "==== Toolkit started - version %VER% - %WINVER% ===="
cls
goto :MAIN_MENU

:MAIN_MENU
call :banner
echo    %cC%[%cW%1%cC%]%cX% %cC%●%cX% Cleaning Tools           %cD%- Remove junk files and caches to free disk space%cX%
echo    %cC%[%cW%2%cC%]%cX% %cC%●%cX% System Repair            %cD%- Fix Windows files, updates and common problems%cX%
echo    %cC%[%cW%3%cC%]%cX% %cC%●%cX% Tron Script              %cD%- Automated deep clean, virus scan and repair (long run)%cX%
echo    %cC%[%cW%4%cC%]%cX% %cC%●%cX% Gaming Fixes             %cD%- Repairs for crashes, stutter and launcher problems%cX%
echo    %cC%[%cW%5%cC%]%cX% %cC%●%cX% Network Fixes            %cD%- Fix internet, DNS and connection problems%cX%
echo    %cC%[%cW%6%cC%]%cX% %cC%●%cX% Tools                    %cD%- Open useful Windows and third-party tools%cX%
echo    %cC%[%cW%7%cC%]%cX% %cC%●%cX% Restore Default Settings %cD%- Put settings back to Windows defaults (preview first)%cX%
echo    %cC%[%cW%8%cC%]%cX% %cC%●%cX% System Information       %cD%- Show your PC hardware and Windows details%cX%
echo    %cC%[%cW%9%cC%]%cX% %cC%●%cX% System Reports           %cD%- Diagnostic, crash and error reports%cX%
echo    %cC%[%cW%C%cC%]%cX% %cC%●%cX% Create Restore Point     %cD%- Save a Windows restore point before making changes%cX%
echo    %cC%[%cW%0%cC%]%cX% %cC%●%cX% Exit
echo.
echo   %cD%Logs are saved to: %LOGDIR%%cX%
echo.
set "M="
set /p "M=  %cC%●%cX% Select an option: "

if "%M%"=="1" goto :CLEAN_ENTRY
if "%M%"=="2" goto :REPAIR_ENTRY
if "%M%"=="3" goto :TRON_ENTRY
if "%M%"=="4" goto :GAME_ENTRY
if "%M%"=="5" goto :NET_MENU
if "%M%"=="6" goto :TOOLS_MENU
if "%M%"=="7" goto :RESTORE_MENU
if "%M%"=="8" goto :SYSINFO
if "%M%"=="9" goto :Diagnostics
if "%M%"=="C" goto :RESTORE_POINT
if "%M%"=="0" goto :EXIT_TOOL

goto :MAIN_MENU

:EXIT_TOOL
call :log "==== Toolkit closed ===="
if defined SR_DIR if exist "%SR_DIR%\sysreports_engine.ps1" rd /s /q "%SR_DIR%" >nul 2>&1
echo.
echo   Goodbye.
timeout /t 2 /nobreak >nul
endlocal
exit /b 0


rem ==================================================================
rem  1) CLEANING TOOLS
rem ==================================================================
:CLEAN_ENTRY
set "RAD_DEEP=n/a"
set "RAD_THUMB=n/a"
set "RAD_ORPH=n/a"
set "RAD_BIN=n/a"
set "RAD_TOTAL=n/a"
call :radar_scan FULL

:CLEAN_MENU
call :header "1) CLEANING TOOLS"
echo   %cC%Space Reclaim Radar%cX% %cD%- estimated space each option can free%cX%
echo.
call :radar_row 1 "Deep clean" DEEP "Temp, caches, Disk Cleanup, drive optimize, RAM cache"
call :radar_row 2 "Thumbnail and icon cache" THUMB "Fixes wrong icons and missing picture previews"
call :radar_row 3 "Orphaned File Scanner" ORPH "Leftovers of removed programs - you review them"
call :radar_row 4 "Recycle Bin" BIN "Permanently delete everything in the Recycle Bin"
echo    %cC%[%cW%0%cC%]%cX% %cC%●%cX% Back to main menu
echo.
echo   %cD%Estimated total: %cG%!RAD_TOTAL!%cD%  (Disk Cleanup and Windows.old may free more)%cX%
echo.
set "M="
set /p "M=  Select an option: "
set "ACT="
if "%M%"=="1" set "ACT=clean_deep"
if "%M%"=="2" set "ACT=rebuild_icons"
if "%M%"=="4" set "ACT=clean_recycle"
if "%M%"=="0" goto :MAIN_MENU
if "%M%"=="3" (
    call :clean_orphans
    call :radar_scan FAST
    goto :CLEAN_MENU
)
if defined ACT (
    call :run_clean %ACT%
    call :radar_scan FAST
)
goto :CLEAN_MENU

rem --- One line of the cleaning menu with its radar size ---
rem --- %~1 = key, %~2 = name, %~3 = radar value (DEEP, THUMB, ORPH, BIN), %~4 = description ---
:radar_row
set "RN=%~2                                "
set "RS=         !RAD_%~3!"
echo    %cC%[%cW%%~1%cC%]%cX% %cC%●%cX% !RN:~0,26!%cG%!RS:~-9!%cX%   %cD%- %~4%cX%
exit /b

rem --- Space Reclaim Radar: estimates how much space each cleaning option can free. Nothing is deleted. ---
rem --- %~1 = FULL (also scans for orphaned folders) or FAST (reuses the last orphan result) ---
:radar_scan
call :header "1) CLEANING TOOLS"
if /i "%~1"=="FULL" (
    call :info "Space Reclaim Radar is scanning your PC to estimate how much space can be freed. This can take a minute..."
) else (
    call :info "Updating the Space Reclaim Radar..."
)
call :cl_extract
if not exist "%FT_CLPS%" exit /b
set "FT_CLMODE=RADAR"
set "FT_RADAR=%~1"
set "FT_SELF=%SCRIPT%"
set "FT_ORPHFILE=%TEMP%\FixToolkit_orphans.txt"
if /i "%~1"=="FULL" del /f /q "%FT_ORPHFILE%" >nul 2>&1
type nul > "%FT_OUT%"
start "" /wait /min cmd /c powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%FT_CLPS%" ^> "%FT_OUT%" 2^>^&1
for /f "usebackq tokens=1,* delims==" %%A in (`findstr /b /c:"DEEP=" /c:"THUMB=" /c:"ORPH=" /c:"BIN=" /c:"TOTAL=" "%FT_OUT%"`) do set "RAD_%%A=%%B"
call :log "Radar: deep !RAD_DEEP!, icons !RAD_THUMB!, orphans !RAD_ORPH!, bin !RAD_BIN!"
exit /b

rem --- [3] Orphaned File Scanner: opens in its own window because it asks questions ---
:clean_orphans
call :header "ORPHANED FILE SCANNER"
call :info "Looks for folders that probably belong to programs that are no longer installed."
call :info "You review the list. Nothing is removed unless you pick it and type DELETE. Removed folders go to the Recycle Bin."
call :cl_extract
if not exist "%FT_CLPS%" (
    call :err "Could not prepare the scanner engine."
    call :pause
    exit /b
)
set "FT_CLMODE=ORPHANS"
set "FT_RADAR="
set "FT_SELF=%SCRIPT%"
set "FT_ORPHFILE=%TEMP%\FixToolkit_orphans.txt"
set "FT_LOGDIR=%LOGDIR%"
set "FT_LOGFILE=%LOGFILE%"
call :log "Orphaned File Scanner opened"
start "Orphaned File Scanner" /wait powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%FT_CLPS%"
call :log "Orphaned File Scanner closed"
exit /b

rem --- Cuts the cleaning engine (stored at the very end of this file) into a temp .ps1 once per session ---
:cl_extract
set "FT_SELF=%SCRIPT%"
set "FT_CLPS=%TEMP%\FixToolkit_clean.ps1"
if defined CL_READY if exist "%FT_CLPS%" exit /b
del /f /q "%FT_CLPS%" >nul 2>&1
set "FT_PS=$t=[IO.File]::ReadAllText($env:FT_SELF,[Text.Encoding]::UTF8); $i=$t.LastIndexOf('#CL_'+'BEGIN'); $j=$t.LastIndexOf('#CL_'+'END'); if($i -lt 0 -or $j -le $i){exit 2}; $b=$t.Substring($i+9,$j-$i-9); [IO.File]::WriteAllText($env:FT_CLPS,$b,(New-Object Text.UTF8Encoding $true))"
call :psx
if exist "%FT_CLPS%" set "CL_READY=1"
exit /b

rem --- Runs one cleaning action and shows how much space was freed ---
:run_clean
if "%~1"=="" exit /b
call :header "CLEANING IN PROGRESS"
call :getfree
set "SP_BEFORE=%FREEMB%"
call :%~1
call :report_space
call :pause
exit /b

rem --- Reads free space of the system drive (in MB) into FREEMB ---
:getfree
set "FREEMB=0"
set "FT_PS=[math]::Round((Get-PSDrive -Name '%SystemDrive:~0,1%').Free/1MB)"
call :psx
for /f "usebackq delims=" %%F in ("%FT_OUT%") do set "FREEMB=%%F"
exit /b

rem --- Compares free space now with SP_BEFORE ---
:report_space
call :getfree
set "FREED=0"
set /a FREED=FREEMB-SP_BEFORE 2>nul
if !FREED! LSS 0 set "FREED=0"
echo.
echo   %cC%Disk space on %SystemDrive%%cX%
echo     Free before : %SP_BEFORE% MB
echo     Free now    : %FREEMB% MB
echo     Freed       : %cG%!FREED! MB%cX%  %cD%(approximate - Windows may use space in the background)%cX%
call :log "Space freed approx !FREED! MB"
exit /b

rem --- Deletes the CONTENTS of a folder (%~1) and keeps the folder itself ---
:clear_folder
if "%~1"=="" exit /b 1
if /i "%~1"=="%SystemDrive%" exit /b 1
if /i "%~1"=="%SystemRoot%" exit /b 1
if not exist "%~1\" exit /b 1
del /f /s /q "%~1\*" >nul 2>&1
for /d %%D in ("%~1\*") do rd /s /q "%%D" >nul 2>&1
call :log "Cleared folder: %~1"
exit /b 0

rem --- [1] DEEP CLEAN: every junk-file cleaning job in ONE option ---
:clean_deep
call :info "Cleans: temp files and logs, Prefetch, Windows Update cache, error reports and dumps, browser caches, app caches, Disk Cleanup, drive optimization and cached RAM."
call :info "Disk Cleanup runs with a safe preset (no window). Drives are optimized with TRIM for SSD and defrag for HDD - you are asked first if an HDD is found."
call :info "Cached RAM uses Microsoft RAMMap - downloaded once into the Tools folder (needs internet) and checked for a Microsoft signature."
call :info "Logins are NOT touched. Windows.old is offered at the end - only if it exists, and you must type DELETE."
call :ask "Start the deep clean now?"
if "%CONFIRMED%"=="0" (
    call :info "Cancelled."
    exit /b
)
set "DEEPCHK="
call :check_running chrome.exe msedge.exe firefox.exe brave.exe opera.exe vivaldi.exe browser.exe chromium.exe librewolf.exe waterfox.exe discord.exe spotify.exe slack.exe Teams.exe ms-teams.exe Telegram.exe Code.exe steam.exe steamwebhelper.exe EpicGamesLauncher.exe Battle.net.exe EADesktop.exe UbisoftConnect.exe upc.exe
if defined RUNNING_LIST (
    call :warn "Still running:!RUNNING_LIST!"
    call :warn "You must close these apps for the deep clean to work. Save your work first."
    call :confirm "Close the apps now?"
    if "!CONFIRMED!"=="0" (
        call :info "Cancelled - the apps must be closed first."
        exit /b
    )
    call :step 1 1 "Closing the apps..."
    set "KILLARGS="
    for %%P in (!RUNNING_LIST!) do set "KILLARGS=!KILLARGS! /im %%P"
    taskkill /f /t !KILLARGS! >nul 2>&1
    timeout /t 2 /nobreak >nul
    call :check_running chrome.exe msedge.exe firefox.exe brave.exe opera.exe vivaldi.exe browser.exe chromium.exe librewolf.exe waterfox.exe discord.exe spotify.exe slack.exe Teams.exe ms-teams.exe Telegram.exe Code.exe steam.exe steamwebhelper.exe EpicGamesLauncher.exe Battle.net.exe EADesktop.exe UbisoftConnect.exe upc.exe
    if defined RUNNING_LIST (
        call :warn "Could not close:!RUNNING_LIST! - locked files will be skipped."
    ) else (
        call :ok "All apps were closed."
    )
)
set "DEEPCHK=1"
call :info "=== Part 1 of 10: Temp files and logs ==="
call :clean_temp
call :info "=== Part 2 of 10: Prefetch ==="
call :clean_prefetch
call :info "=== Part 3 of 10: Windows Update cache ==="
call :clean_wu_cache
call :info "=== Part 4 of 10: Error reports and dumps ==="
call :clean_wer
call :info "=== Part 5 of 10: Browser caches ==="
call :clean_browsers
call :info "=== Part 6 of 10: App caches ==="
call :clean_apps
call :info "=== Part 7 of 10: Disk Cleanup and component cleanup ==="
set "ALLMODE=1"
call :clean_cleanmgr
set "ALLMODE="
call :info "=== Part 8 of 10: Optimize drives ==="
call :clean_optimize
call :info "=== Part 9 of 10: RAM cache ==="
call :clean_ram
call :info "=== Part 10 of 10: Windows.old ==="
call :clean_winold
set "DEEPCHK="
call :ok "Deep clean finished."
exit /b

rem --- Part of deep clean: temp files, old logs and leftovers ---
:clean_temp
call :info "Temp files newer than 24 hours are kept, so running installers and open programs are not broken."
call :step 1 4 "Deleting temp files older than 24 hours (user, Windows and other accounts)..."
set "FT_PS=$cut=(Get-Date).AddDays(-1); $paths=@($env:TEMP,(Join-Path $env:SystemRoot 'Temp')); $paths+=Get-ChildItem (Join-Path $env:SystemDrive 'Users') -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object { Join-Path $_.FullName 'AppData\Local\Temp' }; foreach ($p in ($paths | Select-Object -Unique)) { if (Test-Path -LiteralPath $p) { Get-ChildItem -LiteralPath $p -Recurse -File -Force -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt $cut } | Remove-Item -Force -ErrorAction SilentlyContinue; Get-ChildItem -LiteralPath $p -Recurse -Directory -Force -ErrorAction SilentlyContinue | Sort-Object { $_.FullName.Length } -Descending | Where-Object { -not (Get-ChildItem -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue) } | Remove-Item -Force -ErrorAction SilentlyContinue } }"
call :psx
call :log "Deleted temp files older than 24 hours"
call :step 2 4 "Deleting old Windows logs..."
del /f /q "%SystemRoot%\Logs\CBS\*.cab" >nul 2>&1
del /f /q "%SystemRoot%\Logs\CBS\CbsPersist_*.log" >nul 2>&1
del /f /q "%SystemRoot%\Debug\*.log" >nul 2>&1
del /f /q "%SystemRoot%\Logs\DISM\*.log" >nul 2>&1
del /f /s /q "%SystemRoot%\Logs\MoSetup\*.log" >nul 2>&1
del /f /s /q "%ProgramData%\Microsoft\Windows Defender\Support\*.log" >nul 2>&1
call :clear_folder "%SystemDrive%\PerfLogs"
call :log "Deleted old Windows logs"
call :step 3 4 "Deleting the legacy internet cache..."
call :clear_folder "%LocalAppData%\Microsoft\Windows\INetCache"
call :step 4 4 "Deleting service and leftover temp folders..."
call :clear_folder "%UserProfile%\AppData\LocalLow\Temp"
call :clear_folder "%LocalAppData%\Microsoft\Windows\Caches"
call :clear_folder "%SystemRoot%\System32\config\systemprofile\AppData\Local\Temp"
call :clear_folder "%SystemRoot%\ServiceProfiles\NetworkService\AppData\Local\Temp"
call :clear_folder "%SystemRoot%\ServiceProfiles\LocalService\AppData\Local\Temp"
call :clear_folder "%SystemDrive%\OneDriveTemp"
del /f /q /a "%SystemDrive%\*.chk" >nul 2>&1
for /d %%D in ("%SystemDrive%\FOUND.*") do rd /s /q "%%D" >nul 2>&1
call :ok "Temp files cleaned (files that are in use or newer than 24 hours were skipped)."
exit /b

rem --- Part of deep clean: Prefetch ---
:clean_prefetch
call :step 1 1 "Cleaning Prefetch..."
call :clear_folder "%SystemRoot%\Prefetch"
call :ok "Prefetch cleaned. Windows rebuilds it automatically."
exit /b

rem --- Part of deep clean: Windows Update + Delivery Optimization cache ---
:clean_wu_cache
call :step 1 4 "Stopping Windows Update services..."
net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1
net stop dosvc >nul 2>&1
call :step 2 4 "Deleting the update download cache..."
call :clear_folder "%SystemRoot%\SoftwareDistribution\Download"
call :step 3 4 "Deleting Delivery Optimization cache and update logs..."
call :clear_folder "%SystemRoot%\SoftwareDistribution\DeliveryOptimization"
call :clear_folder "%SystemRoot%\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Cache"
call :clear_folder "%SystemRoot%\Logs\WindowsUpdate"
call :step 4 4 "Starting the services again..."
net start bits >nul 2>&1
net start wuauserv >nul 2>&1
net start dosvc >nul 2>&1
call :ok "Windows Update download cache cleared."
exit /b

rem --- [2] Recycle Bin ---
:clean_recycle
call :ask "This permanently empties the Recycle Bin on all drives. Files inside cannot be restored afterwards."
if "%CONFIRMED%"=="0" (
    call :info "Cancelled - Recycle Bin was not touched."
    exit /b
)
call :step 1 1 "Emptying the Recycle Bin..."
set "FT_PS=Clear-RecycleBin -Force -ErrorAction SilentlyContinue"
call :psx
call :ok "Recycle Bin emptied."
exit /b

rem --- [3] Thumbnail and icon cache (also used by Common Fixes) ---
:rebuild_icons
call :ask "Explorer will restart for a moment - open folder windows will close and the screen may flash."
if "%CONFIRMED%"=="0" (
    call :info "Cancelled."
    exit /b
)
call :step 1 4 "Stopping Explorer..."
call :stop_explorer
call :step 2 4 "Deleting icon cache files..."
del /f /q /a "%LocalAppData%\IconCache.db" >nul 2>&1
del /f /q /a "%LocalAppData%\Microsoft\Windows\Explorer\iconcache_*.db" >nul 2>&1
call :step 3 4 "Deleting thumbnail cache files..."
del /f /q /a "%LocalAppData%\Microsoft\Windows\Explorer\thumbcache_*.db" >nul 2>&1
call :step 4 4 "Starting Explorer again..."
call :start_explorer
call :ok "Icon and thumbnail caches cleared. Windows rebuilds them automatically."
exit /b

rem --- Part of deep clean: error reports, crash dumps and memory dumps ---
:clean_wer
call :info "Note: crash dumps help diagnose blue screens. Delete them only if you do not need them."
call :step 1 5 "Clearing Windows Error Reporting files..."
call :clear_folder "%ProgramData%\Microsoft\Windows\WER\ReportArchive"
call :clear_folder "%ProgramData%\Microsoft\Windows\WER\ReportQueue"
call :clear_folder "%ProgramData%\Microsoft\Windows\WER\Temp"
call :clear_folder "%LocalAppData%\Microsoft\Windows\WER"
call :step 2 5 "Deleting memory dump files..."
del /f /q "%SystemRoot%\MEMORY.DMP" >nul 2>&1
call :clear_folder "%SystemRoot%\Minidump"
del /f /s /q "%SystemRoot%\LiveKernelReports\*.dmp" >nul 2>&1
call :step 3 5 "Deleting application crash dumps..."
for /d %%U in ("%SystemDrive%\Users\*") do call :clear_folder "%%~U\AppData\Local\CrashDumps"
call :step 4 5 "Deleting old diagnostic and sleep study data..."
call :clear_folder "%SystemRoot%\System32\SleepStudy"
call :clear_folder "%ProgramData%\Microsoft\Diagnosis\EventsStore"
call :clear_folder "%ProgramData%\Microsoft\Diagnosis\ETLLogs\AutoLogger"
call :clear_folder "%ProgramData%\Microsoft\Diagnosis\ETLLogs\ShutdownLogger"
call :step 5 5 "Finishing..."
call :ok "Error reports and memory dumps cleared."
exit /b

rem --- Clears the cache-type folders inside ONE Chromium profile folder (%~1).
rem --- Never touches Cookies, Login Data, Web Data, History, Local Storage or IndexedDB.
rem --- Also never touches the GPU, Dawn and Shader caches or Service Worker ScriptCache: deleting them
rem --- leaves the browser window drawn wrongly until it is restarted several times.
:chromium_profile
if not exist "%~1\" exit /b 1
call :clear_folder "%~1\Cache"
call :clear_folder "%~1\Code Cache"
call :clear_folder "%~1\Media Cache"
call :clear_folder "%~1\Application Cache"
call :clear_folder "%~1\Service Worker\CacheStorage"
exit /b 0

rem --- Clears the caches of every profile of one Chromium browser (%~1 = User Data folder, %~2 = name) ---
:chromium_cache
if not exist "%~1\" exit /b 1
echo       %cD%- %~2%cX%
call :chromium_profile "%~1"
for /d %%P in ("%~1\Default" "%~1\Profile *") do call :chromium_profile "%%~P"
call :clear_folder "%~1\Crashpad\reports"
exit /b 0

rem --- Clears the caches of every profile of one Firefox-based browser (%~1 = Profiles folder, %~2 = name) ---
:firefox_cache
if not exist "%~1\" exit /b 1
echo       %cD%- %~2%cX%
for /d %%P in ("%~1\*") do (
    call :clear_folder "%%~P\cache2"
    call :clear_folder "%%~P\OfflineCache"
)
exit /b 0

rem --- Part of deep clean: browser caches only (never passwords, cookies, history or logins) ---
:clean_browsers
call :info "Only cache folders are cleaned. You stay signed in - cookies, passwords, history and bookmarks are NOT touched."
call :step 1 4 "Checking that browsers are closed..."
call :check_running chrome.exe msedge.exe firefox.exe brave.exe opera.exe vivaldi.exe browser.exe chromium.exe librewolf.exe waterfox.exe
if defined RUNNING_LIST (
    call :warn "Still running:!RUNNING_LIST!"
    call :warn "A browser must be closed while its cache is cleaned. Otherwise its window can be drawn wrongly."
    call :confirm "Close these browsers now? Save your work first."
    if "!CONFIRMED!"=="0" (
        call :info "Browser cleaning skipped."
        exit /b
    )
    for %%B in (chrome.exe msedge.exe firefox.exe brave.exe opera.exe vivaldi.exe browser.exe chromium.exe librewolf.exe waterfox.exe) do taskkill /f /im %%B >nul 2>&1
    timeout /t 3 /nobreak >nul
    call :check_running chrome.exe msedge.exe firefox.exe brave.exe opera.exe vivaldi.exe browser.exe chromium.exe librewolf.exe waterfox.exe
    if defined RUNNING_LIST (
        call :warn "Could not close:!RUNNING_LIST! - browser cleaning skipped."
        exit /b
    )
)
call :step 2 4 "Clearing Chrome, Edge and Brave caches..."
call :chromium_cache "%LocalAppData%\Google\Chrome\User Data" "Google Chrome"
call :chromium_cache "%LocalAppData%\Microsoft\Edge\User Data" "Microsoft Edge"
call :chromium_cache "%LocalAppData%\BraveSoftware\Brave-Browser\User Data" "Brave"
call :step 3 4 "Clearing Opera, Opera GX, Vivaldi, Yandex and Chromium caches..."
call :chromium_cache "%LocalAppData%\Opera Software\Opera Stable" "Opera"
call :chromium_cache "%AppData%\Opera Software\Opera Stable" "Opera (roaming)"
call :chromium_cache "%LocalAppData%\Opera Software\Opera GX Stable" "Opera GX"
call :chromium_cache "%AppData%\Opera Software\Opera GX Stable" "Opera GX (roaming)"
call :chromium_cache "%LocalAppData%\Vivaldi\User Data" "Vivaldi"
call :chromium_cache "%LocalAppData%\Yandex\YandexBrowser\User Data" "Yandex Browser"
call :chromium_cache "%LocalAppData%\Chromium\User Data" "Chromium"
call :step 4 4 "Clearing Firefox, LibreWolf and Waterfox caches..."
call :firefox_cache "%LocalAppData%\Mozilla\Firefox\Profiles" "Mozilla Firefox"
call :firefox_cache "%LocalAppData%\librewolf\Profiles" "LibreWolf"
call :firefox_cache "%LocalAppData%\Waterfox\Profiles" "Waterfox"
call :clear_folder "%AppData%\Mozilla\Firefox\Crash Reports"
call :ok "Browser caches cleared. You stay signed in - passwords, cookies and history were NOT touched."
exit /b

rem --- Part of deep clean: app caches (never logins, chats, saved data, game files or saves) ---
:clean_apps
call :info "Only cache and log folders are cleaned. Logins, chats, downloads and game files are NOT touched."
if defined DEEPCHK goto :apps_go
call :step 1 7 "Checking that apps are closed..."
call :check_running discord.exe spotify.exe slack.exe Teams.exe ms-teams.exe Telegram.exe Code.exe steam.exe steamwebhelper.exe EpicGamesLauncher.exe Battle.net.exe EADesktop.exe UbisoftConnect.exe upc.exe
if defined RUNNING_LIST (
    call :warn "Still running:!RUNNING_LIST!"
    call :warn "Close them completely - also from the system tray - for the best result. Locked files will be skipped."
    call :ask "Continue anyway?"
    if "!CONFIRMED!"=="0" (
        call :info "Cancelled."
        exit /b
    )
)
:apps_go
call :step 2 7 "Discord (Stable, PTB, Canary)..."
for %%A in (discord discordptb discordcanary) do call :chromium_profile "%AppData%\%%A"
call :step 3 7 "Spotify (cache only - offline downloads are kept)..."
call :clear_folder "%LocalAppData%\Spotify\Data"
call :clear_folder "%LocalAppData%\Packages\SpotifyAB.SpotifyMusic_zpdnekdrzrea0\LocalCache\Spotify\Data"
call :step 4 7 "Teams, Slack and Telegram..."
call :chromium_profile "%AppData%\Microsoft\Teams"
call :clear_folder "%AppData%\Microsoft\Teams\tmp"
call :chromium_profile "%AppData%\Slack"
call :clear_folder "%AppData%\Telegram Desktop\tdata\user_data\cache"
call :clear_folder "%AppData%\Telegram Desktop\tdata\user_data\media_cache"
call :step 5 7 "Zoom, Java, Adobe, Store/Xbox caches, Visual Studio Code and OneDrive logs..."
call :clear_folder "%AppData%\Zoom\data\cache"
call :clear_folder "%AppData%\Sun\Java\Deployment\cache"
call :clear_folder "%AppData%\Adobe\Common\Media Cache Files"
call :clear_folder "%AppData%\Adobe\Common\Media Cache"
call :clear_folder "%LocalAppData%\Packages\Microsoft.WindowsStore_8wekyb3d8bbwe\LocalCache"
call :clear_folder "%LocalAppData%\Packages\Microsoft.GamingApp_8wekyb3d8bbwe\LocalCache"
call :clear_folder "%LocalAppData%\Packages\Microsoft.XboxGamingOverlay_8wekyb3d8bbwe\LocalCache"
call :chromium_profile "%AppData%\Code"
call :clear_folder "%AppData%\Code\CachedData"
call :clear_folder "%AppData%\Code\CachedExtensionVSIXs"
call :clear_folder "%AppData%\Code\logs"
call :clear_folder "%LocalAppData%\Microsoft\OneDrive\logs"
call :step 6 7 "Game launchers (Steam, Epic, Battle.net, EA, Ubisoft)..."
set "STEAMDIR="
for /f "tokens=2,*" %%A in ('reg query "HKCU\Software\Valve\Steam" /v SteamPath 2^>nul ^| find "SteamPath"') do set "STEAMDIR=%%B"
if defined STEAMDIR set "STEAMDIR=!STEAMDIR:/=\!"
call :clear_folder "%LocalAppData%\Steam\htmlcache"
if defined STEAMDIR call :clear_folder "!STEAMDIR!\appcache\httpcache"
if defined STEAMDIR call :clear_folder "!STEAMDIR!\logs"
if defined STEAMDIR call :clear_folder "!STEAMDIR!\dumps"
for /d %%D in ("%LocalAppData%\EpicGamesLauncher\Saved\webcache*") do call :clear_folder "%%~D"
call :clear_folder "%ProgramData%\Battle.net\Cache"
call :clear_folder "%ProgramData%\Blizzard Entertainment\Battle.net\Cache"
call :clear_folder "%LocalAppData%\Battle.net\Cache"
call :clear_folder "%AppData%\Battle.net\Cache"
call :clear_folder "%LocalAppData%\Electronic Arts\EA Desktop\Cache"
call :clear_folder "%LocalAppData%\Ubisoft Game Launcher\cache"
call :clear_folder "!ProgramFiles(x86)!\Ubisoft\Ubisoft Game Launcher\cache"
if defined STEAMDIR call :clear_folder "!STEAMDIR!\depotcache"
call :clear_folder "%LocalAppData%\EpicGamesLauncher\Saved\Logs"
call :clear_folder "%LocalAppData%\Riot Games\Riot Client\Logs"
call :clear_folder "%LocalAppData%\VALORANT\Saved\Logs"
call :clear_folder "%AppData%\Battle.net\Logs"
call :clear_folder "%ProgramData%\Origin\Logs"
call :clear_folder "%LocalAppData%\Ubisoft Game Launcher\logs"
call :clear_folder "%LocalAppData%\Rockstar Games\Launcher\Cache"
call :clear_folder "%LocalAppData%\GOG.com\Galaxy\logs"
call :clear_folder "%AppData%\.minecraft\logs"
call :clear_folder "%AppData%\.minecraft\crash-reports"
call :step 7 7 "Leftover GPU driver installer files..."
call :clear_folder "%SystemDrive%\NVIDIA"
call :clear_folder "%SystemDrive%\AMD"
call :clear_folder "%SystemDrive%\INTEL"
call :clear_folder "%ProgramData%\NVIDIA Corporation\Downloader"
call :ok "App caches cleared. Logins, saves and game files were NOT touched."
exit /b

rem --- Part of deep clean: Disk Cleanup with a safe sagerun preset ---
:clean_cleanmgr
set "CM_VC=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
if defined ALLMODE (
    call :info "Deep clean: the safe Disk Cleanup preset is used (no window to choose options)."
) else (
    call :info "Opens the FULL Disk Cleanup window of Windows with ALL its options."
    call :info "The safe options are already ticked. Tick more only if you understand them."
    call :warn "Careful - these delete for good: Downloads folder, Recycle Bin, Previous Windows installations, Windows ESD installation files."
)
call :ask "Disk Cleanup can take a while. Continue?"
if "%CONFIRMED%"=="0" (
    call :info "Cancelled."
    exit /b
)
call :step 1 4 "Preparing Disk Cleanup (safe options are pre-ticked)..."
for /f "delims=" %%K in ('reg query "%CM_VC%" 2^>nul') do reg delete "%%K" /v StateFlags0099 /f >nul 2>&1
for %%K in ("Temporary Files" "Temporary Setup Files" "Thumbnail Cache" "Old ChkDsk Files" "Setup Log Files" "Windows Error Reporting Files" "Windows Upgrade Log Files" "Delivery Optimization Files" "Downloaded Program Files" "Internet Cache Files" "Update Cleanup" "System error memory dump files" "System error minidump files" "Windows Defender" "Diagnostic Data Viewer Database Files" "Feedback Hub Archive log files" "Active Setup Temp Folders" "Service Pack Cleanup" "Content Indexer Cleaner") do reg query "%CM_VC%\%%~K" >nul 2>&1 && reg add "%CM_VC%\%%~K" /v StateFlags0099 /t REG_DWORD /d 2 /f >nul 2>&1
if not defined ALLMODE (
    call :step 2 4 "Choose what to clean in the window, then press OK (Cancel keeps the safe options)..."
    start "" /wait cleanmgr.exe /sageset:99
)
call :step 3 4 "Running Disk Cleanup - wait for its window to finish..."
start "" /wait cleanmgr.exe /sagerun:99
call :step 4 4 "Cleaning old Windows component versions (WinSxS) - this can take several minutes, please wait..."
set "RUN_CMD=Dism.exe /Online /Cleanup-Image /StartComponentCleanup"
call :run_long "Cleaning old Windows component versions (WinSxS)" "2 to 15 minutes" "The cleanup stops before it finishes. Nothing is damaged - you can run it again later."
call :log "DISM StartComponentCleanup finished, code !RL_RC!"
if "!RUN_CANCELLED!"=="1" (
    call :warn "Component cleanup was cancelled. Disk Cleanup itself already finished."
    exit /b 1223
)
call :ok "Disk Cleanup and component cleanup finished."
exit /b

rem --- Part of deep clean: RAM cache (standby and modified lists) with Microsoft RAMMap ---
:clean_ram
set "RAMMAP_EXE=%TOOLS_DIR%\RAMMap64.exe"
set "RAMMAP_URL=https://live.sysinternals.com/RAMMap64.exe"
if /i not "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    call :info "RAM cache cleaning needs 64-bit Windows (x64) - skipped."
    exit /b 0
)
call :info "Frees cached RAM (standby and modified lists) with Microsoft RAMMap. No program is closed."
call :step 1 3 "Checking for RAMMap in the Tools folder..."
if not exist "%TOOLS_DIR%" mkdir "%TOOLS_DIR%" >nul 2>&1
set "RAM_READY="
if exist "%RAMMAP_EXE%" (
    call :ram_verify
    if not errorlevel 1 set "RAM_READY=1"
)
if not defined RAM_READY (
    call :step 2 3 "Downloading RAMMap from Microsoft (small file, only the first time)..."
    call :download RAMMAP_URL "%RAMMAP_EXE%"
    call :check_size "%RAMMAP_EXE%" 100000
    if errorlevel 1 (
        call :warn "RAMMap could not be downloaded - RAM cleaning was skipped. Check your internet connection."
        del /f /q "%RAMMAP_EXE%" >nul 2>&1
        exit /b 0
    )
    call :ram_verify
    if errorlevel 1 (
        call :warn "The downloaded file is not signed by Microsoft - it was deleted and RAM cleaning was skipped."
        del /f /q "%RAMMAP_EXE%" >nul 2>&1
        exit /b 0
    )
)
call :step 3 3 "Cleaning cached RAM..."
call :ram_cached
set "RAM_BEFORE=%RAM_CACHED%"
reg add "HKCU\Software\Sysinternals\RamMap" /v EulaAccepted /t REG_DWORD /d 1 /f >nul 2>&1
start "" /wait "%RAMMAP_EXE%" -accepteula -Em
start "" /wait "%RAMMAP_EXE%" -accepteula -Et
call :ram_cached
echo.
echo   %cC%Cached RAM (standby + modified)%cX%
echo     Before : %RAM_BEFORE% MB
echo     Now    : %RAM_CACHED% MB
call :log "RAM cache before %RAM_BEFORE% MB, now %RAM_CACHED% MB"
call :ok "Cached RAM cleaned. Windows refills it as you use programs - this is normal."
exit /b 0

rem --- Checks that RAMMap64.exe is digitally signed by Microsoft (errorlevel 0 = yes) ---
:ram_verify
set "FT_PS=$s=Get-AuthenticodeSignature -LiteralPath '%RAMMAP_EXE%'; if($s.Status -eq 'Valid' -and $s.SignerCertificate.Subject -match 'Microsoft'){exit 0}else{exit 1}"
call :psx
exit /b %errorlevel%

rem --- Reads the size of cached RAM (standby + modified lists) in MB into RAM_CACHED ---
:ram_cached
set "RAM_CACHED=0"
set "FT_PS=$m=Get-CimInstance Win32_PerfRawData_PerfOS_Memory; [math]::Round(($m.StandbyCacheReserveBytes+$m.StandbyCacheNormalPriorityBytes+$m.StandbyCacheCoreBytes+$m.ModifiedPageListBytes)/1MB)"
call :psx
for /f "usebackq delims=" %%F in ("%FT_OUT%") do set "RAM_CACHED=%%F"
exit /b

rem --- Part of deep clean: Windows.old and upgrade leftovers (typed confirmation) ---
:clean_winold
if defined ALLMODE (
    call :info "Windows.old is skipped in Run ALL. Use option 1 on its own to remove it."
    exit /b
)
set "OLD_DIRS=Windows.old $Windows.~BT $Windows.~WS $GetCurrent $SysReset Windows10Upgrade"
set "OLD_FOUND="
for %%F in (%OLD_DIRS%) do if exist "%SystemDrive%\%%F\" set "OLD_FOUND=1"
if not defined OLD_FOUND (
    call :info "No Windows.old or upgrade leftovers were found - nothing to delete."
    exit /b
)
echo.
echo   %cE%STRONG WARNING%cX%
echo   Windows.old contains your PREVIOUS Windows version. Deleting it:
echo     - is PERMANENT and cannot be undone,
echo     - removes your ability to roll back to the previous Windows,
echo     - frees several GB of space.
echo   The hidden upgrade folders on the system drive are removed too.
echo   Do NOT continue if Windows is waiting for a restart to finish an update.
echo   Only continue if your current Windows works fine and you are sure.
echo.
set "TYPED="
set /p "TYPED=  Type DELETE in capital letters to confirm, or press Enter to cancel: "
if not "!TYPED!"=="DELETE" (
    call :info "Cancelled - Windows.old was kept."
    exit /b
)
call :step 1 3 "Taking ownership of the old Windows files (can take a while)..."
for %%F in (%OLD_DIRS%) do if exist "%SystemDrive%\%%F\" takeown /f "%SystemDrive%\%%F" /r /d y >nul 2>&1
call :step 2 3 "Giving Administrators access..."
for %%F in (%OLD_DIRS%) do if exist "%SystemDrive%\%%F\" icacls "%SystemDrive%\%%F" /grant *S-1-5-32-544:F /t /c /q >nul 2>&1
call :step 3 3 "Deleting the old Windows files..."
for %%F in (%OLD_DIRS%) do if exist "%SystemDrive%\%%F\" rd /s /q "%SystemDrive%\%%F" >nul 2>&1
set "OLD_LEFT="
for %%F in (%OLD_DIRS%) do if exist "%SystemDrive%\%%F\" set "OLD_LEFT=1"
if defined OLD_LEFT (
    call :warn "Some files could not be removed. Use Disk Cleanup and tick Previous Windows installations instead."
) else (
    call :ok "Windows.old and the upgrade leftovers were deleted."
)
exit /b

rem --- Part of deep clean: optimize drives. TRIM on SSD, defrag on HDD (asks first only when an HDD exists) ---
:clean_optimize
call :info "Windows chooses the right method for each drive: TRIM for SSD (fast), defrag for HDD (can take a long time)."
set "FT_PS=if(@(Get-PhysicalDisk -ErrorAction SilentlyContinue | Where-Object { $_.MediaType -eq 'HDD' }).Count -gt 0){exit 1}else{exit 0}"
call :psx
if errorlevel 1 (
    call :confirm "A hard drive - HDD - was found. Defragmenting it can take a long time and the PC may feel slower meanwhile. Optimize the drives now?"
    if "!CONFIRMED!"=="0" (
        call :info "Drive optimization skipped."
        exit /b
    )
)
call :step 1 1 "Optimizing drives - wait until it finishes..."
set "RUN_CMD=defrag.exe /C /O /U"
call :run_long "Optimizing drives" "1 to 30 minutes (longer on hard drives)" "Drive optimization stops before it finishes. It is safe - Windows will finish it later by itself."
call :log "Drive optimization finished, code !RL_RC!"
if "!RUN_CANCELLED!"=="1" (
    call :warn "Drive optimization was cancelled."
    exit /b 1223
)
call :ok "Drive optimization finished."
exit /b

rem ==================================================================
rem  2) SYSTEM REPAIR - one place for all Windows repairs
rem     Hub -> Core repair (DISM / SFC / CHKDSK / WMI)
rem         -> Windows Update fixes
rem         -> Common Windows fixes
rem ==================================================================
:REPAIR_ENTRY
call :offer_rp
:REPAIR_HUB
call :header "2) SYSTEM REPAIR"
echo   %cD%All Windows repair tools in one place.%cX%
echo.
echo    %cC%[%cW%1%cC%]%cX% %cC%●%cX% Core repair          %cD%- DISM, SFC, CHKDSK and WMI - fix damaged Windows files%cX%
echo    %cC%[%cW%2%cC%]%cX% %cC%●%cX% Windows Update fixes %cD%- Fix updates that fail, hang or will not install%cX%
echo    %cC%[%cW%3%cC%]%cX% %cC%●%cX% Common Windows fixes %cD%- Search, printer, Store apps, Start menu, Firewall...%cX%
echo    %cC%[%cW%0%cC%]%cX% %cC%●%cX% Back to main menu
echo.
set "M="
set /p "M=  Select an option: "
if "%M%"=="1" goto :REPAIR_MENU
if "%M%"=="2" goto :WU_MENU
if "%M%"=="3" goto :COMMON_MENU
if "%M%"=="0" goto :MAIN_MENU
goto :REPAIR_HUB

:REPAIR_MENU
call :header "2) SYSTEM REPAIR - CORE"
echo   %cD%These tools can take a long time. Do not close this window while they run.%cX%
echo.
echo    %cC%[%cW%1%cC%]%cX% %cC%●%cX% DISM CheckHealth     %cD%- Quick check - is the Windows image damaged?%cX%
echo    %cC%[%cW%2%cC%]%cX% %cC%●%cX% DISM ScanHealth      %cD%- Deeper scan of the Windows image (takes longer)%cX%
echo    %cC%[%cW%3%cC%]%cX% %cC%●%cX% DISM RestoreHealth   %cD%- Repairs the Windows image - needs internet%cX%
echo    %cC%[%cW%4%cC%]%cX% %cC%●%cX% SFC /scannow         %cD%- Scans and repairs protected system files%cX%
echo    %cC%[%cW%5%cC%]%cX% %cC%●%cX% FULL repair sequence %cD%- Runs options 1 to 4 in the correct order%cX%
echo    %cC%[%cW%6%cC%]%cX% %cC%●%cX% CHKDSK               %cD%- Checks a drive for errors and bad sectors%cX%
echo    %cC%[%cW%7%cC%]%cX% %cC%●%cX% WMI Repository Check %cD%- Read-only report - changes nothing%cX%
echo    %cC%[%cW%0%cC%]%cX% %cC%●%cX% Back to the repair menu
echo.
set "M="
set /p "M=  Select an option: "
set "ACT="
if "%M%"=="1" set "ACT=dism_check"
if "%M%"=="2" set "ACT=dism_scan"
if "%M%"=="3" set "ACT=dism_restore"
if "%M%"=="4" set "ACT=sfc_run"
if "%M%"=="5" set "ACT=full_repair"
if "%M%"=="6" set "ACT=chkdsk_tool"
if "%M%"=="7" set "ACT=wmi_repository_check"
if "%M%"=="0" goto :REPAIR_HUB
call :run_tool %ACT%
goto :REPAIR_MENU

rem --- DISM CheckHealth ---
:dism_check
call :step 1 2 "Running DISM CheckHealth..."
set "RUN_CMD=dism.exe /Online /Cleanup-Image /CheckHealth"
call :run_long "DISM CheckHealth" "under 1 minute" "CheckHealth stops. Nothing is changed."
call :log "DISM CheckHealth exit code !RL_RC!"
if "!RUN_CANCELLED!"=="1" (
    call :warn "DISM CheckHealth was cancelled."
    exit /b 1223
)
call :step 2 2 "Reading the health state..."
call :dism_state
exit /b

rem --- DISM ScanHealth ---
:dism_scan
call :info "ScanHealth can take 5 to 20 minutes. Do not close this window."
call :step 1 2 "Running DISM ScanHealth..."
set "RUN_CMD=dism.exe /Online /Cleanup-Image /ScanHealth"
call :run_long "DISM ScanHealth" "5 to 20 minutes" "ScanHealth stops before it finishes. It only scans, so nothing is changed."
call :log "DISM ScanHealth exit code !RL_RC!"
if "!RUN_CANCELLED!"=="1" (
    call :warn "DISM ScanHealth was cancelled."
    exit /b 1223
)
call :step 2 2 "Reading the health state..."
call :dism_state
exit /b

rem --- Translates the DISM image health state into simple words ---
rem --- (uses PowerShell so it works in ANY Windows language)       ---
:dism_state
set "FT_PS=try { $r=Repair-WindowsImage -Online -CheckHealth -ErrorAction Stop; if($r.ImageHealthState -eq 'Healthy'){exit 0} elseif($r.ImageHealthState -eq 'Repairable'){exit 2} else {exit 3} } catch { exit 9 }"
call :psx
set "HS=%errorlevel%"
call :log "DISM health state code %HS%"
if "%HS%"=="0" (
    call :ok "Windows image is HEALTHY - no corruption was found."
) else if "%HS%"=="2" (
    call :warn "Corruption was found but it CAN be repaired. Run option 3 - RestoreHealth."
) else if "%HS%"=="3" (
    call :err "The image is damaged and cannot be repaired online. Try RestoreHealth with internet, or an in-place repair install."
) else (
    call :warn "Could not read the health state. Please read the DISM messages above."
)
exit /b

rem --- DISM RestoreHealth ---
:dism_restore
call :info "RestoreHealth needs an internet connection and can take 10 to 30 minutes."
call :info "The progress may look stuck at 20 or 62 percent - this is normal, just wait."
call :step 1 1 "Running DISM RestoreHealth..."
set "RUN_CMD=dism.exe /Online /Cleanup-Image /RestoreHealth"
call :run_long "DISM RestoreHealth" "10 to 30 minutes" "RestoreHealth stops before it finishes. The repair is not completed, but Windows is not harmed. You can run it again later."
set "RC=!RL_RC!"
if "!RUN_CANCELLED!"=="1" (
    call :warn "DISM RestoreHealth was cancelled."
    exit /b 1223
)

call :log "DISM RestoreHealth exit code %RC%"
if "%RC%"=="0" (
    call :ok "DISM finished successfully. The Windows image is repaired."
) else if "%RC%"=="3010" (
    call :warn "DISM finished but a RESTART is required to complete the repair."
) else (
    call :err "DISM could not finish the repair - code %RC%. Check your internet connection and run it again."
)
exit /b

rem --- SFC /scannow ---
:sfc_run
call :info "SFC takes 10 to 30 minutes. A loading bar shows the progress. Press C in the progress window to cancel."
call :step 1 3 "Recording the start time..."
set "SFC_START="
set "FT_PS=(Get-Date).ToString('yyyy-MM-dd HH:mm:ss', [cultureinfo]::InvariantCulture)"
call :psx
for /f "usebackq delims=" %%T in ("%FT_OUT%") do set "SFC_START=%%T"
call :step 2 3 "Running SFC - System File Checker..."
set "RUN_CMD=sfc /scannow"
call :run_long "SFC - System File Checker" "10 to 30 minutes" "SFC stops before it finishes. Your files are not changed by a cancelled scan - you can run it again later."
call :log "SFC finished, exit code !RL_RC!"
if "!RUN_CANCELLED!"=="1" (
    call :warn "SFC was cancelled."
    exit /b 1223
)

call :step 3 3 "Reading the result from the CBS log..."
set "FT_PS=$s='%SFC_START%'; $l=@(Select-String -Path '%SystemRoot%\Logs\CBS\CBS.log' -Pattern '\[SR\]' -ErrorAction SilentlyContinue | ForEach-Object { $_.Line } | Where-Object { $_.Length -gt 19 -and $_.Substring(0,19) -ge $s }); if($l.Count -eq 0){exit 15}; if(@($l | Where-Object { $_ -match 'Cannot repair member file' }).Count -gt 0){exit 12}; if(@($l | Where-Object { $_ -match 'Repairing corrupted file|successfully repaired|Repairing [1-9][0-9]* components' }).Count -gt 0){exit 11}; if(@($l | Where-Object { $_ -match 'Verify complete' }).Count -gt 0){exit 10}; exit 15"
call :psx
set "SR=%errorlevel%"
call :log "SFC result code %SR%"
if "%SR%"=="10" (
    call :ok "SFC found NO problems - your system files are fine."
) else if "%SR%"=="11" (
    call :ok "SFC found damaged files and REPAIRED them. Please restart your PC."
) else if "%SR%"=="12" (
    call :err "SFC found damaged files it could NOT fix. Run option 3 - DISM RestoreHealth - then run SFC again."
) else (
    call :warn "Could not read the SFC result automatically. Read the SFC messages above. If it asked for a restart, restart and run it again."
)
exit /b

rem --- FULL repair sequence ---
:full_repair
call :confirm "This runs CheckHealth, ScanHealth, RestoreHealth and then SFC. It can take 30 to 90 minutes. Do NOT close this window or turn off the PC. Continue?"
if "%CONFIRMED%"=="0" (
    call :info "Cancelled."
    exit /b
)
call :info "=== STEP 1 of 4: DISM CheckHealth ==="
call :dism_check
if "!RUN_CANCELLED!"=="1" (
    call :warn "Full repair stopped because you cancelled."
    exit /b 1223
)
call :info "=== STEP 2 of 4: DISM ScanHealth ==="
call :dism_scan
if "!RUN_CANCELLED!"=="1" (
    call :warn "Full repair stopped because you cancelled."
    exit /b 1223
)
call :info "=== STEP 3 of 4: DISM RestoreHealth ==="
call :dism_restore
if "!RUN_CANCELLED!"=="1" (
    call :warn "Full repair stopped because you cancelled."
    exit /b 1223
)
call :info "=== STEP 4 of 4: SFC /scannow ==="
call :sfc_run
if "!RUN_CANCELLED!"=="1" (
    call :warn "Full repair stopped because you cancelled."
    exit /b 1223
)
echo.
call :ok "Full repair sequence finished. A restart is recommended."
exit /b

:wmi_repository_check
call :confirm "Checks the WMI repository only. This is read-only and does not repair or reset anything. Continue?"
if "%CONFIRMED%"=="0" (
    call :info "WMI Repository Check cancelled."
    exit /b
)
call :stamp
set "FT_SCAN_REPORT=%LOGDIR%\WMIRepository_%STAMP%.txt"
call :info "Verifying the WMI repository. Results are saved to the report..."
set "FT_PS=$r=$env:FT_SCAN_REPORT; ('WMI REPOSITORY CHECK - ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) | Tee-Object -FilePath $r; & winmgmt.exe /verifyrepository 2>&1 | Tee-Object -FilePath $r -Append; $wmi=$LASTEXITCODE; ('WMI verification exit code: ' + $wmi) | Tee-Object -FilePath $r -Append; exit 0"
set "FT_SHOW=1"
call :psx
set "SCAN_RC=%errorlevel%"
if "%SCAN_RC%"=="0" (
    call :ok "WMI Repository Check finished. Review the report: %FT_SCAN_REPORT%"
) else (
    call :err "The WMI check could not complete. PowerShell exit code: %SCAN_RC%."
)
call :log "WMI Repository Check exit code %SCAN_RC%; report: %FT_SCAN_REPORT%"
exit /b

rem --- CHKDSK ---
:chkdsk_tool
set "DRV="
set /p "DRV=  Drive letter to check [press Enter for %SystemDrive:~0,1%]: "
if not defined DRV set "DRV=%SystemDrive:~0,1%"
set "DRV=!DRV:~0,1!"
set "VALID="
for %%L in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do if /i "!DRV!"=="%%L" set "VALID=1"
if not defined VALID (
    call :err "That is not a valid drive letter."
    exit /b
)
if not exist "!DRV!:\" (
    call :err "Drive !DRV!: was not found."
    exit /b
)
echo.
echo    %cC%[%cW%1%cC%]%cX% %cC%●%cX% Read-only scan (chkdsk /scan) - safe, no restart needed
echo    %cC%[%cW%2%cC%]%cX% %cC%●%cX% Repair (chkdsk /f /r) - scheduled for the next restart if the drive is in use
echo    %cC%[%cW%0%cC%]%cX% %cC%●%cX% Cancel
set "M="
set /p "M=  Select an option: "
if "%M%"=="0" exit /b
if "%M%"=="1" (
    call :step 1 1 "Scanning drive !DRV!: (read-only)..."
    set "RUN_CMD=chkdsk !DRV!: /scan"
    call :run_long "CHKDSK scan of !DRV!:" "5 to 60 minutes" "The scan stops before it finishes. It is read-only, so nothing is changed."
    set "CR=!RL_RC!"
    if "!RUN_CANCELLED!"=="1" (
        call :warn "CHKDSK scan was cancelled."
        exit /b 1223
    )
    call :log "CHKDSK scan on !DRV! exit code !CR!"
    if "!CR!"=="0" (
        call :ok "No disk errors were found on !DRV!:."
    ) else (
        call :warn "CHKDSK reported issues - code !CR!. Run option 2 to repair the drive."
    )
    exit /b
)
if not "%M%"=="2" exit /b
call :warn "Close all programs that use drive !DRV!: first. A repair can take hours on big drives."
call :confirm "Run CHKDSK repair on !DRV!:? If the drive is in use it is scheduled for the next restart."
if "%CONFIRMED%"=="0" (
    call :info "Cancelled."
    exit /b
)
call :step 1 1 "Starting CHKDSK repair on !DRV!:..."
set "RUN_CMD=echo Y| chkdsk !DRV!: /f /r"
call :run_long "CHKDSK repair of !DRV!:" "10 minutes to several hours" "CHKDSK stops before it finishes. Stopping a repair part-way is not ideal - run it again soon to finish the repair."
call :log "CHKDSK repair finished or scheduled, code !RL_RC!"
if "!RUN_CANCELLED!"=="1" (
    call :warn "CHKDSK repair was cancelled."
    exit /b 1223
)

call :info "If CHKDSK said it will run at the next restart, restart your PC now and do not interrupt it."
exit /b


rem ==================================================================
rem  3) TRON SCRIPT (downloaded by this toolkit into Tools\tron)
rem ==================================================================
:TRON_ENTRY
call :header "3) TRON SCRIPT"
echo   %cY%WARNING:%cX% Tron is a powerful third-party tool from r/TronScript.
echo   It can take SEVERAL HOURS and may make significant changes to Windows.
echo   Tron opens in a separate window. Do not close that window or turn off the PC while it runs.
echo.
call :tron_locate
if defined TRON_BAT goto :TRON_MENU

rem --- Tron is not installed: offer to download it ---
call :warn "Tron is not installed on this PC."
echo   Windows Defender blocks Tron, so the toolkit will add a Defender exclusion
echo   for the Tools folder only: %TOOLS_DIR%
echo   Tron comes from the official mirror: bmrf.org/repos/tron
call :confirm "Do you want to download Tron now?"
if "%CONFIRMED%"=="0" goto :MAIN_MENU
call :tron_download
if errorlevel 1 (
    call :pause
    goto :MAIN_MENU
)
call :confirm "The download is finished and Tron is ready. Do you want to run it now?"
if "%CONFIRMED%"=="1" call :tron_launch
call :pause
goto :MAIN_MENU

rem --- Tron is installed: small menu ---
:TRON_MENU
call :header "3) TRON SCRIPT"
echo   %cD%Installed in: !TRON_DIR!%cX%
echo.
echo    %cC%[%cW%1%cC%]%cX% %cC%●%cX% Run Tron Script           %cD%- Deep clean, disinfect and repair in a separate window%cX%
echo    %cC%[%cW%2%cC%]%cX% %cC%●%cX% Remove Defender exclusion %cD%- Re-protect the Tools folder after Tron finishes%cX%
echo    %cC%[%cW%0%cC%]%cX% %cC%●%cX% Back to main menu
echo.
set "M="
set /p "M=  Select an option: "
if "%M%"=="1" (
    call :confirm "Run Tron Script in a separate window now? It can take several hours."
    if "!CONFIRMED!"=="1" call :tron_launch
    call :pause
    goto :TRON_MENU
)
if "%M%"=="2" (
    call :confirm "Remove the Windows Defender exclusion for the Tools folder? Do this only when Tron is NOT running."
    if "!CONFIRMED!"=="1" call :defender_exclusion_remove "%TOOLS_DIR%"
    call :pause
    goto :TRON_MENU
)
if "%M%"=="0" goto :MAIN_MENU
goto :TRON_MENU

rem --- Opens Tron in its own window so the toolkit stays available ---
:tron_launch
call :log "Launching Tron Script in a separate window: %TRON_BAT%"
start "Tron Script" /D "%TRON_DIR%" "%ComSpec%" /k call tron.bat
if errorlevel 1 (
    call :err "Could not open the Tron window."
) else (
    call :ok "Tron opened in a separate window. FixToolkit remains available here."
)
exit /b

rem --- Looks for tron.bat in Tools\tron or Tools\tron\tron ---
:tron_locate
set "TRON_BAT="
set "TRON_DIR="
if exist "%TOOLS_DIR%\tron\tron.bat" (
    set "TRON_BAT=%TOOLS_DIR%\tron\tron.bat"
    set "TRON_DIR=%TOOLS_DIR%\tron"
)
if not defined TRON_BAT if exist "%TOOLS_DIR%\tron\tron\tron.bat" (
    set "TRON_BAT=%TOOLS_DIR%\tron\tron\tron.bat"
    set "TRON_DIR=%TOOLS_DIR%\tron\tron"
)
exit /b

rem --- Downloads, verifies and extracts Tron. Returns errorlevel 1 on failure ---
:tron_download
if not exist "%TOOLS_DIR%" mkdir "%TOOLS_DIR%" >nul 2>&1
if not exist "%TOOLS_DIR%\" (
    call :err "Could not create the Tools folder. Move FixToolkit to a folder you can write to."
    exit /b 1
)
call :step 1 5 "Adding a Windows Defender exclusion for the Tools folder..."
call :defender_exclusion_add "%TOOLS_DIR%"
set "TRON_PKG=%TOOLS_DIR%\Tron_package.exe"
call :step 2 5 "Downloading Tron - a large file, please wait..."
call :download TRON_URL "%TRON_PKG%"
call :check_size "%TRON_PKG%" 1000000
if errorlevel 1 (
    call :err "The Tron download failed or is incomplete."
    del /f /q "%TRON_PKG%" >nul 2>&1
    call :info "Opening the official Tron page so you can download it by hand."
    start "" "https://www.reddit.com/r/TronScript/"
    exit /b 1
)
call :step 3 5 "Checking the SHA-256 checksum..."
call :tron_checksum
if errorlevel 1 exit /b 1
call :step 4 5 "Extracting Tron into the Tools folder..."
start "" /wait "%TRON_PKG%" -o"%TOOLS_DIR%" -y
call :tron_locate
if not defined TRON_BAT (
    call :err "Automatic extraction did not work."
    call :info "Open the file Tron_package.exe in the Tools folder yourself and extract it there, so tron.bat is inside Tools\tron."
    start "" "%TOOLS_DIR%"
    exit /b 1
)
call :step 5 5 "Finishing..."
call :ok "Tron is installed in: !TRON_DIR!"
exit /b 0

rem --- Compares the package hash with the official sha256sums.txt ---
:tron_checksum
set "TRON_SUMS=%TOOLS_DIR%\Tron_sha256sums.txt"
call :download TRON_SUMS_URL "%TRON_SUMS%"
call :check_size "%TRON_SUMS%" 50
if errorlevel 1 (
    call :info "The official checksum list could not be downloaded - the check was skipped."
    exit /b 0
)
set "FT_PS=$h=(Get-FileHash -Algorithm SHA256 -LiteralPath '%TRON_PKG%').Hash; if(Select-String -Path '%TRON_SUMS%' -Pattern $h -Quiet){exit 0}else{exit 1}"
call :psx
if errorlevel 1 (
    call :err "The checksum does NOT match the official list. The file may be damaged, changed, or an older version."
    call :confirm "Continue anyway? This is NOT recommended."
    if "!CONFIRMED!"=="0" exit /b 1
    exit /b 0
)
call :ok "The checksum matches the official list."
exit /b 0

rem --- Adds a Microsoft Defender exclusion for one folder (%~1) ---
:defender_exclusion_add
set "FT_PS=try { Add-MpPreference -ExclusionPath '%~1' -ErrorAction Stop; if((Get-MpPreference).ExclusionPath -contains '%~1'){ exit 0 } else { exit 2 } } catch { Write-Host $_.Exception.Message; exit 1 }"
set "FT_SHOW=1"
call :psx
if errorlevel 1 (
    call :warn "Could not add the Defender exclusion. Another antivirus or a policy may manage protection, so Tron files may be blocked."
) else (
    call :ok "Defender exclusion added for: %~1"
)
exit /b 0

rem --- Removes the Microsoft Defender exclusion for one folder (%~1) ---
:defender_exclusion_remove
set "FT_PS=try { Remove-MpPreference -ExclusionPath '%~1' -ErrorAction Stop; exit 0 } catch { Write-Host $_.Exception.Message; exit 1 }"
set "FT_SHOW=1"
call :psx
if errorlevel 1 (
    call :warn "Could not remove the exclusion. Open Windows Security and remove it by hand."
) else (
    call :ok "Defender exclusion removed."
)
exit /b 0


rem ==================================================================
rem  4) GAMING FIXES (repairs only - no tweaks)
rem ==================================================================
:GAME_ENTRY
call :offer_rp
:GAME_MENU
call :header "4) GAMING FIXES"
echo   %cD%Repairs only - nothing here changes performance settings.%cX%
echo.
echo    %cC%[%cW%1%cC%]%cX% %cC%●%cX% Shader cache fix              %cD%- Crashes or stutter: clear NVIDIA, AMD, Intel and DirectX caches%cX%
echo    %cC%[%cW%2%cC%]%cX% %cC%●%cX% Launcher cache fix            %cD%- Clear Steam, Epic, Battle.net, EA and Ubisoft caches%cX%
echo    %cC%[%cW%3%cC%]%cX% %cC%●%cX% Microsoft Store cache         %cD%- Run wsreset to fix Store and Game Pass problems%cX%
echo    %cC%[%cW%4%cC%]%cX% %cC%●%cX% Xbox app and Gaming Services  %cD%- Repair them and restart their services (game will not start)%cX%
echo    %cC%[%cW%5%cC%]%cX% %cC%●%cX% DirectX and Visual C++        %cD%- Check the runtime files many games need%cX%
echo    %cC%[%cW%6%cC%]%cX% %cC%●%cX% Game audio fix                %cD%- Restart Windows Audio (no sound or crackling)%cX%
echo    %cC%[%cW%7%cC%]%cX% %cC%●%cX% Font cache rebuild            %cD%- Fixes missing or garbled text%cX%
echo    %cC%[%cW%8%cC%]%cX% %cC%●%cX% Graphics driver clean install %cD%- DDU + NVCleanstall: remove the old driver, install a clean one%cX%
echo    %cC%[%cW%9%cC%]%cX% %cC%●%cX% Game Doctor                   %cD%- Enter a game folder: real launch test, proven problems only%cX%
echo    %cC%[%cW%0%cC%]%cX% %cC%●%cX% Back to main menu
echo.
set "M="
set /p "M=  Select an option: "
set "ACT="
if "%M%"=="1" set "ACT=game_shader"
if "%M%"=="2" set "ACT=game_launcher"
if "%M%"=="3" set "ACT=game_wsreset"
if "%M%"=="4" set "ACT=game_xbox"
if "%M%"=="5" set "ACT=game_runtimes"
if "%M%"=="6" set "ACT=fix_audio_tool"
if "%M%"=="7" set "ACT=fix_fontcache"
if "%M%"=="8" set "ACT=game_gpu_clean"
if "%M%"=="9" set "ACT=game_doctor"
if "%M%"=="0" goto :MAIN_MENU
call :run_tool %ACT%
goto :GAME_MENU

rem --- GPU shader caches (NVIDIA, AMD, Intel, DirectX) ---
:game_shader
call :info "Clears corrupted shader caches that cause crashes, black screens and stutter."
call :info "Games rebuild the cache on the next launch, so the first start may load slower."
call :ask "Close all games first. Clear the GPU shader caches now?"
if "%CONFIRMED%"=="0" (
    call :info "Cancelled."
    exit /b
)
call :step 1 3 "Clearing NVIDIA shader caches..."
call :clear_folder "%LocalAppData%\NVIDIA\DXCache"
call :clear_folder "%LocalAppData%\NVIDIA\GLCache"
call :clear_folder "%ProgramData%\NVIDIA Corporation\NV_Cache"
call :step 2 3 "Clearing AMD and Intel shader caches..."
call :clear_folder "%LocalAppData%\AMD\DxCache"
call :clear_folder "%LocalAppData%\AMD\GLCache"
call :clear_folder "%LocalAppData%\AMD\VkCache"
call :clear_folder "%LocalAppData%\Intel\ShaderCache"
call :step 3 3 "Clearing the DirectX shader cache..."
call :clear_folder "%LocalAppData%\D3DSCache"
call :ok "GPU shader caches cleared."
exit /b

rem --- Launcher caches (never game files, saves or logins) ---
:game_launcher
call :info "Clears cache folders of Steam, Epic, Battle.net, EA app and Ubisoft Connect."
call :info "Game files, saves and login data are NOT touched."
call :check_running steam.exe steamwebhelper.exe EpicGamesLauncher.exe Battle.net.exe EADesktop.exe UbisoftConnect.exe upc.exe
if defined RUNNING_LIST (
    call :warn "These launchers are running:!RUNNING_LIST!"
    call :warn "Close them completely - also from the system tray - for the best result."
)
call :confirm "Clear the launcher caches now? Locked files will be skipped."
if "%CONFIRMED%"=="0" (
    call :info "Cancelled."
    exit /b
)
call :step 1 5 "Steam..."
set "STEAMDIR="
for /f "tokens=2,*" %%A in ('reg query "HKCU\Software\Valve\Steam" /v SteamPath 2^>nul ^| find "SteamPath"') do set "STEAMDIR=%%B"
if defined STEAMDIR set "STEAMDIR=!STEAMDIR:/=\!"
call :clear_folder "%LocalAppData%\Steam\htmlcache"
if defined STEAMDIR call :clear_folder "!STEAMDIR!\appcache\httpcache"
call :step 2 5 "Epic Games Launcher..."
for /d %%D in ("%LocalAppData%\EpicGamesLauncher\Saved\webcache*") do call :clear_folder "%%~D"
call :step 3 5 "Battle.net..."
call :clear_folder "%ProgramData%\Battle.net\Cache"
call :clear_folder "%ProgramData%\Blizzard Entertainment\Battle.net\Cache"
call :clear_folder "%LocalAppData%\Battle.net\Cache"
call :clear_folder "%AppData%\Battle.net\Cache"
call :step 4 5 "EA app..."
call :clear_folder "%LocalAppData%\Electronic Arts\EA Desktop\Cache"
call :step 5 5 "Ubisoft Connect..."
call :clear_folder "%LocalAppData%\Ubisoft Game Launcher\cache"
call :clear_folder "%ProgramFiles(x86)%\Ubisoft\Ubisoft Game Launcher\cache"
call :ok "Launcher caches cleared. Start the launcher again - it may ask to reload."
exit /b

rem --- Microsoft Store cache ---
:game_wsreset
call :info "Resets the Microsoft Store cache. The Store window opens when it finishes - just close it."
call :ask "Run wsreset now?"
if "%CONFIRMED%"=="0" (
    call :info "Cancelled."
    exit /b
)
call :step 1 1 "Running wsreset..."
start "" /wait wsreset.exe
call :ok "Microsoft Store cache reset."
exit /b

rem --- [4] Xbox app, Gaming Services and their services (merged: repair + restart) ---
:game_xbox
call :info "Fixes games that will not start because of the Xbox app, Gaming Services or Xbox sign-in."
call :info "Step 1 re-registers the Xbox packages with Windows. Step 2 restarts the Xbox services that are running."
call :info "It does not delete anything. It can take a few minutes."
call :confirm "Repair the Xbox app and Gaming Services now?"
if "%CONFIRMED%"=="0" (
    call :info "Cancelled."
    exit /b
)
set "PKG_VERBOSE=1"
set "PKGS='Microsoft.GamingServices','Microsoft.GamingApp','Microsoft.XboxIdentityProvider','Microsoft.XboxGamingOverlay','Microsoft.XboxGameOverlay','Microsoft.Xbox.TCUI','Microsoft.XboxSpeechToTextOverlay'"
call :step 1 2 "Re-registering Xbox and Gaming Services packages..."
call :reregister_pkgs
call :step 2 2 "Restarting the Xbox and Gaming services (safe - they restart by themselves)..."
for %%S in (XblAuthManager XblGameSave XboxGipSvc XboxNetApiSvc GamingServices GamingServicesNet) do call :restart_service %%S
echo.
echo   %cC%If the game still will not start:%cX%
echo     1. Restart the PC once and try again.
echo     2. Update your graphics driver from the NVIDIA, AMD or Intel website.
echo     3. Verify the game files inside its launcher (Steam, Epic, Battle.net).
echo     4. Install missing runtimes - use option 5 of this menu.
echo     5. Clear shader and launcher caches - options 1 and 2 of this menu.
echo     6. Run Windows Update and the System Repair menu if crashes continue.
echo.
call :ok "Done. If problems continue, restart the PC and sign in to the Xbox app again."
exit /b

rem --- Re-registers the Store packages listed in PKGS (PowerShell) ---
:reregister_pkgs
set "FT_PS=$n=@(%PKGS%); $c=0; foreach($p in $n){ Get-AppxPackage -AllUsers -Name $p -ErrorAction SilentlyContinue | ForEach-Object { $m=$_.InstallLocation + '\AppXManifest.xml'; if(Test-Path -LiteralPath $m){ try { Add-AppxPackage -DisableDevelopmentMode -Register $m -ErrorAction Stop; if($env:PKG_VERBOSE -eq '1'){ Write-Host ('  Re-registered: ' + $_.Name) }; $c++ } catch { if($env:PKG_VERBOSE -eq '1'){ Write-Host ('  Skipped: ' + $_.Name) } } } } }; Write-Host ('  Packages re-registered: ' + $c)"
set "FT_SHOW=1"
call :psx
call :log "Re-registered packages: %PKGS%"
set "PKG_VERBOSE="
exit /b

rem --- DirectX and Visual C++ runtimes check ---
:game_runtimes
call :step 1 2 "Checking legacy DirectX runtime files (needed by older games)..."
set "DXDIR=%SystemRoot%\System32"
if exist "%SystemRoot%\SysWOW64\" set "DXDIR=%SystemRoot%\SysWOW64"
set "DX_MISSING="
for %%F in (d3dx9_43.dll d3dx10_43.dll d3dx11_43.dll d3dcompiler_43.dll xinput1_3.dll xaudio2_7.dll x3daudio1_7.dll) do if not exist "!DXDIR!\%%F" set "DX_MISSING=!DX_MISSING! %%F"
call :info "DirectX 12 and 11 are built into Windows 10 and 11."
if defined DX_MISSING (
    call :warn "Legacy DirectX files missing:!DX_MISSING!"
    call :info "Some older games need them. The official Microsoft installer adds them safely."
    call :confirm "Open the official Microsoft DirectX End-User Runtime page in your browser?"
    if "!CONFIRMED!"=="1" start "" "https://www.microsoft.com/en-us/download/details.aspx?id=35"
) else (
    call :ok "All legacy DirectX runtime files are present."
)
echo.
call :step 2 2 "Checking installed Visual C++ Redistributables..."
set "FT_PS=$k='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'; $d=@(Get-ItemProperty -Path $k -ErrorAction SilentlyContinue | ForEach-Object { $_.DisplayName } | Where-Object { $_ -like '*Visual C++*' }); $miss=0; foreach($y in '2005','2008','2010','2012','2013','2015|v14'){ foreach($a in 'x86','x64'){ $f=@($d | Where-Object { $_ -match ('(' + $y + ').*' + $a) }); $lbl=('VC++ ' + $y.Split('|')[0] + ' ' + $a); if($f.Count -gt 0){ Write-Host ('  [ OK ]    ' + $lbl) } else { Write-Host ('  [MISSING] ' + $lbl); $miss++ } } }; if($miss -gt 0){exit 1}else{exit 0}"
set "FT_SHOW=1"
call :psx
set "VC=%errorlevel%"
call :info "VC++ 2015 covers the modern 2015 to 2022 and newer v14 package."
if "%VC%"=="0" (
    call :ok "All common Visual C++ Redistributables are installed."
) else (
    call :warn "Some Visual C++ Redistributables are missing. Install the ones you need - x86 and x64."
    call :confirm "Open the official Microsoft Visual C++ Redistributable page in your browser?"
    if "!CONFIRMED!"=="1" start "" "https://learn.microsoft.com/cpp/windows/latest-supported-vc-redist"
)
exit /b

rem --- Restarts one service only if it is currently running ---
:restart_service
sc query "%~1" >nul 2>&1
if errorlevel 1 exit /b
sc query "%~1" | find "RUNNING" >nul
if errorlevel 1 (
    call :info "%~1 is not running - left as it is."
    exit /b
)
net stop "%~1" /y >nul 2>&1
net start "%~1" >nul 2>&1
if errorlevel 1 (
    call :warn "Could not restart %~1."
) else (
    call :ok "Restarted %~1."
)
exit /b

rem --- Audio fix wrapper (with confirmation) ---
:fix_audio_tool
call :info "Restarts Windows Audio and Audio Endpoint Builder. Sound cuts out for a few seconds."
call :ask "Restart the audio services now?"
if "%CONFIRMED%"=="0" (
    call :info "Cancelled."
    exit /b
)
call :fix_audio
exit /b

rem --- Restarts Windows Audio and Audio Endpoint Builder ---
:fix_audio
call :step 1 3 "Stopping audio services..."
net stop audiosrv /y >nul 2>&1
net stop AudioEndpointBuilder /y >nul 2>&1
call :step 2 3 "Starting audio services..."
net start AudioEndpointBuilder >nul 2>&1
net start audiosrv >nul 2>&1
call :step 3 3 "Checking the result..."
sc query audiosrv | find "RUNNING" >nul
if errorlevel 1 (
    call :err "Windows Audio did not start. Restart the PC and try again."
) else (
    call :ok "Windows Audio is running again."
)
exit /b

rem --- Rebuild the Windows font cache ---
:fix_fontcache
call :info "Fixes missing or garbled text in games and apps. A restart is recommended afterwards."
call :ask "Rebuild the font cache now?"
if "%CONFIRMED%"=="0" (
    call :info "Cancelled."
    exit /b
)
call :step 1 4 "Stopping the Font Cache services..."
net stop FontCache /y >nul 2>&1
net stop FontCache3.0.0.0 /y >nul 2>&1
call :step 2 4 "Deleting the old font cache files..."
del /f /s /q /a "%SystemRoot%\ServiceProfiles\LocalService\AppData\Local\FontCache\*FontCache*" >nul 2>&1
del /f /q /a "%SystemRoot%\System32\FNTCACHE.DAT" >nul 2>&1
call :step 3 4 "Starting the Font Cache services..."
net start FontCache >nul 2>&1
net start FontCache3.0.0.0 >nul 2>&1
call :step 4 4 "Finishing..."
call :ok "Font cache rebuilt. Restart your PC to finish."
exit /b


rem --- [9] Graphics driver clean install: DDU first, then NVCleanstall ---
:game_gpu_clean
call :info "Fixes graphics driver problems: DDU removes the old driver completely, then a clean driver is installed."
call :info "NVIDIA: NVCleanstall installs the clean driver. AMD and Intel: the official driver page of the maker opens."
call :info "DDU (Wagnard) and NVCleanstall (TechPowerUp) are third-party tools. They work with the cards named above."
echo.
echo   %cY%Before you start:%cX%
echo     - Close all games and apps. The screen may flicker while DDU works.
echo     - In DDU choose: Clean and DO NOT restart. If the PC restarts anyway, run this option again and skip step 1.
echo     - DDU works best in Safe Mode. Normal mode also works: clean, restart, then clean again.
echo     - Windows Update may install a basic driver after DDU, so go to step 2 without delay.
call :confirm "Start the graphics driver repair now?"
if "%CONFIRMED%"=="0" (
    call :info "Cancelled."
    exit /b
)
if not exist "%TOOLS_DIR%" mkdir "%TOOLS_DIR%" >nul 2>&1
call :gpu_pick_vendor
call :confirm "STEP 1 of 2 - Run DDU now? Answer N to skip this step, for example if DDU was already done."
if "%CONFIRMED%"=="1" (
    call :gpu_step_ddu
    if errorlevel 1 exit /b
)
call :confirm "STEP 2 of 2 - Install a clean !GPU_VENDOR! driver now? Answer N to skip this step."
if "%CONFIRMED%"=="1" (
    call :gpu_step_driver
    if errorlevel 1 exit /b
)
echo.
call :ok "All steps are finished. The graphics driver was cleaned and reinstalled. Restarting the PC is recommended."
exit /b

rem --- Asks which graphics card the user has (GPU_VENDOR = NVIDIA, AMD or Intel). Detects it first ---
:gpu_pick_vendor
set "GPU_VENDOR="
set "DET_NV="
set "DET_AMD="
set "DET_INTEL="
set "DET_TXT="
set "DET_COUNT=0"
set "DET_DEF="
set "FT_PS=Get-CimInstance Win32_VideoController | ForEach-Object { $n=[string]$_.Name + ' ' + [string]$_.AdapterCompatibility; if($n -match 'NVIDIA'){'NVIDIA'} elseif($n -match 'AMD|Advanced Micro Devices|Radeon'){'AMD'} elseif($n -match 'Intel'){'Intel'} } | Select-Object -Unique"
call :psx
for /f "usebackq delims=" %%G in ("%FT_OUT%") do (
    if /i "%%G"=="NVIDIA" set "DET_NV=1"
    if /i "%%G"=="AMD" set "DET_AMD=1"
    if /i "%%G"=="Intel" set "DET_INTEL=1"
)
if defined DET_NV (set "DET_TXT=!DET_TXT! NVIDIA" & set "DET_DEF=1" & set /a DET_COUNT+=1)
if defined DET_AMD (set "DET_TXT=!DET_TXT! AMD" & set "DET_DEF=2" & set /a DET_COUNT+=1)
if defined DET_INTEL (set "DET_TXT=!DET_TXT! Intel" & set "DET_DEF=3" & set /a DET_COUNT+=1)
if not "!DET_COUNT!"=="1" set "DET_DEF="
echo.
echo   %cC%Which graphics card do you have?%cX%
if defined DET_TXT call :info "Detected on this PC:!DET_TXT!"
if not defined DET_TXT call :info "The graphics card could not be detected automatically. Please choose it yourself."
echo.
echo    %cC%[%cW%1%cC%]%cX% %cC%●%cX% NVIDIA
echo    %cC%[%cW%2%cC%]%cX% %cC%●%cX% AMD
echo    %cC%[%cW%3%cC%]%cX% %cC%●%cX% Intel
echo.
:gpu_pick_ask
set "GV="
if defined DET_DEF (
    set /p "GV=  Select an option [1-3] - press Enter for !DET_DEF!: "
) else (
    set /p "GV=  Select an option [1-3]: "
)
if not defined GV set "GV=!DET_DEF!"
if "!GV!"=="1" set "GPU_VENDOR=NVIDIA"
if "!GV!"=="2" set "GPU_VENDOR=AMD"
if "!GV!"=="3" set "GPU_VENDOR=Intel"
if not defined GPU_VENDOR (
    call :info "Please enter 1, 2 or 3."
    goto :gpu_pick_ask
)
call :log "Graphics driver repair - vendor chosen: !GPU_VENDOR!"
exit /b 0

rem --- Step 2: installs the clean driver. NVIDIA = NVCleanstall, AMD and Intel = official driver page ---
:gpu_step_driver
if /i "!GPU_VENDOR!"=="NVIDIA" goto :gpu_step_nvci
set "GPU_URL=!AMD_DRV_URL!"
if /i "!GPU_VENDOR!"=="Intel" set "GPU_URL=!INTEL_DRV_URL!"
echo.
call :info "Opening the official !GPU_VENDOR! driver page in your browser."
call :info "Download and install the newest driver for your card from that page."
call :info "On a laptop, the website of the laptop maker may offer a driver that fits your model better."
call :log "Official !GPU_VENDOR! driver page opened: !GPU_URL!"
start "" "!GPU_URL!"
echo.
echo   %cD%Press any key AFTER the driver is installed...%cX%
pause >nul
call :ok "The !GPU_VENDOR! driver step is finished."
exit /b 0

rem --- Step 1: DDU (waits until the user closes it) ---
:gpu_step_ddu
call :find_ddu
if not defined DDU_EXE call :get_ddu
if not defined DDU_EXE (
    call :err "DDU is not available, so step 1 was stopped."
    exit /b 1
)
set "GUIDE_ON="
call :ddu_guide
echo.
call :info "Opening DDU. Choose !GPU_VENDOR! in the list, clean the driver, then CLOSE DDU to continue to step 2."
if defined GUIDE_ON call :info "The tutorial picture stays open next to DDU, so you can follow it. It closes by itself when you close DDU."
start "" /wait "!DDU_EXE!"
if defined GUIDE_ON call :guide_stop
call :ok "DDU was closed."
exit /b 0

rem --- Optional tutorial image for DDU (Y/N, then language 1 = Arabic or 2 = English) ---
:ddu_guide
echo.
echo   %cC%DDU tutorial image%cX%
echo   %cD%A short picture that shows what to click inside DDU.%cX%
echo.
set "GD_ASK="
set /p "GD_ASK=  Do you want to download the DDU tutorial image? [Y/N]: "
if /i "!GD_ASK!"=="N" exit /b 0
if /i not "!GD_ASK!"=="Y" (
    call :info "Please enter Y or N."
    goto :ddu_guide
)
:ddu_guide_lang
echo.
echo   Choose the language of the tutorial:
echo    %cC%[%cW%1%cC%]%cX% %cC%●%cX% Arabic
echo    %cC%[%cW%2%cC%]%cX% %cC%●%cX% English
echo.
set "GD_LANG="
set /p "GD_LANG=  Select an option [1-2]: "
set "GD_URL="
set "GD_NAME="
if "!GD_LANG!"=="1" (
    set "GD_URL=!DDU_GUIDE_AR_URL!"
    set "GD_NAME=Arabic.png"
)
if "!GD_LANG!"=="2" (
    set "GD_URL=!DDU_GUIDE_EN_URL!"
    set "GD_NAME=English.png"
)
if not defined GD_NAME (
    call :info "Please enter 1 or 2."
    goto :ddu_guide_lang
)
set "GD_DIR=%TOOLS_DIR%\DDU_Guide"
set "GD_FILE=!GD_DIR!\!GD_NAME!"
if not exist "!GD_DIR!" mkdir "!GD_DIR!" >nul 2>&1
call :check_size "!GD_FILE!" 10000
if errorlevel 1 (
    call :step 1 2 "Downloading the tutorial image..."
    set "GD_LINK=!GD_URL!"
    call :download GD_LINK "!GD_FILE!"
    call :check_size "!GD_FILE!" 10000
    if errorlevel 1 (
        del /f /q "!GD_FILE!" >nul 2>&1
        call :warn "The tutorial image could not be downloaded. Check your internet connection. Continuing without it."
        exit /b 0
    )
) else (
    call :info "The tutorial image is already on this PC."
)
call :step 2 2 "Opening the tutorial picture..."
call :log "DDU tutorial image opened: !GD_FILE!"
call :show_images_bg "!GD_FILE!" "DDU tutorial"
set "GUIDE_ON=1"
exit /b 0

rem --- Looks for the DDU program in the usual places ---
:find_ddu
set "DDU_EXE="
for /d %%D in ("%TOOLS_DIR%\DDU*" "%ProgramFiles%\Display Driver Uninstaller*" "%ProgramFiles(x86)%\Display Driver Uninstaller*") do if not defined DDU_EXE if exist "%%~D\Display Driver Uninstaller.exe" set "DDU_EXE=%%~D\Display Driver Uninstaller.exe"
exit /b

rem --- Downloads and installs DDU into Tools\DDU ---
:get_ddu
call :warn "DDU was not found on this PC."
call :confirm "Download DDU from the official Wagnard server and install it into the Tools folder now?"
if "%CONFIRMED%"=="0" exit /b 1
set "DDU_PKG=%TOOLS_DIR%\DDU_setup.exe"
call :step 1 3 "Downloading DDU..."
call :download DDU_URL "%DDU_PKG%"
call :check_size "%DDU_PKG%" 500000
if errorlevel 1 (
    del /f /q "%DDU_PKG%" >nul 2>&1
    call :warn "The download failed or was blocked by the website."
    call :info "The official DDU page opens now. Download and install DDU there, then come back."
    start "" "%DDU_PAGE%"
    echo.
    echo   Press any key AFTER you installed DDU...
    pause >nul
    call :find_ddu
    exit /b 0
)
call :step 2 3 "Installing DDU quietly into the Tools folder..."
start "" /wait "%DDU_PKG%" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /DIR="%TOOLS_DIR%\DDU"
call :find_ddu
if not defined DDU_EXE (
    call :warn "The quiet install did not work. The normal installer opens now - follow its steps."
    start "" /wait "%DDU_PKG%"
    call :find_ddu
)
call :step 3 3 "Checking the installation..."
if defined DDU_EXE (
    call :ok "DDU is ready."
) else (
    call :err "DDU could not be installed."
)
exit /b 0

rem --- Step 2: NVCleanstall (waits until the user closes it) ---
:gpu_step_nvci
call :find_nvci
if not defined NVCI_EXE call :get_nvci
if not defined NVCI_EXE (
    call :err "NVCleanstall is not available, so step 2 was stopped."
    exit /b 1
)
set "GUIDE_ON="
call :nvci_guide
echo.
call :info "Opening NVCleanstall. Pick and install your driver, then CLOSE NVCleanstall to finish."
if defined GUIDE_ON call :info "The tutorial pictures stay open next to NVCleanstall. Close one picture to see the next. They close by themselves when you close NVCleanstall."
start "" /wait "!NVCI_EXE!"
if defined GUIDE_ON call :guide_stop
call :ok "NVCleanstall was closed."
exit /b 0

rem --- Optional NVCleanstall tutorial: 3 images shown one after the other (Y/N, then language for image 1) ---
:nvci_guide
echo.
echo   %cC%NVCleanstall tutorial images%cX%
echo   %cD%3 short pictures that show what to click inside NVCleanstall.%cX%
echo   %cD%Close each picture to see the next one.%cX%
echo.
set "NG_ASK="
set /p "NG_ASK=  Do you want to download the NVCleanstall tutorial images? [Y/N]: "
if /i "!NG_ASK!"=="N" exit /b 0
if /i not "!NG_ASK!"=="Y" (
    call :info "Please enter Y or N."
    goto :nvci_guide
)
:nvci_guide_lang
echo.
echo   Choose the language of the first picture:
echo    %cC%[%cW%1%cC%]%cX% %cC%●%cX% Arabic
echo    %cC%[%cW%2%cC%]%cX% %cC%●%cX% English
echo.
set "NG_LANG="
set /p "NG_LANG=  Select an option [1-2]: "
set "NG_URL1="
set "NG_F1="
if "!NG_LANG!"=="1" (
    set "NG_URL1=NV_GUIDE_AR_URL"
    set "NG_F1=NV_1_Arabic.png"
)
if "!NG_LANG!"=="2" (
    set "NG_URL1=NV_GUIDE_EN_URL"
    set "NG_F1=NV_1_English.png"
)
if not defined NG_F1 (
    call :info "Please enter 1 or 2."
    goto :nvci_guide_lang
)
set "NG_DIR=%TOOLS_DIR%\NVCleanstall_Guide"
if not exist "!NG_DIR!" mkdir "!NG_DIR!" >nul 2>&1
call :step 1 3 "Getting picture 1 of 3..."
call :guide_fetch !NG_URL1! "!NG_DIR!\!NG_F1!"
if errorlevel 1 goto :nvci_guide_fail
call :step 2 3 "Getting picture 2 of 3..."
call :guide_fetch NV_GUIDE_2_URL "!NG_DIR!\NV_2.png"
if errorlevel 1 goto :nvci_guide_fail
call :step 3 3 "Getting picture 3 of 3..."
call :guide_fetch NV_GUIDE_3_URL "!NG_DIR!\NV_3.png"
if errorlevel 1 goto :nvci_guide_fail
call :log "NVCleanstall tutorial images ready: !NG_DIR!"
call :show_images_bg "!NG_DIR!\!NG_F1!*!NG_DIR!\NV_2.png*!NG_DIR!\NV_3.png" "NVCleanstall tutorial"
set "GUIDE_ON=1"
exit /b 0
:nvci_guide_fail
call :warn "The tutorial images could not be downloaded. Check your internet connection. Continuing without them."
exit /b 0

rem --- Downloads one tutorial image. %~1 = NAME of the variable that holds the URL, %~2 = destination file. errorlevel 1 = failed ---
:guide_fetch
call :check_size "%~2" 10000
if not errorlevel 1 exit /b 0
call :download %~1 "%~2"
call :check_size "%~2" 10000
if errorlevel 1 (
    del /f /q "%~2" >nul 2>&1
    exit /b 1
)
exit /b 0

rem --- Shows tutorial pictures in their own window at the LEFT side of the screen and does NOT wait: the program opens next to it.
rem --- %~1 = one image file, or several separated by *  (closing one picture opens the next), %~2 = window title.
rem --- The window closes by itself when :guide_stop is called (after the program is closed).
:show_images_bg
set "FT_IMGS=%~1"
set "FT_IMG_TITLE=%~2"
set "FT_STOPFLAG=%TEMP%\FixToolkit_guide_stop.flag"
del /f /q "%FT_STOPFLAG%" >nul 2>&1
set "FT_PS=try { Add-Type -AssemblyName System.Windows.Forms,System.Drawing; [System.Windows.Forms.Application]::EnableVisualStyles(); $files=@($env:FT_IMGS.Split('*')); $n=$files.Count; $i=0; foreach($file in $files){ $i++; if(Test-Path -LiteralPath $env:FT_STOPFLAG){ break }; $img=[System.Drawing.Image]::FromFile($file); $wa=[System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea; $r=[math]::Min(($wa.Width*0.45)/$img.Width,($wa.Height*0.92)/$img.Height); if($r -gt 1){$r=1}; $w=[int]($img.Width*$r); $h=[int]($img.Height*$r); $f=New-Object System.Windows.Forms.Form; $f.Text=($env:FT_IMG_TITLE + ' ' + $i + '/' + $n); $f.StartPosition='Manual'; $f.Location=New-Object System.Drawing.Point(($wa.Left+8),($wa.Top+8)); $f.ShowInTaskbar=$true; $f.ClientSize=New-Object System.Drawing.Size($w,$h); $p=New-Object System.Windows.Forms.PictureBox; $p.Dock='Fill'; $p.SizeMode='Zoom'; $p.Image=$img; $f.Controls.Add($p); $t=New-Object System.Windows.Forms.Timer; $t.Interval=700; $t.Add_Tick({ if(Test-Path -LiteralPath $env:FT_STOPFLAG){ $t.Stop(); $f.Close() } }); $t.Start(); $f.Add_Shown({ $f.Activate() }); [void]$f.ShowDialog(); $t.Dispose(); $img.Dispose() }; exit 0 } catch { exit 1 }"
start "" powershell.exe -NoLogo -NoProfile -NonInteractive -STA -WindowStyle Hidden -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create($env:FT_PS))"
timeout /t 2 /nobreak >nul
exit /b 0

rem --- Closes the tutorial picture window (called after the program was closed) ---
:guide_stop
echo stop> "%FT_STOPFLAG%"
timeout /t 1 /nobreak >nul
exit /b 0

rem --- Looks for NVCleanstall in Tools or in the Downloads folder ---
:find_nvci
set "NVCI_EXE="
for %%P in ("%TOOLS_DIR%\NVCleanstall\*NVCleanstall*.exe" "%TOOLS_DIR%\NVCleanstall*.exe" "%USERPROFILE%\Downloads\NVCleanstall*.exe") do if not defined NVCI_EXE set "NVCI_EXE=%%~fP"
exit /b

rem --- Downloads NVCleanstall automatically into Tools\NVCleanstall ---
:get_nvci
call :warn "NVCleanstall was not found on this PC."
call :confirm "Download NVCleanstall automatically into the Tools folder now?"
if "%CONFIRMED%"=="0" exit /b 1
if not exist "%TOOLS_DIR%\NVCleanstall" mkdir "%TOOLS_DIR%\NVCleanstall" >nul 2>&1
call :step 1 3 "Downloading with winget - the file hash is verified by Microsoft winget..."
where winget.exe >nul 2>&1
if not errorlevel 1 (
    winget download --id TechPowerUp.NVCleanstall -e --accept-package-agreements --accept-source-agreements -d "%TOOLS_DIR%\NVCleanstall"
)
call :find_nvci
if defined NVCI_EXE (
    call :ok "NVCleanstall is ready."
    exit /b 0
)
call :warn "winget could not download it. Trying the SourceForge mirror..."
call :step 2 3 "Downloading NVCleanstall 1.19.0 from SourceForge..."
set "NVCI_PKG=%TOOLS_DIR%\NVCleanstall\NVCleanstall_1.19.0.exe"
call :download NVCI_ALT_URL "%NVCI_PKG%"
call :check_size "%NVCI_PKG%" 2000000
if errorlevel 1 (
    del /f /q "%NVCI_PKG%" >nul 2>&1
    call :warn "The automatic download failed."
    call :info "The official TechPowerUp page and the Tools\NVCleanstall folder open now."
    echo   Download the file there, then press any key here...
    start "" "%NVCI_URL%"
    start "" "%TOOLS_DIR%\NVCleanstall"
    pause >nul
    call :find_nvci
    exit /b 0
)
call :step 3 3 "Checking the download..."
call :find_nvci
if defined NVCI_EXE (
    call :ok "NVCleanstall is ready."
) else (
    call :err "NVCleanstall could not be prepared."
)
exit /b 0


rem --- [10] Game Doctor: evidence-based diagnosis of ONE game (runs in its own window) ---
:game_doctor
call :info "Enter the game folder. Game Doctor checks the files, then really starts the game to see what happens. It reports a problem only with proof, and re-tests after any repair."
call :info "If the game starts fine it changes nothing. Every repair asks first, makes a backup, and is confirmed by a new launch test."
set "FT_SELF=%SCRIPT%"
set "FT_GDPS=%TEMP%\FixToolkit_gamedoctor.ps1"
del /f /q "%FT_GDPS%" >nul 2>&1
set "FT_PS=$t=[IO.File]::ReadAllText($env:FT_SELF,[Text.Encoding]::UTF8); $i=$t.LastIndexOf('#GD_'+'BEGIN'); $j=$t.LastIndexOf('#GD_'+'END'); if($i -lt 0 -or $j -le $i){exit 2}; $b=$t.Substring($i+9,$j-$i-9); [IO.File]::WriteAllText($env:FT_GDPS,$b,(New-Object Text.UTF8Encoding $true))"
call :psx
if not exist "%FT_GDPS%" (
    call :err "Could not prepare the Game Doctor engine."
    exit /b
)
set "FT_LOGDIR=%LOGDIR%"
set "FT_LOGFILE=%LOGFILE%"
call :log "Game Doctor started"
start "Game Doctor" /wait powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%FT_GDPS%"
call :log "Game Doctor closed, exit code %errorlevel%"
call :ok "Game Doctor closed. Reports are in: %LOGDIR%\GameDoctor\Reports"
exit /b


rem ==================================================================
rem  5) NETWORK FIXES
rem ==================================================================
:NET_MENU
call :header "5) NETWORK FIXES"
echo    %cC%[%cW%1%cC%]%cX% %cC%●%cX% Flush DNS cache              %cD%- Clear saved DNS records (fixes wrong or old websites)%cX%
echo    %cC%[%cW%2%cC%]%cX% %cC%●%cX% Release and renew IP address %cD%- Ask your router for a fresh IP address%cX%
echo    %cC%[%cW%3%cC%]%cX% %cC%●%cX% Reset Winsock and TCP/IP     %cD%- Repairs deep network settings - restart needed%cX%
echo    %cC%[%cW%4%cC%]%cX% %cC%●%cX% Reset network adapters       %cD%- Restart your network cards%cX%
echo    %cC%[%cW%5%cC%]%cX% %cC%●%cX% Ping test                    %cD%- Test the connection to 8.8.8.8 and 1.1.1.1%cX%
echo    %cC%[%cW%6%cC%]%cX% %cC%●%cX% Show IP, DNS and gateway     %cD%- View your current network details%cX%
echo    %cC%[%cW%7%cC%]%cX% %cC%●%cX% Set DNS                      %cD%- Switch to Google or Cloudflare DNS%cX%
echo    %cC%[%cW%8%cC%]%cX% %cC%●%cX% Set DNS back to automatic    %cD%- Use the DNS from your router again%cX%
echo    %cC%[%cW%9%cC%]%cX% %cC%●%cX% FIX MY INTERNET              %cD%- Runs the safe repair steps in the correct order%cX%
echo    %cC%[%cW%0%cC%]%cX% %cC%●%cX% Back to main menu
echo.
set "M="
set /p "M=  Select an option: "
set "ACT="
if "%M%"=="1" set "ACT=net_flush"
if "%M%"=="2" set "ACT=net_renew"
if "%M%"=="3" set "ACT=net_reset_stack"
if "%M%"=="4" set "ACT=net_adapter"
if "%M%"=="5" set "ACT=net_ping"
if "%M%"=="6" set "ACT=net_show"
if "%M%"=="7" set "ACT=net_dns_set"
if "%M%"=="8" set "ACT=net_dns_auto"
if "%M%"=="9" set "ACT=net_fix_all"
if "%M%"=="0" goto :MAIN_MENU
call :run_tool %ACT%
goto :NET_MENU

:net_flush
call :step 1 1 "Flushing the DNS cache..."
ipconfig /flushdns >nul 2>&1
if errorlevel 1 (call :err "Could not flush DNS.") else (call :ok "DNS cache flushed.")
exit /b

:net_renew
call :warn "You will be disconnected for a few seconds."
call :confirm "Release and renew the IP address now?"
if "%CONFIRMED%"=="0" (
    call :info "Cancelled."
    exit /b
)
call :step 1 2 "Releasing the IP address..."
ipconfig /release >nul 2>&1
call :step 2 2 "Renewing the IP address..."
ipconfig /renew >nul 2>&1
if errorlevel 1 (call :err "Renew failed. Check the cable or Wi-Fi.") else (call :ok "New IP address received.")
exit /b

:net_reset_stack
call :info "Resets Winsock and the TCP/IP stack to defaults. Fixes many broken-internet problems."
call :confirm "Reset Winsock and TCP/IP now? A restart is needed afterwards."
if "%CONFIRMED%"=="0" (
    call :info "Cancelled."
    exit /b
)
call :step 1 2 "Resetting Winsock..."
netsh winsock reset >nul 2>&1
call :step 2 2 "Resetting the TCP/IP stack..."
netsh int ip reset >nul 2>&1
call :ok "Done. RESTART your PC to finish the reset."
exit /b

:net_adapter
call :warn "Your internet will disconnect for a few seconds."
call :confirm "Restart all active physical network adapters now?"
if "%CONFIRMED%"=="0" (
    call :info "Cancelled."
    exit /b
)
call :step 1 1 "Restarting network adapters..."
call :adapter_restart
exit /b

:adapter_restart
set "FT_PS=Get-NetAdapter -Physical | Where-Object { $_.Status -eq 'Up' } | Restart-NetAdapter -Confirm:$false"
call :psx
if errorlevel 1 (call :err "Could not restart the adapters.") else (call :ok "Network adapters restarted.")
exit /b

:net_ping
call :ping_one 8.8.8.8 Google
call :ping_one 1.1.1.1 Cloudflare
exit /b


rem --- Pings one address 4 times and rates the average latency ---
:ping_one
call :info "Testing %~1 - %~2..."
set "AVG="

set "FT_PS=try { $r=Test-Connection -ComputerName '%~1' -Count 4 -ErrorAction Stop; [math]::Round(($r | Measure-Object -Property ResponseTime -Average).Average) } catch { 'FAIL' }"

call :psx

for /f "usebackq delims=" %%A in ("%FT_OUT%") do set "AVG=%%A"

if not defined AVG set "AVG=FAIL"

if /i "!AVG!"=="FAIL" (
    call :err "%~1 : no reply. The network is down or ping is blocked."
    exit /b
)

if !AVG! LSS 50 (
    call :ok "%~1 : !AVG! ms - GOOD"
) else if !AVG! LSS 100 (
    call :warn "%~1 : !AVG! ms - OK, a little slow"
) else (
    call :err "%~1 : !AVG! ms - HIGH latency"
)

exit /b

:net_show
call :step 1 1 "Reading network settings..."
echo.
set "FT_PS=Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway } | ForEach-Object { 'Adapter : ' + $_.InterfaceAlias; 'IPv4    : ' + ($_.IPv4Address.IPAddress -join ', '); 'Gateway : ' + ($_.IPv4DefaultGateway.NextHop -join ', '); 'DNS     : ' + ($_.DNSServer.ServerAddresses -join ', '); '' }"
set "FT_SHOW=1"
call :psx
exit /b

:net_dns_set
echo    %cC%[%cW%1%cC%]%cX% %cC%●%cX% Google DNS      (8.8.8.8 and 8.8.4.4)
echo    %cC%[%cW%2%cC%]%cX% %cC%●%cX% Cloudflare DNS  (1.1.1.1 and 1.0.0.1)
echo    %cC%[%cW%0%cC%]%cX% %cC%●%cX% Cancel
set "M="
set /p "M=  Select an option: "
if "%M%"=="1" call :dns_apply 8.8.8.8 8.8.4.4 Google
if "%M%"=="2" call :dns_apply 1.1.1.1 1.0.0.1 Cloudflare
exit /b

:dns_apply
call :confirm "Set the DNS of active network adapters to %~3 - %~1 and %~2. You can undo it with option 8."
if "%CONFIRMED%"=="0" (
    call :info "Cancelled."
    exit /b
)
set "FT_PS=Get-NetAdapter -Physical | Where-Object { $_.Status -eq 'Up' } | ForEach-Object { Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ServerAddresses ('%~1','%~2') }"
call :psx
if errorlevel 1 (
    call :err "Could not change the DNS."
) else (
    ipconfig /flushdns >nul 2>&1
    call :ok "DNS set to %~3."
)
exit /b

:net_dns_auto
call :confirm "Set the DNS of active network adapters back to automatic (from your router)?"
if "%CONFIRMED%"=="0" (
    call :info "Cancelled."
    exit /b
)
set "FT_PS=Get-NetAdapter -Physical | Where-Object { $_.Status -eq 'Up' } | ForEach-Object { Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ResetServerAddresses }"
call :psx
if errorlevel 1 (
    call :err "Could not reset the DNS."
) else (
    ipconfig /flushdns >nul 2>&1
    call :ok "DNS is automatic again."
)
exit /b

:net_fix_all
call :warn "Your internet will disconnect for a short time during this repair."
call :confirm "Run the full Fix my internet sequence now?"
if "%CONFIRMED%"=="0" (
    call :info "Cancelled."
    exit /b
)
call :step 1 7 "Flushing the DNS cache..."
ipconfig /flushdns >nul 2>&1
call :step 2 7 "Releasing the IP address..."
ipconfig /release >nul 2>&1
call :step 3 7 "Resetting Winsock..."
netsh winsock reset >nul 2>&1
call :step 4 7 "Resetting the TCP/IP stack..."
netsh int ip reset >nul 2>&1
call :step 5 7 "Restarting network adapters..."
call :adapter_restart
call :step 6 7 "Renewing the IP address..."
ipconfig /renew >nul 2>&1
call :step 7 7 "Testing the connection - please wait..."
timeout /t 8 /nobreak >nul
call :net_ping
call :warn "Please RESTART your PC to finish the Winsock and TCP/IP reset."
exit /b


rem ==================================================================
rem  2) SYSTEM REPAIR - WINDOWS UPDATE FIXES
rem ==================================================================
:WU_MENU
call :header "2) SYSTEM REPAIR - WINDOWS UPDATE"
echo    %cC%[%cW%1%cC%]%cX% %cC%●%cX% Repair Windows Update     %cD%- Full reset of the update system (fixes stuck updates)%cX%
echo    %cC%[%cW%2%cC%]%cX% %cC%●%cX% Delete old backup folders %cD%- Frees the space used by the backups from option 1%cX%
echo    %cC%[%cW%0%cC%]%cX% %cC%●%cX% Back to the repair menu
echo.
set "M="
set /p "M=  Select an option: "
set "ACT="
if "%M%"=="1" set "ACT=wu_repair"
if "%M%"=="2" set "ACT=wu_backups"
if "%M%"=="0" goto :REPAIR_HUB
call :run_tool %ACT%
goto :WU_MENU

:wu_repair
call :info "Stops the update services, renames SoftwareDistribution and catroot2 (kept as"
call :info "backups), starts the services again and re-registers the update DLLs."
call :confirm "Repair Windows Update now? Updates in progress will be restarted."
if "%CONFIRMED%"=="0" (
    call :info "Cancelled."
    exit /b
)
call :step 1 5 "Stopping update services..."
for %%S in (wuauserv bits cryptsvc msiserver) do net stop %%S /y >nul 2>&1
call :step 2 5 "Renaming SoftwareDistribution and catroot2..."
call :stamp
if exist "%SystemRoot%\SoftwareDistribution" ren "%SystemRoot%\SoftwareDistribution" "SoftwareDistribution.bak_%STAMP%" >nul 2>&1
if exist "%SystemRoot%\System32\catroot2" ren "%SystemRoot%\System32\catroot2" "catroot2.bak_%STAMP%" >nul 2>&1
if exist "%SystemRoot%\SoftwareDistribution\" call :warn "SoftwareDistribution could not be renamed - a restart may be needed."
call :step 3 5 "Starting update services..."
for %%S in (cryptsvc bits wuauserv msiserver) do net start %%S >nul 2>&1
call :step 4 5 "Re-registering update DLL files..."
for %%D in (atl.dll urlmon.dll mshtml.dll shdocvw.dll browseui.dll jscript.dll vbscript.dll scrrun.dll msxml.dll msxml3.dll msxml6.dll actxprxy.dll softpub.dll wintrust.dll dssenh.dll rsaenh.dll gpkcsp.dll sccbase.dll slbcsp.dll cryptdlg.dll oleaut32.dll ole32.dll shell32.dll initpki.dll wuapi.dll wuaueng.dll wuaueng1.dll wucltui.dll wups.dll wups2.dll wuweb.dll qmgr.dll qmgrprxy.dll wucltux.dll muweb.dll wuwebv.dll) do if exist "%SystemRoot%\System32\%%D" regsvr32.exe /s "%SystemRoot%\System32\%%D" >nul 2>&1
call :step 5 5 "Finishing..."
call :ok "Windows Update components were reset."
call :warn "RESTART your PC now, then open Windows Update and check for updates."
call :info "The old folders were kept as SoftwareDistribution.bak_ and catroot2.bak_ - use option 2 to delete them later."
exit /b

:wu_backups
call :info "Deletes only the folders named SoftwareDistribution.bak_ and catroot2.bak_ that this toolkit created."
call :confirm "Delete the old Windows Update backup folders?"
if "%CONFIRMED%"=="0" (
    call :info "Cancelled."
    exit /b
)
for /d %%D in ("%SystemRoot%\SoftwareDistribution.bak_*") do rd /s /q "%%D" >nul 2>&1
for /d %%D in ("%SystemRoot%\System32\catroot2.bak_*") do rd /s /q "%%D" >nul 2>&1
call :ok "Backup folders deleted (if any existed)."
exit /b


rem ==================================================================
rem  2) SYSTEM REPAIR - COMMON WINDOWS FIXES
rem ==================================================================
:COMMON_MENU
call :header "2) SYSTEM REPAIR - COMMON FIXES"
echo    %cC%[%cW%1%cC%]%cX% %cC%●%cX% Icon and thumbnail cache      %cD%- Fixes wrong icons and missing previews%cX%
echo    %cC%[%cW%2%cC%]%cX% %cC%●%cX% Fix Windows Search            %cD%- Reset the index when search is slow or empty%cX%
echo    %cC%[%cW%3%cC%]%cX% %cC%●%cX% Fix Print Spooler             %cD%- Clear a stuck print queue%cX%
echo    %cC%[%cW%4%cC%]%cX% %cC%●%cX% Re-register ALL Store apps    %cD%- Fixes apps that will not open (slow)%cX%
echo    %cC%[%cW%5%cC%]%cX% %cC%●%cX% Restart Bluetooth and Audio   %cD%- Fixes lost sound or Bluetooth devices%cX%
echo    %cC%[%cW%6%cC%]%cX% %cC%●%cX% Re-register Start Menu        %cD%- Fixes a broken Start menu or taskbar%cX%
echo    %cC%[%cW%7%cC%]%cX% %cC%●%cX% Restart Explorer              %cD%- Reload the desktop, taskbar and File Explorer%cX%
echo    %cC%[%cW%8%cC%]%cX% %cC%●%cX% Update Defender definitions   %cD%- Download the newest virus definitions%cX%
echo    %cC%[%cW%9%cC%]%cX% %cC%●%cX% Reset Windows Firewall        %cD%- Back to default rules (your rules are backed up)%cX%
echo    %cC%[%cW%10%cC%]%cX% %cC%●%cX% Repair app folder permissions %cD%- Fix access denied errors on one app folder%cX%
echo    %cC%[%cW%0%cC%]%cX% %cC%●%cX% Back to the repair menu
echo.
set "M="
set /p "M=  Select an option: "
set "ACT="
if "%M%"=="1" set "ACT=rebuild_icons"
if "%M%"=="2" set "ACT=fix_search"
if "%M%"=="3" set "ACT=fix_spooler"
if "%M%"=="4" set "ACT=fix_store_apps"
if "%M%"=="5" set "ACT=fix_bt_audio"
if "%M%"=="6" set "ACT=fix_startmenu"
if "%M%"=="7" set "ACT=fix_explorer"
if "%M%"=="8" set "ACT=fix_defender"
if "%M%"=="9" set "ACT=fix_firewall"
if "%M%"=="10" set "ACT=fix_permissions"
if "%M%"=="0" goto :REPAIR_HUB
call :run_tool %ACT%
goto :COMMON_MENU

:fix_search
call :info "Stops Windows Search, deletes its index database and starts it again."
call :info "Windows rebuilds the index in the background - results may be incomplete for a while."
call :confirm "Reset Windows Search now?"
if "%CONFIRMED%"=="0" (
    call :info "Cancelled."
    exit /b
)
call :step 1 4 "Stopping Windows Search..."
net stop WSearch /y >nul 2>&1
call :step 2 4 "Deleting the old search index..."
del /f /q "%ProgramData%\Microsoft\Search\Data\Applications\Windows\Windows.edb" >nul 2>&1
call :step 3 4 "Starting Windows Search..."
net start WSearch >nul 2>&1
call :step 4 4 "Checking the result..."
sc query WSearch | find "RUNNING" >nul
if errorlevel 1 (
    call :err "Windows Search did not start. Restart the PC and try again."
) else (
    call :ok "Windows Search restarted. The index is rebuilding."
)
exit /b

:fix_spooler
call :info "Stops the Print Spooler, deletes stuck print jobs and starts it again."
call :confirm "Clear the print queue and restart the spooler?"
if "%CONFIRMED%"=="0" (
    call :info "Cancelled."
    exit /b
)
call :step 1 3 "Stopping Print Spooler..."
net stop spooler /y >nul 2>&1
call :step 2 3 "Deleting stuck print jobs..."
del /f /q "%SystemRoot%\System32\spool\PRINTERS\*" >nul 2>&1
call :step 3 3 "Starting Print Spooler..."
net start spooler >nul 2>&1
if errorlevel 1 (call :err "Print Spooler did not start.") else (call :ok "Print Spooler is running and the queue is empty.")
exit /b

:fix_store_apps
call :warn "This re-registers every app for all users. It can take 5 to 15 minutes and red errors from system packages are normal."
call :confirm "Re-register all Microsoft Store apps now?"
if "%CONFIRMED%"=="0" (
    call :info "Cancelled."
    exit /b
)
set "PKG_VERBOSE="
set "PKGS='*'"
call :step 1 1 "Re-registering all apps - please wait..."
call :reregister_pkgs
call :ok "Finished. If an app still fails, reinstall it from the Microsoft Store."
exit /b

:fix_bt_audio
call :ask "Restarts the Bluetooth service and the Windows Audio services. Sound and Bluetooth devices disconnect for a few seconds."
if "%CONFIRMED%"=="0" (
    call :info "Cancelled."
    exit /b
)
call :fix_audio
call :info "Restarting the Bluetooth support service..."
sc query bthserv >nul 2>&1
if errorlevel 1 (
    call :info "No Bluetooth service on this PC."
    exit /b
)
net stop bthserv /y >nul 2>&1
net start bthserv >nul 2>&1
if errorlevel 1 (call :warn "Bluetooth service did not restart.") else (call :ok "Bluetooth service restarted.")
exit /b

:fix_startmenu
call :info "Re-registers the Start Menu, taskbar and search packages with Windows."
call :info "Fixes a Start button, taskbar or search box that does not open."
call :confirm "Re-register the Start Menu and taskbar now?"
if "%CONFIRMED%"=="0" (
    call :info "Cancelled."
    exit /b
)
set "PKG_VERBOSE=1"
set "PKGS='Microsoft.Windows.ShellExperienceHost','Microsoft.Windows.StartMenuExperienceHost','MicrosoftWindows.Client.CBS','Microsoft.Windows.Cortana'"
call :step 1 2 "Re-registering the shell packages..."
call :reregister_pkgs
call :step 2 2 "Restarting Explorer..."
call :restart_explorer
call :ok "Done. If the Start Menu still fails, restart the PC."
exit /b

:fix_explorer
call :ask "Explorer restarts - open folder windows will close and the screen may flash."
if "%CONFIRMED%"=="0" (
    call :info "Cancelled."
    exit /b
)
call :step 1 1 "Restarting Explorer..."
call :restart_explorer
call :ok "Explorer restarted."
exit /b

:fix_defender
call :info "Downloads the newest Windows Defender definitions. Nothing is disabled or changed."
call :step 1 1 "Updating Defender definitions..."
set "FT_PS=try { Update-MpSignature -ErrorAction Stop; exit 0 } catch { Write-Host $_.Exception.Message; exit 1 }"
set "FT_SHOW=1"
call :psx
if errorlevel 1 (
    call :err "Update failed. Check your internet, or another antivirus may be managing protection."
) else (
    call :ok "Windows Defender definitions are up to date."
)
exit /b

:fix_firewall
call :warn "This resets Windows Firewall to its defaults. Custom rules made by games and apps are removed and apps may ask for permission again."
call :confirm "Reset Windows Firewall? A backup of your current rules is saved first."
if "%CONFIRMED%"=="0" (
    call :info "Cancelled."
    exit /b
)
call :stamp
set "FWBACKUP=%LOGDIR%\firewall_backup_%STAMP%.wfw"
call :step 1 2 "Saving a backup of the current firewall rules..."
netsh advfirewall export "%FWBACKUP%" >nul 2>&1
if errorlevel 1 (
    call :err "The backup failed - reset cancelled for your safety."
    exit /b
)
call :step 2 2 "Resetting Windows Firewall..."
netsh advfirewall reset >nul 2>&1
if errorlevel 1 (
    call :err "The reset failed."
) else (
    call :ok "Windows Firewall was reset to default."
    call :info "To undo, run: netsh advfirewall import and the backup file in the log folder."
)
exit /b

:fix_permissions
call :info "Repairs explicit DENY write permissions on one app folder only."
call :info "It does not reset the folder ACL or change permissions recursively."
set "FT_LOGDIR=%LOGDIR%"
rem (runs in its own window because it asks you questions)
start "FixToolkit - Folder permissions" /wait powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "function X($c){ Write-Host ''; Read-Host 'Press Enter to close this window' | Out-Null; exit $c }; $ErrorActionPreference='Stop'; $target=(Read-Host 'Enter the full folder path (quotes are optional)').Trim().Trim([char]34); if([string]::IsNullOrWhiteSpace($target)){Write-Host 'No folder path entered.'; X 2}; if(-not (Test-Path -LiteralPath $target -PathType Container)){Write-Host 'Folder not found: ' $target; X 2}; Write-Host ''; Write-Host 'Current permissions:'; & icacls.exe $target; if($LASTEXITCODE -ne 0){X 3}; do{$answer=Read-Host 'Remove explicit DENY entries for Everyone, Users and Authenticated Users from this folder? [Y/N]'} until($answer -match '^(?i:Y|N)$'); if($answer -notmatch '^(?i:Y)$'){Write-Host 'Cancelled; permissions were not changed.'; X 4}; $backup=Join-Path $env:FT_LOGDIR ('permissions_' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.acl'); & icacls.exe $target /save $backup /C; if($LASTEXITCODE -ne 0){Write-Host 'Could not save the ACL backup. No permissions were changed.'; X 5}; foreach($sid in @('*S-1-1-0','*S-1-5-32-545','*S-1-5-11')){& icacls.exe $target /remove:d $sid; if($LASTEXITCODE -ne 0){Write-Host 'A permission update failed. The ACL backup is at: ' $backup; X 6}}; $testFile=Join-Path $target ('.FixToolkit_WriteTest_' + [guid]::NewGuid().ToString('N') + '.tmp'); try{[IO.File]::WriteAllText($testFile,'Permission test'); Remove-Item -LiteralPath $testFile -Force; Write-Host ''; Write-Host 'Write test passed in the elevated toolkit context.'}catch{Write-Host ''; Write-Host 'Write test failed: ' $_.Exception.Message; Remove-Item -LiteralPath $testFile -Force -ErrorAction SilentlyContinue; Write-Host 'Current permissions:'; & icacls.exe $target; Write-Host 'ACL backup: ' $backup; X 7}; Write-Host ''; Write-Host 'Final permissions:'; & icacls.exe $target; Write-Host 'ACL backup saved to: ' $backup; X 0"
set "PERM_RC=%errorlevel%"
if "%PERM_RC%"=="0" (
    call :ok "Folder permission repair completed and the write test passed."
) else if "%PERM_RC%"=="4" (
    call :info "Permission repair cancelled."
) else if "%PERM_RC%"=="2" (
    call :warn "Permission repair stopped because the folder path was empty or invalid."
) else if "%PERM_RC%"=="7" (
    call :warn "DENY entries were processed, but the elevated write test failed. Review the ACL backup and permissions above."
) else (
    call :err "Permission repair failed. Review the PowerShell output and ACL backup path above."
)
call :log "App folder permission repair exit code %PERM_RC%"
exit /b

rem --- Stops Explorer ---
:stop_explorer
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 1 /nobreak >nul
exit /b

rem --- Starts Explorer if Windows did not restart it by itself ---
:start_explorer
timeout /t 2 /nobreak >nul
tasklist /fi "imagename eq explorer.exe" 2>nul | find /i "explorer.exe" >nul
if errorlevel 1 start "" explorer.exe
exit /b

:restart_explorer
call :stop_explorer
call :start_explorer
exit /b


rem ==================================================================
rem  6) TOOLS - catalog of portable tools (downloaded on first use)
rem
rem  HOW TO ADD A NEW TOOL (one line inside :tools_register):
rem    call :tool_add CATEGORY "Name" "Folder" "exe names" "official page" "source" ["source" ...]
rem  Sources are tried in this order until one works:
rem    URL=https://...            direct link (a .zip is extracted, an .exe is kept)
rem    GH=owner/repo^|regex        newest GitHub release asset whose name matches the regex
rem    WG=PackageId               winget download, portable file (hash verified by winget)
rem    WGI=PackageId              winget download, installer that is installed quietly INTO the tool folder
rem    WGR=PackageId              winget download, installer opened normally (you click Next / Install)
rem    FIND=full\path\app.exe     where the program lives after a normal install (also used to find it next time)
rem    REF=https://...            optional Referer header for sites that need one
rem    BI=command                 built-in Windows tool, nothing to download (devmgmt.msc, regedit.exe ...)
rem    ACT=label                  runs a label inside this toolkit (example: ssd_health)
rem  HOW TO ADD A NEW CATEGORY: add one line  call :cat_add KEY "Title"  in :tools_register
rem ==================================================================
:TOOLS_MENU
if not defined TOOLS_READY call :tools_register
:TOOLS_HUB
call :header "6) TOOLS"
echo   %cD%A tool is downloaded from its official source the first time you open it.%cX%
echo.
for /l %%n in (1,1,!CAT_N!) do (
    set "id=0%%n"
    set "PAD=!CAT_%%n_TITLE!                    "
    set "dn=%%n"
    echo    %cC%[%cW%!dn!%cC%]%cX% %cC%●%cX% !PAD:~0,19! %cD%- !CAT_%%n_DESC!%cX%
)
echo    %cC%[%cW%0%cC%]%cX% %cC%●%cX% Back to main menu
echo.
set "M="
set /p "M=  Select an option: "
if not defined M goto :TOOLS_HUB
call :norm2 M
if "!M!"=="00" goto :MAIN_MENU
set "SEL="
for /l %%n in (1,1,!CAT_N!) do (
    set "id=0%%n"
    if "!M!"=="!id:~-2!" set "SEL=%%n"
)
if not defined SEL goto :TOOLS_HUB
set "CUR_CAT=!CAT_%SEL%_KEY!"
set "CUR_TITLE=!CAT_%SEL%_TITLE!"
call :TOOLS_CATEGORY
goto :TOOLS_HUB

rem --- One category: lists its tools and opens the one you pick ---
:TOOLS_CATEGORY
call :header "6) TOOLS - !CUR_TITLE!"
for /l %%n in (1,1,!TL_%CUR_CAT%_N!) do (
    set "id=0%%n"
    set "dn=%%n"
    call :tool_line %%n
)
echo    %cC%[%cW%0%cC%]%cX% %cC%●%cX% Back to the tools menu
echo.
set "M="
set /p "M=  Select an option: "
if not defined M goto :TOOLS_CATEGORY
call :norm2 M
if "!M!"=="00" exit /b
set "SEL="
for /l %%n in (1,1,!TL_%CUR_CAT%_N!) do (
    set "id=0%%n"
    if "!M!"=="!id:~-2!" set "SEL=%%n"
)
if not defined SEL goto :TOOLS_CATEGORY
call :tool_run %CUR_CAT% !SEL!
if errorlevel 1 call :pause
goto :TOOLS_CATEGORY

rem --- Prints one tool line: name in normal color, the (description) in gray after a dash ---
:tool_line
set "TN=!TL_%CUR_CAT%_%~1_NAME!"
set "TD="
set "TX=!TN:(=!"
if not "!TX!"=="!TN!" for /f "tokens=1,* delims=(" %%a in ("!TN!") do (
    set "TN=%%a"
    set "TD=%%b"
)
if defined TD set "TD=!TD:~0,-1!"
set "dn=%~1"
if defined TD (
    set "PAD=!TN!                                    "
    echo    %cC%[%cW%!dn!%cC%]%cX% %cC%●%cX% !PAD:~0,36! %cD%- !TD!%cX%
) else (
    echo    %cC%[%cW%!dn!%cC%]%cX% %cC%●%cX% !TN!
)
exit /b

rem --- Pads a typed number to two digits: 1 becomes 01 (variable name in %~1) ---
:norm2
set "N2=0!%~1!"
set "%~1=!N2:~-2!"
exit /b

rem --- The tool catalog. A tool may appear in more than one category. ---
:tools_register
set "CAT_N=0"
call :cat_add BENCH "Benchmark Tools" "Test the speed and stability of your PC"
call :cat_add STORAGE "Storage Tools" "Drive health, disk speed and what uses space"
call :cat_add UNINST "Uninstaller Tools" "Remove programs completely with their leftovers"
call :cat_add PERF "Performance Tools" "Monitor, tune and get info about CPU and GPU"
call :cat_add WINTOOLS "Windows Tools" "Quick shortcuts to built-in Windows consoles"

rem ---- 1) Benchmark Tools ----
call :tool_add BENCH "PassMark PerformanceTest (full PC benchmark)" "PassMarkPT" "PerformanceTest64.exe" "https://www.passmark.com/products/performancetest/download.php" "WGR=PassMark.PerformanceTest" "FIND=%ProgramFiles%\PerformanceTest\PerformanceTest64.exe" "FIND=%ProgramFiles%\PassMark\PerformanceTest\PerformanceTest64.exe"
call :tool_add BENCH "3DMark (GPU and CPU gaming benchmark - big download)" "3DMark" "3DMark.exe" "https://benchmarks.ul.com/3dmark" "WGR=UL.3DMark" "FIND=%ProgramFiles%\UL\3DMark\3DMark.exe"
call :tool_add BENCH "Cinebench (CPU render benchmark)" "Cinebench" "Cinebench.exe" "https://www.maxon.net/en/downloads/cinebench-2024-downloads" "WG=Maxon.Cinebench" "WG=Maxon.CinebenchR23"
call :tool_add BENCH "OCCT (CPU, GPU and RAM stability test)" "OCCT" "*OCCT*.exe" "https://www.ocbase.com/download-personal" "WG=OCBase.OCCT.Personal"
call :tool_add BENCH "Unigine Superposition (GPU benchmark)" "UnigineSuperposition" "Superposition.exe launcher.exe" "https://benchmark.unigine.com/superposition" "WGR=Unigine.Superposition" "FIND=%ProgramFiles%\Unigine\Superposition Benchmark\bin\launcher.exe" "FIND=%ProgramFiles%\Unigine\Superposition Benchmark\Superposition.exe"
call :tool_add BENCH "CrystalMark Retro (classic all-in-one benchmark)" "CrystalMarkRetro" "CrystalMarkRetro*.exe CrystalMark*.exe" "https://crystalmark.info/en/software/crystalmarkretro/" "WGI=CrystalDewWorld.CrystalMarkRetro"
call :tool_add BENCH "MemTest86 (RAM test - makes a bootable USB, ERASES the USB)" "MemTest86" "imageUSB.exe" "https://www.memtest86.com/download.htm" "URL=https://www.memtest86.com/downloads/memtest86-usb.zip"

rem ---- 2) Storage Tools ----
call :tool_add STORAGE "CrystalDiskInfo (drive health and SMART)" "CrystalDiskInfo" "DiskInfo64.exe" "https://crystalmark.info/en/software/crystaldiskinfo/" "WGI=CrystalDewWorld.CrystalDiskInfo"
call :tool_add STORAGE "CrystalDiskMark (disk speed test)" "CrystalDiskMark" "DiskMark64.exe" "https://crystalmark.info/en/software/crystaldiskmark/" "WGI=CrystalDewWorld.CrystalDiskMark"
call :tool_add STORAGE "TreeSize Free (folder sizes)" "TreeSize" "TreeSizeFree.exe" "https://www.jam-software.com/treesize_free" "WGI=JAMSoftware.TreeSize.Free" "FIND=%ProgramFiles%\JAM Software\TreeSize Free\TreeSizeFree.exe"
call :tool_add STORAGE "WizTree (very fast disk space analyzer)" "WizTree" "WizTree64.exe" "https://diskanalyzer.com/download" "WGI=AntibodySoftware.WizTree"
call :tool_add STORAGE "WinDirStat (what is using my disk space)" "WinDirStat" "WinDirStat_x64.exe WinDirStat*x64*.exe WinDirStat.exe" "https://windirstat.net/download" "URL=https://github.com/windirstat/windirstat/releases/latest/download/WinDirStat.zip"
call :tool_add STORAGE "HDDScan (surface test and SMART)" "HDDScan" "HDDScan.exe" "https://hddscan.com/download.html" "URL=https://hddscan.com/download/HDDScan.zip" "REF=https://hddscan.com/download.html"
call :tool_add STORAGE "SSD Health (wear, temperature, errors - built in)" "-" "-" "https://crystalmark.info/en/software/crystaldiskinfo/" "ACT=ssd_health"
call :tool_add STORAGE "Disk Management (Windows)" "-" "-" "-" "BI=diskmgmt.msc"

rem ---- 3) Uninstaller Tools ----
call :tool_add UNINST "Geek Uninstaller (light uninstaller, removes leftovers)" "GeekUninstaller" "geek.exe" "https://geekuninstaller.com/download" "URL=https://geekuninstaller.com/geek.zip"
call :tool_add UNINST "Revo Uninstaller (portable, removes leftovers)" "RevoUninstaller" "RevoUPort.exe Revo*.exe" "https://www.revouninstaller.com/revo-uninstaller-free-download/" "URL=https://download.revouninstaller.com/download/RevoUninstaller_Portable.zip"
call :tool_add UNINST "Bulk Crap Uninstaller (remove many programs at once)" "BCUninstaller" "BCUninstaller.exe" "https://www.bcuninstaller.com/" "GH=Klocman/Bulk-Crap-Uninstaller|BCUninstaller_.*_portable\.zip$"
call :tool_add UNINST "TreeSize Free (find big folders to remove)" "TreeSize" "TreeSizeFree.exe" "https://www.jam-software.com/treesize_free" "WGI=JAMSoftware.TreeSize.Free" "FIND=%ProgramFiles%\JAM Software\TreeSize Free\TreeSizeFree.exe"
call :tool_add UNINST "Windows Apps (Settings - Installed apps)" "-" "-" "-" "BI=ms-settings:appsfeatures"

rem ---- 4) Performance Tools ----
call :tool_add PERF "MSI Afterburner (GPU overclock and monitoring)" "MSIAfterburner" "MSIAfterburner.exe" "https://www.msi.com/Landing/afterburner/graphics-cards" "WGR=Guru3D.Afterburner" "FIND=%ProgramFiles(x86)%\MSI Afterburner\MSIAfterburner.exe"
call :tool_add PERF "RTSS - RivaTuner Statistics Server (FPS overlay and limiter)" "RTSS" "RTSS.exe" "https://www.guru3d.com/page/rtss-rivatuner-statistics-server-download/" "WGR=Guru3D.RTSS" "FIND=%ProgramFiles(x86)%\RivaTuner Statistics Server\RTSS.exe"
call :tool_add PERF "LatencyMon (DPC latency and audio dropouts)" "LatencyMon" "LatMon.exe" "https://www.resplendence.com/latencymon" "WGR=Resplendence.LatencyMon" "FIND=%ProgramFiles%\LatencyMon\LatMon.exe"
call :tool_add PERF "Autoruns (startup programs)" "Autoruns" "Autoruns64.exe Autoruns.exe" "https://learn.microsoft.com/sysinternals/downloads/autoruns" "URL=https://download.sysinternals.com/files/Autoruns.zip"
call :tool_add PERF "GPU-Z (graphics card information)" "GPU-Z" "*GPU-Z*.exe" "https://www.techpowerup.com/gpuz/" "WG=TechPowerUp.GPU-Z"
call :tool_add PERF "CPU-Z (processor and memory information)" "CPU-Z" "cpuz_x64.exe cpuz*.exe" "https://www.cpuid.com/softwares/cpu-z.html" "WGI=CPUID.CPU-Z"

rem ---- 5) Windows Tools (all built in) ----
call :tool_add WINTOOLS "Device Manager (drivers and hardware)" "-" "-" "-" "BI=devmgmt.msc"
call :tool_add WINTOOLS "Disk Management (drives and partitions)" "-" "-" "-" "BI=diskmgmt.msc"
call :tool_add WINTOOLS "Services (start and stop Windows services)" "-" "-" "-" "BI=services.msc"
call :tool_add WINTOOLS "Task Scheduler (scheduled tasks)" "-" "-" "-" "BI=taskschd.msc"
call :tool_add WINTOOLS "Event Viewer (system logs and errors)" "-" "-" "-" "BI=eventvwr.msc"
call :tool_add WINTOOLS "Computer Management (admin tools in one place)" "-" "-" "-" "BI=compmgmt.msc"
call :tool_add WINTOOLS "Resource Monitor (live CPU, RAM, disk, network)" "-" "-" "-" "BI=resmon.exe"
call :tool_add WINTOOLS "System Information (hardware and system details)" "-" "-" "-" "BI=msinfo32.exe"
call :tool_add WINTOOLS "Registry Editor (advanced - be careful)" "-" "-" "-" "BI=regedit.exe"
call :tool_add WINTOOLS "Group Policy Editor (not on Windows Home)" "-" "-" "-" "BI=gpedit.msc"
call :tool_add WINTOOLS "Windows Features (turn features on or off)" "-" "-" "-" "BI=optionalfeatures.exe"
set "TOOLS_READY=1"
exit /b

rem --- Registers a category: KEY and Title ---
:cat_add
set /a CAT_N+=1
set "CAT_!CAT_N!_KEY=%~1"
set "CAT_!CAT_N!_TITLE=%~2"
set "CAT_!CAT_N!_DESC=%~3"
exit /b

rem --- Registers a tool (see the how-to at the top of this section) ---
:tool_add
set /a TL_%~1_N+=1
set "TLI=!TL_%~1_N!"
set "TL_%~1_!TLI!_NAME=%~2"
set "TL_%~1_!TLI!_DIR=%~3"
set "TL_%~1_!TLI!_EXE=%~4"
set "TL_%~1_!TLI!_PAGE=%~5"
set "TL_%~1_!TLI!_S1=%~6"
set "TL_%~1_!TLI!_S2=%~7"
set "TL_%~1_!TLI!_S3=%~8"
set "TL_%~1_!TLI!_S4=%~9"
exit /b

rem --- Opens one tool: find it, download it if missing, then run it. ---
rem --- Returns errorlevel 0 when it ran, 1 when something failed.       ---
:tool_run
set "T_NAME=!TL_%~1_%~2_NAME!"
set "T_EXES=!TL_%~1_%~2_EXE!"
set "T_PAGE=!TL_%~1_%~2_PAGE!"
set "T_S1=!TL_%~1_%~2_S1!"
set "T_S2=!TL_%~1_%~2_S2!"
set "T_S3=!TL_%~1_%~2_S3!"
set "T_S4=!TL_%~1_%~2_S4!"
set "T_DIR=%TOOLS_DIR%\!TL_%~1_%~2_DIR!"
set "T_FRESH="
call :header "6) TOOLS - !T_NAME!"
set "BK="
set "BV="
for /f "tokens=1,* delims==" %%A in ("!T_S1!") do (
    set "BK=%%A"
    set "BV=%%B"
)
if /i "!BK!"=="BI" goto :tool_builtin
if /i "!BK!"=="ACT" goto :tool_action
call :tool_find
if defined T_EXE_PATH goto :tool_launch
call :info "!T_NAME! is not on this PC yet - getting it from the official source..."
if not exist "!T_DIR!" mkdir "!T_DIR!" >nul 2>&1
if not exist "!T_DIR!\" (
    call :err "Could not create the folder for this tool. Move FixToolkit to a folder you can write to."
    exit /b 1
)
call :tool_acquire
call :tool_find
if defined T_EXE_PATH goto :tool_launch
call :err "Could not download or prepare !T_NAME! automatically."
call :info "Files found in !T_DIR! (send this list if the problem continues):"
dir /s /b "!T_DIR!" 2>nul
call :log "Tool prepare failed: !T_NAME! - folder !T_DIR!"
call :confirm "Open the official page and the tool folder so you can add it by hand?"
if "!CONFIRMED!"=="0" exit /b 1
start "" "!T_PAGE!"
start "" "!T_DIR!"
echo   Put the program files in the folder that just opened, then press any key here...
pause >nul
call :tool_find
if defined T_EXE_PATH goto :tool_launch
call :err "!T_NAME! was still not found in its folder."
exit /b 1

:tool_builtin
set "BV_EXE="
for /f "tokens=1" %%C in ("!BV!") do set "BV_EXE=%%C"
echo !BV!|find ":" >nul
if errorlevel 1 (
    where "!BV_EXE!" >nul 2>&1
    if errorlevel 1 (
        call :err "!T_NAME! is not available on this Windows edition (for example Windows Home has no Group Policy Editor)."
        exit /b 1
    )
)
call :info "Opening !T_NAME! - it opens in its own window."
call :log "Built-in tool started: !BV!"
start "" !BV!
timeout /t 2 /nobreak >nul
exit /b 0

:tool_action
call :log "Toolkit action started: !BV!"
call :!BV!
call :pause
exit /b 0

:tool_launch
if defined T_FRESH call :tool_sig
for %%F in ("!T_EXE_PATH!") do set "T_EXE_DIR=%%~dpF"
set "T_EXE_DIR=!T_EXE_DIR:~0,-1!"
call :info "Starting !T_NAME! - you can keep using this menu while it is open."
call :log "Tool started: !T_EXE_PATH!"
start "" /d "!T_EXE_DIR!" "!T_EXE_PATH!"
call :log "Tool launched (not waiting for it to close): !T_NAME!"
exit /b 0

rem --- Looks for the program inside the tool folder, then at the FIND= paths (first match wins) ---
:tool_find
set "T_EXE_PATH="
if exist "%T_DIR%\" call :tool_find_dir
for %%I in (1 2 3 4) do if not defined T_EXE_PATH if defined T_S%%I call :tool_find_ext "!T_S%%I!"
if defined T_EXE_PATH exit /b 0
exit /b 1

:tool_find_dir
for /f "tokens=1-4 delims= " %%a in ("%T_EXES% - - - -") do (
    call :tool_find_one "%%a"
    call :tool_find_one "%%b"
    call :tool_find_one "%%c"
    call :tool_find_one "%%d"
)
exit /b

rem --- One FIND=path source: if that file exists, use it ---
:tool_find_ext
if defined T_EXE_PATH exit /b
set "FE=%~1"
if /i not "!FE:~0,5!"=="FIND=" exit /b
set "FE=!FE:~5!"
if exist "!FE!" set "T_EXE_PATH=!FE!"
exit /b

:tool_find_one
if defined T_EXE_PATH exit /b
if "%~1"=="-" exit /b
for /r "%T_DIR%" %%F in (%~1) do if not defined T_EXE_PATH if exist "%%F" set "T_EXE_PATH=%%F"
if not defined T_EXE_PATH for /f "delims=" %%G in ('dir /s /b /a-d "%T_DIR%\%~1" 2^>nul') do if not defined T_EXE_PATH set "T_EXE_PATH=%%G"
exit /b

rem --- Tries each source of the tool until the program is found ---
:tool_acquire
set "DL_REF="
for %%I in (1 2 3 4) do (
    if defined T_S%%I (
        for /f "tokens=1,* delims==" %%A in ("!T_S%%I!") do (
            if /i "%%A"=="REF" set "DL_REF=%%B"
        )
    )
)
for %%I in (1 2 3 4) do (
    if not defined T_EXE_PATH if defined T_S%%I call :acq_one "!T_S%%I!"
)
set "DL_REF="
exit /b

rem --- One source: split KIND=VALUE and run the matching method ---
:acq_one
set "ACQ=%~1"
for /f "tokens=1,* delims==" %%A in ("!ACQ!") do (
    set "AK=%%A"
    set "AV=%%B"
)
if /i "!AK!"=="REF" exit /b 1
if /i "!AK!"=="FIND" exit /b 1
if /i "!AK!"=="URL" call :acq_url "!AV!"
if /i "!AK!"=="GH" call :acq_gh
if /i "!AK!"=="WG" call :acq_wg portable
if /i "!AK!"=="WGI" call :acq_wg inno
if /i "!AK!"=="WGR" call :acq_wg run
call :tool_find
if defined T_EXE_PATH set "T_FRESH=1"
exit /b

rem --- Direct download (zip is extracted, exe is kept) ---
:acq_url
set "AU=%~1"
set "AU_P=!AU:/=\!"
for %%X in ("!AU_P!") do set "AU_FILE=%%~nxX"
set "AU_EXT=!AU_FILE:~-4!"
set "AU_DEST=!T_DIR!\!AU_FILE!"
if /i "!AU_EXT!"==".zip" set "AU_DEST=!T_DIR!\_package.zip"
call :step 1 2 "Downloading !T_NAME!..."
set "TL_CUR_URL=!AU!"
call :download TL_CUR_URL "!AU_DEST!"
call :check_size "!AU_DEST!" 20000
if errorlevel 1 (
    del /f /q "!AU_DEST!" >nul 2>&1
    call :warn "The download failed or the file is incomplete."
    exit /b 1
)
if /i "!AU_EXT!"==".zip" (
    call :step 2 2 "Extracting..."
    call :extract_zip "!AU_DEST!" "!T_DIR!"
    if errorlevel 1 call :warn "Extraction failed."
)
exit /b 0

rem --- Newest GitHub release asset whose name matches the regex ---
:acq_gh
for /f "tokens=1,2 delims=|" %%A in ("!AV!") do (
    set "GH_REPO=%%A"
    set "GH_RX=%%B"
)
call :step 1 2 "Looking up the newest release on GitHub..."
set "FT_PS=[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; try { $r=Invoke-RestMethod -UseBasicParsing -Uri 'https://api.github.com/repos/!GH_REPO!/releases/latest' -Headers @{'User-Agent'='FixToolkit'}; $a=$r.assets | Where-Object { $_.name -match '!GH_RX!' } | Select-Object -First 1; if($a){ $a.browser_download_url; exit 0 } else { exit 2 } } catch { Write-Host $_.Exception.Message; exit 1 }"
call :psx
if errorlevel 1 (
    call :warn "Could not read the GitHub release information."
    exit /b 1
)
set "GH_URL="
for /f "usebackq delims=" %%U in ("%FT_OUT%") do if not defined GH_URL set "GH_URL=%%U"
if not defined GH_URL exit /b 1
call :acq_url "!GH_URL!"
exit /b

rem --- winget download. Mode portable = keep the exe, inno = install quietly into the tool folder, run = open the installer normally ---
:acq_wg
where winget.exe >nul 2>&1
if errorlevel 1 (
    call :warn "winget is not available on this PC."
    exit /b 1
)
set "WG_STAGE=!T_DIR!\_dl"
if exist "!WG_STAGE!" rd /s /q "!WG_STAGE!" >nul 2>&1
mkdir "!WG_STAGE!" >nul 2>&1
call :step 1 2 "Downloading with winget - the file hash is checked by winget..."
winget download --id "!AV!" -e --accept-package-agreements --accept-source-agreements -d "!WG_STAGE!"
set "WG_ZIP="
set "WG_EXE="
for %%Z in ("!WG_STAGE!\*.zip") do set "WG_ZIP=%%~fZ"
for %%Z in ("!WG_STAGE!\*.exe") do set "WG_EXE=%%~fZ"
if defined WG_ZIP (
    call :step 2 2 "Extracting..."
    call :extract_zip "!WG_ZIP!" "!T_DIR!"
) else if defined WG_EXE (
    if /i "%~1"=="inno" (
        call :step 2 2 "Preparing !T_NAME! inside its own folder - this is not a Windows-wide install..."
        start "" /wait "!WG_EXE!" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /DIR="!T_DIR!"
    ) else if /i "%~1"=="run" (
        call :step 2 2 "Opening the installer of !T_NAME!..."
        call :info "This program installs normally into Windows. Finish the installer (Next / Install), then the toolkit starts it."
        start "" /wait "!WG_EXE!"
    ) else (
        move /y "!WG_EXE!" "!T_DIR!\" >nul 2>&1
    )
) else (
    call :warn "winget did not download a usable file."
)
rd /s /q "!WG_STAGE!" >nul 2>&1
exit /b 0

rem --- Extracts a zip (%~1) into a folder (%~2) and deletes the zip ---

:extract_zip
set "EX_RC=1"
tar -xf "%~1" -C "%~2" >nul 2>&1
set "EX_RC=!errorlevel!"
if not "!EX_RC!"=="0" (
    call :info "tar could not open the zip - trying PowerShell instead..."
    set "FT_PS=Expand-Archive -LiteralPath '%~1' -DestinationPath '%~2' -Force"
    set "FT_SHOW=1"
    call :psx
    set "EX_RC=!errorlevel!"
)
if not "!EX_RC!"=="0" (
    call :warn "Could not extract %~1 (code !EX_RC!). The zip is kept so you can check it."
    exit /b 1
)
del /f /q "%~1" >nul 2>&1
exit /b 0

rem --- SSD / drive health from the counters Windows reports (no download needed) ---
:ssd_health
call :info "Reads health, wear, temperature and error counters that Windows reports for each drive."
set "FT_PS=Get-PhysicalDisk | ForEach-Object { $d=$_; $r=$d | Get-StorageReliabilityCounter -ErrorAction SilentlyContinue; ('Drive    : ' + $d.FriendlyName + ' (' + $d.MediaType + ', ' + [math]::Round($d.Size/1GB) + ' GB)'); ('Health   : ' + $d.HealthStatus + ' / ' + $d.OperationalStatus); if($r){ ('Wear     : ' + $(if($r.Wear -ne $null){[string]$r.Wear + ' pct of life used'}else{'not reported'})); ('Temp     : ' + $(if($r.Temperature){[string]$r.Temperature + ' C'}else{'not reported'})); ('Power-on : ' + $(if($r.PowerOnHours -ne $null){[string]$r.PowerOnHours + ' hours'}else{'not reported'})); ('Read err : ' + $r.ReadErrorsTotal); ('Write err: ' + $r.WriteErrorsTotal) } else { 'Details  : not reported by this drive' }; '' }"
set "FT_SHOW=1"
call :psx
call :info "For full SMART details open CrystalDiskInfo (option 01 in this menu)."
exit /b

rem --- Shows who signed the program after a fresh download (information only) ---
:tool_sig
set "FT_PS=$s=Get-AuthenticodeSignature -LiteralPath '!T_EXE_PATH!'; if($s.SignerCertificate){ Write-Host ('Signed by: ' + ($s.SignerCertificate.Subject -replace '.*CN=([^,]+).*','$1') + ' - signature ' + $s.Status); if($s.Status -eq 'HashMismatch'){ exit 3 } } else { Write-Host 'This file has no digital signature.' }"
set "FT_SHOW=1"
call :psx
if errorlevel 3 call :warn "The digital signature is NOT valid. Close the program and do not use it."
exit /b


rem ==================================================================
rem  7) RESTORE DEFAULT SETTINGS
rem ==================================================================
:RESTORE_MENU
call :header "7) RESTORE DEFAULT SETTINGS"
echo   %cD%Only real, known restores. Every change is shown first and needs Y/N.%cX%
echo.
echo    %cC%[%cW%1%cC%]%cX% %cC%●%cX% Restore GPU Settings          %cD%- Graphics settings back to defaults%cX%
echo    %cC%[%cW%2%cC%]%cX% %cC%●%cX% Restore Windows Services      %cD%- Services back to their default startup type%cX%
echo    %cC%[%cW%3%cC%]%cX% %cC%●%cX% Restore Network Settings      %cD%- Network configuration back to defaults%cX%
echo    %cC%[%cW%4%cC%]%cX% %cC%●%cX% Restore Firewall Settings     %cD%- Windows Firewall back to default rules%cX%
echo    %cC%[%cW%5%cC%]%cX% %cC%●%cX% Restore Windows Update        %cD%- Update settings back to defaults%cX%
echo    %cC%[%cW%6%cC%]%cX% %cC%●%cX% Restore Power Settings        %cD%- Power plans back to defaults%cX%
echo    %cC%[%cW%7%cC%]%cX% %cC%●%cX% Restore Windows Security      %cD%- Security settings back to defaults%cX%
echo    %cC%[%cW%8%cC%]%cX% %cC%●%cX% Restore Windows Explorer      %cD%- Explorer settings back to defaults%cX%
echo    %cC%[%cW%9%cC%]%cX% %cC%●%cX% Restore Startup Configuration %cD%- Startup settings back to defaults%cX%
echo    %cC%[%cW%0%cC%]%cX% %cC%●%cX% Back to main menu
echo.
set "M="
set /p "M=  Select an option [0-9]: "
if defined M if "!M:~0,1!"=="0" if not "!M!"=="0" set "M=!M:~1!"
set "RS="
set "RT="
if "!M!"=="1" goto :RST_GPU
if "!M!"=="2" (set "RS=SERVICES" & set "RT=Restore Windows Services")
if "!M!"=="3" (set "RS=NETWORK" & set "RT=Restore Network Settings")
if "!M!"=="4" (set "RS=FIREWALL" & set "RT=Restore Firewall Settings")
if "!M!"=="5" (set "RS=WINUPDATE" & set "RT=Restore Windows Update")
if "!M!"=="6" (set "RS=POWER" & set "RT=Restore Power Settings")
if "!M!"=="7" (set "RS=SECURITY" & set "RT=Restore Windows Security")
if "!M!"=="8" (set "RS=EXPLORER" & set "RT=Restore Windows Explorer")
if "!M!"=="9" (set "RS=STARTUP" & set "RT=Restore Startup Configuration")
if "!M!"=="0" goto :MAIN_MENU
if defined RS call :rst_run "!RS!" "!RT!"
goto :RESTORE_MENU

rem --- GPU vendor menu ---
:RST_GPU
call :header "7) RESTORE DEFAULT SETTINGS - GPU"
echo    %cC%[%cW%1%cC%]%cX% %cC%●%cX% NVIDIA
echo    %cC%[%cW%2%cC%]%cX% %cC%●%cX% AMD
echo    %cC%[%cW%3%cC%]%cX% %cC%●%cX% Intel
echo    %cC%[%cW%0%cC%]%cX% %cC%●%cX% Back to the restore menu
echo.
set "M="
set /p "M=  Select an option [0-3]: "
if defined M if "!M:~0,1!"=="0" if not "!M!"=="0" set "M=!M:~1!"
set "RS="
if "!M!"=="1" set "RS=GPU_NVIDIA"
if "!M!"=="2" set "RS=GPU_AMD"
if "!M!"=="3" set "RS=GPU_INTEL"
if "!M!"=="0" goto :RESTORE_MENU
if defined RS call :rst_run "!RS!" "Restore GPU Settings"
goto :RST_GPU

rem --- One restore run: check, show, ask Y/N, apply, summary ---
:rst_run
set "R_OK=0"
set "R_SKIP=0"
set "R_ERR=0"
call :header "RESTORE - %~2"
call :log "==== Restore started: %~1 ===="
call :rst_extract
if not exist "%FT_RPS%" (
    call :rst_line ERROR "Could not prepare the restore engine."
    goto :rst_finish
)
call :info "Checking what can be restored. Nothing is changed yet..."
echo.
call :rst_ps "%~1" Preview
set "PV_RC=!FT_RC!"
call :rst_show P
if not "!PV_RC!"=="0" if not "!PV_RC!"=="3" (
    call :rst_line ERROR "The check failed with PowerShell exit code !PV_RC!. Nothing was changed."
    goto :rst_finish
)
if "!PV_WILL!"=="0" (
    set /a R_SKIP+=PV_SKIP
    set /a R_ERR+=PV_ERR
    echo.
    echo     %cD%Nothing needs to be restored here.%cX%
    goto :rst_finish
)
echo.
echo     %cD%Only the items marked WILL are changed. A backup is saved first where possible.%cX%
:rst_ask
echo.
set "RST_A="
set /p "RST_A=  Are you sure you want to restore these settings? [Y/N]: "
if /i "!RST_A!"=="Y" goto :rst_go
if /i "!RST_A!"=="N" (
    call :log "Restore %~1 cancelled by the user"
    echo.
    call :info "Cancelled. Nothing was changed."
    set "RST_X="
    set /p "RST_X=  Press ENTER to go back."
    exit /b
)
goto :rst_ask
:rst_go
call :log "Restore %~1 confirmed by the user"
echo.
call :rst_ps "%~1" Apply
set "AP_RC=!FT_RC!"
call :rst_show A
if not "!AP_RC!"=="0" if not "!AP_RC!"=="3" call :rst_line ERROR "The restore stopped unexpectedly with PowerShell exit code !AP_RC!."
:rst_finish
call :log "==== Restore finished: %~1 - OK !R_OK! - SKIP !R_SKIP! - ERROR !R_ERR! ===="
echo.
echo   %cC%╔══════════════════════════════════════╗%cX%
echo   %cC%║%cW%          RESTORE COMPLETE            %cC%║%cX%
echo   %cC%╚══════════════════════════════════════╝%cX%
echo.
echo   %cG%[OK]%cX%    Successfully restored: !R_OK!
echo   %cY%[SKIP]%cX%  Skipped: !R_SKIP!
echo   %cE%[ERROR]%cX% Failed: !R_ERR!
echo.
set "RST_X="
set /p "RST_X=  Press ENTER to return to the main menu."
exit /b

rem --- Cuts the PowerShell restore engine (stored at the very end of this file) into a temp .ps1 ---
:rst_extract
set "FT_SELF=%SCRIPT%"
set "FT_RPS=%TEMP%\FixToolkit_restore.ps1"
del /f /q "%FT_RPS%" >nul 2>&1
set "FT_PS=$t=[IO.File]::ReadAllText($env:FT_SELF,[Text.Encoding]::UTF8); $i=$t.LastIndexOf('#RST_'+'BEGIN'); $j=$t.LastIndexOf('#RST_'+'END'); if($i -lt 0 -or $j -le $i){exit 2}; $b=$t.Substring($i+10,$j-$i-10); [IO.File]::WriteAllText($env:FT_RPS,$b,(New-Object Text.UTF8Encoding $true))"
call :psx
exit /b

rem --- Runs the engine. %~1 = section, %~2 = Preview or Apply. Output goes to FT_OUT, exit code to FT_RC ---
:rst_ps
set "FT_SECTION=%~1"
set "FT_MODE=%~2"
set "FT_SELF=%SCRIPT%"
set "FT_LOGDIR=%LOGDIR%"
set "FT_TOOLS=%TOOLS_DIR%"
type nul > "%FT_OUT%"
start "" /wait /min cmd /c powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%FT_RPS%" ^> "%FT_OUT%" 2^>^&1
set "FT_RC=%errorlevel%"
exit /b %FT_RC%

rem --- Shows the engine output. %~1 = P (preview, nothing counted) or A (apply, results counted) ---
:rst_show
set "PV_WILL=0"
set "PV_SKIP=0"
set "PV_ERR=0"
for /f "usebackq tokens=1* delims=]" %%A in (`findstr /b /c:"[OK]" /c:"[SKIP]" /c:"[ERROR]" /c:"[WILL]" /c:"[INFO]" "%FT_OUT%"`) do (
    set "TG=%%A"
    set "MS=%%B"
    if defined MS set "MS=!MS:~1!"
    call :rst_one "%~1"
)
exit /b

rem --- Prints and logs one tagged line. TG = [TAG, MS = message, %~1 = P or A ---
:rst_one
set "TGN=!TG:~1!"
>>"%LOGFILE%" echo([!TODAY! !time:~0,8!] RESTORE-!TGN! - !MS!
if "!TGN!"=="WILL" (
    set /a PV_WILL+=1
    echo     %cY%[WILL]%cX%  !MS!
    exit /b
)
if "!TGN!"=="INFO" (
    echo     %cC%[INFO]%cX%  !MS!
    exit /b
)
if "!TGN!"=="OK" (
    echo     %cG%[OK]%cX%    !MS!
    if /i "%~1"=="A" set /a R_OK+=1
    exit /b
)
if "!TGN!"=="SKIP" (
    echo     %cY%[SKIP]%cX%  !MS!
    if /i "%~1"=="A" (set /a R_SKIP+=1) else (set /a PV_SKIP+=1)
    exit /b
)
if "!TGN!"=="ERROR" (
    echo     %cE%[ERROR]%cX% !MS!
    if /i "%~1"=="A" (set /a R_ERR+=1) else (set /a PV_ERR+=1)
    exit /b
)
exit /b

rem --- A status line made by this batch file itself (always counted). %~1 = tag, %~2 = text ---
:rst_line
set "TG=[%~1"
set "MS=%~2"
call :rst_one A
exit /b



rem ==================================================================
rem  8) SYSTEM INFORMATION
rem ==================================================================
:SYSINFO
call :header_compact "8) SYSTEM INFORMATION"
set "FT_QFILE=%TEMP%\FixToolkit_bios_query.txt"
del /f /q "%FT_QFILE%" >nul 2>&1
call :sysinfo_body
set "BQ="
if exist "%FT_QFILE%" set /p "BQ=" < "%FT_QFILE%"
if defined BQ (
    echo   %cC%[%cW%S%cC%]%cX% Search online for a BIOS update     %cC%[%cW%0%cC%]%cX% Back
    choice /c S0 /n >nul
    if errorlevel 2 goto :MAIN_MENU
    start "" "https://www.google.com/search?q=!BQ!"
    goto :MAIN_MENU
)
call :pause
goto :MAIN_MENU

:sysinfo_body
echo.
rem --- The PowerShell script is split into FT_PART1..FT_PART10 (cmd cannot hold more than 8191 characters in one expanded line). A short stub joins them in PowerShell. ---
set "FT_PART1=$ErrorActionPreference='SilentlyContinue'; [Threading.Thread]::CurrentThread.CurrentCulture=[Globalization.CultureInfo]::InvariantCulture; $rows=New-Object System.Collections.ArrayList; function Add-Row($k,$val){ [void]$rows.Add(@($k,$val)) }; function Bad($s){ (-not $s) -or (([string]$s).Trim() -match 'O\.E\.M|Default string|System Product Name|System manufacturer|System Version|Not Applicable|Not Specified') -or (@('N/A','None','Unknown','0') -contains ([string]$s).Trim()) }; function Clean($s){ if(-not $s){ return 'N/A' }; ($s -replace '\(R\)|\(TM\)','' -replace '\s+',' ').Trim() }; function Brand($s){ if(Bad $s){ return '' }; ($s -replace '\b(technology|co|ltd|inc|corporation|corp|computer|international)\b','' -replace '[,\.]','' -replace 'ASUSTeK','ASUS' -replace 'Micro-Star','MSI' -replace '\s+',' ').Trim() }; function Sz($n){ if($n -ge 1e12){ '{0:0.##} TB' -f ($n/1e12) } else { '{0:0} GB' -f ($n/1e9) } };"
set "FT_PART2=$os=Get-CimInstance Win32_OperatingSystem; $cv=Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'; $wn=(Clean $os.Caption) -replace '^Microsoft\s+',''; $wv=$cv.DisplayVersion; if(-not $wv){ $wv=$cv.ReleaseId }; $wb=[string]$cv.CurrentBuild; if($cv.UBR -ne $null){ $wb=$wb+'.'+$cv.UBR }; $lic=Get-CimInstance SoftwareLicensingProduct -Filter 'PartialProductKey IS NOT NULL' | Where-Object { $_.ApplicationId -eq '55c92734-d682-4d71-983e-d6ec3f16059f' } | Select-Object -First 1; $act='Activation unknown'; if($lic){ if($lic.LicenseStatus -eq 1){ $act='Activated' } else { $act='NOT activated' } }; Add-Row 'Windows' ('{0}  -  {1} (build {2})  -  {3}' -f $wn,$wv,$wb,$act); $cpus=@(Get-CimInstance Win32_Processor); $p=$cpus[0]; $cn=(Clean $p.Name) -replace '\s*@\s*[\d\.]+\s*GHz','' -replace '\s+CPU\b','' -replace '\s+\d+-Core Processor','' -replace '\s+Processor$',''; $cores=($cpus|Measure-Object NumberOfCores -Sum).Sum; $thr=($cpus|Measure-Object NumberOfLogicalProcessors -Sum).Sum; Add-Row 'CPU' ('{0}  ({1} cores / {2} threads)' -f $cn.Trim(),$cores,$thr);"
set "FT_PART3=$bb=Get-CimInstance Win32_BaseBoard; $cs=Get-CimInstance Win32_ComputerSystem; $csp=Get-CimInstance Win32_ComputerSystemProduct; $lap=($cs.PCSystemType -eq 2); $pre=($cs.Manufacturer -match 'Dell|Hewlett|\bHP\b|Lenovo|Acer|Fujitsu|Alienware|Razer|Microsoft|Samsung|Toshiba'); $mdl=$cs.Model; if(($cs.Manufacturer -match 'LENOVO') -and -not (Bad $csp.Version)){ $mdl=$csp.Version }; $mbl='Motherboard'; if(($lap -or $pre) -and -not (Bad $mdl)){ $mbv=(Brand $cs.Manufacturer)+' '+(Clean $mdl); if($lap){ $mbl='Laptop' } } elseif(-not (Bad $bb.Product)){ $mbv=(Brand $bb.Manufacturer)+' '+(Clean $bb.Product) } elseif(-not (Bad $mdl)){ $mbv=(Brand $cs.Manufacturer)+' '+(Clean $mdl) } else { $mbv='Unknown (not reported by BIOS)' }; $mbv=$mbv.Trim(); Add-Row $mbl $mbv; $bi=Get-CimInstance Win32_BIOS; $bd=''; if($bi.ReleaseDate){ $bd='  ('+([datetime]$bi.ReleaseDate).ToString('yyyy-MM-dd',[Globalization.CultureInfo]::InvariantCulture)+')' }; Add-Row 'BIOS' ((Clean $bi.SMBIOSBIOSVersion)+$bd);"
set "FT_PART4=$mem=@(Get-CimInstance Win32_PhysicalMemory); if($mem.Count -gt 0){ $tot=($mem|Measure-Object Capacity -Sum).Sum; $ty=@{20='DDR';21='DDR2';24='DDR3';26='DDR4';30='LPDDR4';34='DDR5';35='LPDDR5'}[[int]$mem[0].SMBIOSMemoryType]; if(-not $ty){ $ty='' }; $sp=$mem[0].ConfiguredClockSpeed; if(-not $sp){ $sp=$mem[0].Speed }; $per=@($mem|ForEach-Object{ [math]::Round($_.Capacity/1GB) }|Select-Object -Unique); if($per.Count -eq 1){ $cfg=('{0}x{1} GB' -f $mem.Count,$per[0]) } else { $cfg=('{0} sticks' -f $mem.Count) }; $mk=([string]$mem[0].Manufacturer).Trim(); $pn=([string]$mem[0].PartNumber).Trim(); if((-not $mk) -or (@('Unknown','Undefined') -contains $mk) -or ($mk -like 'Default*') -or ($mk -match '\A[0-9A-Fa-f]{4}\z') -or ($mk -match '\A0+\z')){ $nm=$pn } else { $nm=($mk+' '+$pn).Trim() }; Add-Row 'RAM' (('{0} GB ({1})  {2} @ {3} MHz' -f [math]::Round($tot/1GB),$cfg,$ty,$sp)+'  -  '+$nm) };"
set "FT_PART5=$vr=@{}; Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}' | ForEach-Object { $rp=Get-ItemProperty $_.PSPath; $q=$rp.'HardwareInformation.qwMemorySize'; if($q -and $rp.DriverDesc){ if($q -is [byte[]]){ $q=[BitConverter]::ToUInt64($q,0) }; $vr[[string]$rp.DriverDesc]=[uint64]$q } }; $gpus=@(Get-CimInstance Win32_VideoController | Where-Object { $_.Name -notmatch 'Basic|Virtual|Remote|Parsec|Meta|Mirage|DisplayLink|Citrix|VNC' }); $gi=0; foreach($g in $gpus){ $gi++; $vm=$vr[[string]$g.Name]; if(-not $vm){ $vm=$g.AdapterRAM }; $vs=''; if($vm -ge 1GB){ $vs='  (' + [math]::Round($vm/1GB) + ' GB)' }; $gl='GPU'; if($gpus.Count -gt 1){ $gl='GPU '+$gi }; Add-Row $gl ((Clean $g.Name)+$vs) }; foreach($g in $gpus){ $dv=[string]$g.DriverVersion; if($dv){ $dd=''; $old=''; if($g.DriverDate){ $dd='  ('+([datetime]$g.DriverDate).ToString('yyyy-MM-dd')+')'; if(([datetime]$g.DriverDate) -lt (Get-Date).AddYears(-1)){ $old='  - older than 1 year' } }; if(($g.Name -match 'NVIDIA') -and ($dv.Split('.').Count -ge 4)){ $dx=$dv.Split('.')[2]+$dv.Split('.')[3]; if($dx.Length -ge 5){ $dx=$dx.Substring($dx.Length-5); $dv=$dx.Substring(0,3)+'.'+$dx.Substring(3) } }; $dl='GPU driver'; if($gpus.Count -gt 1){ $dl='GPU driver '+([array]::IndexOf($gpus,$g)+1) }; Add-Row $dl ($dv+$dd+$old) } };"
set "FT_PART6=$pm=@{}; try { Get-CimInstance -Namespace root/microsoft/windows/storage -ClassName MSFT_PhysicalDisk -ErrorAction Stop | ForEach-Object { $pm[[string]$_.DeviceId]=$_ } } catch { }; $disks=@(Get-CimInstance Win32_DiskDrive | Where-Object { $_.InterfaceType -ne 'USB' -and $_.PNPDeviceID -notmatch 'USBSTOR' } | Sort-Object { [int]$_.Index }); $di=0; foreach($dk in $disks){ $di++; $pd=$pm[[string]$dk.Index]; $dt=''; if($pd){ if($pd.BusType -eq 17){ $dt='NVMe SSD' } elseif($pd.MediaType -eq 4){ $dt='SATA SSD' } elseif($pd.MediaType -eq 3){ $dt='HDD' } }; if(-not $dt){ if($dk.PNPDeviceID -match 'NVME'){ $dt='NVMe SSD' } elseif($dk.Model -match 'SSD'){ $dt='SSD' } }; $hs=''; if($pd){ $hs=@{0='Healthy';1='Warning';2='Unhealthy'}[[int]$pd.HealthStatus] } elseif($dk.Status -eq 'OK'){ $hs='Healthy' } else { $hs=[string]$dk.Status }; $ex=(@($dt,$hs) | Where-Object { $_ }) -join ', '; $dl=(Clean $dk.Model)+'  -  '+(Sz $dk.Size); if($ex){ $dl=$dl+'  ('+$ex+')' }; Add-Row ('Storage '+$di) $dl };"
set "FT_PART7=function Qual($w,$h){ if($w -ge 7680){ '8K UHD 4320p' } elseif(($w -ge 5120) -and ($h -le 1600)){ '32:9 Ultrawide' } elseif(($w -ge 3840) -and ($h -ge 2000)){ '4K UHD 2160p' } elseif(($w -ge 3440) -and ($h -ge 1440)){ 'Ultrawide QHD' } elseif(($w -ge 2560) -and ($h -le 1100)){ 'Ultrawide FHD' } elseif($w -ge 2560){ if($h -eq 1440){ 'QHD 1440p' } else { 'QHD+' } } elseif(($w -ge 1920) -and ($h -ge 1080)){ 'Full HD 1080p' } elseif($w -ge 1600){ 'HD+ 900p' } elseif(($w -ge 1280) -and ($h -ge 720)){ 'HD 720p' } else { '' } }; function Mode($rw,$rh,$hz){ $t=''+$rw+'x'+$rh; $ql=Qual $rw $rh; if($ql){ $t=$t+' ('+$ql+')' }; if($hz -gt 1){ $t=$t+'  -  '+$hz+' Hz' }; $t }; $csrc='using System; using System.Runtime.InteropServices; public class DM { [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)] public struct DEVMODE { [MarshalAs(UnmanagedType.ByValTStr, SizeConst=32)] public string dmDeviceName; public short dmSpecVersion; public short dmDriverVersion; public short dmSize; public short dmDriverExtra; public int dmFields; public int dmPositionX; public int dmPositionY; public int dmDisplayOrientation; public int dmDisplayFixedOutput; public short dmColor; public short dmDuplex; public short dmYResolution; public short dmTTOption; public short dmCollate; [MarshalAs(UnmanagedType.ByValTStr, SizeConst=32)] public string dmFormName; public short dmLogPixels; public int dmBitsPerPel; public int dmPelsWidth; public int dmPelsHeight; public int dmDisplayFlags; public int dmDisplayFrequency; public int dmICMMethod; public int dmICMIntent; public int dmMediaType; public int dmDitherType; public int dmReserved1; public int dmReserved2; public int dmPanningWidth; public int dmPanningHeight; } [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)] public struct DD { public int cb; [MarshalAs(UnmanagedType.ByValTStr, SizeConst=32)] public string DeviceName; [MarshalAs(UnmanagedType.ByValTStr, SizeConst=128)] public string DeviceString; public int StateFlags; [MarshalAs(UnmanagedType.ByValTStr, SizeConst=128)] public string DeviceID; [MarshalAs(UnmanagedType.ByValTStr, SizeConst=128)] public string DeviceKey; } [DllImport(QQuser32.dllQQ, CharSet=CharSet.Unicode)] public static extern bool EnumDisplayDevices(string dev, uint i, ref DD d, uint f); [DllImport(QQuser32.dllQQ, CharSet=CharSet.Unicode)] public static extern bool EnumDisplaySettings(string dev, int m, ref DEVMODE dm); public static string[] Get() { System.Collections.ArrayList r = new System.Collections.ArrayList(); DD d = new DD(); d.cb = Marshal.SizeOf(d); for (uint i = 0; EnumDisplayDevices(null, i, ref d, 0); i++) { if ((d.StateFlags & 1) == 1) { DEVMODE m = new DEVMODE(); m.dmSize = (short)Marshal.SizeOf(m); if (EnumDisplaySettings(d.DeviceName, -1, ref m)) { DD n = new DD(); n.cb = Marshal.SizeOf(n); string id = QQQQ; if (EnumDisplayDevices(d.DeviceName, 0, ref n, 0)) { id = n.DeviceID; } r.Add(id + QQ|QQ + m.dmPelsWidth + QQ|QQ + m.dmPelsHeight + QQ|QQ + m.dmDisplayFrequency); } } d.cb = Marshal.SizeOf(d); } return (string[])r.ToArray(typeof(string)); } }'; $dl=@(); try { if(-not ('DM' -as [type])){ Add-Type -TypeDefinition ($csrc.Replace('QQ',[string][char]34)) }; foreach($e in @([DM]::Get())){ $q=([string]$e).Split('|'); $cd0=''; $tk=$q[0].Split('\'); if($tk.Count -ge 2){ $cd0=$tk[1] }; if([int]$q[1] -gt 0){ $dl+=,@($cd0,(Mode ([int]$q[1]) ([int]$q[2]) ([int]$q[3]))) } } } catch { }; if($dl.Count -eq 0){ foreach($gx in $gpus){ if($gx.CurrentHorizontalResolution -gt 0){ $dl+=,@('',(Mode ([int]$gx.CurrentHorizontalResolution) ([int]$gx.CurrentVerticalResolution) ([int]$gx.CurrentRefreshRate))) } } };"
set "FT_PART8=$mons=@(); try { $mons=@(Get-CimInstance -Namespace root/wmi -ClassName WmiMonitorID -ErrorAction Stop | Where-Object { $_.Active -ne $false }) } catch { }; $bp=@{}; try { Get-CimInstance -Namespace root/wmi -ClassName WmiMonitorBasicDisplayParams -ErrorAction Stop | ForEach-Object { $bp[[string]$_.InstanceName]=$_ } } catch { }; $mkm=@{GSM='LG';SAM='Samsung';DEL='Dell';AOC='AOC';GBT='Gigabyte';ACR='Acer';AUS='ASUS';MSI='MSI';BNQ='BenQ';HKC='HKC';PHL='Philips';HWP='HP';LEN='Lenovo';VSC='ViewSonic';SNY='Sony';IVM='Iiyama';NEC='NEC';BOE='BOE';AUO='AUO';LGD='LG Display';SDC='Samsung Display';TCL='TCL';XMI='Xiaomi'}; $mn=@(); $mc=@(); foreach($mo in $mons){ $nm=(-join ($mo.UserFriendlyName | Where-Object { $_ -gt 0 } | ForEach-Object { [char]$_ })).Trim(); $cd=(-join ($mo.ManufacturerName | Where-Object { $_ -gt 0 } | ForEach-Object { [char]$_ })).Trim(); $bn=$mkm[$cd]; if(-not $bn){ $bn=$cd }; if($nm){ if($nm -notmatch ('\A'+[regex]::Escape($bn))){ $nm=$bn+' '+$nm } } else { $nm=$bn+' monitor' }; $inch=''; $bq2=$bp[[string]$mo.InstanceName]; if($bq2 -and ($bq2.MaxHorizontalImageSize -gt 0) -and ($bq2.MaxVerticalImageSize -gt 0)){ $dg=[math]::Round([math]::Sqrt([math]::Pow($bq2.MaxHorizontalImageSize,2)+[math]::Pow($bq2.MaxVerticalImageSize,2))/2.54); if(($dg -ge 10) -and ($dg -le 100)){ $inch='  -  '+$dg+'-inch' } }; $mn+=($nm.Trim()+$inch); $ik=([string]$mo.InstanceName).Split('\'); $ic=''; if($ik.Count -ge 2){ $ic=$ik[1] }; $mc+=$ic }; if($mn.Count -eq 0){ for($mi=0; $mi -lt $dl.Count; $mi++){ $ml='Monitor'; if($dl.Count -gt 1){ $ml='Monitor '+($mi+1) }; Add-Row $ml $dl[$mi][1] } } else { for($mi=0; $mi -lt $mn.Count; $mi++){ $mt=$mn[$mi]; $fd=$null; foreach($x in $dl){ if($x[0] -and ($x[0] -eq $mc[$mi])){ $fd=$x[1] } }; if(-not $fd){ if($mn.Count -eq $dl.Count){ $fd=$dl[$mi][1] } elseif(($mn.Count -eq 1) -and ($dl.Count -ge 1)){ $fd=$dl[0][1] } }; if($fd){ $mt=$mt+'  -  '+$fd }; $ml='Monitor'; if($mn.Count -gt 1){ $ml='Monitor '+($mi+1) }; Add-Row $ml $mt } };"
set "FT_PART9=$nics=@(Get-CimInstance Win32_NetworkAdapter | Where-Object { $_.PhysicalAdapter -eq $true -and $_.Name -notmatch 'Virtual|VMware|VirtualBox|Hyper-V|Bluetooth|TAP|VPN|Miniport|Loopback|Tunnel|WAN' }); $ni=0; foreach($nc in $nics){ $ni++; $nt='Ethernet'; if($nc.Name -match 'Wi-?Fi|Wireless|802\.11|WLAN'){ $nt='Wi-Fi' }; $nl='Network'; if($nics.Count -gt 1){ $nl='Network '+$ni }; Add-Row $nl ((Clean $nc.Name)+'  ('+$nt+')') }; if($os){ $up=(Get-Date)-$os.LastBootUpTime; $us=('{0} days {1} hours {2} minutes' -f [int]$up.Days,$up.Hours,$up.Minutes); if($up.Days -ge 7){ $us=$us+'  (restart recommended)' }; Add-Row 'Uptime' $us };"
set "FT_PART10=$w1=[math]::Max(11,($rows|ForEach-Object{ ([string]$_[0]).Length }|Measure-Object -Maximum).Maximum); $w2=[math]::Max(7,($rows|ForEach-Object{ ([string]$_[1]).Length }|Measure-Object -Maximum).Maximum); $gd=([string][char]27)+'[38;5;220m'; $rs=([string][char]27)+'[0m'; function Ln { $gd+'+'+('-'*($w1+2))+'+'+('-'*($w2+2))+'+'+$rs }; function Rw($s1,$s2){ $gd+'|'+$rs+' '+([string]$s1).PadRight($w1)+' '+$gd+'|'+$rs+' '+([string]$s2).PadRight($w2)+' '+$gd+'|'+$rs }; Ln; Rw 'Component' 'Details'; Ln; foreach($r in $rows){ Rw ($r[0]) ($r[1]) }; Ln; if($env:FT_QFILE -and ($mbv -notmatch '\AUnknown')){ [IO.File]::WriteAllText($env:FT_QFILE,[uri]::EscapeDataString($mbv+' BIOS update')) }"
set "FT_PS=$s=((1..10)|ForEach-Object{ [Environment]::GetEnvironmentVariable('FT_PART'+$_) }) -join ' '; & ([scriptblock]::Create($s))"
set "FT_RUN_PSMODE=1"
set "FT_RUN_RAW=1"
call :run_long "System Information" "under 1 minute" "Reading stops. Nothing is changed - you can open System Information again."
for /l %%i in (1,1,10) do set "FT_PART%%i="
echo.
exit /b

rem ==================================================================
rem  9) SYSTEM REPORTS - built-in, read-only diagnostics and HTML report
rem  The diagnostic engine is PowerShell code stored at the end of this file
rem  (SR block). It runs in its own window; results of the session are kept in
rem  SR_DIR so the HTML report (option 7) can use them.
rem ==================================================================
:Diagnostics
call :header "9) SYSTEM REPORTS"
echo    %cC%[%cW%1%cC%]%cX% %cC%●%cX% System Health Report        %cD%- Windows, hardware, storage and detected issues%cX%
echo    %cC%[%cW%2%cC%]%cX% %cC%●%cX% System Error Analyzer       %cD%- Analyze System and Application event logs%cX%
echo    %cC%[%cW%3%cC%]%cX% %cC%●%cX% Crash ^& BSOD Analyzer       %cD%- App crashes, bugchecks, restarts and dumps%cX%
echo    %cC%[%cW%4%cC%]%cX% %cC%●%cX% Recent Critical/Error Events %cD%- Quick view of the last 24 hours%cX%
echo    %cC%[%cW%5%cC%]%cX% %cC%●%cX% Reliability History         %cD%- Failures and incidents over time%cX%
echo    %cC%[%cW%6%cC%]%cX% %cC%●%cX% Gaming Diagnostics          %cD%- Game crashes and related system evidence%cX%
echo    %cC%[%cW%0%cC%]%cX% %cC%●%cX% Back to main menu
echo.
set "M="
set /p "M=  Select an option: "
if "%M%"=="0" goto :MAIN_MENU
if "%M%"=="1" goto :SR_HEALTH
if "%M%"=="2" goto :SR_ERRORS
if "%M%"=="3" goto :SR_CRASH
if "%M%"=="4" goto :SR_RECENT
if "%M%"=="5" goto :SR_RELIABILITY
if "%M%"=="6" goto :SR_GAMING
goto :Diagnostics

:SR_HEALTH
call :sr_run Health
goto :Diagnostics

:SR_ERRORS
call :sr_run Errors
goto :Diagnostics

:SR_CRASH
call :sr_run Crash
goto :Diagnostics

:SR_RECENT
call :sr_run Recent
goto :Diagnostics

:SR_RELIABILITY
call :sr_run Reliability
goto :Diagnostics

:SR_GAMING
call :sr_run Gaming
goto :Diagnostics

rem --- Cuts the System Reports engine (SR block at the end of this file) into a temp .ps1 once per session ---
:sr_prepare
if not defined SR_DIR set "SR_DIR=%TEMP%\MeshalFix_Session_%RANDOM%%RANDOM%"
if not exist "%SR_DIR%\" mkdir "%SR_DIR%" >nul 2>&1
if not exist "%SR_DIR%\" exit /b 1
set "FT_SELF=%SCRIPT%"
set "FT_SRPS=%SR_DIR%\sysreports_engine.ps1"
if defined SR_READY if exist "%FT_SRPS%" exit /b 0
del /f /q "%FT_SRPS%" >nul 2>&1
set "FT_PS=$t=[IO.File]::ReadAllText($env:FT_SELF,[Text.Encoding]::UTF8); $i=$t.LastIndexOf('#SR_'+'BEGIN'); $j=$t.LastIndexOf('#SR_'+'END'); if($i -lt 0 -or $j -le $i){exit 2}; $b=$t.Substring($i+9,$j-$i-9); [IO.File]::WriteAllText($env:FT_SRPS,$b,(New-Object Text.UTF8Encoding $true))"
call :psx
if not exist "%FT_SRPS%" exit /b 1
set "SR_READY=1"
exit /b 0

rem --- Runs one System Reports mode (%~1) in its own PowerShell window, then offers to open a report if one was saved ---
:sr_run
call :sr_prepare
if errorlevel 1 (
    call :err "Could not prepare the System Reports engine."
    call :pause
    exit /b 1
)
set "FT_LOGDIR=%LOGDIR%"
set "FT_LOGFILE=%LOGFILE%"
del /f /q "%SR_DIR%\last_report.txt" >nul 2>&1
call :log "System Reports - %~1 started"
start "MeshalFix System Reports" /wait powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%FT_SRPS%" -Mode %~1
set "SR_RC=%errorlevel%"
call :log "System Reports - %~1 closed, exit code !SR_RC!"
if exist "%SR_DIR%\last_report.txt" (
    call :sr_open_prompt
) else if "!SR_RC!"=="1" (
    call :err "The diagnostic stopped with an error, or the report could not be saved. Details are in the log: !LOGFILE!"
    call :pause
)
exit /b 0

rem --- A report file was written by the engine: show where, then ask whether to open it ---
:sr_open_prompt
call :header "HTML REPORT"
setlocal DisableDelayedExpansion
set "SR_RPT="
for /f "usebackq delims=" %%L in ("%SR_DIR%\last_report.txt") do set "SR_RPT=%%L"
endlocal & set "SR_REPORT=%SR_RPT%"
if not defined SR_REPORT (
    call :err "The report path could not be read, so the report will not be opened."
    call :pause
    exit /b 1
)
if not exist "!SR_REPORT!" (
    call :err "The report file was not found on disk, so it will not be opened."
    call :pause
    exit /b 1
)
call :ok "HTML report saved:"
echo     !SR_REPORT!
call :log "HTML report saved: !SR_REPORT!"
echo.
:sr_open_ask
set "SR_ANS="
set /p "SR_ANS=  Diagnostics completed. Would you like to open the HTML report in your browser? [Y/N] "
if /i "!SR_ANS!"=="Y" goto :sr_open_go
if /i "!SR_ANS!"=="N" (
    call :info "The report was not opened. It stays in the logs folder."
    call :pause
    exit /b 0
)
call :info "Please enter Y or N."
goto :sr_open_ask
:sr_open_go
call :info "Asking Windows to open the report in your default browser..."
start "" "!SR_REPORT!"
if errorlevel 1 (
    call :warn "Windows reported a problem starting the browser. Open the file manually from the path shown above."
) else (
    call :info "The open request was sent to Windows. If nothing opens, open the file manually from the path shown above."
)
call :pause
exit /b 0









rem ==================================================================
rem  11) RESTORE POINT
rem ==================================================================
:RESTORE_POINT
call :header "11) CREATE RESTORE POINT"
echo   A restore point lets you roll Windows back if a fix causes problems.
echo.
call :confirm "Create a system restore point now?"
if "%CONFIRMED%"=="1" call :make_rp
call :pause
goto :MAIN_MENU

rem --- Offers a restore point once per session before risky sections ---
:offer_rp
if defined RP_DONE exit /b
call :header "RESTORE POINT RECOMMENDED"
echo   The next section changes system files or settings.
echo   A restore point lets you go back if something goes wrong.
echo.
call :confirm "Create a restore point now? Recommended."
set "RP_DONE=1"
if "%CONFIRMED%"=="1" (
    call :make_rp
    call :pause
)
exit /b

rem --- Enables System Restore and creates a restore point ---
:make_rp
set "RP_OK=0"
call :step 1 2 "Making sure System Restore is enabled..."
set "FT_PS=try { Enable-ComputerRestore -Drive '%SystemDrive%\' -ErrorAction Stop; exit 0 } catch { exit 1 }"
call :psx
if errorlevel 1 call :warn "Could not enable System Restore - it may be blocked by policy. Trying anyway..."
call :step 2 2 "Creating the restore point - this can take a minute..."
set "FT_PS=try { Checkpoint-Computer -Description ('FixToolkit - ' + (Get-Date).ToString('yyyy-MM-dd HH:mm', [cultureinfo]::InvariantCulture)) -RestorePointType MODIFY_SETTINGS -ErrorAction Stop; exit 0 } catch { Write-Host $_.Exception.Message; exit 1 }"
set "FT_SHOW=1"
call :psx
if errorlevel 1 (
    call :err "No restore point was created. Windows allows only one every 24 hours by default, or System Restore is off."
) else (
    set "RP_OK=1"
    call :ok "Restore point created."
)
exit /b


rem ==================================================================
rem  SHARED HELPER ROUTINES
rem ==================================================================

rem --- Runs a tool label (%~1) with a clean screen and a pause afterwards ---
:run_tool
if "%~1"=="" exit /b
call :header "WORKING"
call :%~1
call :pause
exit /b

rem --- Draws the Meshal ASCII banner (same look as the main menu) ---
:banner
cls
echo   %cC%┌────────────────────────────────────────────────────────────────────────┐
echo   %cC%│                                                                        │
echo   %cC%│%cW% ███╗   ███╗███████╗███████╗██╗  ██╗ █████╗ ██╗     ███████╗██╗██╗  ██╗ %cC%│%cW%
echo   %cC%│%cW% ████╗ ████║██╔════╝██╔════╝██║  ██║██╔══██╗██║     ██╔════╝██║╚██╗██╔╝ %cC%│%cW%
echo   %cC%│%cW% ██╔████╔██║█████╗  ███████╗███████║███████║██║     █████╗  ██║ ╚███╔╝  %cC%│%cW%
echo   %cC%│%cW% ██║╚██╔╝██║██╔══╝  ╚════██║██╔══██║██╔══██║██║     ██╔══╝  ██║ ██╔██╗  %cC%│%cW%
echo   %cC%│%cW% ██║ ╚═╝ ██║███████╗███████║██║  ██║██║  ██║███████╗██║     ██║██╔╝ ██╗ %cC%│%cW%
echo   %cC%│%cW% ╚═╝     ╚═╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝ %cC%│%cW%
echo   %cC%│                                                                        │
echo   %cC%└────────────────────────────────────────────────────────────────────────┘
echo.
exit /b

rem --- Draws the banner, then the title of the current menu, date/time and Windows version ---
:header
call :banner
echo    %cC%■%cX% %cW%%~1%cX%
echo    %cD%!TODAY! %time:~0,8%   -   !WINVER!%cX%
echo.
exit /b

rem --- Small header (no big logo) for screens with a lot of output, so the title never scrolls away ---
:header_compact
cls
echo    %cC%■%cX% %cW%MESHAL FIX%cX% %cD%-%cX% %cW%%~1%cX%   %cD%!TODAY! %time:~0,8%   -   !WINVER!%cX%
echo   %cC%──────────────────────────────────────────────────────────────────────────%cX%
exit /b

rem --- Writes a line with timestamp to the log file ---
:log
>>"%LOGFILE%" echo [%TODAY% %time: =0%] %~1
exit /b

rem --- Status messages (also logged) ---
:step
echo   %cC%[%~1/%~2]%cX% %~3
call :log "STEP %~1/%~2 - %~3"
exit /b

:ok
echo   %cG%[ OK ]%cX% %~1
call :log "OK - %~1"
exit /b

:warn
echo   %cY%[WARN]%cX% %~1
call :log "WARN - %~1"
exit /b

:err
echo   %cE%[FAIL]%cX% %~1
call :log "ERROR - %~1"
exit /b

:info
echo   %cC%[INFO]%cX% %~1
call :log "INFO - %~1"
exit /b

rem --- Y/N confirmation. Result is stored in CONFIRMED (1 = yes, 0 = no) ---
:confirm
echo.
echo   %cY%[?]%cX% %~1
:confirm_input
set "M="
set /p "M=      Continue? [Y/N]: "
if /i "%M%"=="Y" (set "CONFIRMED=1") else if /i "%M%"=="N" (set "CONFIRMED=0") else (
    call :info "Please enter Y or N."
    goto :confirm_input
)
call :log "Confirm answer for: %~1 = !CONFIRMED!"
echo.
exit /b

rem --- Same as confirm, but skipped automatically in Run ALL mode ---
:ask
set "CONFIRMED=1"
if defined ALLMODE exit /b
call :confirm %1
exit /b

rem --- Waits for a key press before returning to a menu ---
:pause
echo.
echo   %cD%Press any key to return to the menu...%cX%
pause >nul
exit /b

rem --- Builds a safe timestamp (yyyyMMdd_HHmmss) in STAMP ---
:stamp
set "STAMP=backup"
set "FT_PS=(Get-Date).ToString('yyyyMMdd_HHmmss', [cultureinfo]::InvariantCulture)"
call :psx
for /f "usebackq delims=" %%S in ("%FT_OUT%") do set "STAMP=%%S"
exit /b

rem --- Checks which of the given process names are running (RUNNING_LIST) ---
:check_running
set "RUNNING_LIST="
for %%P in (%*) do (
    tasklist /fi "imagename eq %%P" 2>nul | find /i "%%P" >nul && set "RUNNING_LIST=!RUNNING_LIST! %%P"
)
exit /b

rem --- Runs PowerShell code (variable FT_PS) in its OWN minimized window, so it can never resize
rem --- or damage this console. Output goes to FT_OUT. Set FT_SHOW=1 to print the output afterwards.
rem --- The PowerShell exit code is returned as errorlevel.
:psx
type nul > "%FT_OUT%"
start "" /wait /min cmd /c powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "[Console]::OutputEncoding=New-Object System.Text.UTF8Encoding $false; & ([scriptblock]::Create($env:FT_PS))" ^> "%FT_OUT%" 2^>^&1
set "FT_RC=%errorlevel%"
if defined FT_SHOW type "%FT_OUT%"
set "FT_SHOW="
exit /b %FT_RC%

rem --- Extracts the progress-bar runner (block #RN_BEGIN at the end of this file) into a temp .ps1 ---
:runner_prep
set "FT_SELF=%SCRIPT%"
set "FT_RNPS=%TEMP%\FixToolkit_runner.ps1"
if defined RN_READY if exist "%FT_RNPS%" exit /b
del /f /q "%FT_RNPS%" >nul 2>&1
set "FT_PS=$t=[IO.File]::ReadAllText($env:FT_SELF,[Text.Encoding]::UTF8); $i=$t.LastIndexOf('#RN_'+'BEGIN'); $j=$t.LastIndexOf('#RN_'+'END'); if($i -lt 0 -or $j -le $i){exit 2}; $b=$t.Substring($i+9,$j-$i-9); [IO.File]::WriteAllText($env:FT_RNPS,$b,(New-Object Text.UTF8Encoding $true))"
call :psx
if exist "%FT_RNPS%" set "RN_READY=1"
exit /b

rem --- Runs a LONG command with a loading bar and a Cancel key (press C, then Y).
rem --- Input : RUN_CMD = the command line; %~1 = title; %~2 = expected time; %~3 = what cancelling means.
rem --- Result: errorlevel and RL_RC = exit code of the command (1223 = cancelled by the user);
rem ---         RUN_CANCELLED = 1 when the user cancelled, otherwise 0. The command output is printed afterwards.
:run_long
set "RUN_CANCELLED=0"
set "RL_RC=1"
set "RL_SAVE_PS=!FT_PS!"
call :runner_prep
set "FT_PS=!RL_SAVE_PS!"
set "RL_SAVE_PS="
set "FT_RUN_TITLE=%~1"
set "FT_RUN_HINT=%~2"
set "FT_RUN_WARN=%~3"
set "FT_RUN_CMD=!RUN_CMD!"
set "FT_RUN_OUT=%TEMP%\FixToolkit_run_out.txt"
set "FT_RUN_RCFILE=%TEMP%\FixToolkit_run_rc.txt"
set "FT_RUN_LOGFILE=%LOGFILE%"
del /f /q "%FT_RUN_OUT%" "%FT_RUN_RCFILE%" >nul 2>&1
call :log "RUN - %~1"
if not exist "%FT_RNPS%" (
    rem --- runner could not be prepared: run the command the old way (no bar, no cancel) ---
    call :warn "Loading bar is not available - running without it."
    if "!FT_RUN_PSMODE!"=="1" (
        set "FT_SHOW=1"
        call :psx
        set "RL_RC=!errorlevel!"
    ) else (
        cmd /d /s /c "!RUN_CMD!"
        set "RL_RC=!errorlevel!"
    )
) else (
    start "MeshalFix progress" /wait powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%FT_RNPS%"
    if exist "%FT_RUN_RCFILE%" set /p RL_RC=<"%FT_RUN_RCFILE%"
    if exist "%FT_RUN_OUT%" type "%FT_RUN_OUT%"
)
if "!RL_RC!"=="1223" set "RUN_CANCELLED=1"
if "!RUN_CANCELLED!"=="1" call :warn "Cancelled by you - the task was stopped."
set "RUN_CMD="
set "FT_RUN_TITLE="
set "FT_RUN_HINT="
set "FT_RUN_WARN="
set "FT_RUN_CMD="
set "FT_RUN_PSMODE="
set "FT_RUN_RAW="
exit /b !RL_RC!

rem --- Downloads a file. %~1 = NAME of a variable that holds the URL, %~2 = destination file.
rem --- Uses curl.exe (built into Windows 10/11) and falls back to PowerShell.
:download
set "DL_URL=!%~1!"
del /f /q "%~2" >nul 2>&1
where curl.exe >nul 2>&1
if not errorlevel 1 (
    if defined DL_REF (
        set "RUN_CMD=curl.exe -L --fail --retry 3 --connect-timeout 20 -A "Mozilla/5.0" -e "!DL_REF!" -# -o "%~2" "!DL_URL!""
    ) else (
        set "RUN_CMD=curl.exe -L --fail --retry 3 --connect-timeout 20 -A "Mozilla/5.0" -# -o "%~2" "!DL_URL!""
    )
    call :run_long "Downloading" "depends on your internet speed" "The download stops and the file is not saved. You can start it again later."
    if "!RUN_CANCELLED!"=="1" (
        del /f /q "%~2" >nul 2>&1
        exit /b 1223
    )
    if "!RL_RC!"=="0" exit /b 0
    call :warn "curl could not download the file. Trying PowerShell..."
)
set "FT_PS=$ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -UseBasicParsing -Uri '!DL_URL!' -OutFile '%~2' -UserAgent 'Mozilla/5.0' -ErrorAction Stop; exit 0 } catch { Write-Host $_.Exception.Message; exit 1 }"
set "FT_SHOW=1"
call :psx
exit /b %errorlevel%

rem --- Checks that file %~1 exists and is at least %~2 bytes (errorlevel 0 = yes) ---
:check_size
set "FSZ=0"
if exist "%~1" for %%Z in ("%~1") do set "FSZ=%%~zZ"
if %FSZ% LSS %~2 exit /b 1
exit /b 0


rem ==================================================================
rem  RESTORE ENGINE (PowerShell). Never executed by cmd: the batch file
rem  ends here and the Restore menu copies the block below into a temp
rem  .ps1 file. Do not put anything else after this line.
rem ==================================================================
exit /b
#RST_BEGIN
# ====================================================================
#  FixToolkit restore engine. Started only by the Restore menu.
#  Every restore here uses a known, documented default or a built-in
#  Windows reset command. Nothing is guessed. ASCII only on purpose.
#  Preview mode only reports. Apply mode backs up first, changes,
#  then checks again so a failed change is never reported as OK.
# ====================================================================
$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false

$Section  = $env:FT_SECTION
$Apply    = ($env:FT_MODE -eq 'Apply')
$LogDir   = $env:FT_LOGDIR
$ToolsDir = $env:FT_TOOLS
$Stamp    = (Get-Date).ToString('yyyyMMdd_HHmmss', [cultureinfo]::InvariantCulture)

$script:Items = New-Object System.Collections.ArrayList
$script:Will = 0
$script:RestartExplorer = $false
$script:BcdBackup = $false

function Say([string]$Tag, [string]$Msg) {
    $m = ($Msg -replace '[\r\n]+', ' ') -replace '"', "'"
    $m = $m.Replace('!', '.')
    [Console]::WriteLine('[' + $Tag + '] ' + $m)
}

function Add-Skip([string]$Msg) { Say 'SKIP' $Msg }

# Need  = scriptblock(param($a)) -> returns $null when already default, else a text describing the change
# Do    = scriptblock(param($a)) -> makes the change (throw on failure, return 'SKIP:text' to skip)
function Add-Item([string]$Desc, [scriptblock]$Need, [scriptblock]$Do, $Arg, [bool]$Verify = $true) {
    [void]$script:Items.Add([pscustomobject]@{ Desc = $Desc; Need = $Need; Do = $Do; Arg = $Arg; Verify = $Verify })
}

function Run-Items {
    $already = 0
    foreach ($it in $script:Items) {
        $need = $null
        try { $need = & $it.Need $it.Arg }
        catch { Say 'ERROR' ('Could not check ' + $it.Desc + ': ' + $_.Exception.Message); continue }
        if (-not $need) { $already++; continue }
        if (-not $Apply) { Say 'WILL' ($it.Desc + ': ' + [string]$need); $script:Will++; continue }
        try {
            $res = @(& $it.Do $it.Arg)
            $last = $null
            if ($res.Count -gt 0) { $last = $res[$res.Count - 1] }
            if (($last -is [string]) -and $last.StartsWith('SKIP:')) { Say 'SKIP' ($it.Desc + ' - ' + $last.Substring(5)); continue }
            if ($it.Verify) {
                $after = & $it.Need $it.Arg
                if ($after) { Say 'ERROR' ($it.Desc + ' - the change did not take effect (' + [string]$after + ')'); continue }
            }
            Say 'OK' $it.Desc
        }
        catch { Say 'ERROR' ($it.Desc + ' - ' + $_.Exception.Message) }
    }
    if ($already -gt 0) { Say 'INFO' ([string]$already + ' item(s) already match the default and are left alone') }
}

# Saves a registry key to the log folder with reg.exe. Throws when the backup fails.
function Backup-Key([string]$RegPath, [string]$Tag) {
    $f = Join-Path $LogDir ('restore_backup_' + $Tag + '_' + $Stamp + '.reg')
    $o = & reg.exe export $RegPath $f /y 2>&1
    if (($LASTEXITCODE -ne 0) -or (-not (Test-Path -LiteralPath $f))) { throw ('could not back up ' + $RegPath + ' first, so nothing was changed') }
    Say 'INFO' ('Backup saved: ' + $f)
}

function Restart-Explorer {
    Get-Process -Name explorer -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) { Start-Process -FilePath 'explorer.exe' }
    Say 'INFO' 'Windows Explorer was restarted to apply the changes'
}

# Registry value that must equal a documented default. $a = @(key path, value name, default, label)
$ValueNeed = {
    param($a)
    $p = Get-ItemProperty -LiteralPath $a[0] -ErrorAction SilentlyContinue
    if ($p -eq $null) { return $null }
    $v = $p.($a[1])
    if ($v -eq $null) { return $null }
    if ([int]$v -eq [int]$a[2]) { return $null }
    return ('currently ' + [string]$v + ', default is ' + [string]$a[2])
}
$ValueDo = {
    param($a)
    Set-ItemProperty -LiteralPath $a[0] -Name $a[1] -Value ([int]$a[2]) -Type DWord -ErrorAction Stop
    $script:RestartExplorer = $true
}

# ---------------------------------------------------------------- services
# Start type of a service. $Want is 'Automatic', 'Automatic (Delayed)' or 'Manual'.
function Add-ServiceDefault([string]$Name, [string]$Want) {
    $key = 'HKLM:\SYSTEM\CurrentControlSet\Services\' + $Name
    if (-not (Test-Path -LiteralPath $key)) { Add-Skip ('Service ' + $Name + ' is not installed on this PC'); return }
    Add-Item ('Service ' + $Name) {
        param($a)
        $p = Get-ItemProperty -LiteralPath ('HKLM:\SYSTEM\CurrentControlSet\Services\' + $a[0]) -ErrorAction Stop
        $cur = switch ([int]$p.Start) {
            2 { if ($p.DelayedAutostart -eq 1) { 'Automatic (Delayed)' } else { 'Automatic' } }
            3 { 'Manual' }
            4 { 'Disabled' }
            default { 'Other' }
        }
        if ($cur -eq $a[1]) { return $null }
        return ('start type ' + $cur + ' -> ' + $a[1])
    } {
        param($a)
        $n = $a[0]
        $m = switch ($a[1]) { 'Automatic' { 'auto' } 'Automatic (Delayed)' { 'delayed-auto' } 'Manual' { 'demand' } }
        $o = & sc.exe config $n start= $m 2>&1
        if ($LASTEXITCODE -ne 0) { throw ('sc.exe failed with code ' + $LASTEXITCODE) }
    } @($Name, $Want)
}

function Section-Services {
    # Only services whose default start type is the same on Windows 10 and 11 (Home and Pro).
    # Protected services (Defender, Firewall, BFE, RPC) are not touched here on purpose.
    $t = @(
        @('CryptSvc', 'Automatic'), @('Dhcp', 'Automatic'), @('Dnscache', 'Automatic'), @('EventLog', 'Automatic'),
        @('Winmgmt', 'Automatic'), @('Schedule', 'Automatic'), @('Themes', 'Automatic'), @('Spooler', 'Automatic'),
        @('Audiosrv', 'Automatic'), @('AudioEndpointBuilder', 'Automatic'), @('SysMain', 'Automatic'),
        @('WSearch', 'Automatic (Delayed)'), @('wscsvc', 'Automatic (Delayed)'),
        @('wuauserv', 'Manual'), @('BITS', 'Manual'), @('msiserver', 'Manual'), @('W32Time', 'Manual'),
        @('TrustedInstaller', 'Manual'), @('XblAuthManager', 'Manual'), @('XblGameSave', 'Manual'),
        @('XboxNetApiSvc', 'Manual'), @('XboxGipSvc', 'Manual')
    )
    foreach ($e in $t) { Add-ServiceDefault $e[0] $e[1] }
    Say 'INFO' 'Only start types are restored. Running services are not started or stopped.'
}

# ----------------------------------------------------------------- network
function Section-Network {
    $ads = @()
    try { $ads = @(Get-NetAdapter -Physical -ErrorAction Stop) } catch { $ads = @() }
    if ($ads.Count -eq 0) { Add-Skip 'No physical network adapter was found, the DNS check was skipped' }
    foreach ($ad in $ads) {
        Add-Item ('DNS servers on adapter ' + $ad.Name) {
            param($a)
            $found = @()
            foreach ($fam in @('Tcpip', 'Tcpip6')) {
                $k = 'HKLM:\SYSTEM\CurrentControlSet\Services\' + $fam + '\Parameters\Interfaces\' + $a[1]
                if (Test-Path -LiteralPath $k) {
                    $v = (Get-ItemProperty -LiteralPath $k -ErrorAction Stop).NameServer
                    if ($v) { $found += [string]$v }
                }
            }
            if ($found.Count -eq 0) { return $null }
            return ('manual DNS ' + ($found -join ' ; ') + ' -> automatic')
        } {
            param($a)
            Set-DnsClientServerAddress -InterfaceIndex $a[0] -ResetServerAddresses -ErrorAction Stop
        } @($ad.ifIndex, $ad.InterfaceGuid)
    }
    Add-Item 'Winsock catalog' { param($a) 'reset to default, restart needed' } {
        param($a)
        $o = & netsh.exe winsock reset 2>&1
        if ($LASTEXITCODE -ne 0) { throw ('netsh failed with code ' + $LASTEXITCODE) }
    } $null $false
    Add-Item 'TCP/IP stack' { param($a) 'reset to default, restart needed' } {
        param($a)
        $o = & netsh.exe int ip reset 2>&1
        if ($LASTEXITCODE -ne 0) { throw ('netsh failed with code ' + $LASTEXITCODE) }
    } $null $false
    Add-Item 'WinHTTP proxy' { param($a) 'reset to direct access' } {
        param($a)
        $o = & netsh.exe winhttp reset proxy 2>&1
        if ($LASTEXITCODE -ne 0) { throw ('netsh failed with code ' + $LASTEXITCODE) }
    } $null $false
    Add-Item 'DNS resolver cache' { param($a) 'flush' } {
        param($a)
        $o = & ipconfig.exe /flushdns 2>&1
        if ($LASTEXITCODE -ne 0) { throw ('ipconfig failed with code ' + $LASTEXITCODE) }
    } $null $false
    Say 'INFO' 'Static IP settings, the hosts file and Wi-Fi profiles are not touched.'
}

# ---------------------------------------------------------------- firewall
function Section-Firewall {
    try {
        $pr = @(Get-NetFirewallProfile -ErrorAction Stop | ForEach-Object { $_.Name + '=' + $_.Enabled })
        Say 'INFO' ('Current profiles: ' + ($pr -join ', '))
    } catch { Say 'INFO' 'Could not read the current firewall profiles' }
    Add-Item 'Windows Firewall rules and profiles' {
        param($a) 'reset to the Windows defaults, custom rules are removed, a backup is saved first'
    } {
        param($a)
        $f = Join-Path $LogDir ('firewall_backup_' + $Stamp + '.wfw')
        $o = & netsh.exe advfirewall export $f 2>&1
        if (($LASTEXITCODE -ne 0) -or (-not (Test-Path -LiteralPath $f))) { throw 'the backup failed, so the reset was cancelled' }
        Say 'INFO' ('Backup saved: ' + $f)
        $o = & netsh.exe advfirewall reset 2>&1
        if ($LASTEXITCODE -ne 0) { throw ('netsh advfirewall reset failed with code ' + $LASTEXITCODE) }
    } $null $false
}

# ---------------------------------------------------------- windows update
function Section-WinUpdate {
    Add-ServiceDefault 'wuauserv' 'Manual'
    Add-ServiceDefault 'BITS' 'Manual'
    $base = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
    Add-Item 'Windows Update policy overrides' {
        param($a)
        if (-not (Test-Path -LiteralPath $a)) { return $null }
        $keys = @(Get-Item -LiteralPath $a) + @(Get-ChildItem -LiteralPath $a -Recurse -ErrorAction SilentlyContinue)
        $names = @()
        foreach ($k in $keys) { foreach ($n in $k.GetValueNames()) { if ($n) { $names += $n } } }
        if ($names.Count -eq 0) { return $null }
        return ('remove ' + [string]$names.Count + ' policy value(s) such as ' + (($names | Select-Object -First 6) -join ', ') + ' -> Not configured')
    } {
        param($a)
        Backup-Key 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' 'wu_policies'
        Remove-Item -LiteralPath $a -Recurse -Force -ErrorAction Stop
    } $base
    Say 'INFO' 'If a company or school policy manages this PC, it may apply these policies again.'
}

# ------------------------------------------------------------------- power
function Section-Power {
    try {
        $act = (& powercfg.exe /getactivescheme 2>&1) -join ' '
        Say 'INFO' ('Current plan: ' + $act)
        foreach ($l in (& powercfg.exe /list 2>&1)) {
            $s = ([string]$l).Trim()
            if ($s -match '[0-9a-fA-F]{8}-') { Say 'INFO' ('Plan: ' + $s) }
        }
    } catch { }
    Add-Item 'Power plans' {
        param($a) 'restore the built-in Windows plans, plans you created are removed'
    } {
        param($a)
        $o = & powercfg.exe /restoredefaultschemes 2>&1
        if ($LASTEXITCODE -ne 0) { throw ('powercfg failed with code ' + $LASTEXITCODE) }
    } $null $false
}

# ---------------------------------------------------------------- security
function Section-Security {
    $mp = $null
    $st = $null
    try {
        $mp = Get-MpPreference -ErrorAction Stop
        $st = Get-MpComputerStatus -ErrorAction Stop
    } catch { $mp = $null }

    if ($mp -eq $null) {
        Add-Skip 'Windows Defender is not available here, another antivirus may manage protection'
    } else {
        $passive = $false
        try { if ([string]$st.AMRunningMode -match 'Passive') { $passive = $true } } catch { }
        try { Say 'INFO' ('Tamper Protection is ' + $(if ($st.IsTamperProtected) { 'ON, Windows may refuse some changes' } else { 'OFF' })) } catch { }

        # Group Policy values that tweak tools use to switch Defender off. Removing them = Not configured.
        $dp = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender'
        $rt = $dp + '\Real-Time Protection'
        $pairs = @(
            @($dp, 'DisableAntiSpyware'), @($dp, 'DisableAntiVirus'),
            @($rt, 'DisableRealtimeMonitoring'), @($rt, 'DisableBehaviorMonitoring'),
            @($rt, 'DisableIOAVProtection'), @($rt, 'DisableOnAccessProtection'), @($rt, 'DisableScriptScanning')
        )
        Add-Item 'Defender policy overrides' {
            param($a)
            $hit = @()
            foreach ($e in $a) {
                if (Test-Path -LiteralPath $e[0]) {
                    if ((Get-Item -LiteralPath $e[0]).GetValueNames() -contains $e[1]) { $hit += $e[1] }
                }
            }
            if ($hit.Count -eq 0) { return $null }
            return ('remove ' + ($hit -join ', ') + ' -> Not configured')
        } {
            param($a)
            Backup-Key 'HKLM\SOFTWARE\Policies\Microsoft\Windows Defender' 'defender_policy'
            foreach ($e in $a) {
                if (Test-Path -LiteralPath $e[0]) {
                    if ((Get-Item -LiteralPath $e[0]).GetValueNames() -contains $e[1]) {
                        Remove-ItemProperty -LiteralPath $e[0] -Name $e[1] -ErrorAction Stop
                    }
                }
            }
        } $pairs

        if ($passive) {
            Add-Skip 'Defender is in passive mode because another antivirus is active, its protection switches are left alone'
        } else {
            $names = @(
                @('DisableRealtimeMonitoring', 'Real-time protection'),
                @('DisableBehaviorMonitoring', 'Behavior monitoring'),
                @('DisableIOAVProtection', 'Scanning of downloaded files and attachments'),
                @('DisableScriptScanning', 'Script scanning'),
                @('DisableBlockAtFirstSeen', 'Block at first sight')
            )
            foreach ($e in $names) {
                Add-Item ('Defender ' + $e[1]) {
                    param($a)
                    $v = (Get-MpPreference -ErrorAction Stop).($a[0])
                    if ($v -eq $true) { return 'currently OFF -> ON' }
                    return $null
                } {
                    param($a)
                    $h = @{}
                    $h[$a[0]] = $false
                    Set-MpPreference @h -ErrorAction Stop
                } @($e[0], $e[1])
            }
        }

        if ($ToolsDir) {
            Add-Item 'Defender exclusion for the toolkit Tools folder' {
                param($a)
                $ex = @((Get-MpPreference -ErrorAction Stop).ExclusionPath) | Where-Object { $_ -and ($_.TrimEnd('\') -ieq $a.TrimEnd('\')) }
                if (@($ex).Count -gt 0) { return 'remove the exclusion, do this only when Tron is NOT running' }
                return $null
            } {
                param($a)
                $ex = @((Get-MpPreference -ErrorAction Stop).ExclusionPath) | Where-Object { $_ -and ($_.TrimEnd('\') -ieq $a.TrimEnd('\')) }
                foreach ($x in $ex) { Remove-MpPreference -ExclusionPath $x -ErrorAction Stop }
            } $ToolsDir
        }
    }

    # User Account Control: documented Windows defaults. Only changed when the value exists and differs.
    $uac = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
    Add-Item 'UAC: run all administrators in Admin Approval Mode, restart needed' $ValueNeed $ValueDo @($uac, 'EnableLUA', 1)
    Add-Item 'UAC: prompt level for administrators' $ValueNeed $ValueDo @($uac, 'ConsentPromptBehaviorAdmin', 5)
    Add-Item 'UAC: show the prompt on the secure desktop' $ValueNeed $ValueDo @($uac, 'PromptOnSecureDesktop', 1)
}

# ---------------------------------------------------------------- explorer
function Section-Explorer {
    $adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    Add-Item 'Hidden files and folders: do not show them' $ValueNeed $ValueDo @($adv, 'Hidden', 2)
    Add-Item 'File name extensions: hide them for known types' $ValueNeed $ValueDo @($adv, 'HideFileExt', 1)
    Add-Item 'Protected operating system files: hide them' $ValueNeed $ValueDo @($adv, 'ShowSuperHidden', 0)

    $shell = 'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell'
    Add-Item 'Saved folder views (view mode, sorting, columns)' {
        param($a)
        foreach ($k in $a) { if (Test-Path -LiteralPath $k) { return 'reset every folder to the default view, open Explorer windows will close' } }
        return $null
    } {
        param($a)
        foreach ($k in $a) {
            if (Test-Path -LiteralPath $k) { Backup-Key $k.Replace('HKCU:\', 'HKCU\') ('folderviews_' + (Split-Path $k -Leaf)) }
        }
        Get-Process -Name explorer -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 800
        foreach ($k in $a) {
            if (Test-Path -LiteralPath $k) { Remove-Item -LiteralPath $k -Recurse -Force -ErrorAction Stop }
        }
        $script:RestartExplorer = $true
    } @(($shell + '\Bags'), ($shell + '\BagMRU')) $false
}

# ----------------------------------------------------------- file associations
function Get-UserChoiceKeys($Roots) {
    $r = @()
    foreach ($root in $Roots) {
        if (Test-Path -LiteralPath $root) {
            foreach ($c in @(Get-ChildItem -LiteralPath $root -ErrorAction SilentlyContinue)) {
                foreach ($n in @('UserChoice', 'UserChoiceLatest')) {
                    $p = $c.PSPath + '\' + $n
                    if (Test-Path -LiteralPath $p) { $r += $p }
                }
            }
        }
    }
    return $r
}

function Section-FileAssoc {
    # Base associations of core Windows file types (documented defaults).
    $core = @(
        @('.exe', 'exefile'), @('.lnk', 'lnkfile'), @('.bat', 'batfile'), @('.cmd', 'cmdfile'), @('.com', 'comfile'),
        @('.reg', 'regfile'), @('.msi', 'Msi.Package'), @('.txt', 'txtfile'), @('.vbs', 'VBSFile'), @('.js', 'JSFile')
    )
    foreach ($e in $core) {
        Add-Item ('Core file type ' + $e[0]) {
            param($a)
            $msg = @()
            $u = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Software\Classes\' + $a[0])
            if ($u -ne $null) {
                $v = [string]$u.GetValue('')
                $u.Close()
                if (($v -ne '') -and ($v -ne $a[1])) { $msg += ('user override points to ' + $v) }
            }
            $m = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SOFTWARE\Classes\' + $a[0])
            if ($m -ne $null) {
                $v = [string]$m.GetValue('')
                $m.Close()
                if ($v -ne $a[1]) { $msg += ('system default is ' + $v) }
            }
            if ($msg.Count -eq 0) { return $null }
            return (($msg -join ' ; ') + ' -> ' + $a[1])
        } {
            param($a)
            $tag = 'assoc' + $a[0].Replace('.', '_')
            $u = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Software\Classes\' + $a[0], $true)
            if ($u -ne $null) {
                $v = [string]$u.GetValue('')
                if (($v -ne '') -and ($v -ne $a[1])) {
                    Backup-Key ('HKCU\Software\Classes\' + $a[0]) $tag
                    $u.DeleteValue('')
                }
                $u.Close()
            }
            $m = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SOFTWARE\Classes\' + $a[0], $true)
            if ($m -ne $null) {
                if ([string]$m.GetValue('') -ne $a[1]) {
                    Backup-Key ('HKLM\SOFTWARE\Classes\' + $a[0]) $tag
                    $m.SetValue('', $a[1])
                }
                $m.Close()
            }
            $script:RestartExplorer = $true
        } $e
    }

    # A user-level override of how programs are opened (a classic hijack of .exe and scripts).
    foreach ($pn in @('exefile', 'batfile', 'cmdfile', 'comfile')) {
        Add-Item ('Open command override for ' + $pn) {
            param($a)
            if (Test-Path -LiteralPath ('HKCU:\Software\Classes\' + $a + '\shell\open\command')) { return 'a user-level override exists -> remove it' }
            return $null
        } {
            param($a)
            Backup-Key ('HKCU\Software\Classes\' + $a + '\shell\open\command') ('opencmd_' + $a)
            Remove-Item -LiteralPath ('HKCU:\Software\Classes\' + $a + '\shell\open\command') -Recurse -Force -ErrorAction Stop
            $script:RestartExplorer = $true
        } $pn
    }

    # Apps you picked for file types and links. Removing UserChoice = back to the Windows default app.
    $roots = @(
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts',
        'HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations'
    )
    Add-Item 'Default apps you chose for file types and links' {
        param($a)
        $k = @(Get-UserChoiceKeys $a)
        if ($k.Count -eq 0) { return $null }
        return ([string]$k.Count + ' choice(s) reset to the Windows default apps, your default browser and PDF reader will be asked again')
    } {
        param($a)
        Backup-Key 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts' 'fileexts'
        if (Test-Path -LiteralPath $a[1]) { Backup-Key 'HKCU\Software\Microsoft\Windows\Shell\Associations\UrlAssociations' 'urlassociations' }
        $k = @(Get-UserChoiceKeys $a)
        $fail = 0
        foreach ($p in $k) {
            try { Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction Stop } catch { $fail++ }
        }
        $script:RestartExplorer = $true
        Say 'INFO' ('Removed ' + [string]($k.Count - $fail) + ' of ' + [string]$k.Count + ' choice(s)')
    } $roots
}

# ----------------------------------------------------------------- startup
function Get-BcdValues {
    $o = & bcdedit.exe /enum '{current}' 2>&1
    if ($LASTEXITCODE -ne 0) { throw 'bcdedit could not read the boot configuration' }
    $h = @{}
    foreach ($l in $o) {
        $s = [string]$l
        if ($s -match '^\s*([A-Za-z0-9_]+)\s+(\S.*)$') { $h[$Matches[1].ToLower()] = $Matches[2].Trim() }
    }
    return $h
}

function Section-Startup {
    # Boot options that msconfig, tweak tools or old troubleshooting can leave behind.
    # Windows default for each of them is "not set", so deleting the value restores it.
    $opts = @('safeboot', 'safebootalternateshell', 'onetimeadvancedoptions', 'numproc', 'maxmem',
              'truncatememory', 'removememory', 'sos', 'bootlog', 'quietboot', 'novesa')
    foreach ($o1 in $opts) {
        Add-Item ('Boot option ' + $o1) {
            param($a)
            $h = Get-BcdValues
            if ($h.ContainsKey($a)) { return ('set to ' + $h[$a] + ' -> remove it, the Windows default is not set') }
            return $null
        } {
            param($a)
            if (-not $script:BcdBackup) {
                $f = Join-Path $LogDir ('bcd_backup_' + $Stamp + '.bcd')
                $o = & bcdedit.exe /export $f 2>&1
                if (($LASTEXITCODE -ne 0) -or (-not (Test-Path -LiteralPath $f))) { throw 'the boot configuration backup failed, so nothing was changed' }
                Say 'INFO' ('Backup saved: ' + $f)
                $script:BcdBackup = $true
            }
            $o = & bcdedit.exe /deletevalue '{current}' $a 2>&1
            if ($LASTEXITCODE -ne 0) { throw ('bcdedit failed with code ' + $LASTEXITCODE) }
        } $o1
    }
    Add-Skip 'Startup apps: Windows has no default list for them, so they are left as they are. Use Task Manager, Startup apps.'
}

# --------------------------------------------------------------------- gpu
function Get-SmiPower([string]$Smi) {
    $o = & $Smi '--query-gpu=index,power.limit,power.default_limit' '--format=csv,noheader,nounits' 2>&1
    if ($LASTEXITCODE -ne 0) { throw 'nvidia-smi could not read the power limit' }
    $rows = @()
    foreach ($l in $o) {
        $p = ([string]$l).Split(',')
        if ($p.Count -ge 3) {
            $lim = 0.0
            $def = 0.0
            $ci = [cultureinfo]::InvariantCulture
            $ns = [Globalization.NumberStyles]::Float
            if ([double]::TryParse($p[1].Trim(), $ns, $ci, [ref]$lim) -and [double]::TryParse($p[2].Trim(), $ns, $ci, [ref]$def)) {
                $rows += [pscustomobject]@{ Index = $p[0].Trim(); Limit = $lim; Default = $def }
            }
        }
    }
    return $rows
}

function Section-Gpu([string]$Vendor) {
    $pat = 'NVIDIA'
    if ($Vendor -eq 'AMD') { $pat = 'AMD|Advanced Micro Devices|Radeon' }
    if ($Vendor -eq 'Intel') { $pat = 'Intel' }
    $g = @()
    try {
        $g = @(Get-CimInstance Win32_VideoController -ErrorAction Stop | Where-Object { (([string]$_.Name) + ' ' + ([string]$_.AdapterCompatibility)) -match $pat })
    } catch { $g = @() }
    if ($g.Count -eq 0) { Add-Skip ('No ' + $Vendor + ' graphics card was detected on this PC'); return }
    foreach ($x in $g) {
        Say 'INFO' ('Detected: ' + $x.Name + ', driver ' + $x.DriverVersion + ', device status code ' + [string]$x.ConfigManagerErrorCode)
    }
    $good = @($g | Where-Object { ($_.ConfigManagerErrorCode -eq 0) -and $_.DriverVersion })
    if ($good.Count -eq 0) { Add-Skip ('A ' + $Vendor + ' card was found but its driver is missing or not working, nothing to restore'); return }

    if ($Vendor -eq 'NVIDIA') {
        $smi = $null
        foreach ($c in @((Join-Path $env:SystemRoot 'System32\nvidia-smi.exe'), (Join-Path $env:ProgramFiles 'NVIDIA Corporation\NVSMI\nvidia-smi.exe'))) {
            if (Test-Path -LiteralPath $c) { $smi = $c; break }
        }
        if ($smi) {
            Add-Item 'NVIDIA power limit' {
                param($a)
                $diff = @()
                foreach ($r in (Get-SmiPower $a)) {
                    if (([math]::Abs($r.Limit - $r.Default) -gt 0.5) -and ($r.Default -gt 0)) {
                        $diff += ('GPU ' + $r.Index + ': ' + [string]$r.Limit + ' W -> ' + [string]$r.Default + ' W (driver default)')
                    }
                }
                if ($diff.Count -eq 0) { return $null }
                return ($diff -join ' ; ')
            } {
                param($a)
                foreach ($r in (Get-SmiPower $a)) {
                    if (([math]::Abs($r.Limit - $r.Default) -gt 0.5) -and ($r.Default -gt 0)) {
                        $o = & $a '-i' $r.Index '-pl' ($r.Default.ToString([cultureinfo]::InvariantCulture)) 2>&1
                        if ($LASTEXITCODE -ne 0) { throw ('nvidia-smi failed for GPU ' + $r.Index + ' with code ' + [string]$LASTEXITCODE) }
                    }
                }
            } $smi
        } else {
            Add-Skip 'nvidia-smi was not found, so the power limit could not be checked'
        }
        Add-Skip 'NVIDIA Control Panel, Manage 3D Settings: Could not safely restore this setting.'
        Say 'INFO' 'Manual way: NVIDIA Control Panel > Manage 3D settings > Restore.'
    } else {
        Add-Skip ($Vendor + ' graphics control panel settings: Could not safely restore this setting.')
        Say 'INFO' 'No command-line reset exists for these settings. Use the Reset option inside the vendor control panel.'
    }
    Say 'INFO' 'Drivers, clocks, voltage and performance settings are never touched here.'
}

# -------------------------------------------------------------------- main
try {
    if ([Environment]::OSVersion.Version.Major -lt 10) { Say 'ERROR' 'This tool supports Windows 10 and Windows 11 only.'; exit 1 }
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) { Say 'ERROR' 'Administrator rights are required.'; exit 1 }
    if ((-not $LogDir) -or (-not (Test-Path -LiteralPath $LogDir))) { Say 'ERROR' 'The log folder is missing, so backups cannot be saved.'; exit 1 }

    switch ($Section) {
        'GPU_NVIDIA' { Section-Gpu 'NVIDIA' }
        'GPU_AMD'    { Section-Gpu 'AMD' }
        'GPU_INTEL'  { Section-Gpu 'Intel' }
        'SERVICES'   { Section-Services }
        'NETWORK'    { Section-Network }
        'FIREWALL'   { Section-Firewall }
        'WINUPDATE'  { Section-WinUpdate }
        'POWER'      { Section-Power }
        'SECURITY'   { Section-Security }
        'EXPLORER'   { Section-Explorer }
        'FILEASSOC'  { Section-FileAssoc }
        'STARTUP'    { Section-Startup }
        default      { Say 'ERROR' ('Unknown restore section: ' + $Section); exit 1 }
    }
    Run-Items
    if ($Apply -and $script:RestartExplorer) { Restart-Explorer }
}
catch {
    Say 'ERROR' ('Unexpected problem: ' + $_.Exception.Message)
    exit 1
}
if ((-not $Apply) -and ($script:Will -eq 0)) { exit 3 }
exit 0
#RST_END
#GD_BEGIN
# ====================================================================
#  Game Doctor engine. Started only by Gaming Fixes, option 9. No menu: it asks for the game path, runs the full diagnosis, then offers repairs.
#  Evidence-based game diagnostics and repair. It is NOT an optimizer.
#  Rule 1: the real launch test is the ground truth. A static finding (odd file, odd config, missing DLL)
#          is only reported as a problem when it is PROOF (the OS or the launcher says so) or when the
#          launch test really failed. If the game starts and stays running, such findings are only notes.
#  Rule 2: nothing is changed without asking, a backup comes first, and the result is re-tested.
#  Rule 3: DRM, anti-cheat and launchers are never bypassed.
#  Rule 4: the report always says what was NOT checked. It never claims a game is perfect.
# ====================================================================
$ErrorActionPreference = 'Continue'
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false } catch { }
try { $Host.UI.RawUI.WindowTitle = 'Game Doctor' } catch { }

$LogDir     = $env:FT_LOGDIR
$ToolkitLog = $env:FT_LOGFILE
if (-not $LogDir) { $LogDir = Join-Path $env:TEMP 'MeshalFix_Logs' }
$GdRoot     = Join-Path $LogDir 'GameDoctor'
$ReportDir  = Join-Path $GdRoot 'Reports'
$BackupRoot = Join-Path $GdRoot 'Backups'
foreach ($d in @($GdRoot, $ReportDir, $BackupRoot)) {
    if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

$TICK = [string][char]0x2713
$StartupTimeout = 60      # seconds to wait for the game to start
$StableSeconds  = 15      # window seen this long = launch is stable
$MaxAttempts    = 3

# Known required files per Steam App ID. Add ONLY entries you have verified on a real install.
# Format:  'APPID' = @('relative\path\one.exe', 'relative\path\two.dll')
$KnownRequired = @{
}

$script:GamePath   = ''
$script:G          = $null
$script:Findings   = New-Object System.Collections.ArrayList
$script:Sec        = [ordered]@{}
$script:Attempts   = New-Object System.Collections.ArrayList
$script:Actions    = New-Object System.Collections.ArrayList
$script:Verify     = New-Object System.Collections.ArrayList
$script:CrashInfo  = @()
$script:ReportFile = ''
$script:ScanDone   = $false
$script:LaunchDone = $false

# ------------------------------------------------------------ helpers
function Line([string]$t, [string]$c = 'Gray') { Write-Host $t -ForegroundColor $c }

function Log([string]$m) {
    if ($ToolkitLog) {
        try { Add-Content -LiteralPath $ToolkitLog -Value ('[' + (Get-Date).ToString('yyyy-MM-dd HH:mm:ss', [cultureinfo]::InvariantCulture) + '] GAMEDOCTOR - ' + $m) -ErrorAction SilentlyContinue } catch { }
    }
}

function Ask-YN([string]$q) {
    while ($true) {
        $a = Read-Host ($q + ' [Y/N]')
        if ($a -match '^(?i:y)$') { return $true }
        if ($a -match '^(?i:n)$') { return $false }
    }
}

function Pause-Key { Write-Host ''; [void](Read-Host 'Press Enter to continue') }

function Norm([string]$s) { return (([string]$s).ToLower() -replace '[^a-z0-9]', '') }

function Safe-Name([string]$s) { return (($s -replace '[^\w\.\- ]', '_').Trim()) }

function Step([int]$n, [int]$t, [string]$txt) { Line ('[' + $n + '/' + $t + '] ' + $txt) 'Cyan' }

function Clear-Findings([string]$Cat) {
    $keep = @($script:Findings | Where-Object { $_.Category -ne $Cat })
    $script:Findings.Clear()
    foreach ($k in $keep) { [void]$script:Findings.Add($k) }
}

function Add-Finding {
    param([string]$Category, [string]$Title, [string[]]$Evidence, [string]$Confidence,
          [string]$Recommended = '', [string]$RepairId = '', $RepairData = $null, [string]$Kind = 'SUSPECT')
    $status = 'Informational'
    if ($Confidence -eq 'CONFIRMED') { $status = 'Confirmed' }
    elseif (($Confidence -eq 'HIGH') -or ($Confidence -eq 'MEDIUM')) { $status = 'Likely' }
    elseif ($Confidence -eq 'LOW') { $status = 'Possible' }
    [void]$script:Findings.Add([pscustomobject]@{
        Category = $Category; Title = $Title; Evidence = @($Evidence); Confidence = $Confidence
        Status = $status; Recommended = $Recommended; RepairId = $RepairId; RepairData = $RepairData; Kind = $Kind })
    Log ('Finding [' + $Confidence + '/' + $Kind + '] ' + $Category + ' - ' + $Title)
}

# Result of the real launch test, in plain terms. NOT_TESTED / PASS / PASS_WEAK / INCONCLUSIVE / FAIL / FAIL_UNKNOWN
function Get-LaunchState {
    $att = @($script:Attempts)
    if ($att.Count -eq 0) { return 'NOT_TESTED' }
    $s = $att[$att.Count - 1].State
    if ($s -eq 'RUNNING') { return 'PASS' }
    if ($s -eq 'RUNNING_NO_WINDOW') { return 'PASS_WEAK' }
    if ($s -eq 'EXITED_NORMALLY') { return 'INCONCLUSIVE' }
    if (@('CRASHED', 'LAUNCH_FAILED', 'BLOCKED_BY_LAUNCHER') -contains $s) { return 'FAIL' }
    return 'FAIL_UNKNOWN'
}

# PROOF findings (the OS, the launcher or the real launch say so) are always problems.
# SUSPECT findings (heuristics on files / config / imports) are problems only if the launch test really failed.
# A game that starts and stays running overrides every heuristic.
function Is-Issue($f) {
    if (@('CONFIRMED', 'HIGH', 'MEDIUM') -notcontains $f.Confidence) { return $false }
    if ($f.Kind -eq 'PROOF') { return $true }
    $ls = Get-LaunchState
    return (($ls -eq 'FAIL') -or ($ls -eq 'FAIL_UNKNOWN'))
}

function Issues { return @($script:Findings | Where-Object { Is-Issue $_ }) }

function Get-AcfData {
    $g = $script:G
    if ((-not $g) -or (-not $g.Acf)) { return $null }
    try { return (Parse-Acf $g.Acf) } catch { return $null }
}

function Get-SteamPath {
    foreach ($k in @('HKCU:\Software\Valve\Steam', 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam', 'HKLM:\SOFTWARE\Valve\Steam')) {
        try {
            $v = Get-ItemProperty -LiteralPath $k -ErrorAction Stop
            $s = ''
            if ($v.SteamPath) { $s = [string]$v.SteamPath } elseif ($v.InstallPath) { $s = [string]$v.InstallPath }
            if ($s) { $s = $s.Replace('/', '\'); if (Test-Path -LiteralPath $s) { return $s } }
        } catch { }
    }
    return $null
}

function Parse-Acf([string]$File) {
    $t = Get-Content -LiteralPath $File -Raw -ErrorAction Stop
    $h = @{}
    foreach ($m in [regex]::Matches($t, '"(\w+)"\s+"([^"]*)"')) {
        if (-not $h.ContainsKey($m.Groups[1].Value)) { $h[$m.Groups[1].Value] = $m.Groups[2].Value }
    }
    return $h
}

function Get-AcfFlags {
    $g = $script:G
    if (-not $g.Acf) { return $null }
    try { $d = Parse-Acf $g.Acf; if ($d.ContainsKey('StateFlags')) { return [int]$d['StateFlags'] } } catch { }
    return $null
}

# ------------------------------------------------------- path + detection
function Test-GamePath([string]$p) {
    if (-not $p) { return 'No path was entered.' }
    if (-not (Test-Path -LiteralPath $p -PathType Container)) { return 'The folder was not found.' }
    try { $one = @(Get-ChildItem -LiteralPath $p -Force -ErrorAction Stop | Select-Object -First 1) }
    catch { return ('The folder cannot be accessed: ' + $_.Exception.Message) }
    if ($one.Count -eq 0) { return 'The folder is empty.' }
    return $null
}

$ExeSkip = '^(unins\w*|uninst\w*|unity ?crash ?handler\w*|crashreport\w*|crashpad\w*|crashhandler\w*|vcredist\w*|vc_redist\w*|dxsetup|dxwebsetup|dotnetfx\w*|ndp\w*|setup\w*|install\w*|redist\w*|ue4prereq\w*|ueprereq\w*|easyanticheat\w*|eac\w*|beservice\w*|battleye\w*|bootstrap\w*|updater\w*|helper\w*|notification_helper|cef\w*|steamerrorreporter\w*|7z\w*|oalinst|physx\w*|handler)$'

function Detect-Game([string]$Path) {
    $g = @{ Path = $Path; Root = $Path; Name = (Split-Path $Path -Leaf); Launcher = 'Unknown'; LauncherNote = ''
            AppId = ''; Acf = ''; SteamApps = ''; ExpectedExe = ''; Exe = ''; ExeConf = $false; ExeNote = ''
            Candidates = @(); AntiCheat = @(); EpicUri = ''; Mods = @(); ConfigDirs = @(); FileCount = 0 }
    $idx = $Path.ToLower().IndexOf('\steamapps\common\')
    if ($idx -ge 0) {
        $inst = $Path.Substring($idx + 18).Split('\')[0]
        $steamapps = $Path.Substring(0, $idx + 10)
        $g.Root = Join-Path (Join-Path $steamapps 'common') $inst
        $g.SteamApps = $steamapps
        $g.Launcher = 'Steam'
        $g.Name = $inst
        foreach ($f in @(Get-ChildItem -LiteralPath $steamapps -Filter 'appmanifest_*.acf' -File -ErrorAction SilentlyContinue)) {
            $d = $null
            try { $d = Parse-Acf $f.FullName } catch { continue }
            if ($d.ContainsKey('installdir') -and ([string]$d['installdir'] -ieq $inst)) {
                $g.Acf = $f.FullName; $g.AppId = [string]$d['appid']
                if ($d['name']) { $g.Name = [string]$d['name'] }
                break
            }
        }
        if (-not $g.AppId) { $g.LauncherNote = 'Steam library folder, but no appmanifest was found for this game' }
    }
    if ($g.Launcher -eq 'Unknown') {
        $mdir = Join-Path $env:ProgramData 'Epic\EpicGamesLauncher\Data\Manifests'
        if (Test-Path -LiteralPath $mdir) {
            foreach ($m in @(Get-ChildItem -LiteralPath $mdir -Filter '*.item' -File -ErrorAction SilentlyContinue)) {
                $j = $null
                try { $j = Get-Content -LiteralPath $m.FullName -Raw -ErrorAction Stop | ConvertFrom-Json } catch { continue }
                if ($j -and $j.InstallLocation -and $Path.StartsWith(([string]$j.InstallLocation).TrimEnd('\'), [StringComparison]::OrdinalIgnoreCase)) {
                    $g.Launcher = 'Epic Games'
                    $g.Root = ([string]$j.InstallLocation).TrimEnd('\')
                    if ($j.DisplayName) { $g.Name = [string]$j.DisplayName }
                    if ($j.LaunchExecutable) { $g.ExpectedExe = Join-Path $g.Root ([string]$j.LaunchExecutable) }
                    if ($j.AppName -and $j.CatalogNamespace -and $j.CatalogItemId) {
                        $g.EpicUri = 'com.epicgames.launcher://apps/' + $j.CatalogNamespace + '%3A' + $j.CatalogItemId + '%3A' + $j.AppName + '?action=launch&silent=true'
                    }
                    break
                }
            }
        }
        if (($g.Launcher -eq 'Unknown') -and (Test-Path -LiteralPath (Join-Path $Path '.egstore'))) {
            $g.Launcher = 'Epic Games'; $g.LauncherNote = 'Epic metadata folder found, but no launcher manifest matched'
        }
    }
    if ($g.Launcher -eq 'Unknown') {
        $gi = @(Get-ChildItem -LiteralPath $Path -Filter 'goggame-*.info' -File -ErrorAction SilentlyContinue | Select-Object -First 1)
        if ($gi.Count -gt 0) {
            $g.Launcher = 'GOG Galaxy'
            try {
                $j = Get-Content -LiteralPath $gi[0].FullName -Raw | ConvertFrom-Json
                if ($j.name) { $g.Name = [string]$j.name }
                $pt = @($j.playTasks | Where-Object { $_.isPrimary -and $_.path } | Select-Object -First 1)
                if ($pt.Count -gt 0) { $g.ExpectedExe = Join-Path $Path ([string]$pt[0].path) }
            } catch { }
        }
    }
    if ($g.Launcher -eq 'Unknown') {
        if (($Path -match '(?i)\\(EA Games|Origin Games|Electronic Arts|EA Desktop)\\') -or (Test-Path -LiteralPath (Join-Path $Path '__Installer'))) { $g.Launcher = 'EA App' }
        elseif ($Path -match '(?i)\\Ubisoft Game Launcher\\games\\') { $g.Launcher = 'Ubisoft Connect' }
        elseif (($Path -match '(?i)\\(Battle\.net|Blizzard Entertainment)\\') -or (Test-Path -LiteralPath (Join-Path $Path '.build.info'))) { $g.Launcher = 'Battle.net' }
        elseif ($Path -match '(?i)\\Rockstar Games\\') { $g.Launcher = 'Rockstar Games Launcher' }
        elseif (($Path -match '(?i)\\(WindowsApps|XboxGames)\\') -or (Test-Path -LiteralPath (Join-Path $Path 'MicrosoftGame.config'))) { $g.Launcher = 'Xbox / Microsoft Store' }
        else {
            $hint = @(Get-ChildItem -LiteralPath $Path -File -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '(?i)^(steam_api(64)?\.dll|steam_appid\.txt|eossdk.*\.dll)$' })
            if ($hint.Count -gt 0) { $g.Launcher = 'Unknown'; $g.LauncherNote = 'Launcher libraries found (' + $hint[0].Name + ') but the launcher could not be matched' }
            else { $g.Launcher = 'Standalone'; $g.LauncherNote = 'No launcher indicators were found' }
        }
    }
    # anti-cheat indicators (never bypassed - only used to refuse a direct launch)
    $g.AntiCheat = @(Get-ChildItem -LiteralPath $g.Root -Recurse -Depth 2 -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '(?i)^(easyanticheat.*|battleye|beservice.*|be_?launcher.*|vgk.*|equ8.*|punkbuster|pnkbstr.*|xigncode.*|gameguard.*|nprotect.*)(\.exe|\.sys)?$' } |
        ForEach-Object { $_.Name } | Select-Object -Unique)
    return $g
}

function Find-Exe($g) {
    $g.Exe = ''; $g.ExeConf = $false; $g.ExeNote = ''; $g.Candidates = @()
    if ($g.ExpectedExe) { $g.Exe = $g.ExpectedExe; $g.ExeConf = $true; $g.ExeNote = 'from the launcher manifest'; return }
    $skipDir = '(?i)\\(_commonredist|redist|redistributables?|directx|dotnet|vcredist|__installer|installers?|prerequisites?|support|crashreporter|crashpad|easyanticheat|battleye)\\'
    $root = $g.Root
    $files = @(Get-ChildItem -LiteralPath $root -Filter '*.exe' -File -Recurse -Depth 3 -Force -ErrorAction SilentlyContinue |
        Where-Object { ($_.FullName.Substring($root.Length) -notmatch $skipDir) -and ($_.BaseName -notmatch $ExeSkip) })
    if ($files.Count -eq 0) { $g.ExeNote = 'no executable candidates found'; return }
    $fn = Norm $g.Name
    $leaf = Norm (Split-Path $root -Leaf)
    $scored = @()
    foreach ($f in $files) {
        $en = Norm $f.BaseName
        $s = 0
        foreach ($nm in @($fn, $leaf)) {
            if (($en.Length -ge 4) -and ($nm.Length -ge 4)) {
                if ($nm.Contains($en) -or $en.Contains($nm.Substring(0, [math]::Min(6, $nm.Length)))) { $s = 5 }
            }
        }
        if ($en -match 'shipping') { $s += 3 }
        if ($f.FullName -match '(?i)\\win64\\') { $s += 1 }
        $scored += [pscustomobject]@{ Path = $f.FullName; Size = $f.Length; Score = $s }
    }
    $sorted = @($scored | Sort-Object -Property @{ Expression = 'Score'; Descending = $true }, @{ Expression = 'Size'; Descending = $true })
    $g.Candidates = @($sorted | Select-Object -First 5 | ForEach-Object { $_.Path })
    $top = $sorted[0]
    $confident = $false
    if ($sorted.Count -eq 1) { $confident = $true }
    else {
        $second = $sorted[1]
        if ($top.Score -ge ($second.Score + 3)) { $confident = $true }
        elseif (($second.Size -gt 0) -and ($top.Size -ge (3 * $second.Size)) -and ($top.Score -ge $second.Score)) { $confident = $true }
    }
    if ($confident) { $g.Exe = $top.Path; $g.ExeConf = $true; $g.ExeNote = 'best match among ' + $sorted.Count + ' candidate(s)' }
    else { $g.ExeNote = 'several equally likely executables - not guessing' }
}

function Do-Detection {
    $script:Sec = [ordered]@{}
    $script:Findings.Clear()
    $g = Detect-Game $script:GamePath
    Find-Exe $g
    $script:G = $g
    $script:Sec['Installation'] = $TICK + ' Found'
    if ($g.Exe -and (Test-Path -LiteralPath $g.Exe)) { $script:Sec['Executable'] = $TICK + ' Found - ' + (Split-Path $g.Exe -Leaf) }
    elseif ($g.Exe) { $script:Sec['Executable'] = '[!] Expected executable is missing - ' + $g.Exe }
    else { $script:Sec['Executable'] = 'Unknown - unable to determine automatically (' + $g.ExeNote + ')' }
    $ln = $g.Launcher
    if ($g.LauncherNote) { $ln += ' (' + $g.LauncherNote + ')' }
    $script:Sec['Launcher'] = $ln
    foreach ($k in @('Game Files', 'Configuration', 'Dependencies', 'Mods', 'Launch Test', 'Crash Evidence')) { $script:Sec[$k] = 'Not tested' }
    Log ('Detected game: ' + $g.Name + ' | launcher: ' + $g.Launcher + ' | exe: ' + $g.Exe)
}

# ------------------------------------------------------------ game files
function Check-Files {
    Clear-Findings 'Game Files'
    $g = $script:G
    $any = $false
    $canVerify = ($g.Launcher -eq 'Steam') -and $g.AppId
    $rid = ''
    $rec = 'Use the official verify / repair function of your launcher.'
    if ($canVerify) { $rid = 'steamverify'; $rec = 'Let Steam verify and repair the game files.' }

    if ($g.ExpectedExe -and -not (Test-Path -LiteralPath $g.ExpectedExe)) {
        Add-Finding 'Game Files' 'Game executable missing' @('Expected executable does not exist: ' + $g.ExpectedExe, 'Expected path comes from the launcher manifest.') 'CONFIRMED' $rec $rid $g.AppId -Kind 'PROOF'
        $any = $true
    }
    if ($g.Exe -and (Test-Path -LiteralPath $g.Exe)) {
        $fi = Get-Item -LiteralPath $g.Exe
        $fs = $null
        try {
            $fs = [IO.File]::Open($g.Exe, 'Open', 'Read', 'ReadWrite')
            $buf = New-Object byte[] 2
            $n = $fs.Read($buf, 0, 2)
            if ($fi.Length -eq 0) {
                Add-Finding 'Game Files' 'Game executable is empty' @('The executable has a size of 0 bytes: ' + $g.Exe) 'CONFIRMED' $rec $rid $g.AppId -Kind 'PROOF'; $any = $true
            } elseif (($n -eq 2) -and (($buf[0] -ne 0x4D) -or ($buf[1] -ne 0x5A))) {
                Add-Finding 'Game Files' 'Game executable is not a valid program file' @('The file does not start with a valid executable header: ' + $g.Exe) 'CONFIRMED' $rec $rid $g.AppId -Kind 'PROOF'; $any = $true
            }
        } catch [UnauthorizedAccessException] { }
        catch {
            Add-Finding 'Game Files' 'Game executable cannot be read' @($g.Exe + ' : ' + $_.Exception.Message) 'HIGH' $rec $rid $g.AppId; $any = $true
        } finally { if ($fs) { $fs.Dispose() } }
    }
    # known required files (only if a verified entry exists for this App ID)
    if ($g.AppId -and $KnownRequired.ContainsKey($g.AppId)) {
        $miss = @()
        foreach ($rel in $KnownRequired[$g.AppId]) { if (-not (Test-Path -LiteralPath (Join-Path $g.Root $rel))) { $miss += $rel } }
        if ($miss.Count -gt 0) {
            Add-Finding 'Game Files' 'Known required game file missing' @($miss | ForEach-Object { 'Missing: ' + $_ }) 'CONFIRMED' $rec $rid $g.AppId -Kind 'PROOF'; $any = $true
        }
    }
    # walk the files
    $all = @(Get-ChildItem -LiteralPath $g.Root -File -Recurse -Force -ErrorAction SilentlyContinue)
    $g.FileCount = $all.Count
    $limit = 20000; $checked = 0
    $unread = @(); $unreadHard = $false; $badpe = @(); $zero = @()
    foreach ($f in $all) {
        $ext = $f.Extension.ToLower()
        $isPe = ($ext -eq '.exe') -or ($ext -eq '.dll')
        if ($isPe -and ($f.Length -eq 0)) { $zero += $f.FullName; continue }
        if (($checked -ge $limit) -or ($f.Length -eq 0)) { continue }
        $checked++
        $fs = $null
        try {
            $fs = [IO.File]::Open($f.FullName, 'Open', 'Read', 'ReadWrite')
            $buf = New-Object byte[] 2
            $n = $fs.Read($buf, 0, 2)
            if ($isPe -and ($f.Length -ge 64) -and ($n -eq 2) -and (($buf[0] -ne 0x4D) -or ($buf[1] -ne 0x5A))) { $badpe += $f.FullName }
        } catch [UnauthorizedAccessException] { }
        catch {
            $msg = $_.Exception.Message
            $unread += ($f.FullName + ' : ' + $msg)
            if ($msg -match '(?i)cyclic redundancy|device error|data error|corrupt') { $unreadHard = $true }
        } finally { if ($fs) { $fs.Dispose() } }
    }
    $limitTxt = ''
    if ($all.Count -gt $limit) { $limitTxt = ' (only the first ' + $limit + ' files were opened)' }
    if ($badpe.Count -gt 0) {
        $ev = @($badpe | Select-Object -First 5 | ForEach-Object { 'Invalid program header: ' + $_ })
        if ($badpe.Count -gt 5) { $ev += ('...and ' + ($badpe.Count - 5) + ' more') }
        Add-Finding 'Game Files' 'Program files with an invalid header' $ev 'HIGH' $rec $rid $g.AppId; $any = $true
    }
    if ($zero.Count -gt 0) {
        $ev = @($zero | Select-Object -First 5 | ForEach-Object { 'Empty (0 bytes): ' + $_ })
        if ($zero.Count -gt 5) { $ev += ('...and ' + ($zero.Count - 5) + ' more') }
        Add-Finding 'Game Files' 'Empty program files' $ev 'MEDIUM' $rec $rid $g.AppId; $any = $true
    }
    if ($unread.Count -gt 0) {
        $ev = @($unread | Select-Object -First 5)
        if ($unread.Count -gt 5) { $ev += ('...and ' + ($unread.Count - 5) + ' more') }
        $cf = 'MEDIUM'
        $rc = $rec
        $kd = 'SUSPECT'
        # a CRC / device / data error is reported by Windows itself, that is proof
        if ($unreadHard) { $cf = 'HIGH'; $kd = 'PROOF'; $rc = $rec + ' Read errors can also point to a failing drive.' }
        Add-Finding 'Game Files' 'Game files that cannot be read' $ev $cf $rc $rid $g.AppId -Kind $kd; $any = $true
    }
    # launcher-provided integrity information (Steam). These flags are written by Steam itself.
    if ($g.Acf) {
        try {
            $d = Parse-Acf $g.Acf
            if ($d.ContainsKey('StateFlags')) {
                $fl = [int]$d['StateFlags']
                $working = 256 -bor 1024 -bor 65536 -bor 131072 -bor 262144 -bor 524288 -bor 1048576
                if (($fl -band (32 -bor 128)) -ne 0) {
                    $why = @()
                    if (($fl -band 32) -ne 0) { $why += 'FilesMissing' }
                    if (($fl -band 128) -ne 0) { $why += 'FilesCorrupt' }
                    Add-Finding 'Game Files' 'Steam itself reports damaged or missing game files' @('Steam StateFlags = ' + $fl + ' (' + ($why -join ' + ') + ').', 'Source: ' + $g.Acf) 'CONFIRMED' $rec $rid $g.AppId -Kind 'PROOF'; $any = $true
                } elseif (($fl -band 4) -eq 0) {
                    if (($fl -band $working) -ne 0) {
                        Add-Finding 'Game Files' 'Steam is installing, updating or verifying this game right now' @('Steam StateFlags = ' + $fl + '.') 'INFORMATIONAL' 'Wait for Steam to finish, then test again.'
                    } else {
                        Add-Finding 'Game Files' 'Steam reports the game is not fully installed' @('Steam StateFlags = ' + $fl + ' (the "fully installed" bit is not set).', 'Source: ' + $g.Acf) 'MEDIUM' 'Let Steam finish installing / updating, or verify the game files.' $rid $g.AppId
                    }
                } elseif (($fl -band 2) -ne 0) {
                    Add-Finding 'Game Files' 'Steam reports a pending update' @('Steam StateFlags = ' + $fl + ' (update required bit is set).') 'INFORMATIONAL' 'Let Steam finish the update.'
                }
            }
        } catch { }
    }
    if ($any) { $script:Sec['Game Files'] = '[!] Problem detected - see Detected Issues' }
    else { $script:Sec['Game Files'] = $TICK + ' No obvious problems detected (' + $all.Count + ' files examined' + $limitTxt + ')' }
    if (-not ([string]$script:Sec['Integrity']).StartsWith('Verified')) {
        if (($g.Launcher -eq 'Steam') -and $g.AppId) { $script:Sec['Integrity'] = 'Not compared with Steam records (only Steam verification does that)' }
        else { $script:Sec['Integrity'] = 'Not verified (no launcher record to compare with)' }
    }
}

# --------------------------------------------------------- configuration
function Match-Name([string]$dirName, $names) {
    $n = Norm $dirName
    foreach ($nm in $names) {
        if ($n -eq $nm) { return $true }
        if (($n.Length -ge 6) -and ($nm.Contains($n) -or $n.Contains($nm))) { return $true }
    }
    return $false
}

function Find-ConfigDirs($g) {
    $names = @((Norm $g.Name), (Norm (Split-Path $g.Root -Leaf))) | Where-Object { $_.Length -ge 5 } | Select-Object -Unique
    if (@($names).Count -eq 0) { return @() }
    $roots = @([Environment]::GetFolderPath('MyDocuments'), (Join-Path $env:USERPROFILE 'Saved Games'), $env:LOCALAPPDATA, $env:APPDATA,
               (Join-Path $env:USERPROFILE 'AppData\LocalLow'), $env:ProgramData) | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -Unique
    $skip = '(?i)^(microsoft|packages|temp|google|mozilla|programs|npm|pip|nvidia.*|d3dscache|crashdumps|connecteddevicesplatform|steam|epicgameslauncher)$'
    $hits = @()
    foreach ($r in $roots) {
        foreach ($d in @(Get-ChildItem -LiteralPath $r -Directory -Force -ErrorAction SilentlyContinue)) {
            if (Match-Name $d.Name $names) { $hits += $d.FullName; continue }
            if ($d.Name -match $skip) { continue }
            foreach ($d2 in @(Get-ChildItem -LiteralPath $d.FullName -Directory -Force -ErrorAction SilentlyContinue)) {
                if (Match-Name $d2.Name $names) { $hits += $d2.FullName }
            }
        }
    }
    return @($hits | Select-Object -Unique)
}

# returns $null when the file looks fine, otherwise @{Reason=..; Confidence=..}
# Walks a JSON-like text outside of strings: drops // and /* */ comments and reports the bracket depth.
# Depth <> 0 or an unterminated string means the file is truncated or damaged.
function Get-JsonShape([string]$s) {
    $sb = New-Object System.Text.StringBuilder
    $depth = 0; $inStr = $false; $esc = $false; $i = 0; $n = $s.Length
    while ($i -lt $n) {
        $ch = $s[$i]
        if ($inStr) {
            [void]$sb.Append($ch)
            if ($esc) { $esc = $false } elseif ($ch -eq '\') { $esc = $true } elseif ($ch -eq '"') { $inStr = $false }
            $i++; continue
        }
        if ($ch -eq '"') { $inStr = $true; [void]$sb.Append($ch); $i++; continue }
        if (($ch -eq '/') -and ($i + 1 -lt $n) -and ($s[$i + 1] -eq '/')) { while (($i -lt $n) -and ($s[$i] -ne "`n")) { $i++ }; continue }
        if (($ch -eq '/') -and ($i + 1 -lt $n) -and ($s[$i + 1] -eq '*')) {
            $i += 2
            while (($i + 1 -lt $n) -and (-not (($s[$i] -eq '*') -and ($s[$i + 1] -eq '/')))) { $i++ }
            $i += 2; continue
        }
        if (($ch -eq '{') -or ($ch -eq '[')) { $depth++ } elseif (($ch -eq '}') -or ($ch -eq ']')) { $depth-- }
        [void]$sb.Append($ch); $i++
    }
    return @{ Depth = $depth; InString = $inStr; Clean = $sb.ToString() }
}

# Returns $null when the file looks fine OR when Game Doctor cannot judge it.
# Only real damage is reported: empty, zero-filled, NUL bytes in a text format, truncated, or malformed XML.
# Comments, trailing commas, JSON5 and XML fragments are valid for many games and are NOT reported.
function Test-ConfigFile([IO.FileInfo]$f) {
    $ext = $f.Extension.ToLower()
    if ($f.Length -gt 8MB) { return $null }
    $bytes = [IO.File]::ReadAllBytes($f.FullName)
    $bom16 = ($bytes.Length -ge 2) -and ((($bytes[0] -eq 0xFF) -and ($bytes[1] -eq 0xFE)) -or (($bytes[0] -eq 0xFE) -and ($bytes[1] -eq 0xFF)))
    $hasNul = $false
    if (-not $bom16) { $hasNul = ([Array]::IndexOf($bytes, [byte]0) -ge 0) }
    if ($ext -eq '.json') {
        if ($bytes.Length -eq 0) { return @{ Reason = 'JSON file is empty'; Confidence = 'MEDIUM' } }
        if ($hasNul) { return @{ Reason = 'JSON file contains binary NUL bytes'; Confidence = 'MEDIUM' } }
        $enc = [Text.Encoding]::UTF8
        if ($bom16) { if ($bytes[0] -eq 0xFF) { $enc = [Text.Encoding]::Unicode } else { $enc = [Text.Encoding]::BigEndianUnicode } }
        $txt = $enc.GetString($bytes).TrimStart([char]0xFEFF)
        try { [void]($txt | ConvertFrom-Json -ErrorAction Stop); return $null } catch { }
        $shape = Get-JsonShape $txt
        if (($shape.Depth -ne 0) -or $shape.InString) { return @{ Reason = 'JSON file is cut off or damaged (unbalanced brackets)'; Confidence = 'MEDIUM' } }
        return $null
    }
    if ($ext -eq '.xml') {
        if ($bytes.Length -eq 0) { return @{ Reason = 'XML file is empty'; Confidence = 'MEDIUM' } }
        if ($hasNul) { return @{ Reason = 'XML file contains binary NUL bytes'; Confidence = 'MEDIUM' } }
        $st = New-Object System.Xml.XmlReaderSettings
        $st.DtdProcessing = [System.Xml.DtdProcessing]::Ignore
        $st.XmlResolver = $null
        $rd = $null
        try {
            $rd = [System.Xml.XmlReader]::Create($f.FullName, $st)
            $x = New-Object System.Xml.XmlDocument; $x.XmlResolver = $null
            $x.Load($rd)
            return $null
        } catch { } finally { if ($rd) { $rd.Close() } }
        # several root elements are allowed by many games - try again inside a wrapper
        try {
            $raw = [Text.Encoding]::UTF8.GetString($bytes).TrimStart([char]0xFEFF)
            $raw = [regex]::Replace($raw, '<\?xml[^>]*\?>', '')
            $raw = [regex]::Replace($raw, '<!DOCTYPE[^>\[]*(\[[^\]]*\])?\s*>', '')
            $x2 = New-Object System.Xml.XmlDocument; $x2.XmlResolver = $null
            $x2.LoadXml('<gdroot>' + $raw + '</gdroot>')
            return $null
        } catch { return @{ Reason = 'malformed XML data'; Confidence = 'MEDIUM' } }
    }
    # ini / cfg / conf
    if ($bytes.Length -eq 0) { return $null }
    $nz = 0
    foreach ($b in $bytes) { if ($b -ne 0) { $nz++; break } }
    if ($nz -eq 0) { return @{ Reason = 'file is filled with zero bytes'; Confidence = 'HIGH' } }
    if (($ext -eq '.ini') -and $hasNul) { return @{ Reason = 'text configuration contains binary NUL bytes'; Confidence = 'MEDIUM' } }
    return $null
}

function Check-Config {
    Clear-Findings 'Configuration'
    $g = $script:G
    $dirs = @(Find-ConfigDirs $g)
    $g.ConfigDirs = $dirs
    $files = @()
    foreach ($d in $dirs) {
        $files += @(Get-ChildItem -LiteralPath $d -File -Recurse -Depth 3 -Force -ErrorAction SilentlyContinue |
            Where-Object { @('.ini', '.cfg', '.conf', '.json', '.xml') -contains $_.Extension.ToLower() } | Select-Object -First 300)
    }
    $files += @(Get-ChildItem -LiteralPath $g.Root -File -Recurse -Depth 2 -Force -ErrorAction SilentlyContinue |
        Where-Object { @('.ini', '.cfg', '.conf') -contains $_.Extension.ToLower() } | Select-Object -First 300)
    $files = @($files | Sort-Object -Property FullName -Unique)
    $bad = @()
    foreach ($f in $files) {
        $r = $null
        try { $r = Test-ConfigFile $f } catch { continue }
        if ($r) { $bad += [pscustomobject]@{ Path = $f.FullName; Reason = $r.Reason; Confidence = $r.Confidence } }
    }
    if ($bad.Count -gt 0) {
        $cf = 'MEDIUM'
        if (@($bad | Where-Object { $_.Confidence -eq 'HIGH' }).Count -gt 0) { $cf = 'HIGH' }
        $ev = @($bad | Select-Object -First 6 | ForEach-Object { $_.Path + ' : ' + $_.Reason })
        if ($bad.Count -gt 6) { $ev += ('...and ' + ($bad.Count - 6) + ' more') }
        Add-Finding 'Configuration' 'Configuration file contains invalid data' $ev $cf 'Reset the affected configuration file(s). A backup is created first.' 'config' @($bad | ForEach-Object { $_.Path })
        $script:Sec['Configuration'] = '[!] Configuration issue detected - see Detected Issues'
    } elseif ($files.Count -eq 0) {
        $script:Sec['Configuration'] = 'No configuration files were found (nothing to check)'
    } else {
        $script:Sec['Configuration'] = $TICK + ' No obvious problems detected (' + $files.Count + ' file(s) examined)'
    }
}

# ---------------------------------------------------------- dependencies
function RvaToOff($secs, [uint32]$rva) {
    foreach ($s in $secs) {
        if (($rva -ge $s.VA) -and ($rva -lt ($s.VA + $s.VS))) { return [int64]([int64]$rva - [int64]$s.VA + [int64]$s.Raw) }
    }
    return [int64]-1
}

function Get-PEImports([string]$File) {
    $res = @{ Machine = 0; Imports = @(); Error = '' }
    $fs = $null
    try {
        $fs = [IO.File]::Open($File, 'Open', 'Read', 'ReadWrite')
        $br = New-Object IO.BinaryReader($fs)
        if ($fs.Length -lt 512) { $res.Error = 'file too small'; return $res }
        if ($br.ReadUInt16() -ne 0x5A4D) { $res.Error = 'not a PE file'; return $res }
        [void]$fs.Seek(0x3C, 'Begin')
        $pe = $br.ReadInt32()
        [void]$fs.Seek($pe, 'Begin')
        if ($br.ReadUInt32() -ne 0x4550) { $res.Error = 'bad PE signature'; return $res }
        $machine = $br.ReadUInt16()
        $nsec = $br.ReadUInt16()
        [void]$fs.Seek(12, 'Current')
        $optSize = $br.ReadUInt16()
        [void]$fs.Seek(2, 'Current')
        $optStart = $fs.Position
        $magic = $br.ReadUInt16()
        $ddOff = 96
        if ($magic -eq 0x20B) { $ddOff = 112 }
        [void]$fs.Seek($optStart + $ddOff + 8, 'Begin')
        $impRva = $br.ReadUInt32()
        $res.Machine = $machine
        if ($impRva -eq 0) { return $res }
        [void]$fs.Seek($optStart + $optSize, 'Begin')
        $secs = @()
        for ($i = 0; $i -lt $nsec; $i++) {
            [void]$br.ReadBytes(8)
            $vsize = $br.ReadUInt32(); $va = $br.ReadUInt32(); $rawsz = $br.ReadUInt32(); $rawptr = $br.ReadUInt32()
            [void]$br.ReadBytes(16)
            $secs += [pscustomobject]@{ VA = [int64]$va; VS = [int64]([math]::Max([int64]$vsize, [int64]$rawsz)); Raw = [int64]$rawptr }
        }
        $off = RvaToOff $secs $impRva
        if ($off -lt 0) { $res.Error = 'import table not mapped'; return $res }
        $names = @()
        for ($k = 0; $k -lt 512; $k++) {
            [void]$fs.Seek($off + 20 * $k, 'Begin')
            $d = $br.ReadBytes(20)
            if ($d.Length -lt 20) { break }
            $nameRva = [BitConverter]::ToUInt32($d, 12)
            if ($nameRva -eq 0) { break }
            $no = RvaToOff $secs $nameRva
            if ($no -lt 0) { continue }
            [void]$fs.Seek($no, 'Begin')
            $sb = New-Object Text.StringBuilder
            for ($c = 0; $c -lt 256; $c++) { $ch = $fs.ReadByte(); if ($ch -le 0) { break }; [void]$sb.Append([char]$ch) }
            $names += $sb.ToString()
        }
        $res.Imports = $names
    } catch { $res.Error = $_.Exception.Message }
    finally { if ($fs) { $fs.Dispose() } }
    return $res
}

function Dll-Exists([string]$dir, [string]$name) {
    try { return (Test-Path -LiteralPath (Join-Path $dir $name)) } catch { return $false }
}

function Classify-Dll([string]$n) {
    $l = $n.ToLower()
    if ($l -match '^(d3dx9_\d+|d3dx10(_\d+)?|d3dx11_\d+|d3dcompiler_(3\d|4\d)|xinput1_[123]|xaudio2_[0-7]|x3daudio1_[0-7]|xactengine\d+_\d+|xapofx1_\d+)\.dll$') { return 'DirectX' }
    if ($l -match '^(vcruntime\d+(_\d+)?|msvcp\d+(_\d+)?|msvcr\d+|vcomp\d+|concrt\d+)\.dll$') { return 'VC++' }
    if ($l -eq 'openal32.dll') { return 'OpenAL' }
    if ($l -match '^(physx\w*|nxcooking\w*)\.dll$') { return 'PhysX' }
    return 'Other'
}

function Check-Deps {
    Clear-Findings 'Dependencies'
    $g = $script:G
    if ((-not $g.Exe) -or (-not (Test-Path -LiteralPath $g.Exe))) { $script:Sec['Dependencies'] = 'Not checked (executable unknown)'; return }
    $pe = Get-PEImports $g.Exe
    if ($pe.Error) { $script:Sec['Dependencies'] = 'Not checked (' + $pe.Error + ')'; return }
    if ($pe.Imports.Count -eq 0) { $script:Sec['Dependencies'] = 'Not checked (no import table, the executable may be packed)'; return }
    $os64 = [Environment]::Is64BitOperatingSystem
    $sys = Join-Path $env:SystemRoot 'System32'
    if ($os64 -and ($pe.Machine -eq 0x14C)) { $sys = Join-Path $env:SystemRoot 'SysWOW64' }
    elseif ($os64 -and ($pe.Machine -eq 0x8664) -and (-not [Environment]::Is64BitProcess)) { $sys = Join-Path $env:SystemRoot 'Sysnative' }
    $dirs = @((Split-Path $g.Exe -Parent), $sys, $env:SystemRoot) + @(([string]$env:PATH).Split(';') | Where-Object { $_ })
    # CRT / GDI+ libraries below are resolved through side-by-side manifests, not System32
    $skip = '(?i)^(api-ms-.*|ext-ms-.*|gdiplus\.dll|(msvc[pr]|mfc|atl|vcomp)(80|90)u?\.dll)$'
    $missing = @()
    foreach ($n in ($pe.Imports | Select-Object -Unique)) {
        if ($n -match $skip) { continue }
        $found = $false
        foreach ($d in $dirs) { if (Dll-Exists $d $n) { $found = $true; break } }
        if (-not $found) { $missing += $n }
    }
    if ($missing.Count -eq 0) { $script:Sec['Dependencies'] = $TICK + ' No obvious problems detected (' + $pe.Imports.Count + ' imported libraries resolved)'; return }
    $byClass = @{}
    foreach ($m in $missing) { $c = Classify-Dll $m; if (-not $byClass.ContainsKey($c)) { $byClass[$c] = @() }; $byClass[$c] += $m }
    $redist = ''
    if (Test-Path -LiteralPath (Join-Path $g.Root '_CommonRedist')) { $redist = ' The game also ships its own installers in the _CommonRedist folder.' }
    foreach ($c in $byClass.Keys) {
        $list = $byClass[$c]
        $ev = @($list | ForEach-Object { 'Imported by ' + (Split-Path $g.Exe -Leaf) + ' but not found: ' + $_ })
        if ($c -eq 'DirectX') {
            Add-Finding 'Dependencies' 'DirectX component missing' $ev 'HIGH' ('Install the official Microsoft DirectX End-User Runtime.' + $redist) 'dep' @('https://www.microsoft.com/en-us/download/details.aspx?id=35')
        } elseif ($c -eq 'VC++') {
            Add-Finding 'Dependencies' 'Visual C++ Redistributable missing' $ev 'HIGH' ('Install the official Microsoft Visual C++ Redistributable (x86 and x64).' + $redist) 'dep' @('https://learn.microsoft.com/cpp/windows/latest-supported-vc-redist')
        } elseif ($c -eq 'OpenAL') {
            Add-Finding 'Dependencies' 'OpenAL runtime missing' $ev 'HIGH' ('Install the official OpenAL runtime.' + $redist) 'dep' @('https://www.openal.org/downloads/')
        } elseif ($c -eq 'PhysX') {
            Add-Finding 'Dependencies' 'PhysX runtime missing' $ev 'HIGH' ('Install the PhysX runtime that ships with the game or from NVIDIA.' + $redist) '' $null
        } else {
            $rid = ''; $rec = 'Use the official verify / repair function of your launcher. Do not download single DLL files.'
            if (($g.Launcher -eq 'Steam') -and $g.AppId) { $rid = 'steamverify'; $rec = 'Let Steam verify and repair the game files. Do not download single DLL files.' }
            Add-Finding 'Dependencies' 'Required library missing' $ev 'HIGH' $rec $rid $g.AppId
        }
    }
    $script:Sec['Dependencies'] = '[!] Dependency issue detected - see Detected Issues'
}

# ------------------------------------------------------------------ mods
function Detect-Mods {
    $g = $script:G
    $found = @()
    $dirs = @($g.Root)
    if ($g.Exe) { $dirs += (Split-Path $g.Exe -Parent) }
    foreach ($d in ($dirs | Select-Object -Unique)) {
        foreach ($f in @(Get-ChildItem -LiteralPath $d -File -Force -ErrorAction SilentlyContinue)) {
            if ($f.Name -match '(?i)^(dinput8|dsound|d3d8|d3d9|d3d10|d3d11|dxgi|winmm|version|winhttp|opengl32|xinput9_1_0)\.dll$' -or
                $f.Name -match '(?i)^(scripthook.*|asiloader.*|reshade.*|dxvk.*|enb.*|dsoal.*)\.(dll|ini)$' -or
                $f.Extension -ieq '.asi') { $found += $f.FullName }
        }
        foreach ($sub in @('mods', 'BepInEx', 'MelonLoader', 'UE4SS', 'reshade-shaders')) {
            $p = Join-Path $d $sub
            if (Test-Path -LiteralPath $p -PathType Container) { $found += $p }
        }
    }
    $g.Mods = @($found | Select-Object -Unique)
    if ($g.Mods.Count -eq 0) { $script:Sec['Mods'] = 'None detected' }
    else { $script:Sec['Mods'] = $TICK + ' Detected (informational) - ' + (($g.Mods | ForEach-Object { Split-Path $_ -Leaf }) -join ', ') }
}

# ------------------------------------------------------ crash + launching
function Get-CrashEvents([string[]]$ExeNames, [datetime]$Since, [string]$RootPath) {
    $out = @()
    $ev = @()
    try { $ev = @(Get-WinEvent -FilterHashtable @{ LogName = 'Application'; Id = 1000; StartTime = $Since } -ErrorAction Stop) } catch { $ev = @() }
    foreach ($e in $ev) {
        $p = $e.Properties
        if ($p.Count -lt 7) { continue }
        $app = [string]$p[0].Value
        $path = ''
        if ($p.Count -gt 10) { $path = [string]$p[10].Value }
        $hit = ($ExeNames -contains $app.ToLower())
        if ((-not $hit) -and $path -and $path.StartsWith($RootPath, [StringComparison]::OrdinalIgnoreCase)) { $hit = $true }
        if ($hit) { $out += [pscustomobject]@{ Time = $e.TimeCreated; App = $app; Module = [string]$p[3].Value; Code = [string]$p[6].Value; Path = $path } }
    }
    return @($out)
}

function Get-CrashFiles([string]$Root, $ExtraDirs, [datetime]$Since) {
    $out = @()
    foreach ($d in (@($Root) + @($ExtraDirs))) {
        if (-not (Test-Path -LiteralPath $d)) { continue }
        $out += @(Get-ChildItem -LiteralPath $d -File -Recurse -Depth 3 -Force -ErrorAction SilentlyContinue |
            Where-Object { ($_.LastWriteTime -ge $Since) -and ($_.Name -match '(?i)crash|\.dmp$|\.mdmp$|minidump') } | Select-Object -First 10 | ForEach-Object { $_.FullName })
    }
    return @($out)
}

function Get-GameProcs([string]$Root) {
    $list = @()
    try {
        $cp = @(Get-CimInstance Win32_Process -ErrorAction Stop | Where-Object { $_.ExecutablePath -and $_.ExecutablePath.StartsWith($Root + '\', [StringComparison]::OrdinalIgnoreCase) })
        foreach ($c in $cp) { $list += [pscustomobject]@{ ProcId = [int]$c.ProcessId; Name = [string]$c.Name; Path = [string]$c.ExecutablePath; Parent = [int]$c.ParentProcessId } }
    } catch { }
    return @($list)
}

function Get-SteamLaunchErrors([string]$AppId, [datetime]$Since) {
    $out = @()
    $sp = Get-SteamPath
    if ((-not $sp) -or (-not $AppId)) { return @($out) }
    foreach ($rel in @('logs\console_log.txt', 'logs\content_log.txt')) {
        $file = Join-Path $sp $rel
        if (-not (Test-Path -LiteralPath $file)) { continue }
        $lines = @()
        try { $lines = @(Get-Content -LiteralPath $file -Tail 400 -ErrorAction Stop) } catch { continue }
        foreach ($l in $lines) {
            if ($l -match '^\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\]') {
                $t = [datetime]::MinValue
                if ([datetime]::TryParseExact($Matches[1], 'yyyy-MM-dd HH:mm:ss', [cultureinfo]::InvariantCulture, [Globalization.DateTimeStyles]::None, [ref]$t)) {
                    if (($t -ge $Since.AddSeconds(-2)) -and ($l -match ('(?i)(AppID|app) ' + $AppId + '\b')) -and ($l -match '(?i)fail|error|corrupt|disk write|unable|cannot|invalid')) { $out += $l.Trim() }
                }
            }
        }
    }
    return @($out | Select-Object -First 5)
}

# The toolkit runs as administrator, but a player starts a game with normal rights. Some games
# (FiveM, for example) refuse to run elevated, so the test must start the game like a double-click would.
function Test-Admin {
    try { return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) } catch { return $false }
}

# Starts a file or a launcher link through the normal (non-elevated) Windows shell when we are elevated.
function Start-AsNormalUser([string]$Target) {
    if (Test-Admin) { Start-Process -FilePath 'explorer.exe' -ArgumentList ('"' + $Target + '"') -ErrorAction Stop }
    else { Start-Process -FilePath $Target -ErrorAction Stop }
}

function Resolve-LaunchMethod($g) {
    $m = @{ Kind = 'manual'; Label = 'Manual start (monitor only)'; Uri = ''; Exe = ''; Why = '' }
    if ($g.Launcher -eq 'Steam') {
        if ($g.AppId) { $m.Kind = 'uri'; $m.Label = 'Steam'; $m.Uri = 'steam://rungameid/' + $g.AppId }
        else { $m.Why = 'The Steam App ID could not be determined.' }
    }
    elseif ($g.Launcher -eq 'Epic Games') {
        if ($g.EpicUri) { $m.Kind = 'uri'; $m.Label = 'Epic Games Launcher'; $m.Uri = $g.EpicUri }
        else { $m.Why = 'The Epic launcher manifest for this game was not found.' }
    }
    elseif (($g.Launcher -eq 'Standalone') -or ($g.Launcher -eq 'GOG Galaxy')) {
        if ($g.AntiCheat.Count -gt 0) { $m.Why = 'Anti-cheat files were found (' + ($g.AntiCheat -join ', ') + '), so a direct launch is not used.' }
        elseif ($g.ExeConf -and $g.Exe -and (Test-Path -LiteralPath $g.Exe)) { $m.Kind = 'direct'; $m.Label = 'Direct Executable'; $m.Exe = $g.Exe }
        else { $m.Why = 'The game executable could not be determined with confidence.' }
    }
    else { $m.Why = 'The official launch method for ' + $g.Launcher + ' cannot be determined automatically.' }
    return $m
}

function Invoke-LaunchAttempt([int]$Number) {
    $g = $script:G
    $r = @{ Attempt = $Number; State = 'UNKNOWN'; Method = ''; Notes = @(); ExeNames = @(); Window = $false; WindowTitle = ''
            ExitCodes = @(); Events = @(); Files = @(); Seconds = 0; LauncherErrors = @(); Started = (Get-Date); Children = 0 }
    $m = Resolve-LaunchMethod $g
    $base = @(Get-GameProcs $g.Root)
    $seen = @{}
    $start = Get-Date
    $r.Started = $start
    $r.State = 'LAUNCHING'
    if ($base.Count -gt 0) {
        $r.Method = 'Already running (no launch performed)'
        $r.Notes += 'The game was already running, so the existing process is monitored.'
    } elseif ($m.Kind -eq 'manual') {
        $r.Method = $m.Label
        if ($m.Why) { $r.Notes += $m.Why }
        Line ('  ' + $m.Why) 'Yellow'
        Line '  Start the game yourself from its launcher now. Game Doctor will watch for it.' 'Yellow'
        [void](Read-Host '  Press Enter AFTER you pressed Play')
        $start = Get-Date; $r.Started = $start
    } else {
        $r.Method = $m.Label
        if ($g.Launcher -eq 'Steam') {
            $sr = @(Get-Process -Name 'steam' -ErrorAction SilentlyContinue)
            if ($sr.Count -eq 0) { $r.Notes += 'Steam was not running before the launch request.' }
        }
        try {
            if (Test-Admin) {
                # processes are found afterwards by their install folder, so no handle from Start-Process is needed
                if ($m.Kind -eq 'uri') { Start-AsNormalUser $m.Uri } else { Start-AsNormalUser $m.Exe }
                $r.Notes += 'The game was started with normal user rights (not as administrator), exactly like a double-click. Some games refuse to run as administrator.'
            } elseif ($m.Kind -eq 'uri') { Start-Process -FilePath $m.Uri -ErrorAction Stop }
            else {
                $po = Start-Process -FilePath $m.Exe -WorkingDirectory (Split-Path $m.Exe -Parent) -PassThru -ErrorAction Stop
                if ($po) { try { [void]$po.Handle } catch { }; $seen[[int]$po.Id] = $po }
            }
            $r.Notes += 'Launch request sent.'
        } catch {
            $r.State = 'LAUNCH_FAILED'
            $r.Notes += ('Windows could not start the game: ' + $_.Exception.Message)
            return $r
        }
    }
    $deadline = $start.AddSeconds($StartupTimeout)
    $winSince = $null
    $allGoneSince = $null
    $lastShown = ''
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Seconds 1
        foreach ($c in @(Get-GameProcs $g.Root)) {
            if (-not $seen.ContainsKey($c.ProcId)) {
                $po = Get-Process -Id $c.ProcId -ErrorAction SilentlyContinue
                if ($po) { try { [void]$po.Handle } catch { }; $seen[$c.ProcId] = $po }
                if ($r.ExeNames -notcontains $c.Name.ToLower()) { $r.ExeNames += $c.Name.ToLower() }
            }
        }
        $alive = 0; $haveWin = $false
        foreach ($k in @($seen.Keys)) {
            $po = $seen[$k]
            try {
                $po.Refresh()
                if (-not $po.HasExited) {
                    $alive++
                    if ($po.MainWindowHandle -ne [IntPtr]::Zero) { $haveWin = $true; $r.WindowTitle = [string]$po.MainWindowTitle }
                    if ($r.ExeNames -notcontains $po.ProcessName.ToLower() + '.exe') { $r.ExeNames += ($po.ProcessName.ToLower() + '.exe') }
                }
            } catch { }
        }
        $status = 'waiting for the game process'
        if ($seen.Count -gt 0) { $status = 'processes: ' + $alive + ' running, window: ' + $(if ($haveWin) { 'detected' } else { 'not yet' }) }
        if ($status -ne $lastShown) { Line ('  ' + $status) 'DarkGray'; $lastShown = $status }
        if ($haveWin) { $r.Window = $true; if (-not $winSince) { $winSince = Get-Date } } else { $winSince = $null }
        if ($winSince -and (((Get-Date) - $winSince).TotalSeconds -ge $StableSeconds)) { break }
        if (($seen.Count -gt 0) -and ($alive -eq 0)) {
            if (-not $allGoneSince) { $allGoneSince = Get-Date }
            if (((Get-Date) - $allGoneSince).TotalSeconds -ge 5) { break }
        } else { $allGoneSince = $null }
    }
    $r.Seconds = [int]((Get-Date) - $start).TotalSeconds
    $r.Children = [math]::Max(0, $seen.Count - 1)
    $alive = 0
    foreach ($k in @($seen.Keys)) {
        $po = $seen[$k]
        try {
            $po.Refresh()
            if ($po.HasExited) { $r.ExitCodes += ([int64]$po.ExitCode -band 4294967295) } else { $alive++ }
        } catch { }
    }
    if ($seen.Count -eq 0) {
        $errs = @()
        if ($g.Launcher -eq 'Steam') { $errs = @(Get-SteamLaunchErrors $g.AppId $start) }
        $r.LauncherErrors = $errs
        $fl = $null
        if ($g.Launcher -eq 'Steam') { $fl = Get-AcfFlags }
        if ($errs.Count -gt 0) { $r.State = 'BLOCKED_BY_LAUNCHER' }
        elseif (($fl -ne $null) -and ((($fl -band 4) -eq 0) -or (($fl -band 2) -ne 0))) {
            $r.State = 'BLOCKED_BY_LAUNCHER'
            $r.LauncherErrors = @('Steam StateFlags = ' + $fl + ' (the game is not in a fully installed / up-to-date state).')
        } else { $r.State = 'TIMEOUT'; $r.Notes += 'No game process appeared within ' + $StartupTimeout + ' seconds. The launcher may be showing a dialog (sign-in, update, EULA).' }
        return $r
    }
    if ($alive -gt 0) {
        if ($r.Window) { $r.State = 'RUNNING' } else { $r.State = 'RUNNING_NO_WINDOW' }
        return $r
    }
    # every process has exited - look for real crash evidence, never assume
    $names = @($r.ExeNames)
    foreach ($k in @($seen.Keys)) { try { $nm = $seen[$k].ProcessName.ToLower() + '.exe'; if ($names -notcontains $nm) { $names += $nm } } catch { } }
    $r.ExeNames = $names
    $r.Events = @(Get-CrashEvents $names $start.AddSeconds(-5) $g.Root)
    $r.Files = @(Get-CrashFiles $g.Root $g.ConfigDirs $start)
    $ntstatus = @($r.ExitCodes | Where-Object { $_ -ge 3221225472 })
    $nonzero = @($r.ExitCodes | Where-Object { $_ -ne 0 })
    if (($r.Events.Count -gt 0) -or ($ntstatus.Count -gt 0)) { $r.State = 'CRASHED' }
    elseif ($nonzero.Count -gt 0) { $r.State = 'EXITED_WITH_ERROR' }
    else { $r.State = 'EXITED_NORMALLY' }
    return $r
}

function Show-Attempt($r) {
    Line ('  Attempt ' + $r.Attempt + ': ' + $r.State + '   (method: ' + $r.Method + ', ' + $r.Seconds + 's)') 'White'
    foreach ($n in $r.Notes) { Line ('    - ' + $n) 'Gray' }
    if ($r.ExeNames.Count -gt 0) { Line ('    Process: ' + ($r.ExeNames -join ', ')) 'Gray' }
    if ($r.Window) { Line ('    Window: ' + $TICK + ' detected' + $(if ($r.WindowTitle) { ' - ' + $r.WindowTitle } else { '' })) 'Green' }
    if ($r.ExitCodes.Count -gt 0) { Line ('    Exit code(s): ' + (($r.ExitCodes | ForEach-Object { '0x{0:X8}' -f $_ }) -join ', ')) 'Gray' }
    foreach ($e in $r.Events) { Line ('    [!] Windows Application Error: ' + $e.App + ' | exception ' + $e.Code + ' | module ' + $e.Module) 'Red' }
    foreach ($e in $r.LauncherErrors) { Line ('    Launcher evidence: ' + $e) 'Yellow' }
}

function Run-LaunchTest {
    $g = $script:G
    $script:Attempts.Clear()
    $script:Sec['Launch Test'] = 'NOT_TESTED'
    $m = Resolve-LaunchMethod $g
    Line ''
    Line ('  Launch method : ' + $m.Label) 'White'
    if ($m.Why) { Line ('  Note          : ' + $m.Why) 'Yellow' }
    Line ''
    Line '  This will START the game. Save your work in other apps first.' 'Yellow'
    Line '  The launch is the real test: it decides whether anything Game Doctor found actually matters.' 'Gray'
    if (-not (Ask-YN '  Start the launch test now?')) { Line '  Launch test skipped. Nothing was started.' 'Gray'; $script:Sec['Launch Test'] = 'NOT_TESTED (skipped by the user)'; return }
    $n = 0
    while ($n -lt $MaxAttempts) {
        $n++
        Line ''
        Line ('  Launch test - attempt ' + $n + ' (timeout ' + $StartupTimeout + ' s)...') 'Cyan'
        $r = Invoke-LaunchAttempt $n
        [void]$script:Attempts.Add($r)
        Show-Attempt $r
        Log ('Launch attempt ' + $n + ' = ' + $r.State)
        if (($r.State -eq 'RUNNING') -or ($r.State -eq 'RUNNING_NO_WINDOW') -or ($r.State -eq 'EXITED_NORMALLY')) { break }
        if ($n -ge $MaxAttempts) { break }
        # Steam was already running and still created no game process: a second identical try tells nothing new
        if (($r.State -eq 'TIMEOUT') -and ($g.Launcher -eq 'Steam') -and (@($r.Notes | Where-Object { $_ -match 'was not running' }).Count -eq 0)) {
            Line ''
            Line '  Steam was already running and did not start the game, so repeating the test would show nothing new.' 'Yellow'
            Line '  Moving on to the diagnosis.' 'Gray'
            break
        }
        Line ''
        Line '  One failed attempt is not proof that the game is broken.' 'Yellow'
        if (-not (Ask-YN '  Retry the launch test?')) { break }
    }
    $script:LaunchDone = $true
    $last = $script:Attempts[$script:Attempts.Count - 1]
    $script:Sec['Launch Test'] = $last.State
    if (($last.State -eq 'RUNNING') -or ($last.State -eq 'RUNNING_NO_WINDOW')) {
        Line ''
        if (Ask-YN '  The game is still running. Ask it to close now?') {
            foreach ($p in @(Get-GameProcs $g.Root)) { try { $po = Get-Process -Id $p.ProcId -ErrorAction Stop; [void]$po.CloseMainWindow() } catch { } }
            $script:Actions.Add('Asked the game window to close after the launch test.') | Out-Null
        } else { Line '  The game was left running.' 'Gray' }
    }
}

# Plain-language meaning of a crash. These are the usual causes, never a proof of one single cause.
function Explain-Crash([string]$Code, [string]$Module, [string]$GameExe, $ModNames) {
    $out = @()
    $c = ([string]$Code).ToLower().Replace('0x', '')
    if (($c.Length -gt 0) -and ($c.Length -lt 8)) { $c = $c.PadLeft(8, '0') }
    $m = ([string]$Module).ToLower()
    switch ($c) {
        'c0000005' { $out += 'Access violation (the program touched memory it must not). Usual causes: a bug in the game, a mod or overlay, an unstable overclock, or a faulty driver. The code alone does not say which.' }
        'c0000135' { $out += 'A required DLL was not found when the program started. Usually a missing runtime (Visual C++, DirectX) or damaged game files.' }
        'c000007b' { $out += 'A DLL could not be loaded (32-bit / 64-bit mismatch or a damaged DLL). Usually a missing runtime - install both the x86 and x64 Visual C++ Redistributables.' }
        'c0000142' { $out += 'A DLL failed to initialize. Often a runtime problem or software that injects into the game.' }
        'c0000409' { $out += 'A built-in safety check detected memory corruption (fast-fail). Often a game bug, a mod, or a conflicting overlay or anti-cheat.' }
        'c0000374' { $out += 'Heap corruption. Often a game bug, a mod, or unstable memory (RAM overclock / XMP).' }
        'c00000fd' { $out += 'Stack overflow. Almost always a bug in the game or in a mod.' }
        'c000001d' { $out += 'Illegal CPU instruction. The game used an instruction this CPU does not support, or the CPU is unstable (overclock).' }
        'e0434352' { $out += '.NET exception. The .NET Runtime entry in Windows Event Viewer has the real error. Often a missing .NET runtime or a broken mod.' }
        '887a0005' { $out += 'The graphics device was removed (GPU driver crash, overheating or unstable overclock).' }
        '887a0006' { $out += 'The graphics device stopped responding (GPU driver crash, overheating or unstable overclock).' }
        '887a0007' { $out += 'The graphics device was reset (GPU driver problem).' }
    }
    if ($m -match '^(nvwgf2um|nvlddmkm|nvoglv|nvd3dum|nvapi)') { $out += 'The crash happened inside the NVIDIA graphics driver. Update or clean-install the driver (Gaming Fixes, option 8). If it keeps happening, check the GPU temperature and any overclock.' }
    elseif ($m -match '^(atidxx|atiumd|amdxx|amdvlk|amdkmdag|atio6axx|aticfx)') { $out += 'The crash happened inside the AMD graphics driver. Update or clean-install the driver (Gaming Fixes, option 8). If it keeps happening, check the GPU temperature and any overclock.' }
    elseif ($m -match '^(igd|ig9|igxel|igc|igdumd)') { $out += 'The crash happened inside the Intel graphics driver. Update the driver from Intel or your PC maker.' }
    elseif ($m -match '^(d3d\d+|dxgi|d3dcompiler|d3d12core)') { $out += 'The crash happened inside a DirectX component, which usually points to the graphics driver or the GPU rather than to missing game files.' }
    elseif ($m -match '(easyanticheat|^eac|beclient|battleye|^vgk|equ8)') { $out += 'The crash happened inside an anti-cheat module. Restart the anti-cheat service or reinstall it through the game launcher.' }
    elseif ($m -match '^(vcruntime|msvcp|msvcr|ucrtbase)') { $out += 'The crash was raised through the C/C++ runtime, which usually means the game stopped itself after an internal error.' }
    elseif (($ModNames) -and (@($ModNames) -contains $m)) { $out += 'The crash happened inside a file that looks like a mod / injector. Test without it.' }
    elseif ($GameExe -and ($m -eq $GameExe.ToLower())) { $out += 'The crash happened in the game''s own code.' }
    elseif (@('ntdll.dll', 'kernelbase.dll', 'kernel32.dll', 'unknown') -contains $m) { $out += 'The faulting module is a Windows core library, where many different failures are reported. It does not point to a specific cause.' }
    return @($out | Select-Object -Unique)
}

function Build-LaunchFindings {
    Clear-Findings 'Launch'
    Clear-Findings 'Mods'
    $g = $script:G
    $att = @($script:Attempts)
    if ($att.Count -eq 0) { return }
    $modNames = @($g.Mods | ForEach-Object { (Split-Path $_ -Leaf).ToLower() })
    $gameExe = ''
    if ($g.Exe) { $gameExe = (Split-Path $g.Exe -Leaf) }
    $ok = @($att | Where-Object { ($_.State -eq 'RUNNING') -or ($_.State -eq 'RUNNING_NO_WINDOW') -or ($_.State -eq 'EXITED_NORMALLY') })
    $bad = @($att | Where-Object { $ok -notcontains $_ })
    if (($ok.Count -gt 0) -and ($bad.Count -gt 0)) {
        # the game did start at least once: informational only, never reported as a problem
        Add-Finding 'Launch' 'Not every launch attempt succeeded' @($att | ForEach-Object { 'Attempt ' + $_.Attempt + ': ' + $_.State }) 'LOW' 'The game does start. A first failed attempt is often just the launcher starting up. If it keeps happening, look at the crash evidence, if any.'
    } elseif ($bad.Count -gt 0) {
        $l = $bad[$bad.Count - 1]
        if ($l.State -eq 'CRASHED') {
            $ev = @()
            foreach ($e in $l.Events) {
                $ev += ('Windows Application Error: ' + $e.App + ' | exception ' + $e.Code + ' | faulting module ' + $e.Module)
                foreach ($mm in @(Explain-Crash $e.Code $e.Module $gameExe $modNames)) { $ev += ('Meaning: ' + $mm) }
            }
            foreach ($c in @($l.ExitCodes | Where-Object { $_ -ge 3221225472 })) {
                $ev += ('Process exit code is an exception status: 0x{0:X8}' -f $c)
                if (@($l.Events).Count -eq 0) { foreach ($mm in @(Explain-Crash ('{0:X8}' -f $c) '' $gameExe $modNames)) { $ev += ('Meaning: ' + $mm) } }
            }
            foreach ($f in $l.Files) { $ev += ('Crash file created during the test: ' + $f) }
            Add-Finding 'Launch' 'The game crashed during the launch test' $ev 'CONFIRMED' 'The exception code and the faulting module above are the evidence. Game Doctor does not guess beyond them.' '' $null -Kind 'PROOF'
        } elseif ($l.State -eq 'BLOCKED_BY_LAUNCHER') {
            Add-Finding 'Launch' 'The launcher did not let the game start' (@('The launch request was sent, but no game process was created.') + @($l.LauncherErrors)) 'MEDIUM' 'Resolve the message shown by the launcher, then run the test again.' '' $null -Kind 'PROOF'
        } elseif ($l.State -eq 'LAUNCH_FAILED') {
            Add-Finding 'Launch' 'Windows could not start the game' @($l.Notes) 'CONFIRMED' 'Resolve the Windows error above.' '' $null -Kind 'PROOF'
        }
        # EXITED_WITH_ERROR / TIMEOUT / UNKNOWN: there is no evidence of a cause - reported as "not proven", never invented
    }
    # mod correlation (crash inside a detected third-party module during THIS test)
    foreach ($a in $att) {
        foreach ($e in $a.Events) {
            if ($modNames -contains $e.Module.ToLower()) {
                Add-Finding 'Mods' 'The crash happened inside a mod / injector file' @('Faulting module: ' + $e.Module) 'MEDIUM' 'Test without that file. Game Doctor never removes mods automatically.' '' $null -Kind 'PROOF'
            }
        }
    }
}

function Get-TdrCount([datetime]$Since) {
    try { return @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; ProviderName = 'Display'; Id = 4101; StartTime = $Since } -ErrorAction Stop).Count } catch { return 0 }
}

# Past events are history. They are shown, but they are never counted as a current problem.
function Check-CrashHistory {
    $g = $script:G
    Clear-Findings 'CrashHistory'
    $names = @()
    if ($g.Exe) { $names += (Split-Path $g.Exe -Leaf).ToLower() }
    foreach ($a in $script:Attempts) { foreach ($n in $a.ExeNames) { if ($names -notcontains $n) { $names += $n } } }
    $since = (Get-Date).AddDays(-7)
    $ev = @(Get-CrashEvents $names $since $g.Root)
    $script:CrashInfo = $ev
    $launchCrash = @($script:Attempts | Where-Object { $_.State -eq 'CRASHED' })
    $modNames = @($g.Mods | ForEach-Object { (Split-Path $_ -Leaf).ToLower() })
    $gameExe = ''
    if ($g.Exe) { $gameExe = (Split-Path $g.Exe -Leaf) }
    if ($launchCrash.Count -gt 0) { $script:Sec['Crash Evidence'] = '[!] CRASH DETECTED during the launch test' }
    elseif ($ev.Count -gt 0) {
        $script:Sec['Crash Evidence'] = 'None during the launch test. History: ' + $ev.Count + ' Windows crash event(s) for this game in the last 7 days.'
        $lines = @()
        foreach ($grp in @($ev | Group-Object -Property { $_.Module + '|' + $_.Code } | Sort-Object Count -Descending | Select-Object -First 3)) {
            $first = $grp.Group[0]
            $lines += ('Faulting module ' + $first.Module + ', exception ' + $first.Code + ', ' + $grp.Count + ' time(s), last on ' + (($grp.Group | Sort-Object Time -Descending | Select-Object -First 1).Time.ToString('yyyy-MM-dd HH:mm', [cultureinfo]::InvariantCulture)))
            foreach ($mm in @(Explain-Crash $first.Code $first.Module $gameExe $modNames)) { $lines += ('Meaning: ' + $mm) }
        }
        Add-Finding 'CrashHistory' ('Windows recorded ' + $ev.Count + ' crash(es) of this game in the last 7 days') $lines 'LOW' 'These happened outside the launch test, so Game Doctor cannot reproduce them. If they continue, the Meaning lines show where to look.'
        foreach ($e in $ev) {
            if ($modNames -contains $e.Module.ToLower()) {
                Add-Finding 'Mods' 'A past crash happened inside a mod / injector file' @('Crash on ' + $e.Time + ' occurred inside: ' + $e.Module) 'LOW' 'Test without that file. Game Doctor never removes mods automatically.'
                break
            }
        }
    } else { $script:Sec['Crash Evidence'] = $TICK + ' No crash of this game recorded by Windows in the last 7 days' }
    $tdr = Get-TdrCount $since
    if ($tdr -gt 0) {
        Add-Finding 'CrashHistory' ('Windows reset the display driver ' + $tdr + ' time(s) in the last 7 days') @('This is system-wide, not necessarily caused by this game.') 'LOW' 'Repeated display driver resets point to the graphics driver, temperature or an overclock. See Gaming Fixes, option 8.'
    }
}

# ------------------------------------------------------------- diagnosis
function Get-Overall {
    $iss = @(Issues)
    $proof = @($iss | Where-Object { $_.Kind -eq 'PROOF' })
    $ls = Get-LaunchState
    if ($proof.Count -gt 0) { return @{ Kind = 'proven'; Text = '[!] PROBLEM CONFIRMED (' + $proof.Count + ')' } }
    if (($ls -eq 'FAIL') -or ($ls -eq 'FAIL_UNKNOWN')) { return @{ Kind = 'failed'; Text = '[!] THE GAME DID NOT START CORRECTLY - the cause is not proven' } }
    if ($ls -eq 'PASS') { return @{ Kind = 'pass'; Text = $TICK + ' NO PROBLEM FOUND - the game started and stayed running' } }
    if ($ls -eq 'PASS_WEAK') { return @{ Kind = 'pass'; Text = $TICK + ' NO PROBLEM FOUND - the game process is running (no window was detected, it may still be loading)' } }
    if ($ls -eq 'INCONCLUSIVE') { return @{ Kind = 'inconclusive'; Text = '? INCONCLUSIVE - the game closed by itself with exit code 0 (a launcher stub or a normal exit)' } }
    return @{ Kind = 'nottested'; Text = '? NOT TESTED - without the launch test Game Doctor cannot say whether the game works' }
}

function Get-ScopeLines {
    $l = @()
    $l += 'Checked    : launch test, game files are readable and look like programs, configuration files, imported libraries, Windows crash history (7 days).'
    $v = [string]$script:Sec['Integrity']
    if ($v.StartsWith('Verified')) { $l += 'Integrity  : ' + $v + '.' }
    else { $l += 'Not covered: whether every file content matches the original (only the launcher''s own verification can tell), and problems that appear later during gameplay.' }
    return @($l)
}

function Show-Result {
    $o = Get-Overall
    $ls = Get-LaunchState
    $col = 'Green'
    if (($o.Kind -eq 'proven') -or ($o.Kind -eq 'failed')) { $col = 'Red' } elseif (($o.Kind -eq 'inconclusive') -or ($o.Kind -eq 'nottested')) { $col = 'Yellow' }
    Line ''
    Line '--------------------------------------------------' 'DarkGray'
    Line 'RESULT' 'White'
    Line ''
    Line $o.Text $col
    $att = @($script:Attempts)
    if ($att.Count -gt 0) {
        $last = $att[$att.Count - 1]
        Line ('Launch test: ' + $last.State + ' (' + $last.Seconds + ' s, ' + $att.Count + ' attempt(s))') 'Gray'
    }
    $iss = @(Issues)
    if ($o.Kind -eq 'proven') {
        $proof = @($iss | Where-Object { $_.Kind -eq 'PROOF' })
        $i = 0
        foreach ($f in $proof) {
            $i++
            Line ''
            Line ('  ' + $i + '. ' + $f.Title + '   [' + $f.Category + ']') 'Red'
            foreach ($e in $f.Evidence) { if ($e.StartsWith('Meaning: ')) { Line ('     ' + $e) 'Yellow' } else { Line ('     Evidence : ' + $e) 'Gray' } }
            if ($f.Recommended) { Line ('     Recommended: ' + $f.Recommended) 'Yellow' }
        }
        $rest = @($iss | Where-Object { $_.Kind -ne 'PROOF' })
        if ($rest.Count -gt 0) {
            Line ''
            Line '  Also found while the game was failing (possible related causes, not proof by themselves):' 'Yellow'
            foreach ($f in $rest) { Line ('   - ' + $f.Title); foreach ($e in $f.Evidence) { Line ('       ' + $e) 'DarkGray' } }
        }
        if (($ls -eq 'PASS') -or ($ls -eq 'PASS_WEAK')) { Line ''; Line '  The game does start, but the problem above is real and was reported by the system or the launcher.' 'Gray' }
    } elseif ($o.Kind -eq 'failed') {
        Line ''
        Line 'The launch failed, but Game Doctor found no proof of why.' 'Yellow'
        if ($iss.Count -gt 0) {
            Line 'Possible causes found (not proven):' 'Yellow'
            foreach ($f in $iss) { Line ('   - ' + $f.Title + '   [' + $f.Category + ']'); foreach ($e in $f.Evidence) { Line ('       ' + $e) 'DarkGray' } }
        } else {
            Line 'Game files, configuration and imported libraries show no evidence of a problem.' 'Gray'
            Line 'The cause may be outside the game files (graphics driver, Windows, anti-cheat, the launcher).' 'Gray'
        }
    } elseif ($o.Kind -eq 'pass') {
        Line ''
        Line 'The game launched and kept running. No repair is needed.' 'Green'
    } elseif ($o.Kind -eq 'inconclusive') {
        Line ''
        Line 'The process ended by itself without an error, so the test proves nothing either way.' 'Gray'
    } else {
        Line ''
        Line 'Run the diagnosis again and allow the launch test.' 'Gray'
    }
    # everything else is a note: it never counts as a problem
    $notes = @($script:Findings | Where-Object { -not (Is-Issue $_) })
    if ($notes.Count -gt 0) {
        Line ''
        Line 'Notes (not problems):' 'DarkGray'
        foreach ($f in $notes) {
            $tag = ''
            if ((($ls -eq 'PASS') -or ($ls -eq 'PASS_WEAK')) -and ($f.Kind -eq 'SUSPECT') -and (@('CONFIRMED', 'HIGH', 'MEDIUM') -contains $f.Confidence)) { $tag = ' (ignored: the game starts fine, so this has no visible effect)' }
            Line ('  - ' + $f.Title + $tag) 'DarkGray'
            foreach ($e in $f.Evidence) { Line ('      ' + $e) 'DarkGray' }
        }
    }
    Line ''
    foreach ($s in @(Get-ScopeLines)) { Line $s 'DarkGray' }
}

function Show-Sections {
    $g = $script:G
    Line ''
    Line 'GAME DOCTOR' 'Cyan'
    Line ''
    Line ('Game      : ' + $g.Name) 'White'
    Line ('Launcher  : ' + $script:Sec['Launcher']) 'White'
    foreach ($k in $script:Sec.Keys) {
        if ($k -eq 'Launcher') { continue }
        $c = 'Gray'
        if (([string]$script:Sec[$k]).StartsWith($TICK)) { $c = 'Green' } elseif (([string]$script:Sec[$k]).StartsWith('[!]')) { $c = 'Red' }
        Line (($k + ':').PadRight(16) + $script:Sec[$k]) $c
    }
}

function Build-Report {
    $g = $script:G
    $o = Get-Overall
    $L = New-Object System.Collections.ArrayList
    [void]$L.Add('GAME DOCTOR REPORT')
    [void]$L.Add('Generated: ' + (Get-Date).ToString('yyyy-MM-dd HH:mm:ss', [cultureinfo]::InvariantCulture))
    [void]$L.Add('')
    [void]$L.Add('Game:         ' + $g.Name)
    [void]$L.Add('Launcher:     ' + $g.Launcher + $(if ($g.LauncherNote) { ' (' + $g.LauncherNote + ')' } else { '' }))
    [void]$L.Add('Install Path: ' + $g.Root)
    [void]$L.Add('Executable:   ' + $(if ($g.Exe) { $g.Exe } else { 'Unknown' }))
    [void]$L.Add('')
    [void]$L.Add('Overall Status: ' + $o.Text)
    [void]$L.Add('')
    foreach ($k in $script:Sec.Keys) { [void]$L.Add(($k + ':').PadRight(16) + $script:Sec[$k]) }
    if ($script:Attempts.Count -gt 0) {
        [void]$L.Add('')
        [void]$L.Add('Launch attempts:')
        foreach ($a in $script:Attempts) {
            [void]$L.Add('  Attempt ' + $a.Attempt + ': ' + $a.State + ' (method: ' + $a.Method + ', ' + $a.Seconds + 's)')
            foreach ($n in $a.Notes) { [void]$L.Add('    - ' + $n) }
            foreach ($e in $a.Events) { [void]$L.Add('    Crash event: ' + $e.App + ' | ' + $e.Code + ' | module ' + $e.Module) }
        }
    }
    [void]$L.Add('')
    [void]$L.Add('Detected Issues:')
    $iss = @(Issues)
    if ($iss.Count -eq 0) { [void]$L.Add('  None (No Issue)') }
    $i = 0
    foreach ($f in $iss) {
        $i++
        [void]$L.Add('  ' + $i + '. ' + $f.Title + ' [' + $f.Category + ']')
        foreach ($e in $f.Evidence) { [void]$L.Add('     Evidence: ' + $e) }
        [void]$L.Add('     Confidence: ' + $f.Confidence + ' (' + $f.Status + ')')
        if ($f.Recommended) { [void]$L.Add('     Recommended: ' + $f.Recommended) }
    }
    $info = @($script:Findings | Where-Object { -not (Is-Issue $_) })
    if ($info.Count -gt 0) {
        [void]$L.Add('')
        [void]$L.Add('Notes (not problems):')
        foreach ($f in $info) { [void]$L.Add('  - [' + $f.Confidence + '] ' + $f.Title); foreach ($e in $f.Evidence) { [void]$L.Add('      ' + $e) } }
    }
    [void]$L.Add('')
    foreach ($s in @(Get-ScopeLines)) { [void]$L.Add($s) }
    [void]$L.Add('')
    [void]$L.Add('Actions Performed:')
    if ($script:Actions.Count -eq 0) { [void]$L.Add('  None') } else { foreach ($a in $script:Actions) { [void]$L.Add('  - ' + $a) } }
    [void]$L.Add('')
    [void]$L.Add('Verification:')
    if ($script:Verify.Count -eq 0) { [void]$L.Add('  Not applicable') } else { foreach ($a in $script:Verify) { [void]$L.Add('  - ' + $a) } }
    [void]$L.Add('')
    [void]$L.Add('Final Status: ' + $o.Text)
    return @($L)
}

function Save-Report {
    $stamp = (Get-Date).ToString('yyyy-MM-dd_HH-mm-ss', [cultureinfo]::InvariantCulture)
    $file = Join-Path $ReportDir ('GameDoctor_' + (Safe-Name $script:G.Name) + '_' + $stamp + '.txt')
    try {
        [IO.File]::WriteAllLines($file, [string[]](Build-Report), (New-Object Text.UTF8Encoding $true))
        $script:ReportFile = $file
        Line ''
        Line ('  Report saved: ' + $file) 'DarkGray'
        Log ('Report saved: ' + $file)
    } catch { Line ('  Could not save the report: ' + $_.Exception.Message) 'Yellow' }
}

# ------------------------------------------------------------ run modes
function Ensure-Detected { if (-not $script:G) { Do-Detection } }

function Run-Scan([bool]$withLaunchSteps) {
    $total = 8
    Step 1 $total 'Detecting Game...'
    Do-Detection
    Step 2 $total 'Detecting Launcher...'
    Line ('      ' + $script:G.Launcher + ' - ' + $TICK + ' Detected') 'Gray'
    Step 3 $total 'Checking Game Files...'
    Check-Files
    Detect-Mods
    Step 4 $total 'Checking Configuration...'
    Check-Config
    Step 5 $total 'Checking Dependencies...'
    Check-Deps
    $script:ScanDone = $true
}

function Run-Full {
    $script:Attempts.Clear(); $script:LaunchDone = $false
    Run-Scan $true
    Step 6 8 'Testing Game Launch (the real test)...'
    Run-LaunchTest
    Step 7 8 'Analyzing Crash Evidence...'
    Build-LaunchFindings
    Check-CrashHistory
    Step 8 8 'Building Diagnosis...'
    Show-Sections
    Show-Result
    Save-Report
}

# ---------------------------------------------------------------- repairs
function New-BackupDir {
    $stamp = (Get-Date).ToString('yyyy-MM-dd_HH-mm-ss', [cultureinfo]::InvariantCulture)
    $d = Join-Path (Join-Path $BackupRoot (Safe-Name $script:G.Name)) $stamp
    New-Item -ItemType Directory -Path $d -Force | Out-Null
    return $d
}

function Repair-Config($f) {
    $paths = @($f.RepairData | Where-Object { $_ -and (Test-Path -LiteralPath $_) })
    if ($paths.Count -eq 0) { Line '  The affected files no longer exist. Nothing to repair.' 'Gray'; return }
    Line '  Files that will be reset (moved away so the game recreates them):' 'White'
    foreach ($p in $paths) { Line ('    ' + $p) 'Gray' }
    Line '  A backup of every file is created first.' 'Gray'
    if (-not (Ask-YN '  Proceed?')) { Line '  Skipped.' 'Gray'; return }
    $bd = New-BackupDir
    $manifest = @()
    $i = 0
    $failed = $false
    foreach ($p in $paths) {
        $i++
        $dest = Join-Path $bd ('{0:D2}_{1}' -f $i, (Split-Path $p -Leaf))
        try {
            Copy-Item -LiteralPath $p -Destination $dest -Force -ErrorAction Stop
            $h1 = (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash
            $h2 = (Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash
            if ($h1 -ne $h2) { throw 'backup copy does not match the original' }
            $manifest += [pscustomobject]@{ OriginalPath = $p; BackupPath = $dest; SHA256 = $h1; Timestamp = (Get-Date).ToString('s'); Action = 'Configuration file reset (moved away)' }
        } catch { Line ('  Backup failed for ' + $p + ' : ' + $_.Exception.Message + ' - nothing was changed for this file.') 'Red'; $failed = $true; continue }
        try { Remove-Item -LiteralPath $p -Force -ErrorAction Stop }
        catch { Line ('  Could not reset ' + $p + ' : ' + $_.Exception.Message) 'Red'; $failed = $true }
    }
    try { $manifest | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $bd 'manifest.json') -Encoding UTF8 } catch { }
    Line ''
    Line 'Backup Created:' 'Green'
    Line ('  ' + $bd) 'Gray'
    foreach ($m in $manifest) { Line ('  ' + $m.OriginalPath) 'DarkGray' }
    [void]$script:Actions.Add('Configuration reset for ' + $manifest.Count + ' file(s). Backup: ' + $bd)
    Log ('Config reset, backup: ' + $bd)
    $gone = @($manifest | Where-Object { -not (Test-Path -LiteralPath $_.OriginalPath) }).Count
    if ($gone -eq $manifest.Count -and -not $failed) { Line ('  Repair completed. The game recreates default settings on its next start.') 'Green' }
    else { Line '  Repair finished with problems - see the messages above.' 'Yellow' }
}

function Repair-SteamVerify($f) {
    $g = $script:G
    Line '  Steam will verify the files with its own official function.' 'White'
    Line '  It compares every game file with its records and re-downloads only what is damaged or missing.' 'Gray'
    Line '  Steam shows the progress in its own window. This can take several minutes.' 'Gray'
    if (-not (Ask-YN '  Ask Steam to verify the game files now?')) { Line '  Skipped.' 'Gray'; return }
    $d0 = Get-AcfData
    $f0 = $null
    if ($d0 -and $d0.ContainsKey('StateFlags')) { $f0 = [int]$d0['StateFlags'] }
    try { Start-Process -FilePath ('steam://validate/' + $g.AppId) -ErrorAction Stop } catch { Line ('  Could not send the request to Steam: ' + $_.Exception.Message) 'Red'; return }
    [void]$script:Actions.Add('Asked Steam to verify game files (App ID ' + $g.AppId + ').')
    Log ('Steam verify requested for ' + $g.AppId)
    $t0 = Get-Date
    $changed = $false
    $done = $false
    $touched = $false
    Write-Host '  Waiting for Steam' -NoNewline
    while (((Get-Date) - $t0).TotalMinutes -lt 60) {
        Start-Sleep -Seconds 3
        Write-Host '.' -NoNewline
        $d = Get-AcfData
        if ($d -and $d.ContainsKey('StateFlags')) {
            $fl = [int]$d['StateFlags']
            if ($fl -ne $f0) { $changed = $true }
            # Steam asks for an update / downloads only when it found something to replace
            if (($fl -band (2 -bor 256 -bor 1024 -bor 524288)) -ne 0) { $touched = $true }
            $bd = 0
            if ($d.ContainsKey('BytesToDownload')) { try { $bd = [int64]$d['BytesToDownload'] } catch { } }
            if ($bd -gt 0) { $touched = $true }
            if ($changed -and ($fl -eq 4)) { $done = $true; break }
        }
        if ((-not $changed) -and (((Get-Date) - $t0).TotalSeconds -ge 90)) { break }
    }
    Write-Host ''
    if ($done) {
        if ($touched) {
            Line '  Steam found files that needed repair and replaced them.' 'Green'
            $script:Sec['Integrity'] = 'Verified by Steam - damaged or missing files were repaired'
            [void]$script:Verify.Add('Steam verification finished: files were repaired.')
        } else {
            Line '  Steam verified the game files. Game Doctor did not observe any file being replaced.' 'Green'
            $script:Sec['Integrity'] = 'Verified by Steam - no file replacement observed'
            [void]$script:Verify.Add('Steam verification finished: no file replacement observed.')
        }
    } else {
        Line '  Game Doctor could not confirm the end of the verification from Steam data.' 'Yellow'
        [void](Read-Host '  When Steam shows that verification is complete, press Enter')
        [void]$script:Verify.Add('Steam verification was started; the end was confirmed by the user.')
    }
}

function Repair-Dep($f) {
    $urls = @($f.RepairData)
    Line ('  Recommended: ' + $f.Recommended) 'White'
    Line '  Game Doctor never downloads single DLL files. It can open the official page.' 'Gray'
    if (-not (Ask-YN '  Open the official download page now?')) { Line '  Skipped.' 'Gray'; return }
    foreach ($u in $urls) { try { Start-Process -FilePath $u } catch { } }
    [void]$script:Actions.Add('Opened the official page: ' + ($urls -join ', '))
    [void](Read-Host '  Install the component, then press Enter to re-scan')
}

function Run-Repair {
    $g = $script:G
    $ls = Get-LaunchState
    $iss = @(Issues)
    $fixable = @($iss | Where-Object { $_.RepairId })
    # Elimination step: if a Steam game failed to start, Steam's own verification is the only check
    # that compares every file, so it rules damaged files in or out.
    $failed = (($ls -eq 'FAIL') -or ($ls -eq 'FAIL_UNKNOWN'))
    if ($failed -and ($g.Launcher -eq 'Steam') -and $g.AppId -and (@($fixable | Where-Object { $_.RepairId -eq 'steamverify' }).Count -eq 0)) {
        $fixable += [pscustomobject]@{ Category = 'Game Files'; Title = 'Rule out damaged game files'
            Evidence = @('The game did not start correctly and no single cause is proven.', 'Steam compares every file with its own records, which Game Doctor cannot do.')
            Confidence = 'CHECK'; Status = 'Check'; Recommended = 'Let Steam verify the game files.'; RepairId = 'steamverify'; RepairData = $g.AppId; Kind = 'SUSPECT' }
    }
    if (($iss.Count -eq 0) -and ($fixable.Count -eq 0)) { return }
    if ($fixable.Count -eq 0) {
        Line ''
        Line 'The problem found has no automatic repair:' 'Yellow'
        foreach ($f in $iss) { Line ('  - ' + $f.Title + ' : ' + $f.Recommended) 'Gray' }
        return
    }
    $beforeState = $ls
    $beforeAtt = @($script:Attempts)
    $actionsBefore = $script:Actions.Count
    $done = @{}
    foreach ($f in $fixable) {
        Line ''
        Line ('[!] ' + $f.Title.ToUpper()) 'Red'
        foreach ($e in $f.Evidence) { Line ('    Evidence: ' + $e) 'Gray' }
        if ($f.RepairId -eq 'steamverify') { if ($done.ContainsKey('steamverify')) { continue }; $done['steamverify'] = $true; Repair-SteamVerify $f }
        elseif ($f.RepairId -eq 'config') { Repair-Config $f }
        elseif ($f.RepairId -eq 'dep') { Repair-Dep $f }
    }
    if ($script:Actions.Count -eq $actionsBefore) { Save-Report; return }
    # a repair that is not re-tested is only a guess: run the same launch test again
    Line ''
    Line 'Re-checking after the repair...' 'Cyan'
    Check-Files
    Check-Config
    Check-Deps
    Run-LaunchTest
    if ($script:Attempts.Count -eq 0) {
        foreach ($a in $beforeAtt) { [void]$script:Attempts.Add($a) }
        Line ''
        Line '  The launch test was skipped, so the result of the repair is NOT confirmed.' 'Yellow'
        [void]$script:Verify.Add('Repair performed; the result was not confirmed (launch test skipped).')
    } else {
        Build-LaunchFindings
        Check-CrashHistory
        $afterState = Get-LaunchState
        $good = @('PASS', 'PASS_WEAK')
        $bad = @('FAIL', 'FAIL_UNKNOWN')
        Line ''
        if (($bad -contains $beforeState) -and ($good -contains $afterState)) {
            Line ($TICK + ' FIXED - before the repair the game failed to start, now it starts and stays running.') 'Green'
            [void]$script:Verify.Add('Before: ' + $beforeState + '. After: ' + $afterState + '. Fixed.')
        } elseif (($bad -contains $beforeState) -and ($bad -contains $afterState)) {
            Line '[!] NOT FIXED - the game still does not start correctly after the repair.' 'Red'
            Line '    The repair above did not remove the cause. Look at the new evidence below.' 'Gray'
            [void]$script:Verify.Add('Before: ' + $beforeState + '. After: ' + $afterState + '. Not fixed.')
        } else {
            Line ('Result after the repair: ' + $afterState + ' (before: ' + $beforeState + ').') 'Gray'
            [void]$script:Verify.Add('Before: ' + $beforeState + '. After: ' + $afterState + '.')
        }
        Show-Result
    }
    Save-Report
}

# ------------------------------------------------------------------- UI
# Same logo as the toolkit banner: gold frame, white letters
function Show-Banner {
    $rows = @(
        '┌────────────────────────────────────────────────────────────────────────┐'
        '│                                                                        │'
        '│ ███╗   ███╗███████╗███████╗██╗  ██╗ █████╗ ██╗     ███████╗██╗██╗  ██╗ │'
        '│ ████╗ ████║██╔════╝██╔════╝██║  ██║██╔══██╗██║     ██╔════╝██║╚██╗██╔╝ │'
        '│ ██╔████╔██║█████╗  ███████╗███████║███████║██║     █████╗  ██║ ╚███╔╝  │'
        '│ ██║╚██╔╝██║██╔══╝  ╚════██║██╔══██║██╔══██║██║     ██╔══╝  ██║ ██╔██╗  │'
        '│ ██║ ╚═╝ ██║███████╗███████║██║  ██║██║  ██║███████╗██║     ██║██╔╝ ██╗ │'
        '│ ╚═╝     ╚═╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝ │'
        '│                                                                        │'
        '└────────────────────────────────────────────────────────────────────────┘'
    )
    foreach ($r in $rows) {
        if ($r.Length -gt 2 -and $r[1] -ne ([char]0x2500) -and $r.Trim().Length -gt 2 -and $r -match '[\u2588\u2557\u2554\u255D\u2550\u2551\u255A]') {
            Write-Host '  ' -NoNewline
            Write-Host $r.Substring(0, 1) -NoNewline -ForegroundColor Yellow
            Write-Host $r.Substring(1, $r.Length - 2) -NoNewline -ForegroundColor White
            Write-Host $r.Substring($r.Length - 1) -ForegroundColor Yellow
        }
        else { Write-Host ('  ' + $r) -ForegroundColor Yellow }
    }
    Write-Host ''
}

function Read-GamePath {
    while ($true) {
        Line ''
        Line 'Paste the full path of the game folder (example: D:\Games\MyGame).' 'White'
        Line 'Leave empty to exit:' 'DarkGray'
        $p = (Read-Host 'Game Path').Trim().Trim('"')
        if (-not $p) { return $false }
        $err = Test-GamePath $p
        if ($err) { Line ('  ' + $err) 'Red'; continue }
        $script:GamePath = (Resolve-Path -LiteralPath $p).ProviderPath.TrimEnd('\')
        $script:G = $null; $script:ScanDone = $false; $script:LaunchDone = $false
        $script:Attempts.Clear(); $script:Findings.Clear(); $script:Actions.Clear(); $script:Verify.Clear(); $script:Sec = [ordered]@{}
        Log ('Game path set: ' + $script:GamePath)
        return $true
    }
}

# ------------------------------------------------------------------ main
try {
    Clear-Host
    Show-Banner
    Line 'GAME DOCTOR - evidence-based game diagnostics and repair' 'Yellow'
    Line 'Give it the game folder. It checks the files, then starts the game for real to see what happens.' 'Gray'
    Line 'A problem is reported only when there is proof. Nothing is changed without your approval.' 'Gray'
    if (-not (Read-GamePath)) { exit 0 }
    Line ''
    Run-Full
    Run-Repair
    Pause-Key
} catch {
    Line ('Unexpected problem: ' + $_.Exception.Message) 'Red'
    Log ('Unexpected error: ' + $_.Exception.Message)
    Pause-Key
    exit 1
}
exit 0
#GD_END
#SR_BEGIN
# ====================================================================
#  MeshalFix System Reports engine. Started only by System Reports (main menu option 9).
#  Modes: Health, Errors, Crash, Recent, Reliability, Gaming, Report
#  READ-ONLY diagnostics: nothing is repaired, deleted, cleared or changed here.
#  Results of the current toolkit session are kept as small JSON files in SR_DIR
#  and the HTML report is built from them.
#  Rules: missing data is never shown as a passed check. Observations, warnings,
#  possible causes and confirmed findings are kept apart. ASCII only on purpose.
# ====================================================================
param([string]$Mode = 'Health')

$ErrorActionPreference = 'Continue'
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false } catch { }
try { [Threading.Thread]::CurrentThread.CurrentCulture = [Globalization.CultureInfo]::InvariantCulture } catch { }
try { $Host.UI.RawUI.WindowTitle = 'MeshalFix - System Reports' } catch { }
$Inv  = [Globalization.CultureInfo]::InvariantCulture
$Utf8 = New-Object System.Text.UTF8Encoding $false

$SessionDir = $env:SR_DIR
if (-not $SessionDir) { $SessionDir = Join-Path $env:TEMP 'MeshalFix_Session' }
if (-not (Test-Path -LiteralPath $SessionDir)) { New-Item -ItemType Directory -Path $SessionDir -Force | Out-Null }
$LogDir = $env:FT_LOGDIR
if (-not $LogDir) { $LogDir = Join-Path ([Environment]::GetFolderPath('Desktop')) 'MeshalFix_Logs' }
if (-not (Test-Path -LiteralPath $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }
$ToolkitLog = $env:FT_LOGFILE
$IsAdmin = $false
try { $IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) } catch { }
$script:ExitCode = 0
$script:UserMask = $env:USERNAME

# ------------------------------------------------------------ console helpers
function Line([string]$t, [string]$c = 'Gray') { Write-Host $t -ForegroundColor $c }
function Blank { Write-Host '' }
function Log([string]$m) {
    if ($ToolkitLog) {
        try { Add-Content -LiteralPath $ToolkitLog -Value ('[' + (Get-Date).ToString('yyyy-MM-dd HH:mm:ss', $Inv) + '] SYSREPORTS - ' + $m) -ErrorAction SilentlyContinue } catch { }
    }
}
function Get-ConWidth {
    try { $w = $Host.UI.RawUI.WindowSize.Width; if ($w -ge 60) { return ($w - 2) } } catch { }
    return 100
}
function Fit([string]$s, [int]$n) {
    if ($null -eq $s) { return '' }
    $s = ($s -replace '[\r\n\t]+', ' ').Trim()
    if ($s.Length -gt $n) {
        if ($n -gt 3) { return ($s.Substring(0, $n - 3) + '...') }
        return $s.Substring(0, $n)
    }
    return $s
}
function OneLine([string]$s, [int]$n) {
    if ([string]::IsNullOrWhiteSpace($s)) { return '' }
    $first = ''
    foreach ($ln in ($s -split '\r?\n')) { if (-not [string]::IsNullOrWhiteSpace($ln)) { $first = $ln.Trim(); break } }
    return (Fit $first $n)
}
function Wrap-Text([string]$s, [int]$w, [int]$maxLines = 40) {
    $out = New-Object System.Collections.ArrayList
    if ([string]::IsNullOrEmpty($s)) { return @() }
    foreach ($ln in ($s -split '\r?\n')) {
        $ln = $ln.TrimEnd()
        if ($ln.Length -eq 0) { [void]$out.Add(''); continue }
        while ($ln.Length -gt $w) {
            $cut = $ln.LastIndexOf(' ', $w - 1)
            if ($cut -lt 10) { $cut = $w }
            [void]$out.Add($ln.Substring(0, $cut))
            $ln = $ln.Substring($cut).TrimStart()
        }
        [void]$out.Add($ln)
        if ($out.Count -ge $maxLines) { [void]$out.Add('...[more text not shown]'); break }
    }
    return @($out)
}
function Head([string]$t) {
    try { Clear-Host } catch { }
    Line ('  MESHAL FIX  -  ' + $t) 'Yellow'
    Line ('  ' + (Get-Date).ToString('yyyy-MM-dd HH:mm:ss', $Inv) + '   Read-only diagnostics') 'DarkGray'
    Line ('  ' + ('-' * 72)) 'DarkYellow'
}
function Ask-YN([string]$q) {
    while ($true) {
        $a = Read-Host ($q + ' [Y/N]')
        if ($null -eq $a) { return $false }
        $a = $a.Trim()
        if ($a -ieq 'Y') { return $true }
        if ($a -ieq 'N') { return $false }
        Line '  Please enter Y or N.' 'Yellow'
    }
}
function Wait-Enter([string]$m = 'Press Enter to continue') { [void](Read-Host ('  ' + $m)) }

# ------------------------------------------------------------ generic helpers
function Fmt($d) {
    if ($null -eq $d) { return '' }
    try { return ([datetime]$d).ToString('yyyy-MM-dd HH:mm:ss', $Inv) } catch { return [string]$d }
}
function SizeText($b) {
    if ($null -eq $b) { return 'n/a' }
    try { $v = [double]$b } catch { return 'n/a' }
    if ($v -ge 1TB) { return ('{0:N2} TB' -f ($v / 1TB)) }
    if ($v -ge 1GB) { return ('{0:N1} GB' -f ($v / 1GB)) }
    if ($v -ge 1MB) { return ('{0:N1} MB' -f ($v / 1MB)) }
    if ($v -ge 1KB) { return ('{0:N0} KB' -f ($v / 1KB)) }
    return ([string][int64]$v + ' B')
}
function LevelName([int]$l) {
    switch ($l) { 1 { return 'Critical' } 2 { return 'Error' } 3 { return 'Warning' } 4 { return 'Information' } 5 { return 'Verbose' } default { return 'LogAlways' } }
}
function LevelColor([int]$l) {
    switch ($l) { 1 { return 'Red' } 2 { return 'Red' } 3 { return 'Yellow' } default { return 'Gray' } }
}
function StatusText([string]$s) {
    switch ($s) { 'PASSED' { return 'Passed' } 'ISSUE' { return 'Issue detected' } 'WARNING' { return 'Warning' } 'NOTCHECKED' { return 'Not checked' } 'UNKNOWN' { return 'Unable to determine' } default { return 'Info' } }
}
function StatusColor([string]$s) {
    switch ($s) { 'PASSED' { return 'Green' } 'ISSUE' { return 'Red' } 'WARNING' { return 'Yellow' } 'NOTCHECKED' { return 'DarkGray' } 'UNKNOWN' { return 'Magenta' } default { return 'Cyan' } }
}
function SevRank([string]$s) {
    switch ($s) { 'High' { return 3 } 'Medium' { return 2 } 'Low' { return 1 } default { return 0 } }
}
function Short([string]$s, [int]$n) { return (Fit $s $n) }

# Masks user names in profile paths and anything that looks like a product key or secret (used for the HTML report)
function Mask([string]$s) {
    if ([string]::IsNullOrEmpty($s)) { return '' }
    $r = $s
    try {
        if ($script:UserMask) { $r = [regex]::Replace($r, ('(?i)([\\/]Users[\\/])' + [regex]::Escape($script:UserMask) + '(?=[\\/]|$)'), '$1<user>') }
        $r = [regex]::Replace($r, '\b[A-Z0-9]{5}(?:-[A-Z0-9]{5}){4}\b', '[redacted-key]')
        $r = [regex]::Replace($r, '(?i)\b(password|passwd|pwd|token|secret|apikey)\s*[=:]\s*\S+', '$1=[redacted]')
    } catch { }
    return $r
}
# HTML-escapes any value (and strips control characters). Every dynamic value in the report goes through H.
function Esc($s) {
    if ($null -eq $s) { return '' }
    $t = [string]$s
    try { $t = [regex]::Replace($t, '[\x00-\x08\x0B\x0C\x0E-\x1F\uFFFE\uFFFF]', '') } catch { }
    return [System.Net.WebUtility]::HtmlEncode((Mask $t))
}

function Save-Session([string]$name, $obj) {
    try {
        $json = ConvertTo-Json -InputObject $obj -Depth 8
        [IO.File]::WriteAllText((Join-Path $SessionDir ($name + '.json')), $json, $Utf8)
        return $true
    } catch {
        Log ('Could not save session data ' + $name + ': ' + $_.Exception.Message)
        return $false
    }
}
function Load-Session([string]$name) {
    $p = Join-Path $SessionDir ($name + '.json')
    if (-not (Test-Path -LiteralPath $p)) { return $null }
    try { return (ConvertFrom-Json ([IO.File]::ReadAllText($p, [Text.Encoding]::UTF8))) }
    catch { Log ('Could not read session data ' + $name + ': ' + $_.Exception.Message); return $null }
}

function New-Finding([string]$Area, [string]$Title, [string]$Status, [string]$Severity, $Evidence, [string]$Next, [string]$Kind = 'Observation') {
    return [pscustomobject]@{
        Area = $Area; Title = $Title; Status = $Status; Severity = $Severity
        Evidence = @($Evidence | Where-Object { $_ })
        Next = $Next; Kind = $Kind
    }
}

# ------------------------------------------------------------ reference tables
# Windows exception (NTSTATUS) codes that appear in Application Error events
$ExcMap = @{
    'c0000005' = 'Access violation (the program touched memory it was not allowed to use)'
    'c0000409' = 'Stack buffer overrun / fast-fail (the program stopped itself after detecting corruption)'
    'c0000374' = 'Heap corruption detected'
    'c000001d' = 'Illegal instruction'
    'c0000094' = 'Integer divide by zero'
    'c00000fd' = 'Stack overflow'
    'c0000135' = 'A required DLL was not found (STATUS_DLL_NOT_FOUND)'
    'c000007b' = 'Invalid image format, often a 32-bit / 64-bit mismatch (STATUS_INVALID_IMAGE_FORMAT)'
    'c0000142' = 'A DLL failed to initialize (STATUS_DLL_INIT_FAILED)'
    'c0000006' = 'In-page error (data could not be read from disk or a mapped file)'
    'c0000417' = 'Invalid parameter passed to the C runtime'
    '80000003' = 'Breakpoint exception'
    'e0434352' = '.NET (CLR) unhandled exception'
    'e06d7363' = 'C++ exception that was not caught'
}
# Bugcheck (stop) codes, keyed by lowercase hex without leading zeros. Value = NAME|cautious hint
$BugMap = @{
    '1a'  = 'MEMORY_MANAGEMENT|Memory management failure. Often associated with RAM or driver problems; the code alone does not identify the cause.'
    '24'  = 'NTFS_FILE_SYSTEM|File system (NTFS) failure. Can involve the drive, its connection or a driver.'
    '3b'  = 'SYSTEM_SERVICE_EXCEPTION|Exception while running a system service. Frequently involves a driver.'
    '4e'  = 'PFN_LIST_CORRUPT|Memory page list corruption. Often associated with a driver or memory fault.'
    '50'  = 'PAGE_FAULT_IN_NONPAGED_AREA|Invalid memory reference. Can involve drivers, RAM or storage software.'
    '51'  = 'REGISTRY_ERROR|Registry I/O problem.'
    '7a'  = 'KERNEL_DATA_INPAGE_ERROR|Windows could not read paged kernel data. Can involve storage, cabling or memory.'
    '7b'  = 'INACCESSIBLE_BOOT_DEVICE|Windows could not access the boot volume during startup.'
    '7e'  = 'SYSTEM_THREAD_EXCEPTION_NOT_HANDLED|A system thread raised an unhandled exception, often in a driver.'
    '7f'  = 'UNEXPECTED_KERNEL_MODE_TRAP|Unexpected processor trap. Can involve hardware, overclocking or drivers.'
    '8e'  = 'KERNEL_MODE_EXCEPTION_NOT_HANDLED|Kernel-mode exception that was not handled.'
    '9c'  = 'MACHINE_CHECK_EXCEPTION|Hardware reported a fatal machine check.'
    '9f'  = 'DRIVER_POWER_STATE_FAILURE|A driver did not handle a power transition in time (sleep, wake, shutdown).'
    'a'   = 'IRQL_NOT_LESS_OR_EQUAL|Invalid memory access at a high interrupt level. Frequently involves a driver.'
    'be'  = 'ATTEMPTED_WRITE_TO_READONLY_MEMORY|A driver tried to write to read-only memory.'
    'c2'  = 'BAD_POOL_CALLER|Invalid memory pool request, usually from a driver.'
    'c4'  = 'DRIVER_VERIFIER_DETECTED_VIOLATION|Driver Verifier detected a violation.'
    'c5'  = 'DRIVER_CORRUPTED_EXPOOL|Memory pool corruption, usually involving a driver.'
    'd1'  = 'DRIVER_IRQL_NOT_LESS_OR_EQUAL|A driver accessed invalid memory at a high interrupt level.'
    'ef'  = 'CRITICAL_PROCESS_DIED|A critical Windows process ended unexpectedly.'
    'f4'  = 'CRITICAL_OBJECT_TERMINATION|A critical system process or thread ended unexpectedly.'
    '101' = 'CLOCK_WATCHDOG_TIMEOUT|A processor did not respond in time. Can involve hardware, firmware or overclocking.'
    '109' = 'CRITICAL_STRUCTURE_CORRUPTION|Corruption of a protected kernel structure was detected.'
    '116' = 'VIDEO_TDR_FAILURE|The graphics driver could not recover from a timeout. Commonly associated with the graphics driver or GPU; not a confirmed GPU fault.'
    '117' = 'VIDEO_TDR_TIMEOUT_DETECTED|The graphics driver did not respond in time. Commonly associated with the graphics driver or GPU.'
    '119' = 'VIDEO_SCHEDULER_INTERNAL_ERROR|The video scheduler detected a fatal violation. Commonly associated with the graphics driver or GPU.'
    '124' = 'WHEA_UNCORRECTABLE_ERROR|The hardware error architecture reported an uncorrectable hardware error (CPU, memory, PCIe, and similar).'
    '133' = 'DPC_WATCHDOG_VIOLATION|A driver or firmware routine ran too long. Often associated with drivers or storage firmware.'
    '139' = 'KERNEL_SECURITY_CHECK_FAILURE|A kernel integrity check failed, often caused by a driver.'
    '13a' = 'KERNEL_MODE_HEAP_CORRUPTION|Kernel heap corruption, usually from a driver.'
    '141' = 'VIDEO_ENGINE_TIMEOUT_DETECTED|The graphics engine timed out. Commonly associated with the graphics driver or GPU.'
    '154' = 'UNEXPECTED_STORE_EXCEPTION|A storage component raised an unexpected exception. Can involve the drive or its driver.'
    'c000021a' = 'STATUS_SYSTEM_PROCESS_TERMINATED|A critical user-mode system process ended unexpectedly.'
}
function Norm-Hex($v) {
    # returns lowercase hex without 0x and leading zeros, or '' when the value is not a number
    if ($null -eq $v) { return '' }
    $t = ([string]$v).Trim()
    if ($t -match '^0x([0-9a-fA-F]{1,16})$') { $t = $Matches[1] }
    elseif ($t -match '^[0-9a-fA-F]{1,16}$') { }
    else { return '' }
    $t = $t.ToLowerInvariant().TrimStart('0')
    if ($t -eq '') { $t = '0' }
    return $t
}
function Bug-Info([string]$hex) {
    $k = Norm-Hex $hex
    if ($k -ne '' -and $BugMap.ContainsKey($k)) {
        $p = $BugMap[$k].Split('|', 2)
        return [pscustomobject]@{ Name = $p[0]; Hint = $p[1] }
    }
    return [pscustomobject]@{ Name = ''; Hint = '' }
}

# Known events. Text is intentionally cautious: what the event records, possible causes (not confirmed), next steps.
$KB = @{}
function Add-KB([string]$prov, [string]$id, [string]$title, [string]$means, [string]$causes, [string]$next, [string]$cls) {
    $KB[($prov + '|' + $id).ToLowerInvariant()] = [pscustomobject]@{ Title = $title; Means = $means; Causes = $causes; Next = $next; Class = $cls }
}
function Find-KB([string]$prov, $id) {
    $k = (($prov + '|' + [string]$id)).ToLowerInvariant()
    if ($KB.ContainsKey($k)) { return $KB[$k] }
    $k2 = ($prov + '|*').ToLowerInvariant()
    if ($KB.ContainsKey($k2)) { return $KB[$k2] }
    return $null
}
Add-KB 'Microsoft-Windows-Kernel-Power' '41' 'Unexpected restart (Kernel-Power 41)' 'Windows recorded that the system restarted without shutting down cleanly first. The event records that the restart happened, not why.' 'Possible causes include loss of power, a hard reset or power-button press during a freeze, protective shutdown from overheating, a system crash (bugcheck), or unstable hardware or drivers. The event alone does not tell which.' 'Check for a BugCheck event or dump file around the same time (Crash and BSOD Analyzer). If the bugcheck code in the event is 0 and nothing else was recorded, consider power supply, temperatures and whether the PC froze before the restart.' 'restart'
Add-KB 'EventLog' '6008' 'Previous shutdown was unexpected (EventLog 6008)' 'At startup the Event Log service recorded that the previous shutdown was not clean.' 'The same possible causes as Kernel-Power 41: power loss, hard reset, freeze or a crash. This event does not identify which.' 'Compare with Kernel-Power 41 and any BugCheck event in the Crash and BSOD Analyzer.' 'restart'
Add-KB 'Microsoft-Windows-WER-SystemErrorReporting' '1001' 'Restart after a bugcheck (BSOD)' 'Windows recorded that the computer restarted after a bugcheck (stop error) and lists the stop code, its parameters and often a dump file path.' 'The stop code names the kind of failure. The underlying cause is often a driver, hardware or memory problem, but the code alone rarely identifies it.' 'Open the Crash and BSOD Analyzer for details. Finding the faulting driver requires analyzing the dump file with a debugger such as WinDbg.' 'restart'
Add-KB 'BugCheck' '1001' 'Restart after a bugcheck (BSOD)' 'Windows recorded that the computer restarted after a bugcheck (stop error) and lists the stop code, its parameters and often a dump file path.' 'The stop code names the kind of failure. The underlying cause is often a driver, hardware or memory problem, but the code alone rarely identifies it.' 'Open the Crash and BSOD Analyzer for details. Finding the faulting driver requires analyzing the dump file with a debugger such as WinDbg.' 'restart'
Add-KB 'User32' '1074' 'Shutdown or restart was requested (User32 1074)' 'A process or user asked Windows to shut down or restart. This is normally an expected, planned action.' 'Updates, installers, the Start menu or an application can request this.' 'No action needed unless a restart was not expected.' 'info'
foreach ($sid in @('7000','7001','7009','7011','7023','7024','7026','7031','7034')) {
    $stitle = 'Service problem (Service Control Manager ' + $sid + ')'
    switch ($sid) {
        '7000' { $stitle = 'A service failed to start (7000)' }
        '7001' { $stitle = 'A service failed because a dependency did not start (7001)' }
        '7009' { $stitle = 'A service did not respond in time while starting (7009)' }
        '7011' { $stitle = 'Timeout waiting for a service to respond (7011)' }
        '7023' { $stitle = 'A service ended with an error (7023)' }
        '7024' { $stitle = 'A service ended with a service-specific error (7024)' }
        '7026' { $stitle = 'A boot-start or system-start driver failed to load (7026)' }
        '7031' { $stitle = 'A service ended unexpectedly, recovery action configured (7031)' }
        '7034' { $stitle = 'A service ended unexpectedly (7034)' }
    }
    Add-KB 'Service Control Manager' $sid $stitle 'The Service Control Manager reported a problem with the service or driver named in the event message.' 'Possible causes include a disabled or failed dependency, missing or damaged files, permissions, or a conflict. Many services are optional, so a single failure of a rarely used service is often harmless.' 'Read the service name and error text in the event details and decide whether that service matters for your use. Repeated failures of an important service deserve a closer look.' 'service'
}
Add-KB 'Microsoft-Windows-DistributedCOM' '10016' 'DCOM permission message (10016)' 'A program asked to activate a COM component and the security settings did not allow it for that account.' 'This message is frequently logged on working Windows installations and is often harmless.' 'No action is usually needed unless a specific feature is failing. Do not change DCOM permissions without a clear reason.' 'noise'
Add-KB 'Application Error' '1000' 'Application crash (Application Error 1000)' 'A program stopped working. The event lists the program, the faulting module and the exception code.' 'The faulting module shows where the crash happened, not necessarily its cause. Causes range from program bugs to driver, overlay, memory or file problems.' 'Compare the module and exception code across crashes. Repeated identical crashes point to the same problem; update or reinstall the program, and check for related driver issues.' 'app'
Add-KB 'Application Hang' '1002' 'Application stopped responding (Application Hang 1002)' 'A program stopped responding and was closed.' 'A busy or blocked program, a slow disk or network resource, or a driver problem can cause hangs.' 'Check whether it repeats with the same program. Update the program and look for slow storage or network resources.' 'app'
Add-KB '.NET Runtime' '1026' '.NET application crashed (.NET Runtime 1026)' 'A .NET program ended because of an unhandled exception. The message normally includes the exception type and stack trace.' 'Mostly a problem in the program itself or in its configuration or data.' 'Read the exception text in the details. Updating or reinstalling the program is the usual next step.' 'app'
Add-KB 'Windows Error Reporting' '1001' 'Windows Error Reporting record (1001)' 'Windows Error Reporting recorded a problem report. It adds technical details to another crash or failure.' 'This is a supporting record, not a separate problem.' 'Read it together with the Application Error or BugCheck event close to the same time.' 'info'
Add-KB 'Display' '4101' 'Display driver stopped responding and recovered (Display 4101)' 'Windows detected that the display driver did not respond in time, reset it and recovered.' 'Possible causes include a graphics driver problem, a heavy GPU workload, overheating, overclocking, unstable GPU hardware or conflicting overlay software. A single event is not proof of failing hardware.' 'If it repeats, update or cleanly reinstall the graphics driver from the GPU vendor, check temperatures and remove GPU overclocks.' 'display'
Add-KB 'nvlddmkm' '*' 'Message from the NVIDIA display driver' 'The NVIDIA kernel driver logged this event. The message text is the only evidence of what happened.' 'A single driver message does not prove GPU failure. Repeated messages together with crashes or display resets are more significant.' 'Note the time and what you were doing. If it repeats, update or cleanly reinstall the graphics driver.' 'display'
Add-KB 'amdkmdag' '*' 'Message from the AMD display driver' 'The AMD kernel driver logged this event. The message text is the only evidence of what happened.' 'A single driver message does not prove GPU failure. Repeated messages together with crashes or display resets are more significant.' 'Note the time and what you were doing. If it repeats, update or cleanly reinstall the graphics driver.' 'display'
Add-KB 'disk' '7' 'Bad block reported on a disk (disk 7)' 'The disk driver reported a bad block on the device named in the message.' 'Possible causes include damaged storage media, but also cable, controller or driver problems.' 'Back up important data, then check the drive with the manufacturer tool and review its SMART data.' 'storage'
Add-KB 'disk' '11' 'Disk controller error (disk 11)' 'The disk driver detected a controller error on the device named in the message.' 'Possible causes include the drive, its cable or connection, the controller or the driver.' 'Back up important data and check the connection and drive health.' 'storage'
Add-KB 'disk' '51' 'Error during a paging operation (disk 51)' 'Windows detected an error on a device while reading or writing virtual memory.' 'Possible causes include the drive, its connection, the controller or the driver.' 'Back up important data and check drive health. A single event may be a transient condition.' 'storage'
Add-KB 'disk' '153' 'Disk I/O operation was retried (disk 153)' 'An I/O operation had to be retried.' 'Possible causes include a failing drive, a loose connection or a driver or controller problem.' 'Check whether it repeats. If it does, back up data and check drive health.' 'storage'
Add-KB 'Ntfs' '55' 'File system corruption found (Ntfs 55)' 'NTFS reported a corruption in the file system structure of the volume named in the message.' 'Possible causes include an unclean shutdown, a failing drive or connection, or a driver problem.' 'Back up important data. A read-only check is available in the System Repair menu; repairs there ask for your confirmation first.' 'storage'
Add-KB 'Microsoft-Windows-Ntfs' '55' 'File system corruption found (Ntfs 55)' 'NTFS reported a corruption in the file system structure of the volume named in the message.' 'Possible causes include an unclean shutdown, a failing drive or connection, or a driver problem.' 'Back up important data. A read-only check is available in the System Repair menu; repairs there ask for your confirmation first.' 'storage'
Add-KB 'Microsoft-Windows-WHEA-Logger' '*' 'Hardware error reported by Windows (WHEA)' 'The Windows Hardware Error Architecture reported a hardware-level error, for example from the processor, memory or a PCIe device.' 'Corrected errors can be harmless in isolation. Recurring or uncorrectable errors can indicate hardware, firmware, overclocking or power problems.' 'Check whether it repeats. Review the details in the event, remove overclocks and update BIOS and chipset drivers.' 'hardware'
Add-KB 'Microsoft-Windows-WindowsUpdateClient' '20' 'Windows Update installation failure (20)' 'Windows Update reported that an update failed to install. The message contains the update and an error code.' 'Many causes are possible, including servicing problems, disk space or conflicting software.' 'Note the error code in the message. The Windows Update fixes in the System Repair menu can help; they ask for confirmation first.' 'update'
Add-KB 'Microsoft-Windows-Kernel-PnP' '219' 'A driver failed to load for a device (Kernel-PnP 219)' 'Plug and Play could not load the driver for the device named in the message.' 'Possible causes include a missing or incompatible driver, or a device that is no longer connected.' 'Identify the device in the message and update or reinstall its driver if the device matters to you.' 'driver'
Add-KB 'Microsoft-Windows-Resource-Exhaustion-Detector' '2004' 'Low virtual memory was diagnosed (2004)' 'Windows reported that the system ran low on virtual memory (RAM plus page file) and lists the largest memory users.' 'A memory-hungry program, a memory leak or a small page file can cause this.' 'Check the programs named in the message and consider closing them or increasing the page file.' 'memory'

function Get-ExcText([string]$code) {
    $k = Norm-Hex $code
    if ($k -ne '') { $k = $k.PadLeft(8, '0') }
    if ($k -ne '' -and $ExcMap.ContainsKey($k)) { return $ExcMap[$k] }
    return ''
}
function Show-Code([string]$code) {
    $k = Norm-Hex $code
    if ($k -eq '') { return $code }
    return ('0x' + $k.PadLeft(8, '0').ToUpperInvariant())
}

# ------------------------------------------------------------ event retrieval
# Reads events from one or more logs. A log that cannot be read is recorded in Problems
# (so "no events" is never confused with "could not read"). Newest events come first.
function Get-LogEvents {
    param([string[]]$Logs, [datetime]$Since, [int[]]$Levels, [int[]]$Ids, [int]$Max = 1500)
    $res = [pscustomobject]@{
        Events  = (New-Object System.Collections.ArrayList)
        Problems = (New-Object System.Collections.ArrayList)
        Scanned = (New-Object System.Collections.ArrayList)
        Limited = $false
    }
    foreach ($ln in $Logs) {
        $flt = @{ LogName = $ln; StartTime = $Since }
        if ($Levels -and $Levels.Count -gt 0) { $flt['Level'] = $Levels }
        if ($Ids -and $Ids.Count -gt 0) { $flt['Id'] = $Ids }
        $got = @()
        try {
            $got = @(Get-WinEvent -FilterHashtable $flt -MaxEvents $Max -ErrorAction Stop)
            [void]$res.Scanned.Add($ln)
        } catch {
            $fq = [string]$_.FullyQualifiedErrorId
            if ($fq -like 'NoMatchingEventsFound*') {
                [void]$res.Scanned.Add($ln)
                $got = @()
            } else {
                $why = [string]$_.Exception.Message
                if ($_.Exception -is [System.UnauthorizedAccessException]) { $why = 'Access denied. ' + $why }
                [void]$res.Problems.Add(($ln + ': ' + (Fit $why 180)))
                Log ('Event log read problem for ' + $ln + ': ' + $why)
                $got = @()
            }
        }
        if ($got.Count -ge $Max) { $res.Limited = $true }
        foreach ($e in $got) {
            $t = $null
            try { $t = $e.TimeCreated } catch { }
            if ($null -eq $t) { $t = [datetime]::MinValue }
            $lv = 0
            try { if ($null -ne $e.Level) { $lv = [int]$e.Level } } catch { }
            $o = [pscustomobject]@{
                Time = $t; Log = $ln; Provider = [string]$e.ProviderName; Id = [int]$e.Id
                Level = $lv; RecordId = $e.RecordId; Raw = $e
            }
            [void]$res.Events.Add($o)
        }
    }
    return $res
}

function Get-EvMessage($e, [int]$max = 3000) {
    $m = $null
    try { $m = $e.Message } catch { }
    if ([string]::IsNullOrWhiteSpace($m)) {
        try {
            $vals = @($e.Properties | ForEach-Object { [string]$_.Value })
            if ($vals.Count -gt 0) { $m = '(message text not available - raw event data) ' + ($vals -join ' | ') }
        } catch { }
    }
    if ([string]::IsNullOrWhiteSpace($m)) { $m = '(no message text or data available for this event)' }
    $m = ([string]$m).Replace([string][char]0, '')
    if ($m.Length -gt $max) { $m = $m.Substring(0, $max) + ' ...[truncated]' }
    return $m
}

# Returns @{ List = ordered data values; Named = name->value } for an event, from its XML (language independent)
function Get-EvData($e) {
    $list = New-Object System.Collections.ArrayList
    $named = @{}
    try {
        $x = New-Object System.Xml.XmlDocument
        $x.LoadXml([string]$e.ToXml())
        $ns = New-Object System.Xml.XmlNamespaceManager($x.NameTable)
        $ns.AddNamespace('e', 'http://schemas.microsoft.com/win/2004/08/events/event')
        $nodes = $x.SelectNodes('//e:EventData/e:Data', $ns)
        foreach ($n in $nodes) {
            $v = [string]$n.InnerText
            [void]$list.Add($v)
            $nm = [string]$n.GetAttribute('Name')
            if ($nm) { $named[$nm] = $v }
        }
    } catch { }
    if ($list.Count -eq 0) {
        try { foreach ($p in $e.Properties) { [void]$list.Add([string]$p.Value) } } catch { }
    }
    return [pscustomobject]@{ List = $list; Named = $named }
}

# Groups similar events (same log, source, Event ID and level)
function Group-Events($events) {
    $map = @{}
    foreach ($o in $events) {
        $k = ($o.Log + '|' + $o.Provider + '|' + [string]$o.Id + '|' + [string]$o.Level)
        if (-not $map.ContainsKey($k)) {
            $map[$k] = [pscustomobject]@{
                Key = $k; Log = $o.Log; Provider = $o.Provider; Id = $o.Id; Level = $o.Level
                Cnt = 0; First = $o.Time; Last = $o.Time; Latest = $o
                Items = (New-Object System.Collections.ArrayList); MsgCache = $null
            }
        }
        $g = $map[$k]
        $g.Cnt = $g.Cnt + 1
        if ($o.Time -lt $g.First) { $g.First = $o.Time }
        if ($o.Time -gt $g.Last) { $g.Last = $o.Time; $g.Latest = $o }
        if ($g.Items.Count -lt 8) { [void]$g.Items.Add($o) }
    }
    $arr = @($map.Values)
    return @($arr | Sort-Object @{ Expression = { if ($_.Level -eq 0) { 9 } else { $_.Level } }; Ascending = $true }, @{ Expression = { $_.Cnt }; Descending = $true }, @{ Expression = { $_.Last }; Descending = $true })
}
function Group-Msg($g) {
    if ($null -eq $g.MsgCache) { $g.MsgCache = Get-EvMessage $g.Latest.Raw 3000 }
    return $g.MsgCache
}
function Group-ToRecord($g) {
    $kb = Find-KB $g.Provider $g.Id
    $msg = Group-Msg $g
    if ($msg.Length -gt 1500) { $msg = $msg.Substring(0, 1500) + ' ...[truncated]' }
    $rec = [ordered]@{
        Log = $g.Log; Provider = $g.Provider; Id = $g.Id; Level = (LevelName $g.Level)
        Count = $g.Cnt; First = (Fmt $g.First); Last = (Fmt $g.Last); Message = $msg
        Known = [bool]$kb; KbTitle = ''; KbMeans = ''; KbCauses = ''; KbNext = ''; KbClass = ''
    }
    if ($kb) { $rec.KbTitle = $kb.Title; $rec.KbMeans = $kb.Means; $rec.KbCauses = $kb.Causes; $rec.KbNext = $kb.Next; $rec.KbClass = $kb.Class }
    return [pscustomobject]$rec
}

# One scan of System + Application. Used by Errors, Recent and Health.
function Scan-Events([int]$hours, [bool]$withWarnings) {
    $since = (Get-Date).AddHours(-1 * $hours)
    $levels = @(1, 2)
    if ($withWarnings) { $levels = @(1, 2, 3) }
    $r = Get-LogEvents -Logs @('System', 'Application') -Since $since -Levels $levels -Max 1500
    $groups = @(Group-Events $r.Events)
    $nCrit = @($r.Events | Where-Object { $_.Level -eq 1 }).Count
    $nErr  = @($r.Events | Where-Object { $_.Level -eq 2 }).Count
    $nWarn = @($r.Events | Where-Object { $_.Level -eq 3 }).Count
    return [pscustomobject]@{
        Hours = $hours; Since = $since; Levels = $levels; WithWarnings = $withWarnings; Result = $r; Groups = $groups
        Total = $r.Events.Count; Critical = $nCrit; Errors = $nErr; Warnings = $nWarn
        Complete = ($r.Problems.Count -eq 0); Limited = [bool]$r.Limited; Time = (Get-Date)
    }
}
function Save-EventSession([string]$name, $scan) {
    $top = @($scan.Groups | Select-Object -First 60 | ForEach-Object { Group-ToRecord $_ })
    $obj = [ordered]@{
        Module = $name; Generated = (Fmt (Get-Date)); WindowHours = $scan.Hours
        Levels = (@($scan.Levels | ForEach-Object { LevelName $_ }) -join ', ')
        Logs = 'System, Application'; LogsRead = @($scan.Result.Scanned)
        TotalEvents = $scan.Total; Critical = $scan.Critical; Errors = $scan.Errors; Warnings = $scan.Warnings
        GroupCount = $scan.Groups.Count; Limited = $scan.Limited; Complete = $scan.Complete
        Problems = @($scan.Result.Problems); Groups = $top
    }
    [void](Save-Session $name $obj)
    Log ('Saved ' + $name + ': ' + $scan.Total + ' events, ' + $scan.Groups.Count + ' groups, complete=' + $scan.Complete)
}

# ------------------------------------------------------------ system summary
function Get-SystemSummary {
    $s = [ordered]@{ Collected = (Fmt (Get-Date)); Notes = @() }
    $notes = New-Object System.Collections.ArrayList

    $os = $null
    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        $cv = $null
        try { $cv = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction Stop } catch { }
        $s.OS = [ordered]@{
            Caption = [string]$os.Caption; Version = [string]$os.Version; Build = [string]$os.BuildNumber
            Ubr = $(if ($cv) { [string]$cv.UBR } else { '' })
            DisplayVersion = $(if ($cv) { [string]$cv.DisplayVersion } else { '' })
            Edition = $(if ($cv) { [string]$cv.EditionID } else { '' })
            Arch = [string]$os.OSArchitecture; InstallDate = (Fmt $os.InstallDate); LastBoot = (Fmt $os.LastBootUpTime)
            TotalRamMB = [math]::Round([double]$os.TotalVisibleMemorySize / 1024); FreeRamMB = [math]::Round([double]$os.FreePhysicalMemory / 1024)
        }
    } catch { $s.OS = $null; [void]$notes.Add('Windows information: ' + (Fit $_.Exception.Message 120)) }

    try {
        $cs = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
        $cpus = @(Get-CimInstance -ClassName Win32_Processor -ErrorAction SilentlyContinue)
        $bios = Get-CimInstance -ClassName Win32_BIOS -ErrorAction SilentlyContinue
        $mods = @(Get-CimInstance -ClassName Win32_PhysicalMemory -ErrorAction SilentlyContinue)
        $cpuName = ''
        $cores = 0; $threads = 0
        if ($cpus.Count -gt 0) {
            $cpuName = ([string]$cpus[0].Name).Trim()
            foreach ($c in $cpus) { $cores += [int]$c.NumberOfCores; $threads += [int]$c.NumberOfLogicalProcessors }
        }
        $speed = ''
        if ($mods.Count -gt 0 -and $mods[0].Speed) { $speed = [string]$mods[0].Speed + ' MHz' }
        $s.Hardware = [ordered]@{
            Manufacturer = ([string]$cs.Manufacturer).Trim(); Model = ([string]$cs.Model).Trim()
            Cpu = $cpuName; Cores = $cores; Threads = $threads
            RamBytes = [double]$cs.TotalPhysicalMemory; RamModules = $mods.Count; RamSpeed = $speed
            Bios = $(if ($bios) { ([string]$bios.SMBIOSBIOSVersion).Trim() + ' (' + (Fmt $bios.ReleaseDate) + ')' } else { '' })
        }
    } catch { $s.Hardware = $null; [void]$notes.Add('Hardware information: ' + (Fit $_.Exception.Message 120)) }

    $gpus = New-Object System.Collections.ArrayList
    try {
        foreach ($v in @(Get-CimInstance -ClassName Win32_VideoController -ErrorAction Stop)) {
            $drv = [string]$v.DriverVersion
            $brand = ''
            if (([string]$v.Name) -match 'NVIDIA' -and $drv -match '^\d+\.\d+\.(\d+)\.(\d+)$') {
                $digits = ($Matches[1] + $Matches[2])
                if ($digits.Length -ge 5) { $d5 = $digits.Substring($digits.Length - 5); $brand = ($d5.Substring(0, 3) + '.' + $d5.Substring(3)) }
            }
            $ec = 0
            try { if ($null -ne $v.ConfigManagerErrorCode) { $ec = [int]$v.ConfigManagerErrorCode } } catch { }
            [void]$gpus.Add([ordered]@{
                Name = [string]$v.Name; Driver = $drv; DriverDate = (Fmt $v.DriverDate); NvidiaBranded = $brand
                Status = [string]$v.Status; ErrorCode = $ec
                Resolution = $(if ($v.CurrentHorizontalResolution) { [string]$v.CurrentHorizontalResolution + 'x' + [string]$v.CurrentVerticalResolution } else { '' })
            })
        }
    } catch { [void]$notes.Add('Display adapters: ' + (Fit $_.Exception.Message 120)) }
    $s.Gpus = @($gpus)

    $vols = New-Object System.Collections.ArrayList
    $volOk = $false
    try {
        foreach ($v in @(Get-Volume -ErrorAction Stop)) {
            if ($v.DriveType -eq 'Fixed' -and $v.DriveLetter) {
                [void]$vols.Add([ordered]@{
                    Drive = ([string]$v.DriveLetter + ':'); Label = [string]$v.FileSystemLabel; Fs = [string]$v.FileSystem
                    SizeBytes = [double]$v.Size; FreeBytes = [double]$v.SizeRemaining; Health = [string]$v.HealthStatus
                })
            }
        }
        $volOk = $true
    } catch { }
    if (-not $volOk) {
        try {
            foreach ($v in @(Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DriveType=3' -ErrorAction Stop)) {
                [void]$vols.Add([ordered]@{
                    Drive = [string]$v.DeviceID; Label = [string]$v.VolumeName; Fs = [string]$v.FileSystem
                    SizeBytes = [double]$v.Size; FreeBytes = [double]$v.FreeSpace; Health = ''
                })
            }
        } catch { [void]$notes.Add('Storage volumes: ' + (Fit $_.Exception.Message 120)) }
    }
    $s.Volumes = @($vols)

    $disks = New-Object System.Collections.ArrayList
    $diskNote = ''
    try {
        foreach ($d in @(Get-PhysicalDisk -ErrorAction Stop)) {
            $rc = $null
            try { $rc = $d | Get-StorageReliabilityCounter -ErrorAction Stop } catch { $rc = $null }
            $row = [ordered]@{
                Name = [string]$d.FriendlyName; Media = [string]$d.MediaType; Bus = [string]$d.BusType; SizeBytes = [double]$d.Size
                Health = [string]$d.HealthStatus; Operational = (@($d.OperationalStatus) -join ', ')
                Wear = $null; Temp = $null; PowerOnHours = $null; ReadErrUncorrected = $null; WriteErrUncorrected = $null
            }
            if ($rc) {
                $row.Wear = $rc.Wear; $row.Temp = $rc.Temperature; $row.PowerOnHours = $rc.PowerOnHours
                $row.ReadErrUncorrected = $rc.ReadErrorsUncorrected; $row.WriteErrUncorrected = $rc.WriteErrorsUncorrected
            }
            [void]$disks.Add($row)
        }
    } catch { $diskNote = (Fit $_.Exception.Message 140) }
    $s.Disks = @($disks)
    $s.DiskNote = $diskNote

    $act = [ordered]@{ Known = $false; Status = ''; Text = ''; Detail = '' }
    try {
        $lic = Get-CimInstance -ClassName SoftwareLicensingProduct -Filter "ApplicationID='55c92734-d682-4d71-983e-d6ec3f16059f' AND PartialProductKey IS NOT NULL" -ErrorAction Stop | Select-Object -First 1
        if ($lic) {
            $code = [int]$lic.LicenseStatus
            $act.Known = $true; $act.Status = [string]$code
            switch ($code) {
                0 { $act.Text = 'Unlicensed' }
                1 { $act.Text = 'Licensed (activated)' }
                2 { $act.Text = 'Initial grace period' }
                3 { $act.Text = 'Additional grace period' }
                4 { $act.Text = 'Non-genuine grace period' }
                5 { $act.Text = 'Notification mode' }
                6 { $act.Text = 'Extended grace period' }
                default { $act.Text = 'Unrecognized status code ' + $code }
            }
            $act.Detail = [string]$lic.Description
        }
    } catch { }
    $s.Activation = $act

    $pend = New-Object System.Collections.ArrayList
    try { if (Test-Path -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') { [void]$pend.Add('Component servicing is waiting for a restart') } } catch { }
    try { if (Test-Path -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired') { [void]$pend.Add('Windows Update is waiting for a restart') } } catch { }
    try {
        $pf = (Get-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name PendingFileRenameOperations -ErrorAction Stop).PendingFileRenameOperations
        if ($pf) { [void]$pend.Add('Pending file rename operations exist (often left by installers)') }
    } catch { }
    $s.PendingReboot = @($pend)
    $s.Notes = @($notes)
    return $s
}

# ------------------------------------------------------------ crash data
function Get-DumpFiles {
    $items = New-Object System.Collections.ArrayList
    $problems = New-Object System.Collections.ArrayList
    $specs = @(
        @{ Dir = (Join-Path $env:SystemRoot 'Minidump'); Filter = '*.dmp'; Kind = 'Kernel minidump'; Recurse = $false },
        @{ Dir = $env:SystemRoot; Filter = 'MEMORY.DMP'; Kind = 'Kernel or complete memory dump'; Recurse = $false },
        @{ Dir = (Join-Path $env:SystemRoot 'LiveKernelReports'); Filter = '*.dmp'; Kind = 'Live kernel report'; Recurse = $true },
        @{ Dir = (Join-Path $env:LOCALAPPDATA 'CrashDumps'); Filter = '*.dmp'; Kind = 'User-mode crash dump (current user)'; Recurse = $false }
    )
    foreach ($sp in $specs) {
        if (-not (Test-Path -LiteralPath $sp.Dir)) { continue }
        try {
            $files = @()
            if ($sp.Recurse) { $files = @(Get-ChildItem -LiteralPath $sp.Dir -Filter $sp.Filter -File -Recurse -Force -ErrorAction Stop | Sort-Object LastWriteTime -Descending | Select-Object -First 40) }
            else { $files = @(Get-ChildItem -LiteralPath $sp.Dir -Filter $sp.Filter -File -Force -ErrorAction Stop | Sort-Object LastWriteTime -Descending | Select-Object -First 40) }
            foreach ($f in $files) {
                [void]$items.Add([pscustomobject]@{ Path = $f.FullName; Kind = $sp.Kind; SizeBytes = [double]$f.Length; Modified = $f.LastWriteTime })
            }
        } catch { [void]$problems.Add(($sp.Dir + ': ' + (Fit $_.Exception.Message 140))) }
    }
    return [pscustomobject]@{ Items = $items; Problems = $problems }
}
function Get-DumpSettings {
    $r = [ordered]@{ Known = $false; Type = ''; AutoReboot = ''; DumpFile = '' }
    try {
        $c = Get-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl' -ErrorAction Stop
        $r.Known = $true
        switch ([int]$c.CrashDumpEnabled) {
            0 { $r.Type = 'None (no dump is written)' }
            1 { $r.Type = 'Complete memory dump' }
            2 { $r.Type = 'Kernel memory dump' }
            3 { $r.Type = 'Small memory dump (minidump)' }
            7 { $r.Type = 'Automatic memory dump' }
            default { $r.Type = 'Setting value ' + [string]$c.CrashDumpEnabled }
        }
        if ($null -ne $c.AutoReboot) { $r.AutoReboot = $(if ([int]$c.AutoReboot -eq 1) { 'Restart automatically after a crash' } else { 'Do not restart automatically' }) }
        $r.DumpFile = [string]$c.DumpFile
    } catch { }
    return $r
}

function Parse-AppCrash($o) {
    $e = $o.Raw
    $d = Get-EvData $e
    $l = $d.List
    $x = [ordered]@{
        Time = $o.Time; Provider = $o.Provider; Id = $o.Id; Kind = ''; App = ''; AppVer = ''; Module = ''; ModVer = ''
        Code = ''; Offset = ''; ProcId = ''; Path = ''; Parsed = $false; Message = ''
    }
    if ($o.Provider -eq 'Application Error' -and $o.Id -eq 1000) {
        $x.Kind = 'Application crash'
        if ($l.Count -ge 7 -and ([string]$l[6]) -match '^[0-9a-fA-F]{8}$') {
            $x.App = [string]$l[0]; $x.AppVer = [string]$l[1]; $x.Module = [string]$l[3]; $x.ModVer = [string]$l[4]; $x.Code = ([string]$l[6]).ToLowerInvariant()
            if ($l.Count -gt 7) { $x.Offset = [string]$l[7] }
            if ($l.Count -gt 8) { $x.ProcId = [string]$l[8] }
            if ($l.Count -gt 10) { $x.Path = [string]$l[10] }
            $x.Parsed = $true
        }
    } elseif ($o.Provider -eq 'Application Hang' -and $o.Id -eq 1002) {
        $x.Kind = 'Application hang'
        if ($l.Count -ge 1) { $x.App = [string]$l[0]; $x.Parsed = $true }
        if ($l.Count -gt 1) { $x.AppVer = [string]$l[1] }
        if ($l.Count -gt 5 -and ([string]$l[5]) -match '^([A-Za-z]:\\|\\\\)') { $x.Path = [string]$l[5] }
    } elseif ($o.Provider -eq '.NET Runtime' -and $o.Id -eq 1026) {
        $x.Kind = '.NET unhandled exception'
        $txt = ''
        if ($l.Count -ge 1) { $txt = [string]$l[0] }
        $mm = [regex]::Match($txt, '(?im)^[^\r\n:]{1,40}:\s*([^\r\n]+?\.exe)\s*$')
        if ($mm.Success) { $x.App = $mm.Groups[1].Value.Trim(); $x.Parsed = $true }
        $x.Code = 'e0434352'
    }
    $x.Message = Get-EvMessage $e 1500
    return [pscustomobject]$x
}

# Collects application crashes, unexpected restarts / bugchecks and dump files for the window
function Collect-Crashes([datetime]$since) {
    $problems = New-Object System.Collections.ArrayList
    $appEv = Get-LogEvents -Logs @('Application') -Since $since -Ids @(1000, 1001, 1002, 1026) -Max 1500
    $sysEv = Get-LogEvents -Logs @('System') -Since $since -Ids @(41, 1001, 6005, 6006, 6008, 1074) -Max 1500
    foreach ($p in $appEv.Problems) { [void]$problems.Add($p) }
    foreach ($p in $sysEv.Problems) { [void]$problems.Add($p) }

    $crashes = New-Object System.Collections.ArrayList
    $werCount = 0
    $werTypes = @{}
    foreach ($o in $appEv.Events) {
        if (($o.Provider -eq 'Application Error' -and $o.Id -eq 1000) -or ($o.Provider -eq 'Application Hang' -and $o.Id -eq 1002) -or ($o.Provider -eq '.NET Runtime' -and $o.Id -eq 1026)) {
            [void]$crashes.Add((Parse-AppCrash $o))
        } elseif ($o.Provider -eq 'Windows Error Reporting' -and $o.Id -eq 1001) {
            $werCount++
            try {
                $d = Get-EvData $o.Raw
                foreach ($v in $d.List) {
                    if ([string]$v -match '^(APPCRASH|BEX|BEX64|AppHangB1|AppHangXProcB1|MoAppCrash|MoAppHang|CLR20r3|BlueScreen|LiveKernelEvent|PCHang|StoreAppCrash)$') {
                        $nm = [string]$v
                        if ($werTypes.ContainsKey($nm)) { $werTypes[$nm] = $werTypes[$nm] + 1 } else { $werTypes[$nm] = 1 }
                        break
                    }
                }
            } catch { }
        }
    }

    # application crash groups: same program + module + exception code
    $gmap = @{}
    foreach ($c in $crashes) {
        $k = (($c.Kind + '|' + $c.App + '|' + $c.Module + '|' + $c.Code)).ToLowerInvariant()
        if (-not $gmap.ContainsKey($k)) {
            $gmap[$k] = [pscustomobject]@{ Kind = $c.Kind; App = $c.App; Module = $c.Module; Code = $c.Code; Path = $c.Path; AppVer = $c.AppVer; Cnt = 0; First = $c.Time; Last = $c.Time; Items = (New-Object System.Collections.ArrayList) }
        }
        $g = $gmap[$k]
        $g.Cnt = $g.Cnt + 1
        if ($c.Time -lt $g.First) { $g.First = $c.Time }
        if ($c.Time -gt $g.Last) { $g.Last = $c.Time }
        if (-not $g.Path -and $c.Path) { $g.Path = $c.Path }
        if ($g.Items.Count -lt 6) { [void]$g.Items.Add($c) }
    }
    $appGroups = @(@($gmap.Values) | Sort-Object @{ Expression = { $_.Cnt }; Descending = $true }, @{ Expression = { $_.Last }; Descending = $true })

    # incidents: unexpected restarts and bugchecks
    $k41 = @($sysEv.Events | Where-Object { $_.Provider -eq 'Microsoft-Windows-Kernel-Power' -and $_.Id -eq 41 })
    $bug = @($sysEv.Events | Where-Object { $_.Id -eq 1001 -and $_.Provider -match 'WER-SystemErrorReporting|^BugCheck$' })
    $u6008 = @($sysEv.Events | Where-Object { $_.Provider -eq 'EventLog' -and $_.Id -eq 6008 })
    $shut = @($sysEv.Events | Where-Object { $_.Provider -eq 'User32' -and $_.Id -eq 1074 })
    $dumps = Get-DumpFiles
    foreach ($p in $dumps.Problems) { [void]$problems.Add($p) }
    $usedBug = @{}
    $used6008 = @{}
    $incidents = New-Object System.Collections.ArrayList

    foreach ($k in $k41) {
        $inc = [ordered]@{
            Time = $k.Time; Type = 'Unexpected restart (Kernel-Power 41)'; BugCode = ''; BugName = ''; BugHint = ''; BugParams = ''
            DumpPath = ''; DumpExists = $false; Dumps = @(); Related = @(); Evidence = ''; Source = 'Kernel-Power 41'
        }
        $d41 = Get-EvData $k.Raw
        if ($d41.Named.ContainsKey('BugcheckCode')) {
            $bc = 0
            try { $bc = [uint32]$d41.Named['BugcheckCode'] } catch { $bc = 0 }
            if ($bc -ne 0) { $inc.BugCode = ('0x{0:X}' -f $bc) }
        }
        $rel = New-Object System.Collections.ArrayList
        [void]$rel.Add((Fmt $k.Time) + '  Kernel-Power 41: system restarted without a clean shutdown')
        foreach ($b in $bug) {
            if ($usedBug.ContainsKey([string]$b.RecordId)) { continue }
            if ([math]::Abs(($b.Time - $k.Time).TotalMinutes) -le 15) {
                $usedBug[[string]$b.RecordId] = $true
                $bd = Get-EvData $b.Raw
                $joined = (@($bd.List) -join ' ')
                $mc = [regex]::Match($joined, '(0x[0-9a-fA-F]{1,16})\s*\(([^)]*)\)')
                if ($mc.Success) { $inc.BugCode = $mc.Groups[1].Value; $inc.BugParams = $mc.Groups[2].Value.Trim() }
                elseif ($inc.BugCode -eq '') { $m2 = [regex]::Match($joined, '0x[0-9a-fA-F]{1,16}'); if ($m2.Success) { $inc.BugCode = $m2.Value } }
                $dm = [regex]::Match($joined, '[A-Za-z]:\\[^\r\n|]*?\.dmp', 'IgnoreCase')
                if ($dm.Success) { $inc.DumpPath = $dm.Value }
                [void]$rel.Add((Fmt $b.Time) + '  BugCheck record (WER-SystemErrorReporting 1001)')
                break
            }
        }
        foreach ($u in $u6008) {
            if ([math]::Abs(($u.Time - $k.Time).TotalMinutes) -le 15) { $used6008[[string]$u.RecordId] = $true; [void]$rel.Add((Fmt $u.Time) + '  EventLog 6008: previous shutdown was unexpected'); break }
        }
        foreach ($sh in $shut) {
            $diff = ($k.Time - $sh.Time).TotalMinutes
            if ($diff -ge 0 -and $diff -le 30) { [void]$rel.Add((Fmt $sh.Time) + '  User32 1074: a shutdown or restart was requested shortly before'); break }
        }
        $inc.Related = @($rel)
        [void]$incidents.Add($inc)
    }
    foreach ($b in $bug) {
        if ($usedBug.ContainsKey([string]$b.RecordId)) { continue }
        $bd = Get-EvData $b.Raw
        $joined = (@($bd.List) -join ' ')
        $inc = [ordered]@{
            Time = $b.Time; Type = 'Restart after a bugcheck (BSOD)'; BugCode = ''; BugName = ''; BugHint = ''; BugParams = ''
            DumpPath = ''; DumpExists = $false; Dumps = @(); Related = @(((Fmt $b.Time) + '  BugCheck record (WER-SystemErrorReporting 1001)')); Evidence = ''; Source = 'BugCheck 1001'
        }
        $mc = [regex]::Match($joined, '(0x[0-9a-fA-F]{1,16})\s*\(([^)]*)\)')
        if ($mc.Success) { $inc.BugCode = $mc.Groups[1].Value; $inc.BugParams = $mc.Groups[2].Value.Trim() }
        else { $m2 = [regex]::Match($joined, '0x[0-9a-fA-F]{1,16}'); if ($m2.Success) { $inc.BugCode = $m2.Value } }
        $dm = [regex]::Match($joined, '[A-Za-z]:\\[^\r\n|]*?\.dmp', 'IgnoreCase')
        if ($dm.Success) { $inc.DumpPath = $dm.Value }
        [void]$incidents.Add($inc)
    }
    foreach ($u in $u6008) {
        if ($used6008.ContainsKey([string]$u.RecordId)) { continue }
        $dup = $false
        foreach ($i in $incidents) { if ([math]::Abs(($i.Time - $u.Time).TotalMinutes) -le 15) { $dup = $true; break } }
        if ($dup) { continue }
        [void]$incidents.Add([ordered]@{
            Time = $u.Time; Type = 'Previous shutdown was unexpected (EventLog 6008)'; BugCode = ''; BugName = ''; BugHint = ''; BugParams = ''
            DumpPath = ''; DumpExists = $false; Dumps = @(); Related = @(((Fmt $u.Time) + '  EventLog 6008')); Evidence = ''; Source = 'EventLog 6008'
        })
    }

    # bugcheck names, dump association (by event path or by timestamp) and an honest evidence statement
    foreach ($inc in $incidents) {
        if ($inc.BugCode -ne '') { $bi = Bug-Info $inc.BugCode; $inc.BugName = $bi.Name; $inc.BugHint = $bi.Hint }
        if ($inc.DumpPath -ne '') { try { $inc.DumpExists = [bool](Test-Path -LiteralPath $inc.DumpPath) } catch { $inc.DumpExists = $false } }
        $near = New-Object System.Collections.ArrayList
        foreach ($f in $dumps.Items) {
            if ($f.Kind -like 'User-mode*') { continue }
            if ([math]::Abs(($f.Modified - $inc.Time).TotalMinutes) -le 30) { [void]$near.Add($f.Path + '  (' + (SizeText $f.SizeBytes) + ', ' + (Fmt $f.Modified) + ')') }
        }
        $inc.Dumps = @($near)
        if ($inc.DumpExists -or $near.Count -gt 0) {
            $inc.Evidence = 'A dump file is associated with this incident (by the path in the event or by timestamp). Only its name, size and date were inspected; MeshalFix does not analyze dump contents. Identifying a faulting driver needs a debugger such as WinDbg (!analyze -v).'
        } elseif ($inc.BugCode -ne '') {
            $inc.Evidence = 'A stop code was recorded but no matching dump file was found, so the faulting component cannot be identified from this data.'
        } else {
            $inc.Evidence = 'No stop code or dump was recorded. The available evidence does not show whether this was a crash, a power loss or a hard reset.'
        }
    }
    $incSorted = @(@($incidents) | Sort-Object @{ Expression = { $_.Time }; Descending = $true })

    return [pscustomobject]@{
        Since = $since; AppCrashes = $crashes; AppGroups = $appGroups; Incidents = $incSorted
        WerCount = $werCount; WerTypes = $werTypes; Dumps = $dumps.Items; DumpSettings = (Get-DumpSettings)
        Problems = $problems; Complete = ($problems.Count -eq 0); AppOk = ($appEv.Problems.Count -eq 0); SysOk = ($sysEv.Problems.Count -eq 0)
        Limited = ([bool]$appEv.Limited -or [bool]$sysEv.Limited); Time = (Get-Date)
    }
}

# ------------------------------------------------------------ findings
function Cm-Text([int]$c) {
    switch ($c) {
        1  { return 'Device is not configured correctly' }
        3  { return 'Driver may be corrupted or the system is low on memory' }
        10 { return 'Device cannot start' }
        12 { return 'Not enough free resources for the device' }
        14 { return 'Device needs a restart to work properly' }
        18 { return 'Drivers for the device need to be reinstalled' }
        22 { return 'Device is disabled' }
        24 { return 'Device is not present, not working properly, or does not have all drivers installed' }
        28 { return 'Drivers are not installed for the device' }
        31 { return 'Device is not working properly because Windows cannot load its drivers' }
        37 { return 'The driver returned a failure from its initialization routine' }
        39 { return 'The driver is corrupted or missing' }
        43 { return 'Windows stopped the device because it reported problems' }
        52 { return 'Windows cannot verify the digital signature of the driver' }
        default { return 'Windows device error code ' + $c }
    }
}

function Quick-Restarts([datetime]$since) {
    $r = Get-LogEvents -Logs @('System') -Since $since -Ids @(41, 1001, 6008) -Max 500
    $k = @($r.Events | Where-Object { $_.Provider -eq 'Microsoft-Windows-Kernel-Power' -and $_.Id -eq 41 })
    $b = @($r.Events | Where-Object { $_.Id -eq 1001 -and $_.Provider -match 'WER-SystemErrorReporting|^BugCheck$' })
    $u = @($r.Events | Where-Object { $_.Provider -eq 'EventLog' -and $_.Id -eq 6008 })
    $codes = New-Object System.Collections.ArrayList
    foreach ($e in $b) {
        try {
            $d = Get-EvData $e.Raw
            $m = [regex]::Match((@($d.List) -join ' '), '0x[0-9a-fA-F]{1,16}')
            if ($m.Success) { [void]$codes.Add($m.Value) }
        } catch { }
    }
    return [pscustomobject]@{ Kp41 = $k; Bug = $b; E6008 = $u; Codes = @($codes); Problems = @($r.Problems); Complete = ($r.Problems.Count -eq 0) }
}

function Run-DismCheck {
    $r = [pscustomobject]@{ Ran = $true; ExitCode = $null; Result = 'UNKNOWN'; Summary = ''; Output = '' }
    try {
        $out = (& dism.exe /Online /Cleanup-Image /CheckHealth 2>&1 | Out-String)
        $r.ExitCode = $LASTEXITCODE
        $out = $out.Replace([string][char]0, '')
        $r.Output = (Fit $out 1500)
        if ($out -match 'No component store corruption detected') { $r.Result = 'PASSED'; $r.Summary = 'DISM reported: no component store corruption detected.' }
        elseif ($out -match 'component store is repairable') { $r.Result = 'ISSUE'; $r.Summary = 'DISM reported that the component store is repairable (corruption was flagged).' }
        else { $r.Result = 'UNKNOWN'; $r.Summary = ('The DISM result text was not recognized (it may be in another language). Exit code: ' + [string]$r.ExitCode + '.') }
    } catch { $r.Result = 'UNKNOWN'; $r.Summary = ('DISM could not be started: ' + (Fit $_.Exception.Message 120)) }
    return $r
}
function Run-SfcVerify {
    $r = [pscustomobject]@{ Ran = $true; ExitCode = $null; Result = 'UNKNOWN'; Summary = ''; Output = '' }
    $old = $null
    try { $old = [Console]::OutputEncoding } catch { }
    try {
        try { [Console]::OutputEncoding = [Text.Encoding]::Unicode } catch { }
        $out = (& sfc.exe /verifyonly 2>&1 | Out-String)
        $r.ExitCode = $LASTEXITCODE
        $out = $out.Replace([string][char]0, '')
        $r.Output = (Fit $out 1500)
        if ($out -match 'did not find any integrity violations') { $r.Result = 'PASSED'; $r.Summary = 'SFC verify-only reported no integrity violations.' }
        elseif ($out -match 'found integrity violations') { $r.Result = 'ISSUE'; $r.Summary = 'SFC verify-only reported integrity violations. Details are in the CBS.log file.' }
        else { $r.Result = 'UNKNOWN'; $r.Summary = ('The SFC result text was not recognized (it may be in another language or the scan could not run). Exit code: ' + [string]$r.ExitCode + '.') }
    } catch { $r.Result = 'UNKNOWN'; $r.Summary = ('SFC could not be started: ' + (Fit $_.Exception.Message 120)) }
    finally { if ($old) { try { [Console]::OutputEncoding = $old } catch { } } }
    return $r
}

function Add-EventClassFindings($f, $scan) {
    # Groups of known classes, from a completed scan. Always cautious: an isolated entry is not a root cause.
    $cls = @{ storage = (New-Object System.Collections.ArrayList); hardware = (New-Object System.Collections.ArrayList); display = (New-Object System.Collections.ArrayList); memory = (New-Object System.Collections.ArrayList) }
    foreach ($g in $scan.Groups) {
        $kb = Find-KB $g.Provider $g.Id
        if ($kb -and $cls.ContainsKey($kb.Class)) { [void]$cls[$kb.Class].Add($g) }
    }
    $titles = @{ storage = 'Storage or file-system errors were recorded'; hardware = 'Hardware error reports (WHEA) were recorded'; display = 'Display driver errors were recorded'; memory = 'A low virtual memory condition was recorded' }
    foreach ($c in @('storage', 'hardware', 'display', 'memory')) {
        $list = $cls[$c]
        if ($list.Count -eq 0) { continue }
        $total = 0
        $ev = New-Object System.Collections.ArrayList
        $nextText = ''
        foreach ($g in $list) {
            $total += $g.Cnt
            $kb = Find-KB $g.Provider $g.Id
            [void]$ev.Add(([string]$g.Cnt + ' x ' + $g.Provider + ' (Event ' + [string]$g.Id + '), last ' + (Fmt $g.Last)))
            if (-not $nextText) { $nextText = $kb.Next }
        }
        $status = 'WARNING'; $sev = 'Low'
        if ($c -eq 'storage') { $sev = 'Medium'; if ($total -ge 3) { $status = 'ISSUE'; $sev = 'High' } }
        elseif ($c -eq 'hardware') { $sev = 'Medium'; if ($total -ge 3) { $status = 'ISSUE' } }
        elseif ($c -eq 'display') { if ($total -ge 3) { $sev = 'Medium' } }
        [void]$ev.Add('These are observations from the event log. They do not by themselves confirm a failing component.')
        [void]$f.Add((New-Finding 'Events' ($titles[$c] + ' (' + $total + ')') $status $sev $ev $nextText))
    }
}

function Build-HealthFindings($sys, $scan, $rs, $dism, $sfc) {
    $f = New-Object System.Collections.ArrayList

    # activation
    if ($sys.Activation -and $sys.Activation.Known) {
        $code = [int]$sys.Activation.Status
        if ($code -eq 1) { [void]$f.Add((New-Finding 'Windows' 'Windows activation' 'PASSED' 'Info' @('Windows reports: ' + $sys.Activation.Text + '. No product key was read.') '')) }
        elseif ($code -eq 0) { [void]$f.Add((New-Finding 'Windows' 'Windows is not activated' 'ISSUE' 'Low' @('Windows reports: ' + $sys.Activation.Text + '.') 'Open Settings > System > Activation to see the status and options.')) }
        else { [void]$f.Add((New-Finding 'Windows' 'Windows activation is not in the normal licensed state' 'WARNING' 'Low' @('Windows reports: ' + $sys.Activation.Text + '.') 'Open Settings > System > Activation to see the status.')) }
    } else {
        [void]$f.Add((New-Finding 'Windows' 'Windows activation' 'UNKNOWN' 'Info' @('The activation status could not be read reliably on this PC.') 'Open Settings > System > Activation to check it manually.'))
    }

    # pending restart
    if (@($sys.PendingReboot).Count -gt 0) {
        [void]$f.Add((New-Finding 'Windows' 'A restart appears to be pending' 'WARNING' 'Low' @($sys.PendingReboot) 'Restart Windows when convenient, then run the checks again. Some indicators are left behind by installers and do not always mean a restart is required.'))
    } else {
        [void]$f.Add((New-Finding 'Windows' 'Pending restart' 'PASSED' 'Info' @('None of the checked pending-restart indicators were set.') ''))
    }

    # free space
    $vols = @($sys.Volumes)
    if ($vols.Count -gt 0) {
        $st = 'PASSED'; $sev = 'Info'; $ev = New-Object System.Collections.ArrayList
        foreach ($v in $vols) {
            if ($v.SizeBytes -le 0) { continue }
            $pct = [math]::Round(100.0 * $v.FreeBytes / $v.SizeBytes, 1)
            [void]$ev.Add(($v.Drive + '  ' + (SizeText $v.FreeBytes) + ' free of ' + (SizeText $v.SizeBytes) + ' (' + $pct + ' percent free)'))
            if ($pct -lt 5) { $st = 'ISSUE'; $sev = 'Medium' }
            elseif ($pct -lt 10 -and $st -ne 'ISSUE') { $st = 'WARNING'; $sev = 'Low' }
        }
        $nx = ''
        if ($st -ne 'PASSED') { $nx = 'Free up space on the low drive. The Cleaning Tools menu can help.' }
        [void]$f.Add((New-Finding 'Storage' 'Free disk space' $st $sev $ev $nx))
    } else {
        [void]$f.Add((New-Finding 'Storage' 'Free disk space' 'UNKNOWN' 'Info' @('Volume information could not be read.') ''))
    }

    # drive health reported by Windows
    $disks = @($sys.Disks)
    if ($disks.Count -gt 0) {
        foreach ($d in $disks) {
            $ev = New-Object System.Collections.ArrayList
            [void]$ev.Add(($d.Name + ' (' + $d.Media + ', ' + $d.Bus + ', ' + (SizeText $d.SizeBytes) + ')'))
            [void]$ev.Add('Windows storage status: ' + $d.Health + ' / ' + $d.Operational)
            $st = 'UNKNOWN'; $sev = 'Info'
            if ($d.Health -eq 'Healthy') { $st = 'PASSED' }
            elseif ($d.Health -eq 'Warning') { $st = 'WARNING'; $sev = 'Medium' }
            elseif ($d.Health -eq 'Unhealthy') { $st = 'ISSUE'; $sev = 'High' }
            if ($null -ne $d.Wear -and [string]$d.Wear -ne '') { [void]$ev.Add('Wear reported by the drive: ' + [string]$d.Wear + ' percent of rated life used'); if ([double]$d.Wear -ge 80 -and $st -eq 'PASSED') { $st = 'WARNING'; $sev = 'Medium' } }
            if ($null -ne $d.Temp -and [string]$d.Temp -ne '' -and [double]$d.Temp -gt 0) { [void]$ev.Add('Temperature reported: ' + [string]$d.Temp + ' C') }
            $ue = 0
            if ($null -ne $d.ReadErrUncorrected) { $ue += [double]$d.ReadErrUncorrected }
            if ($null -ne $d.WriteErrUncorrected) { $ue += [double]$d.WriteErrUncorrected }
            if ($ue -gt 0) { [void]$ev.Add('Uncorrected read/write errors reported by the drive: ' + [string]$ue); if ($st -eq 'PASSED') { $st = 'WARNING'; $sev = 'Medium' } }
            [void]$ev.Add('This is the status Windows reports. It is not a full SMART analysis.')
            $nx = ''
            if ($st -eq 'WARNING' -or $st -eq 'ISSUE') { $nx = 'Back up important data and check the drive with the manufacturer tool.' }
            if ($st -eq 'UNKNOWN') { $nx = 'This drive does not report a health status to Windows. Use the manufacturer tool if you need SMART details.' }
            [void]$f.Add((New-Finding 'Storage' ('Drive health: ' + $d.Name) $st $sev $ev $nx))
        }
    } else {
        $why = 'Drive health is not reported on this PC or could not be read.'
        if ($sys.DiskNote) { $why = $why + ' (' + $sys.DiskNote + ')' }
        [void]$f.Add((New-Finding 'Storage' 'Drive health' 'UNKNOWN' 'Info' @($why) ''))
    }

    # display adapters
    $gpus = @($sys.Gpus)
    if ($gpus.Count -gt 0) {
        foreach ($g in $gpus) {
            $ev = New-Object System.Collections.ArrayList
            [void]$ev.Add(($g.Name + ', driver ' + $g.Driver + $(if ($g.DriverDate) { ' (' + $g.DriverDate.Substring(0, [math]::Min(10, $g.DriverDate.Length)) + ')' } else { '' })))
            if ([int]$g.ErrorCode -ne 0) {
                [void]$ev.Add('Windows device error code ' + [string]$g.ErrorCode + ': ' + (Cm-Text ([int]$g.ErrorCode)))
                [void]$f.Add((New-Finding 'Display' ('Display adapter reports a device error: ' + $g.Name) 'ISSUE' 'Medium' $ev 'Open Device Manager, check the adapter properties and update or reinstall its driver from the GPU vendor.'))
            } elseif ($g.Status -eq 'OK') {
                [void]$ev.Add('Windows device status: OK. This is a device status, not a GPU health test.')
                [void]$f.Add((New-Finding 'Display' ('Display adapter status: ' + $g.Name) 'PASSED' 'Info' $ev ''))
            } else {
                [void]$ev.Add('Windows device status: ' + $(if ($g.Status) { $g.Status } else { 'not reported' }))
                [void]$f.Add((New-Finding 'Display' ('Display adapter status: ' + $g.Name) 'UNKNOWN' 'Info' $ev ''))
            }
        }
    } else {
        [void]$f.Add((New-Finding 'Display' 'Display adapter status' 'UNKNOWN' 'Info' @('No display adapter information could be read.') ''))
    }

    # unexpected restarts
    if ($rs.Complete) {
        $n41 = @($rs.Kp41).Count; $nb = @($rs.Bug).Count; $n6 = @($rs.E6008).Count
        if ($n41 + $nb + $n6 -gt 0) {
            $ev = New-Object System.Collections.ArrayList
            [void]$ev.Add(('Kernel-Power 41 events: ' + $n41 + ', BugCheck records: ' + $nb + ', EventLog 6008 records: ' + $n6 + ' (last 7 days)'))
            foreach ($e in @($rs.Kp41 | Select-Object -First 3)) { [void]$ev.Add('Unexpected restart recorded at ' + (Fmt $e.Time)) }
            if (@($rs.Codes).Count -gt 0) { [void]$ev.Add('Bugcheck code(s) recorded: ' + ((@($rs.Codes) | Select-Object -Unique) -join ', ')) }
            [void]$ev.Add('The events record that restarts happened. They do not identify the cause.')
            $sev = 'Medium'; if ($n41 -ge 3) { $sev = 'High' }
            [void]$f.Add((New-Finding 'Stability' 'Unexpected restart(s) were recorded' 'ISSUE' $sev $ev 'Open the Crash and BSOD Analyzer to see stop codes, related events and dump files.'))
        } else {
            [void]$f.Add((New-Finding 'Stability' 'Unexpected restarts' 'PASSED' 'Info' @('No Kernel-Power 41, BugCheck or EventLog 6008 records in the last 7 days (the System log was read successfully).') ''))
        }
    } else {
        [void]$f.Add((New-Finding 'Stability' 'Unexpected restarts' 'UNKNOWN' 'Info' (@('The System log could not be read completely, so restarts could not be checked.') + @($rs.Problems)) 'Run the toolkit as administrator and try again.'))
    }

    # event summary
    if (-not $scan.Complete) {
        [void]$f.Add((New-Finding 'Events' 'Critical and Error events' 'UNKNOWN' 'Info' (@('The event log scan was incomplete. Zero results would not mean zero events.') + @($scan.Result.Problems)) 'Run the toolkit as administrator and try again.'))
    } elseif ($scan.Total -eq 0) {
        [void]$f.Add((New-Finding 'Events' 'Critical and Error events' 'PASSED' 'Info' @('No Critical or Error events in the System and Application logs in the last 7 days (both logs were read successfully).') ''))
    } else {
        $ev = New-Object System.Collections.ArrayList
        $allNoise = $true
        foreach ($g in @($scan.Groups | Select-Object -First 6)) {
            [void]$ev.Add(([string]$g.Cnt + ' x ' + $g.Provider + ' (Event ' + [string]$g.Id + '): ' + (OneLine (Group-Msg $g) 110)))
        }
        foreach ($g in $scan.Groups) { $kb = Find-KB $g.Provider $g.Id; if (-not ($kb -and $kb.Class -eq 'noise')) { $allNoise = $false } }
        if ($scan.Limited) { [void]$ev.Add('Results are limited to the newest 1500 events per log; the real number may be higher.') }
        $title = ([string]$scan.Total + ' Critical/Error event(s) in ' + [string]$scan.Groups.Count + ' group(s), last 7 days')
        $nx = 'Open the System Error Analyzer to inspect them. Isolated errors are common and are not a confirmed problem by themselves.'
        if ($allNoise) { [void]$f.Add((New-Finding 'Events' $title 'INFO' 'Info' $ev $nx)) }
        else { [void]$f.Add((New-Finding 'Events' $title 'WARNING' 'Low' $ev $nx)) }
        Add-EventClassFindings $f $scan
    }

    # integrity
    if ($dism) {
        $sev = 'Info'; if ($dism.Result -eq 'ISSUE') { $sev = 'Medium' }
        $nx = ''; if ($dism.Result -eq 'ISSUE') { $nx = 'The System Repair menu offers the component store repair and asks for confirmation first.' }
        [void]$f.Add((New-Finding 'Integrity' 'Component store check (DISM CheckHealth)' $dism.Result $sev @($dism.Summary, 'This check reads the recorded component store state. It is not a full scan.') $nx))
    } else {
        [void]$f.Add((New-Finding 'Integrity' 'Component store check (DISM CheckHealth)' 'NOTCHECKED' 'Info' @('Not run in this session. Component store health is unknown.') 'Run this report again and choose Y at the DISM prompt (read-only, usually under a minute).'))
    }
    if ($sfc) {
        $sev = 'Info'; if ($sfc.Result -eq 'ISSUE') { $sev = 'Medium' }
        $nx = ''; if ($sfc.Result -eq 'ISSUE') { $nx = 'The System Repair menu offers SFC and DISM repairs and asks for confirmation first.' }
        [void]$f.Add((New-Finding 'Integrity' 'System file check (SFC verify-only)' $sfc.Result $sev @($sfc.Summary) $nx))
    } else {
        [void]$f.Add((New-Finding 'Integrity' 'System file check (SFC verify-only)' 'NOTCHECKED' 'Info' @('Not run in this session. The state of protected system files is unknown.') 'Run this report again and choose Y at the SFC prompt (read-only, can take 5 to 15 minutes).'))
    }
    return @($f)
}

function Get-Overall($findings) {
    $arr = @($findings)
    if ($arr.Count -eq 0) { return [pscustomobject]@{ Status = 'NOTCHECKED'; Text = 'No diagnostic results are available' } }
    $high = @($arr | Where-Object { $_.Status -eq 'ISSUE' -and $_.Severity -eq 'High' }).Count
    $iss  = @($arr | Where-Object { $_.Status -eq 'ISSUE' }).Count
    $wrn  = @($arr | Where-Object { $_.Status -eq 'WARNING' }).Count
    $unk  = @($arr | Where-Object { $_.Status -eq 'UNKNOWN' }).Count
    $nc   = @($arr | Where-Object { $_.Status -eq 'NOTCHECKED' }).Count
    if ($high -gt 0) { return [pscustomobject]@{ Status = 'ISSUE'; Text = 'Attention recommended: serious issue(s) detected' } }
    if ($iss -gt 0) { return [pscustomobject]@{ Status = 'ISSUE'; Text = 'Issues detected' } }
    if ($wrn -gt 0) { return [pscustomobject]@{ Status = 'WARNING'; Text = 'Warnings detected' } }
    if ($unk -gt 0) { return [pscustomobject]@{ Status = 'UNKNOWN'; Text = 'No issues found in the checks that completed, but some results could not be determined' } }
    $t = 'No issues detected in the checks that were performed'
    if ($nc -gt 0) { $t = $t + ' (some checks were not performed)' }
    return [pscustomobject]@{ Status = 'PASSED'; Text = $t }
}

# ------------------------------------------------------------ console display helpers
function Row([string]$label, [string]$value, [string]$color = 'Gray') {
    Line ('  ' + $label.PadRight(14) + $value) $color
}
function Show-SystemSummary($sys) {
    Line '  WINDOWS AND HARDWARE' 'Yellow'
    if ($sys.OS) {
        $o = $sys.OS
        Row 'Windows' ($o.Caption + $(if ($o.DisplayVersion) { '  ' + $o.DisplayVersion } else { '' }))
        Row 'Build' ($o.Version + $(if ($o.Ubr) { '.' + $o.Ubr } else { '' }) + '   Architecture: ' + $o.Arch + $(if ($o.Edition) { '   Edition ID: ' + $o.Edition } else { '' }))
        Row 'Installed' ([string]$o.InstallDate) 
        Row 'Last boot' ([string]$o.LastBoot)
    } else { Row 'Windows' 'Could not be read' 'Magenta' }
    if ($sys.Hardware) {
        $h = $sys.Hardware
        Row 'Computer' ($h.Manufacturer + ' ' + $h.Model)
        Row 'Processor' ($h.Cpu + '  (' + $h.Cores + ' cores, ' + $h.Threads + ' threads)')
        Row 'RAM' ((SizeText $h.RamBytes) + $(if ($h.RamModules -gt 0) { '  in ' + $h.RamModules + ' module(s) ' + $h.RamSpeed } else { '' }))
        Row 'BIOS' ([string]$h.Bios)
    } else { Row 'Computer' 'Could not be read' 'Magenta' }
    foreach ($g in @($sys.Gpus)) {
        $dd = ''
        if ($g.DriverDate) { $dd = ' (' + $g.DriverDate.Substring(0, [math]::Min(10, $g.DriverDate.Length)) + ')' }
        Row 'GPU' ($g.Name)
        Row '' ('Driver ' + $g.Driver + $dd + $(if ($g.NvidiaBranded) { '  [NVIDIA version ' + $g.NvidiaBranded + ' - derived]' } else { '' }) + '  Status: ' + $g.Status + $(if ($g.Resolution) { '  ' + $g.Resolution } else { '' })) 'DarkGray'
    }
    foreach ($v in @($sys.Volumes)) {
        $pct = 0
        if ($v.SizeBytes -gt 0) { $pct = [math]::Round(100.0 * $v.FreeBytes / $v.SizeBytes, 1) }
        Row ('Drive ' + $v.Drive) ((SizeText $v.SizeBytes) + ' total, ' + (SizeText $v.FreeBytes) + ' free (' + $pct + ' percent)  ' + $v.Fs + $(if ($v.Label) { '  "' + $v.Label + '"' } else { '' }))
    }
    foreach ($n in @($sys.Notes)) { Line ('  Note: ' + $n) 'DarkGray' }
}
function Show-Findings($findings) {
    $w = Get-ConWidth
    $areas = @(@($findings | ForEach-Object { $_.Area }) | Select-Object -Unique)
    foreach ($a in $areas) {
        Blank
        Line ('  ' + $a.ToUpper()) 'Yellow'
        foreach ($x in @($findings | Where-Object { $_.Area -eq $a })) {
            $tag = '[' + (StatusText $x.Status) + ']'
            Write-Host ('  ' + $tag.PadRight(22)) -NoNewline -ForegroundColor (StatusColor $x.Status)
            $sv = ''
            if ($x.Status -eq 'ISSUE' -or $x.Status -eq 'WARNING') { if ($x.Severity -and $x.Severity -ne 'Info') { $sv = '  (severity: ' + $x.Severity + ')' } }
            if ($x.Kind -eq 'Possible') { $sv = $sv + '  (possible explanation, not confirmed)' }
            Write-Host ((Fit $x.Title ($w - 26)) + $sv) -ForegroundColor White
            $shown = 0
            foreach ($ev in @($x.Evidence)) {
                if ($shown -ge 6) { Line '                        ...more evidence is in the HTML report' 'DarkGray'; break }
                foreach ($wl in (Wrap-Text ([string]$ev) ($w - 28) 4)) { Line ('                        ' + $wl) 'Gray' }
                $shown++
            }
            if ($x.Next) { foreach ($wl in (Wrap-Text ('Next step: ' + $x.Next) ($w - 28) 4)) { Line ('                        ' + $wl) 'Cyan' } }
        }
    }
}
function Show-Overall($ov, $findings) {
    Blank
    $arr = @($findings)
    $p = @($arr | Where-Object { $_.Status -eq 'PASSED' }).Count
    $i = @($arr | Where-Object { $_.Status -eq 'ISSUE' }).Count
    $w = @($arr | Where-Object { $_.Status -eq 'WARNING' }).Count
    $n = @($arr | Where-Object { $_.Status -eq 'NOTCHECKED' }).Count
    $u = @($arr | Where-Object { $_.Status -eq 'UNKNOWN' }).Count
    Line ('  OVERALL: ' + $ov.Text) (StatusColor $ov.Status)
    Line ('  Passed: ' + $p + '   Issues: ' + $i + '   Warnings: ' + $w + '   Not checked: ' + $n + '   Unable to determine: ' + $u) 'Gray'
}

# ------------------------------------------------------------ Health
function Do-Health($dism, $sfc) {
    Line '  [1/4] Reading Windows, hardware, GPU, storage and activation information...' 'Cyan'
    $sys = Get-SystemSummary
    Line '  [2/4] Reading System and Application events (last 7 days, Critical and Error)...' 'Cyan'
    $scan = Scan-Events 168 $false
    Line '  [3/4] Checking for unexpected restarts (last 7 days)...' 'Cyan'
    $rs = Quick-Restarts ((Get-Date).AddDays(-7))
    Line '  [4/4] Evaluating the results...' 'Cyan'
    $findings = @(Build-HealthFindings $sys $scan $rs $dism $sfc)
    $ov = Get-Overall $findings
    $egroups = @($scan.Groups | Select-Object -First 20 | ForEach-Object { Group-ToRecord $_ })
    $obj = [ordered]@{
        Module = 'health'; Generated = (Fmt (Get-Date)); EventWindowHours = 168
        System = $sys; Findings = $findings
        Overall = [ordered]@{ Status = $ov.Status; Text = $ov.Text }
        EventCounts = [ordered]@{ Total = $scan.Total; Critical = $scan.Critical; Errors = $scan.Errors; Groups = $scan.Groups.Count; Complete = $scan.Complete; Limited = $scan.Limited }
        EventGroups = $egroups
        Integrity = [ordered]@{ Dism = $dism; Sfc = $sfc }
    }
    [void](Save-Session 'health' $obj)
    Log ('Health report collected: ' + $findings.Count + ' findings, overall ' + $ov.Status)
    return [pscustomobject]@{ Sys = $sys; Findings = $findings; Overall = $ov }
}
function Run-Health {
    Head 'SYSTEM HEALTH REPORT'
    Line '  Read-only checks. Repair commands (SFC /scannow, DISM RestoreHealth, CHKDSK /f) are never started here.' 'Gray'
    if (-not $IsAdmin) { Line '  Note: this window is not elevated, so some checks may be unavailable.' 'Yellow' }
    Blank
    $dism = $null; $sfc = $null
    Line '  Optional integrity checks (read-only). If you skip them they are shown as Not checked.' 'Gray'
    if ($IsAdmin) {
        if (Ask-YN '  Run DISM CheckHealth now? It only reads the stored component-store state (usually under a minute)') {
            Line '  Running DISM CheckHealth...' 'Cyan'; $dism = Run-DismCheck
        }
        if (Ask-YN '  Run SFC verify-only now? It scans protected files WITHOUT repairing them and can take 5 to 15 minutes') {
            Line '  Running SFC verify-only. Please wait, there is no progress display...' 'Cyan'; $sfc = Run-SfcVerify
        }
    } else { Line '  DISM and SFC need administrator rights, so they are marked Not checked.' 'Yellow' }
    Blank
    $r = Do-Health $dism $sfc
    Head 'SYSTEM HEALTH REPORT'
    Show-SystemSummary $r.Sys
    Show-Findings $r.Findings
    Show-Overall $r.Overall $r.Findings
    Blank
    Line '  Findings marked Not checked or Unable to determine are NOT passed checks.' 'DarkGray'
    Offer-Export
}

# ------------------------------------------------------------ event browsing (Errors, Recent)
function Show-Occurrence($o, [string]$title) {
    Head $title
    Row 'Time' (Fmt $o.Time)
    Row 'Log' $o.Log
    Row 'Source' $o.Provider
    Row 'Event ID' ([string]$o.Id)
    Row 'Level' (LevelName $o.Level) (LevelColor $o.Level)
    Row 'Record ID' ([string]$o.RecordId)
    Blank
    Line '  Message:' 'Yellow'
    $w = Get-ConWidth
    foreach ($l in (Wrap-Text (Get-EvMessage $o.Raw 3000) ($w - 4) 45)) { Line ('    ' + $l) 'Gray' }
    try {
        $d = Get-EvData $o.Raw
        if ($d.List.Count -gt 0 -and $d.List.Count -le 12) {
            Blank
            Line '  Event data fields:' 'Yellow'
            $i = 0
            foreach ($v in $d.List) { $i++; Line ('    [' + $i + '] ' + (Fit ([string]$v) ($w - 12))) 'DarkGray' }
        }
    } catch { }
    Blank
    Wait-Enter 'Press Enter to go back'
}
function Show-GroupDetail($g) {
    while ($true) {
        Head 'EVENT DETAILS'
        $w = Get-ConWidth
        Row 'Source' $g.Provider
        Row 'Event ID' ([string]$g.Id)
        Row 'Log / level' ($g.Log + ' / ' + (LevelName $g.Level)) (LevelColor $g.Level)
        Row 'Occurrences' ([string]$g.Cnt + ' in the scanned window (first ' + (Fmt $g.First) + ', last ' + (Fmt $g.Last) + ')')
        Blank
        Line '  Latest message (observed evidence):' 'Yellow'
        foreach ($l in (Wrap-Text (Group-Msg $g) ($w - 4) 22)) { Line ('    ' + $l) 'Gray' }
        Blank
        $kb = Find-KB $g.Provider $g.Id
        if ($kb) {
            Line ('  What this event is: ' + $kb.Title) 'Yellow'
            foreach ($l in (Wrap-Text $kb.Means ($w - 4) 8)) { Line ('    ' + $l) 'Gray' }
            Line '  Possible causes (not confirmed):' 'Yellow'
            foreach ($l in (Wrap-Text $kb.Causes ($w - 4) 8)) { Line ('    ' + $l) 'Gray' }
            Line '  Suggested next steps:' 'Yellow'
            foreach ($l in (Wrap-Text $kb.Next ($w - 4) 8)) { Line ('    ' + $l) 'Cyan' }
        } else {
            Line '  No built-in explanation exists for this event, so none is guessed.' 'DarkGray'
            Line '  The message above is the only evidence. Search the source name and Event ID in Microsoft documentation if you need more.' 'DarkGray'
        }
        Blank
        if ($g.Items.Count -gt 1) {
            Line '  Recent occurrences:' 'Yellow'
            $i = 0
            foreach ($o in $g.Items) { $i++; Line ('    [' + $i + '] ' + (Fmt $o.Time)) 'Gray' }
        }
        Blank
        $a = (Read-Host '  Enter an occurrence number to see its full text, or press Enter to go back').Trim()
        if ($a -eq '') { return }
        $n = 0
        if ([int]::TryParse($a, [ref]$n) -and $n -ge 1 -and $n -le $g.Items.Count) { Show-Occurrence $g.Items[$n - 1] 'EVENT OCCURRENCE' }
    }
}
# Returns: 'back', 'window', 'warnings' or 'analyzer'
function Browse-Events($scan, [string]$title, [bool]$isRecent) {
    $page = 0; $size = 12
    while ($true) {
        Head $title
        $w = Get-ConWidth
        $lvl = (@($scan.Levels | ForEach-Object { LevelName $_ }) -join ' + ')
        Line ('  Window: last ' + $scan.Hours + ' hours   Logs: System, Application   Levels: ' + $lvl) 'Gray'
        Line ('  Events found: ' + $scan.Total + ' (Critical ' + $scan.Critical + ', Error ' + $scan.Errors + ', Warning ' + $scan.Warnings + ') in ' + $scan.Groups.Count + ' group(s)') 'Gray'
        if ($scan.Complete) { Line ('  Scan status: completed. Logs read: ' + (@($scan.Result.Scanned) -join ', ')) 'Green' }
        else {
            Line '  Scan status: INCOMPLETE. Zero results here would NOT mean zero events.' 'Yellow'
            foreach ($p in @($scan.Result.Problems)) { Line ('    ' + (Fit $p ($w - 6))) 'Yellow' }
        }
        if ($scan.Limited) { Line '  Results were limited to the newest 1500 events per log; the real count may be higher.' 'Yellow' }
        Blank
        $groups = @($scan.Groups)
        if ($groups.Count -eq 0) {
            if ($scan.Complete) { Line '  No matching events were found. Both logs were read successfully.' 'Green' }
            else { Line '  No events could be listed because the scan did not complete.' 'Yellow' }
        } else {
            $msgW = [math]::Max(16, $w - 66)
            Line (('  {0,-3} {1,-8} {2,5}  {3,-11} {4,-30} {5}' -f '#', 'Level', 'Count', 'Last seen', 'Source (ID)', 'Message')) 'DarkYellow'
            $end = [math]::Min($groups.Count, ($page + 1) * $size)
            for ($i = $page * $size; $i -lt $end; $i++) {
                $g = $groups[$i]
                $row = ('  {0,-3} {1,-8} {2,5}  {3,-11} {4,-30} {5}' -f ($i + 1), (LevelName $g.Level), $g.Cnt, $g.Last.ToString('MM-dd HH:mm', $Inv), (Fit ($g.Provider + ' (' + $g.Id + ')') 30), (OneLine (Group-Msg $g) $msgW))
                Line $row (LevelColor $g.Level)
            }
            $pages = [math]::Ceiling($groups.Count / $size)
            Line ('  Page ' + ($page + 1) + ' of ' + $pages) 'DarkGray'
        }
        Blank
        $mi = New-Object System.Collections.ArrayList
        if ($groups.Count -gt 0) {
            $fn = $page * $size + 1
            $ln = [math]::Min($groups.Count, ($page + 1) * $size)
            $rng = $(if ($fn -eq $ln) { [string]$fn } else { [string]$fn + '-' + [string]$ln })
            [void]$mi.Add(@($rng, ('Type an event number from the list (' + $rng + ') to see its details')))
        }
        [void]$mi.Add(@('N', 'Next page'))
        [void]$mi.Add(@('P', 'Previous page'))
        if ($isRecent) { [void]$mi.Add(@('E', 'Expand time window')); [void]$mi.Add(@('A', 'Open the full System Error Analyzer')) }
        else { [void]$mi.Add(@('W', 'Change time window')); [void]$mi.Add(@('T', 'Toggle warnings')) }
        [void]$mi.Add(@('0', 'Back'))
        Show-Menu $mi
        $a = Read-Choice
        if ($a -eq '0' -or $a -eq '') { return 'back' }
        if ($a -ieq 'N') { if (($page + 1) * $size -lt $groups.Count) { $page++ }; continue }
        if ($a -ieq 'P') { if ($page -gt 0) { $page-- }; continue }
        if ($isRecent) {
            if ($a -ieq 'E') { return 'window' }
            if ($a -ieq 'A') { return 'analyzer' }
        } else {
            if ($a -ieq 'W') { return 'window' }
            if ($a -ieq 'T') { return 'warnings' }
        }
        $n = 0
        if ([int]::TryParse($a, [ref]$n) -and $n -ge 1 -and $n -le $groups.Count) { Show-GroupDetail $groups[$n - 1] }
    }
}
function Show-Menu($items) {
    $dot = [string][char]0x25CF
    foreach ($it in $items) {
        Write-Host '   [' -NoNewline -ForegroundColor DarkYellow
        Write-Host ([string]$it[0]) -NoNewline -ForegroundColor White
        Write-Host '] ' -NoNewline -ForegroundColor DarkYellow
        Write-Host ($dot + ' ') -NoNewline -ForegroundColor DarkYellow
        Write-Host ([string]$it[1]) -ForegroundColor Gray
    }
    Blank
}
function Read-Choice {
    $dot = [string][char]0x25CF
    Write-Host ('  ' + $dot + ' ') -NoNewline -ForegroundColor DarkYellow
    $a = Read-Host 'Select an option'
    if ($null -eq $a) { return '' }
    return $a.Trim()
}
function Pick-Window([int]$defIdx) {
    $dot = [string][char]0x25CF
    $opts = @('last 24 hours', 'last 7 days', 'last 30 days')
    $hrs = @(24, 168, 720)
    Blank
    Line '  Time window:' 'Yellow'
    for ($i = 0; $i -lt 3; $i++) {
        Write-Host '   [' -NoNewline -ForegroundColor DarkYellow
        Write-Host ([string]($i + 1)) -NoNewline -ForegroundColor White
        Write-Host '] ' -NoNewline -ForegroundColor DarkYellow
        Write-Host ($dot + ' ') -NoNewline -ForegroundColor DarkYellow
        Write-Host $opts[$i] -ForegroundColor Gray
    }
    Blank
    while ($true) {
        Write-Host ('  ' + $dot + ' ') -NoNewline -ForegroundColor DarkYellow
        $a = (Read-Host 'Select an option').Trim()
        if ($a -eq '') { $a = [string]$defIdx }
        if ($a -eq '1' -or $a -eq '2' -or $a -eq '3') {
            $k = [int]$a - 1
            return [pscustomobject]@{ Hours = $hrs[$k]; Label = $opts[$k] }
        }
        Line '  Please enter 1, 2 or 3.' 'Yellow'
    }
}

function Run-Errors {
    Head 'SYSTEM ERROR ANALYZER'
    Line '  Reads the System and Application event logs and groups repeated events. Read-only.' 'Gray'
    Blank
    $win = Pick-Window 2
    $hours = $win.Hours
    $withWarn = $false
    while ($true) {
        Head 'SYSTEM ERROR ANALYZER'
        Line ('  Reading System and Application logs (' + $hours + ' hours)... this can take a moment.') 'Cyan'
        $scan = Scan-Events $hours $withWarn
        Save-EventSession 'errors' $scan
        $act = Browse-Events $scan 'SYSTEM ERROR ANALYZER' $false
        if ($act -eq 'window') { Head 'SYSTEM ERROR ANALYZER'; $hours = (Pick-Window 2).Hours; continue }
        if ($act -eq 'warnings') { $withWarn = -not $withWarn; continue }
        break
    }
    Offer-Export
}
function Run-Recent {
    $hours = 24
    while ($true) {
        Head 'RECENT CRITICAL/ERROR EVENTS'
        Line ('  Reading System and Application logs (' + $hours + ' hours)...') 'Cyan'
        $scan = Scan-Events $hours $false
        Save-EventSession 'recent' $scan
        $act = Browse-Events $scan 'RECENT CRITICAL/ERROR EVENTS' $true
        if ($act -eq 'window') {
            if ($hours -lt 168) { $hours = 168 } elseif ($hours -lt 720) { $hours = 720 } else { Line '  The time window is already at its maximum (30 days).' 'Yellow'; Start-Sleep -Seconds 2 }
            continue
        }
        if ($act -eq 'analyzer') { Run-Errors; return }
        break
    }
    Offer-Export
}

# ------------------------------------------------------------ Crash and BSOD
function Get-ModuleHint([string]$mod) {
    $m = ([string]$mod).ToLowerInvariant()
    if ($m -eq '' -or $m -eq 'unknown') { return 'The faulting module is not named in the event.' }
    if ($m -match '^(ntdll|kernelbase|kernel32)\.dll$') { return 'A Windows core library. Many different failures are reported here, so it does not point to a specific cause.' }
    if ($m -match '^(nvwgf2um|nvwgf2umx|atidxx64|atidxx32|amdxx64|amdxx32|atiumd64|igd10iumd64|igd11iumd64|igd12umd64|nvd3dum|nvd3dumx|nvoglv64)\.dll$') { return 'A graphics driver module. The crash happened in or through the graphics driver stack. The cause could be the program, the driver or the GPU; this is not a confirmed GPU fault.' }
    if ($m -match '^(d3d9|d3d11|d3d12|dxgi|d3dcompiler_\d+)\.dll$') { return 'A DirectX component. It shows where the crash surfaced, not necessarily what caused it.' }
    if ($m -match '^(vcruntime\d+|msvcp\d+|msvcr\d+|ucrtbase|concrt\d+)(_\d)?\.dll$') { return 'A C/C++ runtime library. Often a program error surfacing in the runtime; it is not proof that the runtime is missing or damaged.' }
    if ($m -match '^(unityplayer|gameassembly)\.dll$') { return 'A Unity engine component of the program itself.' }
    if ($m -match 'easyanticheat|beclient|battleye|vgk') { return 'An anti-cheat module is named. Anti-cheat software can be involved in a crash but is not necessarily the cause.' }
    if ($m -match '^gameoverlayrenderer') { return 'The Steam overlay module. An overlay can be involved in a crash but is not necessarily the cause.' }
    return ''
}

function Build-CrashFindings($c, [int]$hours) {
    $f = New-Object System.Collections.ArrayList
    $lab = $(if ($hours -lt 48) { [string]$hours + ' hours' } else { [string][math]::Round($hours / 24) + ' days' })
    if (-not $c.AppOk) {
        [void]$f.Add((New-Finding 'Crashes' 'Application crashes' 'UNKNOWN' 'Info' (@('The Application log could not be read completely.') + @($c.Problems)) 'Run the toolkit as administrator and try again.'))
    } elseif (@($c.AppGroups).Count -eq 0) {
        [void]$f.Add((New-Finding 'Crashes' 'Application crashes' 'PASSED' 'Info' @('No Application Error 1000, Application Hang 1002 or .NET Runtime 1026 events in the last ' + $lab + ' (the Application log was read successfully).') ''))
    } else {
        foreach ($g in @($c.AppGroups | Select-Object -First 5)) {
            $ev = New-Object System.Collections.ArrayList
            [void]$ev.Add($g.Kind + ': ' + $(if ($g.App) { $g.App } else { '(program name not parsed)' }) + $(if ($g.AppVer) { ' ' + $g.AppVer } else { '' }))
            if ($g.Module) { [void]$ev.Add('Faulting module: ' + $g.Module) }
            if ($g.Code) { $t = Get-ExcText $g.Code; [void]$ev.Add('Exception code: ' + (Show-Code $g.Code) + $(if ($t) { ' - ' + $t } else { '' })) }
            [void]$ev.Add([string]$g.Cnt + ' occurrence(s), first ' + (Fmt $g.First) + ', last ' + (Fmt $g.Last))
            $mh = Get-ModuleHint $g.Module
            if ($mh -and $g.Module) { [void]$ev.Add('About the module: ' + $mh) }
            $st = 'WARNING'; $sev = 'Low'
            if ($g.Cnt -ge 3) { $st = 'ISSUE'; $sev = 'Medium' } elseif ($g.Cnt -eq 2) { $sev = 'Medium' }
            $nm = $(if ($g.App) { $g.App } else { 'a program' })
            [void]$f.Add((New-Finding 'Crashes' ($nm + ' ' + $g.Kind.ToLower() + ' (' + $g.Cnt + 'x)') $st $sev $ev 'Update or reinstall the program. If the same module and exception repeat, the same problem is likely recurring; the exception code alone is not a root cause.'))
        }
        if (@($c.AppGroups).Count -gt 5) { [void]$f.Add((New-Finding 'Crashes' ('More crash groups exist (' + (@($c.AppGroups).Count - 5) + ' further)') 'INFO' 'Info' @('See the Crash and BSOD Analyzer or the HTML report for the full list.') '')) }
    }
    if (-not $c.SysOk) {
        [void]$f.Add((New-Finding 'Crashes' 'Unexpected restarts and bugchecks' 'UNKNOWN' 'Info' (@('The System log could not be read completely.') + @($c.Problems)) 'Run the toolkit as administrator and try again.'))
    } elseif (@($c.Incidents).Count -eq 0) {
        [void]$f.Add((New-Finding 'Crashes' 'Unexpected restarts and bugchecks' 'PASSED' 'Info' @('No Kernel-Power 41, BugCheck or EventLog 6008 records in the last ' + $lab + ' (the System log was read successfully).') ''))
    } else {
        $ev = New-Object System.Collections.ArrayList
        foreach ($i in @($c.Incidents | Select-Object -First 5)) {
            $t = (Fmt $i.Time) + '  ' + $i.Type
            if ($i.BugCode) { $t = $t + '  stop code ' + $i.BugCode + $(if ($i.BugName) { ' (' + $i.BugName + ')' } else { '' }) }
            [void]$ev.Add($t)
        }
        $withDump = @($c.Incidents | Where-Object { $_.DumpExists -or @($_.Dumps).Count -gt 0 }).Count
        [void]$ev.Add($withDump.ToString() + ' of ' + @($c.Incidents).Count + ' incident(s) have an associated dump file (metadata only; contents not analyzed).')
        $sev = 'Medium'; if (@($c.Incidents).Count -ge 3) { $sev = 'High' }
        [void]$f.Add((New-Finding 'Crashes' (@($c.Incidents).Count.ToString() + ' unexpected restart or bugcheck incident(s) in the last ' + $lab) 'ISSUE' $sev $ev 'Identifying a faulting driver needs a debugger such as WinDbg to analyze the dump. Meanwhile check recent driver or hardware changes, temperatures and power.'))
    }
    $dl = @($c.Dumps)
    if ($dl.Count -gt 0) {
        [void]$f.Add((New-Finding 'Crashes' 'Crash dump files' 'INFO' 'Info' @($dl.Count.ToString() + ' dump file(s) found in standard locations. Newest: ' + (Fmt $dl[0].Modified) + '.', 'MeshalFix lists names, sizes and dates only. It does not analyze dump contents and never deletes dumps.') ''))
    } else {
        $why = 'No dump files were found in the standard locations.'
        if ($c.DumpSettings.Known) { $why = $why + ' Crash dump setting: ' + $c.DumpSettings.Type + '.' }
        [void]$f.Add((New-Finding 'Crashes' 'Crash dump files' 'INFO' 'Info' @($why) ''))
    }
    return @($f)
}

function Do-Crash([int]$hours) {
    $since = (Get-Date).AddHours(-1 * $hours)
    Line '  [1/3] Reading Application and System events for crashes and restarts...' 'Cyan'
    $c = Collect-Crashes $since
    Line '  [2/3] Evaluating incidents and dump files...' 'Cyan'
    $findings = @(Build-CrashFindings $c $hours)
    $agr = @($c.AppGroups | Select-Object -First 40 | ForEach-Object {
        [pscustomobject]@{ Kind = $_.Kind; App = $_.App; AppVer = $_.AppVer; Module = $_.Module; Code = $_.Code; CodeText = (Get-ExcText $_.Code); ModuleHint = (Get-ModuleHint $_.Module)
            Count = $_.Cnt; First = (Fmt $_.First); Last = (Fmt $_.Last); Path = $_.Path }
    })
    $inc = @($c.Incidents | Select-Object -First 40 | ForEach-Object {
        [pscustomobject]@{ Time = (Fmt $_.Time); Type = $_.Type; BugCode = $_.BugCode; BugName = $_.BugName; BugHint = $_.BugHint; BugParams = $_.BugParams
            DumpPath = $_.DumpPath; DumpExists = $_.DumpExists; Dumps = @($_.Dumps); Related = @($_.Related); Evidence = $_.Evidence }
    })
    $dm = @($c.Dumps | Select-Object -First 40 | ForEach-Object { [pscustomobject]@{ Path = $_.Path; Kind = $_.Kind; Size = (SizeText $_.SizeBytes); Modified = (Fmt $_.Modified) } })
    $wt = @(); foreach ($k in $c.WerTypes.Keys) { $wt += ($k + ': ' + $c.WerTypes[$k]) }
    $obj = [ordered]@{
        Module = 'crash'; Generated = (Fmt (Get-Date)); WindowHours = $hours; Complete = $c.Complete; Limited = $c.Limited
        Problems = @($c.Problems); AppCrashEvents = @($c.AppCrashes).Count; AppGroups = $agr; Incidents = $inc; Dumps = $dm
        DumpSettings = $c.DumpSettings; WerRecords = $c.WerCount; WerTypes = $wt; Findings = $findings
    }
    [void](Save-Session 'crash' $obj)
    Line '  [3/3] Done.' 'Cyan'
    Log ('Crash analysis: ' + @($c.AppGroups).Count + ' app groups, ' + @($c.Incidents).Count + ' incidents, ' + @($c.Dumps).Count + ' dump files')
    return [pscustomobject]@{ Data = $c; Findings = $findings }
}

function Show-AppGroup($g) {
    Head 'APPLICATION CRASH DETAILS'
    $w = Get-ConWidth
    Row 'Type' $g.Kind
    Row 'Program' ($g.App + $(if ($g.AppVer) { '  version ' + $g.AppVer } else { '' }))
    Row 'Module' ($(if ($g.Module) { $g.Module } else { '(not named)' }))
    Row 'Exception' ((Show-Code $g.Code) + $(if (Get-ExcText $g.Code) { ' - ' + (Get-ExcText $g.Code) } else { '' }))
    Row 'Path' ($(if ($g.Path) { $g.Path } else { '(not available)' }))
    Row 'Occurrences' ([string]$g.Cnt + '  (first ' + (Fmt $g.First) + ', last ' + (Fmt $g.Last) + ')')
    $mh = Get-ModuleHint $g.Module
    if ($mh) { Blank; Line '  About the faulting module:' 'Yellow'; foreach ($l in (Wrap-Text $mh ($w - 4) 6)) { Line ('    ' + $l) 'Gray' } }
    Blank
    Line '  Recent occurrences:' 'Yellow'
    foreach ($i in $g.Items) { Line ('    ' + (Fmt $i.Time) + '   process ID ' + $i.ProcId + '   offset ' + $i.Offset) 'Gray' }
    Blank
    Line '  The same module and exception repeating suggests the same problem recurring. It does not confirm a root cause.' 'DarkGray'
    Blank
    Wait-Enter 'Press Enter to go back'
}
function Show-Incident($i) {
    Head 'RESTART / BSOD INCIDENT DETAILS'
    $w = Get-ConWidth
    Row 'Time' (Fmt $i.Time)
    Row 'Type' $i.Type
    if ($i.BugCode) {
        Row 'Stop code' ($i.BugCode + $(if ($i.BugName) { '  ' + $i.BugName } else { '  (name not in the built-in list)' }))
        if ($i.BugParams) { Row 'Parameters' $i.BugParams }
        if ($i.BugHint) { foreach ($l in (Wrap-Text $i.BugHint ($w - 18) 5)) { Row '' $l 'DarkGray' } }
    } else { Row 'Stop code' 'none recorded' }
    Row 'Dump (event)' ($(if ($i.DumpPath) { $i.DumpPath + $(if ($i.DumpExists) { '  [file exists]' } else { '  [file not found]' }) } else { 'not named in the event' }))
    foreach ($d in @($i.Dumps)) { Row 'Dump (time)' ($d + '  [possible match by timestamp]') }
    Blank
    Line '  Related events:' 'Yellow'
    foreach ($r in @($i.Related)) { Line ('    ' + $r) 'Gray' }
    Blank
    Line '  Is the evidence sufficient?' 'Yellow'
    foreach ($l in (Wrap-Text $i.Evidence ($w - 4) 8)) { Line ('    ' + $l) 'Gray' }
    Blank
    Wait-Enter 'Press Enter to go back'
}

function Run-Crash {
    Head 'CRASH & BSOD ANALYZER'
    Line '  Looks at application crashes, bugchecks, unexpected restarts and dump files. Read-only; dumps are never deleted.' 'Gray'
    Blank
    $win = Pick-Window 3
    Blank
    $res = Do-Crash $win.Hours
    $c = $res.Data
    while ($true) {
        Head 'CRASH & BSOD ANALYZER'
        $w = Get-ConWidth
        Line ('  Window: ' + $win.Label + '   ' + $(if ($c.Complete) { 'Scan status: completed' } else { 'Scan status: INCOMPLETE (see below)' })) $(if ($c.Complete) { 'Green' } else { 'Yellow' })
        foreach ($p in @($c.Problems)) { Line ('    ' + (Fit $p ($w - 6))) 'Yellow' }
        if ($c.Limited) { Line '  Results were limited to the newest 1500 events per query.' 'Yellow' }
        Blank
        Line '  APPLICATION CRASHES' 'Yellow'
        $ag = @($c.AppGroups)
        if ($ag.Count -eq 0) { Line $(if ($c.AppOk) { '    None recorded in this window.' } else { '    Could not be determined (the log could not be read).' }) $(if ($c.AppOk) { 'Green' } else { 'Yellow' }) }
        else {
            for ($i = 0; $i -lt [math]::Min(10, $ag.Count); $i++) {
                $g = $ag[$i]
                Line (('    [A{0}] {1,3}x  {2,-11} {3,-22} {4,-22} {5}' -f ($i + 1), $g.Cnt, $g.Last.ToString('MM-dd HH:mm', $Inv), (Fit $g.App 22), (Fit $g.Module 22), (Show-Code $g.Code))) 'Gray'
            }
            if ($ag.Count -gt 10) { Line ('    ...and ' + ($ag.Count - 10) + ' more group(s) in the HTML report') 'DarkGray' }
        }
        Blank
        Line '  SYSTEM CRASHES AND UNEXPECTED RESTARTS' 'Yellow'
        $ic = @($c.Incidents)
        if ($ic.Count -eq 0) { Line $(if ($c.SysOk) { '    None recorded in this window.' } else { '    Could not be determined (the log could not be read).' }) $(if ($c.SysOk) { 'Green' } else { 'Yellow' }) }
        else {
            for ($i = 0; $i -lt [math]::Min(10, $ic.Count); $i++) {
                $n = $ic[$i]
                $code = $(if ($n.BugCode) { $n.BugCode + $(if ($n.BugName) { ' ' + $n.BugName } else { '' }) } else { 'no stop code recorded' })
                Line (('    [I{0}] {1,-17} {2,-40} {3}' -f ($i + 1), (Fmt $n.Time).Substring(0, [math]::Min(16, (Fmt $n.Time).Length)), (Fit $n.Type 40), (Fit $code ($w - 70)))) 'Red'
            }
        }
        Blank
        Line '  DUMP FILES (names, sizes and dates only; contents are not analyzed)' 'Yellow'
        $dl = @($c.Dumps)
        if ($dl.Count -eq 0) { Line '    No dump files found in the standard locations.' 'Gray' }
        else { foreach ($d in @($dl | Select-Object -First 8)) { Line ('    ' + (Fit ($d.Path + '  ' + (SizeText $d.SizeBytes) + '  ' + (Fmt $d.Modified)) ($w - 6))) 'Gray' } }
        if ($c.DumpSettings.Known) { Line ('    Crash dump setting: ' + $c.DumpSettings.Type + '. ' + $c.DumpSettings.AutoReboot + '. (read only, not changed)') 'DarkGray' }
        if ($c.WerCount -gt 0) { Line ('    Windows Error Reporting records in the window: ' + $c.WerCount) 'DarkGray' }
        Blank
        Line '  Dump contents (faulting driver, call stack) need a debugger such as WinDbg. MeshalFix does not analyze them.' 'DarkGray'
        Show-Menu @(@('A1', 'Type A and a number (A1, A2...) to see an application crash in detail'), @('I1', 'Type I and a number (I1, I2...) to see a restart or BSOD incident in detail'), @('0', 'Back'))
        $a = Read-Choice
        if ($a -eq '0' -or $a -eq '') { break }
        if ($a -match '^[Aa](\d+)$') { $n = [int]$Matches[1]; if ($n -ge 1 -and $n -le $ag.Count) { Show-AppGroup $ag[$n - 1] } }
        elseif ($a -match '^[Ii](\d+)$') { $n = [int]$Matches[1]; if ($n -ge 1 -and $n -le $ic.Count) { Show-Incident $ic[$n - 1] } }
    }
    Offer-Export
}

# ------------------------------------------------------------ Reliability history
function Rel-Category([string]$src) {
    $s = ([string]$src).ToLowerInvariant()
    if ($s -match 'application error|application hang') { return 'Application failure' }
    if ($s -match 'systemerrorreporting|bugcheck|kernel-power|^eventlog$') { return 'Windows failure' }
    if ($s -match 'windows error reporting') { return 'Failure report (WER)' }
    if ($s -match 'windowsupdate') { return 'Windows Update' }
    if ($s -match 'msiinstaller|installer|appx|appmodel') { return 'Software install or removal' }
    if ($s -match 'whea|^disk$|ntfs|stor') { return 'Hardware or storage' }
    return 'Other'
}
function Rel-IsFailure([string]$cat) { return ($cat -eq 'Application failure' -or $cat -eq 'Windows failure' -or $cat -eq 'Failure report (WER)' -or $cat -eq 'Hardware or storage') }

function Collect-Reliability([datetime]$since) {
    $r = [pscustomobject]@{ Source = ''; Available = $false; Records = (New-Object System.Collections.ArrayList); Stability = (New-Object System.Collections.ArrayList); Problems = (New-Object System.Collections.ArrayList); Limited = $false; Note = ''; Fallback = $false }
    $recs = $null
    try {
        $recs = @(Get-CimInstance -ClassName Win32_ReliabilityRecords -OperationTimeoutSec 120 -ErrorAction Stop)
        $r.Available = $true
    } catch { [void]$r.Problems.Add('Reliability records: ' + (Fit $_.Exception.Message 160)) }
    if ($r.Available) {
        $r.Source = 'Windows Reliability Monitor records (Win32_ReliabilityRecords)'
        $sel = @($recs | Where-Object { $_.TimeGenerated -ge $since } | Sort-Object TimeGenerated -Descending)
        if ($sel.Count -gt 1500) { $r.Limited = $true; $sel = @($sel | Select-Object -First 1500) }
        foreach ($x in $sel) {
            $src = [string]$x.SourceName
            $cat = Rel-Category $src
            $msg = [string]$x.Message
            if ($msg.Length -gt 1500) { $msg = $msg.Substring(0, 1500) + ' ...[truncated]' }
            [void]$r.Records.Add([pscustomobject]@{
                Time = $x.TimeGenerated; Source = $src; Component = $(if ($x.ProductName) { [string]$x.ProductName } else { $src }); Category = $cat
                IsFailure = (Rel-IsFailure $cat); Id = [string]$x.EventIdentifier; Summary = (OneLine $msg 120); Details = $msg
            })
        }
        if ($r.Records.Count -eq 0) { $r.Note = 'The Reliability Monitor data source returned no records in this window. That can mean nothing was recorded or that reliability data collection is not active. It is not proof of a problem-free system.' }
    } else {
        $r.Fallback = $true
        $r.Source = 'Event-log approximation (Reliability Monitor data was not accessible)'
        $r.Note = 'The Reliability Monitor data source could not be read, so this list is built from Application and System event logs instead. It may differ from what Reliability Monitor shows, and it is not a complete history.'
        $ap = Get-LogEvents -Logs @('Application') -Since $since -Ids @(1000, 1002, 1026) -Max 1500
        $s1 = Get-LogEvents -Logs @('System') -Since $since -Ids @(41, 1001, 6008, 4101) -Max 1500
        $s2 = Get-LogEvents -Logs @('System') -Since $since -Levels @(1, 2, 3) -Max 3000
        foreach ($q in @($ap, $s1, $s2)) { foreach ($p in $q.Problems) { [void]$r.Problems.Add($p) } }
        if ($ap.Limited -or $s1.Limited -or $s2.Limited) { $r.Limited = $true }
        $seen = @{}
        $all = @()
        foreach ($o in $ap.Events) { if ($o.Provider -match '^(Application Error|Application Hang|\.NET Runtime)$') { $all += $o } }
        foreach ($o in $s1.Events) { if ($o.Provider -match 'Kernel-Power|WER-SystemErrorReporting|^BugCheck$|^EventLog$|^Display$') { $all += $o } }
        foreach ($o in $s2.Events) { if ($o.Provider -match 'WHEA-Logger|^disk$|^Ntfs$|Microsoft-Windows-Ntfs|nvlddmkm|amdkmdag') { $all += $o } }
        foreach ($o in ($all | Sort-Object Time -Descending)) {
            $key = $o.Log + '|' + [string]$o.RecordId
            if ($seen.ContainsKey($key)) { continue }
            $seen[$key] = $true
            $cat = Rel-Category $o.Provider
            if ($o.Provider -eq 'Display') { $cat = 'Hardware or storage' }
            $msg = Get-EvMessage $o.Raw 1500
            [void]$r.Records.Add([pscustomobject]@{
                Time = $o.Time; Source = $o.Provider; Component = $o.Provider; Category = $cat; IsFailure = (Rel-IsFailure $cat)
                Id = [string]$o.Id; Summary = (OneLine $msg 120); Details = $msg
            })
        }
    }
    try {
        $st = @(Get-CimInstance -ClassName Win32_ReliabilityStabilityMetrics -OperationTimeoutSec 60 -ErrorAction Stop | Sort-Object TimeGenerated -Descending | Select-Object -First 14)
        foreach ($m in $st) { [void]$r.Stability.Add([pscustomobject]@{ Time = (Fmt $m.TimeGenerated); Index = [math]::Round([double]$m.SystemStabilityIndex, 2) }) }
    } catch { }
    return $r
}
function Get-RelClusters($records) {
    $out = New-Object System.Collections.ArrayList
    $asc = @($records | Sort-Object Time)
    $cur = New-Object System.Collections.ArrayList
    $flush = {
        param($list)
        if ($list.Count -ge 2) {
            $srcs = @($list | ForEach-Object { $_.Source } | Select-Object -Unique)
            $fail = @($list | Where-Object { $_.IsFailure }).Count
            if ($srcs.Count -ge 2 -and $fail -ge 1) {
                $lines = @($list | Select-Object -First 6 | ForEach-Object { (Fmt $_.Time) + '  ' + $_.Category + ': ' + $_.Component })
                [void]$out.Add([pscustomobject]@{ Start = (Fmt $list[0].Time); End = (Fmt $list[$list.Count - 1].Time); Count = $list.Count; Lines = $lines })
            }
        }
    }
    $last = $null
    foreach ($x in $asc) {
        if ($null -ne $last -and (($x.Time - $last).TotalMinutes -gt 10)) { & $flush $cur; $cur = New-Object System.Collections.ArrayList }
        [void]$cur.Add($x)
        $last = $x.Time
    }
    & $flush $cur
    return @($out | Sort-Object Start -Descending | Select-Object -First 10)
}
function Do-Reliability([int]$hours) {
    $since = (Get-Date).AddHours(-1 * $hours)
    Line '  Collecting reliability data (this can take a little while)...' 'Cyan'
    $r = Collect-Reliability $since
    $recs = @($r.Records)
    $cats = [ordered]@{}
    foreach ($x in $recs) { if ($cats.Contains($x.Category)) { $cats[$x.Category] = $cats[$x.Category] + 1 } else { $cats[$x.Category] = 1 } }
    $clusters = @(Get-RelClusters $recs)
    $f = New-Object System.Collections.ArrayList
    if (-not $r.Available -and $recs.Count -eq 0) {
        [void]$f.Add((New-Finding 'Reliability' 'Reliability history' 'UNKNOWN' 'Info' (@('Neither the Reliability Monitor data source nor the event-log fallback produced records.') + @($r.Problems)) 'Open the native Reliability Monitor to look at the history.'))
    } else {
        $nApp = @($recs | Where-Object { $_.Category -eq 'Application failure' }).Count
        $nWin = @($recs | Where-Object { $_.Category -eq 'Windows failure' }).Count
        $nHw = @($recs | Where-Object { $_.Category -eq 'Hardware or storage' }).Count
        $ev = New-Object System.Collections.ArrayList
        [void]$ev.Add('Source: ' + $r.Source)
        [void]$ev.Add('Records in window: ' + $recs.Count + ' (application failures ' + $nApp + ', Windows failures ' + $nWin + ', hardware/storage ' + $nHw + ')')
        if ($r.Note) { [void]$ev.Add($r.Note) }
        if ($r.Stability.Count -gt 0) { [void]$ev.Add('Latest stability index reported by Windows: ' + [string]$r.Stability[0].Index + ' (scale 1 to 10) on ' + $r.Stability[0].Time) }
        $st = 'INFO'; $sev = 'Info'
        if ($nWin -gt 0 -or $nHw -gt 0) { $st = 'WARNING'; $sev = 'Medium' } elseif ($nApp -gt 0) { $st = 'WARNING'; $sev = 'Low' }
        if ($r.Fallback) { $st = $(if ($st -eq 'INFO') { 'UNKNOWN' } else { $st }) }
        [void]$f.Add((New-Finding 'Reliability' 'Reliability history summary' $st $sev $ev 'Review the timeline below or in the HTML report. Related items are linked by time only, which is not proof of causation.'))
    }
    $top = @($recs | Select-Object -First 200 | ForEach-Object {
        [pscustomobject]@{ Time = (Fmt $_.Time); Source = $_.Source; Component = $_.Component; Category = $_.Category; IsFailure = $_.IsFailure; Id = $_.Id; Summary = $_.Summary; Details = $_.Details }
    })
    $obj = [ordered]@{
        Module = 'reliability'; Generated = (Fmt (Get-Date)); WindowHours = $hours; Source = $r.Source; Available = $r.Available; Fallback = $r.Fallback
        Complete = ($r.Problems.Count -eq 0); Limited = $r.Limited; Note = $r.Note; Problems = @($r.Problems)
        TotalRecords = $recs.Count; Categories = $cats; Stability = @($r.Stability); Clusters = $clusters; Records = $top; Findings = @($f)
    }
    [void](Save-Session 'reliability' $obj)
    Log ('Reliability: ' + $recs.Count + ' records, source ' + $r.Source)
    return [pscustomobject]@{ Data = $r; Records = $recs; Clusters = $clusters; Categories = $cats; Findings = @($f) }
}
function Run-Reliability {
    Head 'RELIABILITY HISTORY'
    Line '  Summarizes Windows reliability data. Read-only.' 'Gray'
    Blank
    $win = Pick-Window 3
    Blank
    $page = 0; $size = 12
    $res = Do-Reliability $win.Hours
    while ($true) {
        Head 'RELIABILITY HISTORY'
        $w = Get-ConWidth
        $r = $res.Data
        Line ('  Window: ' + $win.Label) 'Gray'
        Line ('  Source: ' + $r.Source) $(if ($r.Fallback) { 'Yellow' } else { 'Green' })
        if ($r.Note) { foreach ($l in (Wrap-Text $r.Note ($w - 4) 5)) { Line ('  ' + $l) 'Yellow' } }
        foreach ($p in @($r.Problems)) { Line ('    ' + (Fit $p ($w - 6))) 'Yellow' }
        if ($r.Limited) { Line '  Results were limited; older records in the window may not be listed.' 'Yellow' }
        Blank
        $recs = @($res.Records)
        if ($res.Categories.Count -gt 0) { Line ('  Records: ' + $recs.Count + '   ' + ((@($res.Categories.Keys | ForEach-Object { $_ + ' ' + $res.Categories[$_] })) -join ', ')) 'Gray' }
        if ($r.Stability.Count -gt 0) { Line ('  Stability index (1-10, computed by Windows): ' + ((@($r.Stability | Select-Object -First 7 | ForEach-Object { [string]$_.Index })) -join '  ') + '  (newest first)') 'Gray' }
        if (@($res.Clusters).Count -gt 0) {
            Blank
            Line '  Related incidents (records close in time; correlation by time only, not proof of cause):' 'Yellow'
            foreach ($cl in @($res.Clusters | Select-Object -First 3)) { Line ('    ' + $cl.Start + ' - ' + $cl.End + '  ' + $cl.Count + ' records: ' + (Fit (@($cl.Lines) -join ' | ') ($w - 50))) 'Gray' }
        }
        Blank
        if ($recs.Count -gt 0) {
            Line (('  {0,-3} {1,-16} {2,-24} {3,-26} {4}' -f '#', 'Date and time', 'Type', 'Component', 'Summary')) 'DarkYellow'
            $end = [math]::Min($recs.Count, ($page + 1) * $size)
            for ($i = $page * $size; $i -lt $end; $i++) {
                $x = $recs[$i]
                Line (('  {0,-3} {1,-16} {2,-24} {3,-26} {4}' -f ($i + 1), $x.Time.ToString('yyyy-MM-dd HH:mm', $Inv), (Fit $x.Category 24), (Fit $x.Component 26), (Fit $x.Summary ([math]::Max(10, $w - 74))))) $(if ($x.IsFailure) { 'Red' } else { 'Gray' })
            }
            Line ('  Page ' + ($page + 1) + ' of ' + [math]::Ceiling($recs.Count / $size)) 'DarkGray'
        } else { Line '  No records to list.' 'Gray' }
        Blank
        $rf = $page * $size + 1
        $rl = [math]::Min($recs.Count, ($page + 1) * $size)
        $rr = $(if ($rf -eq $rl) { [string]$rf } else { [string]$rf + '-' + [string]$rl })
        $rmenu = New-Object System.Collections.ArrayList
        if ($recs.Count -gt 0) { [void]$rmenu.Add(@($rr, ('Type a record number from the list (' + $rr + ') to see its details'))) }
        foreach ($ri in @(@('N', 'Next page'), @('P', 'Previous page'), @('W', 'Change time window'), @('R', 'Open Windows Reliability Monitor'), @('0', 'Back'))) { [void]$rmenu.Add($ri) }
        Show-Menu $rmenu
        $a = Read-Choice
        if ($a -eq '0' -or $a -eq '') { break }
        if ($a -ieq 'N') { if (($page + 1) * $size -lt $recs.Count) { $page++ }; continue }
        if ($a -ieq 'P') { if ($page -gt 0) { $page-- }; continue }
        if ($a -ieq 'R') { try { Start-Process -FilePath 'perfmon.exe' -ArgumentList '/rel' -ErrorAction Stop } catch { Line ('  Could not open Reliability Monitor: ' + $_.Exception.Message) 'Yellow'; Start-Sleep -Seconds 2 }; continue }
        if ($a -ieq 'W') { Head 'RELIABILITY HISTORY'; $win = Pick-Window 3; $page = 0; $res = Do-Reliability $win.Hours; continue }
        $n = 0
        if ([int]::TryParse($a, [ref]$n) -and $n -ge 1 -and $n -le $recs.Count) {
            $x = $recs[$n - 1]
            Head 'RELIABILITY RECORD'
            Row 'Time' (Fmt $x.Time); Row 'Type' $x.Category; Row 'Component' $x.Component; Row 'Source' $x.Source; Row 'Event ID' $x.Id
            Blank
            foreach ($l in (Wrap-Text $x.Details ($w - 4) 30)) { Line ('    ' + $l) 'Gray' }
            Blank
            Wait-Enter 'Press Enter to go back'
        }
    }
    Offer-Export
}

# ------------------------------------------------------------ Gaming diagnostics
function Get-PeArch([string]$p) {
    try {
        $fs = [IO.File]::Open($p, 'Open', 'Read', 'ReadWrite')
        try {
            $br = New-Object IO.BinaryReader($fs)
            if ($fs.Length -lt 64) { return 'unknown' }
            if ($br.ReadUInt16() -ne 0x5A4D) { return 'not a PE file' }
            $fs.Position = 0x3C
            $off = $br.ReadInt32()
            if ($off -lt 0 -or $off -gt ($fs.Length - 6)) { return 'unknown' }
            $fs.Position = $off
            if ($br.ReadUInt32() -ne 0x4550) { return 'unknown' }
            $m = $br.ReadUInt16()
            if ($m -eq 0x8664) { return 'x64' }
            if ($m -eq 0x14c) { return 'x86 (32-bit)' }
            if ($m -eq 0xAA64) { return 'ARM64' }
            return ('machine type 0x' + $m.ToString('X'))
        } finally { $fs.Close() }
    } catch { return 'unknown' }
}
function Get-ExeInfo([string]$exe) {
    $i = [ordered]@{ Path = $exe; SizeBytes = 0; Modified = ''; Product = ''; FileVersion = ''; Company = ''; Description = ''; Arch = ''; Signature = ''; AppCompat = ''; GpuPreference = '' }
    try { $fi = Get-Item -LiteralPath $exe -ErrorAction Stop; $i.SizeBytes = [double]$fi.Length; $i.Modified = (Fmt $fi.LastWriteTime) } catch { }
    try {
        $vi = [Diagnostics.FileVersionInfo]::GetVersionInfo($exe)
        $i.Product = [string]$vi.ProductName; $i.FileVersion = [string]$vi.FileVersion; $i.Company = [string]$vi.CompanyName; $i.Description = [string]$vi.FileDescription
    } catch { }
    $i.Arch = Get-PeArch $exe
    try { $sig = Get-AuthenticodeSignature -LiteralPath $exe -ErrorAction Stop; $i.Signature = [string]$sig.Status } catch { $i.Signature = 'could not be read' }
    foreach ($key in @('HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers', 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers')) {
        try { $k = Get-Item -LiteralPath $key -ErrorAction Stop; $v = $k.GetValue($exe); if ($v) { $i.AppCompat = ([string]$v).Trim() } } catch { }
    }
    try { $k = Get-Item -LiteralPath 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences' -ErrorAction Stop; $v = $k.GetValue($exe); if ($v) { $i.GpuPreference = [string]$v } } catch { }
    return $i
}
function Get-DxDiagInfo {
    $r = [ordered]@{ Ran = $false; Ok = $false; DirectX = ''; FeatureLevels = ''; Message = '' }
    $f = Join-Path $env:TEMP ('MeshalFix_dxdiag_' + [guid]::NewGuid().ToString('N') + '.txt')
    try {
        $p = Start-Process -FilePath 'dxdiag.exe' -ArgumentList @('/whql:off', '/t', ('"' + $f + '"')) -PassThru -WindowStyle Hidden -ErrorAction Stop
        $r.Ran = $true
        [void]$p.WaitForExit(90000)
        $prev = -1
        for ($n = 0; $n -lt 45; $n++) {
            if (Test-Path -LiteralPath $f) { $len = (Get-Item -LiteralPath $f).Length; if ($len -gt 0 -and $len -eq $prev) { break }; $prev = $len }
            Start-Sleep -Seconds 1
        }
        if (Test-Path -LiteralPath $f) {
            $txt = [IO.File]::ReadAllText($f)
            $m = [regex]::Match($txt, '(?im)^[^\r\n:]{1,60}:\s*(DirectX\s+\d+(?:\.\d+)?)\s*$')
            if ($m.Success) { $r.DirectX = $m.Groups[1].Value.Trim(); $r.Ok = $true }
            $fl = [regex]::Match($txt, '(?m)^[^\r\n:]{1,60}:\s*(\d{1,2}_\d(?:\s*,\s*\d{1,2}_\d)+)\s*$')
            if ($fl.Success) { $r.FeatureLevels = $fl.Groups[1].Value.Trim() }
            if (-not $r.Ok) { $r.Message = 'dxdiag finished but the DirectX version line was not found in its output.' }
        } else { $r.Message = 'dxdiag did not produce an output file in time.' }
    } catch { $r.Message = 'dxdiag could not be run: ' + (Fit $_.Exception.Message 120) }
    finally { try { if (Test-Path -LiteralPath $f) { Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue } } catch { } }
    return $r
}
function Get-GameReasons($c, [string]$root) {
    $strong = New-Object System.Collections.ArrayList
    $weak = New-Object System.Collections.ArrayList
    $p = [string]$c.Path
    if ($p) {
        if ($p -match '(?i)\\steamapps\\common\\') { [void]$strong.Add('installed in a Steam library (steamapps\common)') }
        if ($p -match '(?i)\\Epic Games\\') { [void]$strong.Add('installed under an Epic Games folder') }
        if ($p -match '(?i)\\Riot Games\\') { [void]$strong.Add('installed under a Riot Games folder') }
        if ($p -match '(?i)\\Ubisoft\\') { [void]$strong.Add('installed under a Ubisoft folder') }
        if ($p -match '(?i)\\(GOG Galaxy\\Games|GOG Games)\\') { [void]$strong.Add('installed under a GOG games folder') }
        if ($p -match '(?i)\\(EA Games|Origin Games)\\') { [void]$strong.Add('installed under an EA or Origin games folder') }
        if ($p -match '(?i)\\XboxGames\\') { [void]$strong.Add('installed under XboxGames') }
        if ($p -match '(?i)\\Games\\' -and $strong.Count -eq 0) { [void]$weak.Add('located in a folder named Games') }
        if ($root -and $p.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) { [void]$strong.Add('inside the game folder you entered') }
    }
    if ($c.App -match '(?i)-Win(64|32)-Shipping\.exe$') { [void]$strong.Add('Unreal Engine shipping executable naming') }
    if ($c.Module -match '(?i)^(UnityPlayer|GameAssembly)\.dll$') { [void]$strong.Add('the faulting module is a Unity runtime component') }
    if ($c.Module -match '(?i)^(nvwgf2um|nvwgf2umx|atidxx64|atidxx32|amdxx64|amdxx32|igd10iumd64|igd12umd64|d3d11|d3d12|dxgi|d3d9)\.dll$') { [void]$weak.Add('the faulting module is a graphics driver or DirectX component (suggestive only)') }
    return [pscustomobject]@{ Strong = @($strong); Weak = @($weak) }
}

function Build-GamingFindings($sys, $crash, $disp, $stops, $dx, $targeted, $gameGroups, $otherCount, [int]$hours) {
    $f = New-Object System.Collections.ArrayList
    $lab = $(if ($hours -lt 48) { [string]$hours + ' hours' } else { [string][math]::Round($hours / 24) + ' days' })
    # A + C: game crashes and stability
    if (-not $crash.AppOk) {
        [void]$f.Add((New-Finding 'Game crashes' 'Game crash detection' 'UNKNOWN' 'Info' (@('The Application log could not be read completely.') + @($crash.Problems)) 'Run the toolkit as administrator and try again.'))
    } elseif ($gameGroups.Count -eq 0) {
        $ev = @('No crash events matched the game-related patterns in the last ' + $lab + ' (the Application log was read successfully).')
        if ($otherCount -gt 0) { $ev += ([string]$otherCount + ' other application crash event(s) exist but were not classified as game-related. See the Crash and BSOD Analyzer.') }
        $ev += 'This does not prove games run well. Only crash records were checked.'
        [void]$f.Add((New-Finding 'Game crashes' 'Game crash detection' 'PASSED' 'Info' $ev ''))
    } else {
        foreach ($g in @($gameGroups | Select-Object -First 5)) {
            $ev = New-Object System.Collections.ArrayList
            [void]$ev.Add('Program: ' + $g.App + $(if ($g.AppVer) { ' ' + $g.AppVer } else { '' }))
            [void]$ev.Add('Classified as game-related (' + $g.Likelihood + ') because ' + ((@($g.Reasons)) -join '; ') + '. This is a heuristic.')
            if ($g.Module) { [void]$ev.Add('Faulting module: ' + $g.Module) }
            if ($g.Code) { [void]$ev.Add('Exception code: ' + (Show-Code $g.Code) + $(if ($g.CodeText) { ' - ' + $g.CodeText } else { '' })) }
            [void]$ev.Add([string]$g.Cnt + ' crash(es) from ' + (Fmt $g.First) + ' to ' + (Fmt $g.Last))
            if ($g.Cnt -ge 2) { [void]$ev.Add('Repeated crash with the same module and exception code: a consistent pattern, not a confirmed root cause.') }
            $st = 'WARNING'; $sev = 'Low'
            if ($g.Cnt -ge 3) { $st = 'ISSUE'; $sev = 'Medium' } elseif ($g.Cnt -eq 2) { $sev = 'Medium' }
            [void]$f.Add((New-Finding 'Game crashes' ($g.App + ' crashed ' + $g.Cnt + ' time(s)') $st $sev $ev 'Verify game files in its launcher, update the game and graphics driver, and test with overlays disabled.'))
        }
        $poss = New-Object System.Collections.ArrayList
        foreach ($g in @($gameGroups | Select-Object -First 5)) {
            $k = Norm-Hex $g.Code
            if ($k -eq 'c0000005') { [void]$poss.Add($g.App + ': access violations are often program bugs, but can also involve a graphics driver, overlay or mod, or unstable memory or overclock.') }
            elseif ($k -eq 'c0000409' -or $k -eq 'c0000374') { [void]$poss.Add($g.App + ': the program or runtime detected memory corruption. Mods, the program itself, or unstable RAM or an overclock can be involved.') }
            elseif ($k -eq 'c0000135' -or $k -eq 'c000007b') { [void]$poss.Add($g.App + ': this code relates to a missing or mismatched DLL. Check the exact message and the program required runtimes.') }
            if ($g.ModuleHint -and $g.Module) { [void]$poss.Add($g.App + ' / ' + $g.Module + ': ' + $g.ModuleHint) }
        }
        if ($poss.Count -gt 0) { [void]$f.Add((New-Finding 'Game crashes' 'Possible explanations (not confirmed)' 'INFO' 'Info' @($poss | Select-Object -Unique) 'Treat these as leads to test, one change at a time.' 'Possible')) }
    }
    # B: compatibility
    foreach ($g in @($sys.Gpus)) {
        $ev = @($g.Name + ', driver ' + $g.Driver + $(if ($g.DriverDate) { ' (' + $g.DriverDate.Substring(0, [math]::Min(10, $g.DriverDate.Length)) + ')' } else { '' }))
        if ([int]$g.ErrorCode -ne 0) { [void]$f.Add((New-Finding 'Gaming' ('Display adapter device error: ' + $g.Name) 'ISSUE' 'Medium' ($ev + @('Windows device error code ' + [string]$g.ErrorCode + ': ' + (Cm-Text ([int]$g.ErrorCode)))) 'Check the adapter in Device Manager and reinstall its driver from the GPU vendor.')) }
        else { [void]$f.Add((New-Finding 'Gaming' ('Display adapter: ' + $g.Name) 'INFO' 'Info' ($ev + @('Device status: ' + $g.Status)) '')) }
    }
    if ($sys.OS) { [void]$f.Add((New-Finding 'Gaming' 'Windows and memory' 'INFO' 'Info' @(($sys.OS.Caption + ' build ' + $sys.OS.Version + $(if ($sys.OS.Ubr) { '.' + $sys.OS.Ubr } else { '' }) + ', ' + $sys.OS.Arch), ('RAM: ' + (SizeText ($sys.OS.TotalRamMB * 1MB)) + ' total, ' + (SizeText ($sys.OS.FreeRamMB * 1MB)) + ' free right now'), 'Hardware figures are information only; they are not evidence of a performance bottleneck.') '')) }
    if ($dx.Ran -and $dx.Ok) { [void]$f.Add((New-Finding 'Gaming' 'DirectX (reported by dxdiag)' 'INFO' 'Info' @(@($dx.DirectX) + $(if ($dx.FeatureLevels) { @('Feature levels listed: ' + $dx.FeatureLevels) } else { @() })) '')) }
    elseif ($dx.Ran) { [void]$f.Add((New-Finding 'Gaming' 'DirectX (dxdiag)' 'UNKNOWN' 'Info' @($dx.Message) '')) }
    else { [void]$f.Add((New-Finding 'Gaming' 'DirectX (dxdiag)' 'NOTCHECKED' 'Info' @('dxdiag was not run in this session.') '')) }
    # display driver events and GPU stop codes
    if ($disp.Complete) {
        $n = 0; foreach ($g in $disp.Groups) { $n += $g.Cnt }
        if ($n -gt 0) {
            $ev = @($disp.Groups | Select-Object -First 4 | ForEach-Object { [string]$_.Cnt + ' x ' + $_.Provider + ' (Event ' + [string]$_.Id + '), last ' + (Fmt $_.Last) })
            $sev = 'Low'; if ($n -ge 3) { $sev = 'Medium' }
            [void]$f.Add((New-Finding 'Gaming' ('Display driver reset or error events (' + $n + ')') 'WARNING' $sev ($ev + @('A reset is an observation; it does not confirm failing hardware.')) 'If it repeats, update or cleanly reinstall the graphics driver, check temperatures and remove GPU overclocks.'))
        } else { [void]$f.Add((New-Finding 'Gaming' 'Display driver reset or error events' 'PASSED' 'Info' @('No Display 4101 or NVIDIA/AMD driver Error/Warning events in the last ' + $lab + ' (the System log was read successfully).') '')) }
    } else { [void]$f.Add((New-Finding 'Gaming' 'Display driver reset or error events' 'UNKNOWN' 'Info' (@('The System log could not be read completely.') + @($disp.Problems)) '')) }
    if (@($stops).Count -gt 0) {
        [void]$f.Add((New-Finding 'Gaming' 'Graphics-related bugcheck(s) recorded' 'ISSUE' 'Medium' @($stops | ForEach-Object { (Fmt $_.Time) + '  ' + $_.BugCode + ' ' + $_.BugName }) 'See the Crash and BSOD Analyzer. These stop codes are commonly associated with the graphics driver or GPU but do not by themselves identify the cause.'))
    }
    # storage
    $sd = $env:SystemDrive
    foreach ($v in @($sys.Volumes)) {
        if ($v.SizeBytes -le 0) { continue }
        $isTarget = ($targeted -and $targeted.Folder -and $targeted.Folder.StartsWith($v.Drive, [StringComparison]::OrdinalIgnoreCase))
        if ($isTarget -or $v.Drive -ieq $sd) {
            $pct = [math]::Round(100.0 * $v.FreeBytes / $v.SizeBytes, 1)
            $st = 'INFO'; $sev = 'Info'; $nx = ''
            if ($v.FreeBytes -lt 10GB -or $pct -lt 5) { $st = 'WARNING'; $sev = 'Low'; $nx = 'Low free space can interfere with game updates, shader caches and virtual memory. Free some space on this drive.' }
            [void]$f.Add((New-Finding 'Gaming' ('Free space on ' + $v.Drive + $(if ($isTarget) { ' (game drive)' } else { '' })) $st $sev @((SizeText $v.FreeBytes) + ' free of ' + (SizeText $v.SizeBytes) + ' (' + $pct + ' percent)') $nx))
        }
    }
    # D: targeted
    if ($targeted -and $targeted.Provided) {
        if ($targeted.Exists) {
            $ev = New-Object System.Collections.ArrayList
            if ($targeted.Info) {
                $x = $targeted.Info
                [void]$ev.Add($x.Path)
                [void]$ev.Add('Size ' + (SizeText $x.SizeBytes) + ', modified ' + $x.Modified + ', architecture ' + $x.Arch)
                if ($x.Product -or $x.FileVersion) { [void]$ev.Add('Product: ' + $x.Product + '  File version: ' + $x.FileVersion + '  Publisher: ' + $x.Company) }
                [void]$ev.Add('Digital signature status: ' + $x.Signature + '. This does not verify game-file integrity.')
                if ($x.AppCompat) { [void]$ev.Add('Compatibility settings applied to this executable: ' + $x.AppCompat) }
                if ($x.GpuPreference) { [void]$ev.Add('Windows graphics preference for this executable: ' + $x.GpuPreference) }
                if ($sys.OS -and $sys.OS.Arch -match '32' -and $x.Arch -eq 'x64') { [void]$ev.Add('This is a 64-bit program on a 32-bit Windows installation, so it cannot run.') }
            }
            [void]$ev.Add([string]$targeted.CrashMatches + ' crash record(s) in the window match this game folder or executable.')
            [void]$f.Add((New-Finding 'Gaming' 'Targeted game inspection' 'INFO' 'Info' $ev ''))
        } else { [void]$f.Add((New-Finding 'Gaming' 'Targeted game inspection' 'UNKNOWN' 'Info' @('The path you entered was not found: ' + $targeted.Input) 'Check the path and try again.')) }
    }
    [void]$f.Add((New-Finding 'Gaming' 'Game file integrity' 'NOTCHECKED' 'Info' @('MeshalFix has no supported way to verify game files for every launcher, so this was not checked.') 'Use the launcher own verify function (for example Verify integrity of game files in Steam).'))
    [void]$f.Add((New-Finding 'Gaming' 'Performance (FPS, stutter, frametime)' 'NOTCHECKED' 'Info' @('This tool does not measure frame rate or frametimes, so low FPS or stuttering cannot be diagnosed from this data.') 'Use an in-game or third-party performance overlay while reproducing the problem.'))
    return @($f)
}

function Do-Gaming([int]$hours, [bool]$runDx, [string]$gamePath, $pickedExe) {
    $since = (Get-Date).AddHours(-1 * $hours)
    Line '  [1/5] Reading system and GPU information...' 'Cyan'
    $sys = Get-SystemSummary
    Line '  [2/5] Looking for game-related crashes...' 'Cyan'
    $crash = Collect-Crashes $since
    Line '  [3/5] Looking for display driver events...' 'Cyan'
    $de = Get-LogEvents -Logs @('System') -Since $since -Levels @(2, 3) -Max 3000
    $dev = @($de.Events | Where-Object { $_.Provider -eq 'Display' -or $_.Provider -match '^(nvlddmkm|amdkmdag)$' })
    $disp = [pscustomobject]@{ Groups = @(Group-Events $dev); Complete = ($de.Problems.Count -eq 0); Problems = @($de.Problems) }
    Line '  [4/5] Preparing DirectX and game information...' 'Cyan'
    $dx = [pscustomobject]@{ Ran = $false; Ok = $false; DirectX = ''; FeatureLevels = ''; Message = '' }
    if ($runDx) { Line '        Running dxdiag (up to about a minute)...' 'DarkGray'; $dx = [pscustomobject](Get-DxDiagInfo) }
    $targeted = $null
    $root = ''
    if ($gamePath) {
        $p = $gamePath.Trim().Trim('"')
        $targeted = [pscustomobject]@{ Provided = $true; Input = $p; Exists = $false; Folder = ''; Exe = ''; Info = $null; CrashMatches = 0 }
        if (Test-Path -LiteralPath $p) {
            $targeted.Exists = $true
            $it = Get-Item -LiteralPath $p
            if ($it.PSIsContainer) { $targeted.Folder = $it.FullName } else { $targeted.Folder = $it.DirectoryName; $targeted.Exe = $it.FullName }
            if ($pickedExe) { $targeted.Exe = [string]$pickedExe }
            $root = $targeted.Folder
            if ($targeted.Exe) { $targeted.Info = Get-ExeInfo $targeted.Exe }
        }
    }
    Line '  [5/5] Evaluating...' 'Cyan'
    $gmap = @{}; $other = 0
    foreach ($c in $crash.AppCrashes) {
        $rs = Get-GameReasons $c $root
        $inRoot = ($root -and $c.Path -and $c.Path.StartsWith($root, [StringComparison]::OrdinalIgnoreCase))
        if ($inRoot -and $targeted) { $targeted.CrashMatches = $targeted.CrashMatches + 1 }
        if ($rs.Strong.Count -eq 0) { $other++; continue }
        $k = (($c.App + '|' + $c.Module + '|' + $c.Code)).ToLowerInvariant()
        if (-not $gmap.ContainsKey($k)) {
            $gmap[$k] = [pscustomobject]@{ App = $c.App; AppVer = $c.AppVer; Module = $c.Module; Code = $c.Code; CodeText = (Get-ExcText $c.Code); ModuleHint = (Get-ModuleHint $c.Module); Path = $c.Path; Likelihood = 'likely'; Reasons = @($rs.Strong + $rs.Weak); Cnt = 0; First = $c.Time; Last = $c.Time }
        }
        $g = $gmap[$k]; $g.Cnt = $g.Cnt + 1
        if ($c.Time -lt $g.First) { $g.First = $c.Time }
        if ($c.Time -gt $g.Last) { $g.Last = $c.Time }
    }
    $gameGroups = @(@($gmap.Values) | Sort-Object @{ Expression = { $_.Cnt }; Descending = $true }, @{ Expression = { $_.Last }; Descending = $true })
    $stops = @($crash.Incidents | Where-Object { (Norm-Hex $_.BugCode) -match '^(116|117|119|141)$' })
    $findings = @(Build-GamingFindings $sys $crash $disp $stops $dx $targeted $gameGroups $other $hours)
    $ov = Get-Overall $findings
    $obj = [ordered]@{
        Module = 'gaming'; Generated = (Fmt (Get-Date)); WindowHours = $hours; Complete = ($crash.AppOk -and $disp.Complete)
        Gpus = @($sys.Gpus); OS = $sys.OS; Volumes = @($sys.Volumes); DirectX = $dx
        GameCrashGroups = @($gameGroups | Select-Object -First 30 | ForEach-Object { [pscustomobject]@{ App = $_.App; AppVer = $_.AppVer; Module = $_.Module; Code = $_.Code; CodeText = $_.CodeText; ModuleHint = $_.ModuleHint; Path = $_.Path; Likelihood = $_.Likelihood; Reasons = @($_.Reasons); Count = $_.Cnt; First = (Fmt $_.First); Last = (Fmt $_.Last) } })
        OtherAppCrashes = $other; DisplayEvents = @($disp.Groups | Select-Object -First 10 | ForEach-Object { Group-ToRecord $_ })
        Targeted = $targeted; Findings = $findings; Overall = [ordered]@{ Status = $ov.Status; Text = $ov.Text }
    }
    [void](Save-Session 'gaming' $obj)
    Log ('Gaming diagnostics: ' + $gameGroups.Count + ' game crash groups, ' + $findings.Count + ' findings')
    return [pscustomobject]@{ Findings = $findings; Overall = $ov }
}
function Run-Gaming {
    Head 'GAMING DIAGNOSTICS'
    Line '  Looks for game crashes and relevant system evidence. It does not tune anything and does not measure FPS.' 'Gray'
    Blank
    $win = Pick-Window 3
    Blank
    $runDx = Ask-YN '  Collect DirectX information with dxdiag? (read-only, can take up to a minute)'
    $gamePath = ''; $picked = $null
    if (Ask-YN '  Inspect a specific game? You can enter a game .exe or a game folder') {
        $gamePath = (Read-Host '  Path to the game .exe or folder').Trim().Trim('"')
        if ($gamePath -and (Test-Path -LiteralPath $gamePath) -and (Get-Item -LiteralPath $gamePath).PSIsContainer) {
            $skip = '^(unins\w*|uninst\w*|crashreport\w*|crashpad\w*|crashhandler\w*|vcredist\w*|vc_redist\w*|dxsetup|dxwebsetup|dotnetfx\w*|setup\w*|install\w*|redist\w*|ue4prereq\w*|easyanticheat\w*|eac\w*|beservice\w*|battleye\w*|updater\w*|helper\w*|7z\w*|handler)$'
            $exes = @(Get-ChildItem -LiteralPath $gamePath -Filter '*.exe' -File -Recurse -Depth 2 -ErrorAction SilentlyContinue | Where-Object { $_.BaseName -notmatch $skip } | Sort-Object Length -Descending | Select-Object -First 8)
            if ($exes.Count -gt 0) {
                Blank
                Line '  Executables found in that folder (largest first):' 'Yellow'
                for ($i = 0; $i -lt $exes.Count; $i++) { Line ('    [' + ($i + 1) + '] ' + $exes[$i].FullName) 'Gray' }
                $a = (Read-Host '  Pick a number to inspect, or press Enter to inspect the folder only').Trim()
                $n = 0
                if ([int]::TryParse($a, [ref]$n) -and $n -ge 1 -and $n -le $exes.Count) { $picked = $exes[$n - 1].FullName }
            } else { Line '  No executables were found within two levels of that folder.' 'Yellow' }
        }
    }
    Blank
    $r = Do-Gaming $win.Hours $runDx $gamePath $picked
    Head 'GAMING DIAGNOSTICS'
    Line ('  Window: ' + $win.Label) 'Gray'
    Line '  Items marked "possible explanation" are leads, not confirmed causes.' 'DarkGray'
    Show-Findings $r.Findings
    Show-Overall $r.Overall $r.Findings
    Offer-Export
}

# ------------------------------------------------------------ HTML report
function StCls([string]$st) { return ('st-' + ([string]$st).ToLowerInvariant()) }
function Hx-Findings($list) {
    $sb = New-Object System.Text.StringBuilder
    $arr = @($list | Where-Object { $_ })
    if ($arr.Count -eq 0) { return '<p class="muted">No findings.</p>' }
    foreach ($x in $arr) {
        $c = StCls $x.Status
        [void]$sb.Append('<div class="finding ' + $c + '"><div class="fh"><span class="badge ' + $c + '">' + (Esc (StatusText $x.Status)) + '</span> <strong>' + (Esc $x.Title) + '</strong>')
        if (($x.Status -eq 'ISSUE' -or $x.Status -eq 'WARNING') -and $x.Severity -and $x.Severity -ne 'Info') { [void]$sb.Append(' <span class="sev">severity: ' + (Esc $x.Severity) + '</span>') }
        if ($x.Kind -eq 'Possible') { [void]$sb.Append(' <span class="sev">possible explanation, not confirmed</span>') }
        [void]$sb.Append('</div>')
        $ev = @($x.Evidence | Where-Object { $_ })
        if ($ev.Count -gt 0) { [void]$sb.Append('<ul>'); foreach ($e in $ev) { [void]$sb.Append('<li>' + (Esc $e) + '</li>') }; [void]$sb.Append('</ul>') }
        if ($x.Next) { [void]$sb.Append('<p class="next"><b>Next step:</b> ' + (Esc $x.Next) + '</p>') }
        [void]$sb.Append('</div>')
    }
    return $sb.ToString()
}
function Hx-KV($pairs) {
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append('<table class="kv">')
    foreach ($p in $pairs) { [void]$sb.Append('<tr><th>' + (Esc $p[0]) + '</th><td>' + (Esc $p[1]) + '</td></tr>') }
    [void]$sb.Append('</table>')
    return $sb.ToString()
}
function Hx-SystemSection($sys) {
    if ($null -eq $sys) { return '<p class="muted">System information was not collected.</p>' }
    $sb = New-Object System.Text.StringBuilder
    $pairs = New-Object System.Collections.ArrayList
    if ($sys.OS) {
        $o = $sys.OS
        [void]$pairs.Add(@('Windows', ([string]$o.Caption + $(if ($o.DisplayVersion) { '  ' + $o.DisplayVersion } else { '' }))))
        [void]$pairs.Add(@('Build', ([string]$o.Version + $(if ($o.Ubr) { '.' + $o.Ubr } else { '' }) + ', ' + $o.Arch + $(if ($o.Edition) { ', edition ID ' + $o.Edition } else { '' }))))
        [void]$pairs.Add(@('Installed on', [string]$o.InstallDate))
        [void]$pairs.Add(@('Last boot', [string]$o.LastBoot))
    } else { [void]$pairs.Add(@('Windows', 'Could not be read')) }
    if ($sys.Hardware) {
        $h = $sys.Hardware
        [void]$pairs.Add(@('Computer', ([string]$h.Manufacturer + ' ' + [string]$h.Model)))
        [void]$pairs.Add(@('Processor', ([string]$h.Cpu + ' (' + $h.Cores + ' cores, ' + $h.Threads + ' threads)')))
        [void]$pairs.Add(@('Memory', ((SizeText $h.RamBytes) + $(if ($h.RamModules -gt 0) { ' in ' + $h.RamModules + ' module(s) ' + $h.RamSpeed } else { '' }))))
        [void]$pairs.Add(@('BIOS', [string]$h.Bios))
    }
    foreach ($g in @($sys.Gpus)) {
        [void]$pairs.Add(@('Display adapter', ([string]$g.Name + ', driver ' + $g.Driver + $(if ($g.DriverDate) { ' (' + ([string]$g.DriverDate).Substring(0, [math]::Min(10, ([string]$g.DriverDate).Length)) + ')' } else { '' }) + $(if ($g.NvidiaBranded) { ', NVIDIA version ' + $g.NvidiaBranded + ' (derived)' } else { '' }) + ', status ' + $g.Status)))
    }
    foreach ($v in @($sys.Volumes)) {
        $pct = 0; if ($v.SizeBytes -gt 0) { $pct = [math]::Round(100.0 * $v.FreeBytes / $v.SizeBytes, 1) }
        [void]$pairs.Add(@(('Volume ' + $v.Drive), ((SizeText $v.SizeBytes) + ' total, ' + (SizeText $v.FreeBytes) + ' free (' + $pct + ' percent), ' + $v.Fs)))
    }
    foreach ($d in @($sys.Disks)) { [void]$pairs.Add(@('Drive', ([string]$d.Name + ' (' + $d.Media + ', ' + (SizeText $d.SizeBytes) + '), Windows status ' + $d.Health))) }
    [void]$sb.Append((Hx-KV $pairs))
    return $sb.ToString()
}
function Hx-EventSection($m, [string]$label) {
    if ($null -eq $m) { return '<p class="muted">' + (Esc $label) + ': not run in this session.</p>' }
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append('<p><b>' + (Esc $label) + '</b> - collected ' + (Esc $m.Generated) + ', window: last ' + (Esc $m.WindowHours) + ' hours, logs: ' + (Esc $m.Logs) + ', levels: ' + (Esc $m.Levels) + '.</p>')
    [void]$sb.Append('<p>Events found: ' + (Esc $m.TotalEvents) + ' (Critical ' + (Esc $m.Critical) + ', Error ' + (Esc $m.Errors) + ', Warning ' + (Esc $m.Warnings) + ') in ' + (Esc $m.GroupCount) + ' group(s). ')
    if ($m.Complete) { [void]$sb.Append('Scan status: <span class="badge st-passed">completed</span>') } else { [void]$sb.Append('Scan status: <span class="badge st-unknown">incomplete - zero results would not mean zero events</span>') }
    [void]$sb.Append('</p>')
    foreach ($p in @($m.Problems)) { [void]$sb.Append('<p class="warnline">' + (Esc $p) + '</p>') }
    if ($m.Limited) { [void]$sb.Append('<p class="warnline">Results were limited to the newest 1500 events per log; the real number may be higher.</p>') }
    $gr = @($m.Groups)
    if ($gr.Count -eq 0) {
        if ($m.Complete) { [void]$sb.Append('<p>No matching events were found. Both logs were read successfully.</p>') }
        else { [void]$sb.Append('<p>No events could be listed because the scan did not complete.</p>') }
    } else {
        [void]$sb.Append('<div class="scroll"><table><thead><tr><th>Level</th><th>Count</th><th>Last seen</th><th>Source (Event ID)</th><th>Message</th></tr></thead><tbody>')
        foreach ($g in @($gr | Select-Object -First 40)) {
            $lv = ([string]$g.Level).ToLowerInvariant()
            [void]$sb.Append('<tr><td><span class="lvl lvl-' + (Esc $lv) + '">' + (Esc $g.Level) + '</span></td><td>' + (Esc $g.Count) + '</td><td>' + (Esc $g.Last) + '</td><td>' + (Esc $g.Provider) + ' (' + (Esc $g.Id) + ')<br><span class="muted">' + (Esc $g.Log) + '</span></td><td><details><summary>' + (Esc (OneLine ([string]$g.Message) 110)) + '</summary><pre>' + (Esc $g.Message) + '</pre>')
            if ($g.Known) {
                [void]$sb.Append('<p><b>' + (Esc $g.KbTitle) + '</b><br>' + (Esc $g.KbMeans) + '</p><p><b>Possible causes (not confirmed):</b> ' + (Esc $g.KbCauses) + '</p><p><b>Next steps:</b> ' + (Esc $g.KbNext) + '</p>')
            } else { [void]$sb.Append('<p class="muted">No built-in explanation exists for this event; none is guessed.</p>') }
            [void]$sb.Append('</details></td></tr>')
        }
        [void]$sb.Append('</tbody></table></div>')
        if ($gr.Count -gt 40) { [void]$sb.Append('<p class="muted">Only the first 40 groups are shown.</p>') }
    }
    return $sb.ToString()
}
function Hx-CrashSection($c) {
    if ($null -eq $c) { return '<p class="muted">Crash and BSOD analysis was not run in this session.</p>' }
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append('<p>Collected ' + (Esc $c.Generated) + ', window: last ' + (Esc $c.WindowHours) + ' hours. Scan status: ' + $(if ($c.Complete) { '<span class="badge st-passed">completed</span>' } else { '<span class="badge st-unknown">incomplete</span>' }) + '</p>')
    foreach ($p in @($c.Problems)) { [void]$sb.Append('<p class="warnline">' + (Esc $p) + '</p>') }
    [void]$sb.Append('<h3>Application crashes</h3>')
    $ag = @($c.AppGroups)
    if ($ag.Count -eq 0) { [void]$sb.Append('<p>None recorded in this window.</p>') }
    else {
        [void]$sb.Append('<div class="scroll"><table><thead><tr><th>Count</th><th>Program</th><th>Faulting module</th><th>Exception code</th><th>First / last</th></tr></thead><tbody>')
        foreach ($g in $ag) {
            [void]$sb.Append('<tr><td>' + (Esc $g.Count) + '</td><td>' + (Esc $g.App) + ' ' + (Esc $g.AppVer) + '<br><span class="muted">' + (Esc $g.Kind) + '</span></td><td>' + (Esc $g.Module) + $(if ($g.ModuleHint) { '<details><summary>about this module</summary>' + (Esc $g.ModuleHint) + '</details>' } else { '' }) + '</td><td>' + (Esc (Show-Code ([string]$g.Code))) + $(if ($g.CodeText) { '<br><span class="muted">' + (Esc $g.CodeText) + '</span>' } else { '' }) + '</td><td>' + (Esc $g.First) + '<br>' + (Esc $g.Last) + '</td></tr>')
        }
        [void]$sb.Append('</tbody></table></div>')
    }
    [void]$sb.Append('<h3>Unexpected restarts and bugchecks</h3>')
    $ic = @($c.Incidents)
    if ($ic.Count -eq 0) { [void]$sb.Append('<p>None recorded in this window.</p>') }
    else {
        foreach ($i in $ic) {
            [void]$sb.Append('<details class="inc"><summary><b>' + (Esc $i.Time) + '</b> - ' + (Esc $i.Type) + $(if ($i.BugCode) { ' - stop code ' + (Esc $i.BugCode) + ' ' + (Esc $i.BugName) } else { ' - no stop code recorded' }) + '</summary>')
            if ($i.BugParams) { [void]$sb.Append('<p>Parameters: ' + (Esc $i.BugParams) + '</p>') }
            if ($i.BugHint) { [void]$sb.Append('<p>' + (Esc $i.BugHint) + '</p>') }
            if ($i.DumpPath) { [void]$sb.Append('<p>Dump named in the event: ' + (Esc $i.DumpPath) + ($(if ($i.DumpExists) { ' (file exists)' } else { ' (file not found)' })) + '</p>') }
            foreach ($d in @($i.Dumps)) { [void]$sb.Append('<p>Possible dump by timestamp: ' + (Esc $d) + '</p>') }
            [void]$sb.Append('<ul>'); foreach ($r in @($i.Related)) { [void]$sb.Append('<li>' + (Esc $r) + '</li>') }; [void]$sb.Append('</ul>')
            [void]$sb.Append('<p><b>Is the evidence sufficient?</b> ' + (Esc $i.Evidence) + '</p></details>')
        }
    }
    [void]$sb.Append('<h3>Dump files</h3>')
    $dm = @($c.Dumps)
    if ($dm.Count -eq 0) { [void]$sb.Append('<p>No dump files found in the standard locations.</p>') }
    else {
        [void]$sb.Append('<div class="scroll"><table><thead><tr><th>Type</th><th>Path</th><th>Size</th><th>Modified</th></tr></thead><tbody>')
        foreach ($d in $dm) { [void]$sb.Append('<tr><td>' + (Esc $d.Kind) + '</td><td>' + (Esc $d.Path) + '</td><td>' + (Esc $d.Size) + '</td><td>' + (Esc $d.Modified) + '</td></tr>') }
        [void]$sb.Append('</tbody></table></div>')
    }
    [void]$sb.Append('<p class="muted">Only dump names, sizes and dates were inspected. Dump contents were not analyzed; that needs a debugger such as WinDbg.')
    if ($c.DumpSettings -and $c.DumpSettings.Known) { [void]$sb.Append(' Crash dump setting (read only): ' + (Esc $c.DumpSettings.Type) + '.') }
    [void]$sb.Append('</p>')
    return $sb.ToString()
}
function Hx-RelSection($m) {
    if ($null -eq $m) { return '<p class="muted">Reliability history was not collected in this session.</p>' }
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append('<p>Collected ' + (Esc $m.Generated) + ', window: last ' + (Esc $m.WindowHours) + ' hours.<br>Source: <b>' + (Esc $m.Source) + '</b></p>')
    if ($m.Note) { [void]$sb.Append('<p class="warnline">' + (Esc $m.Note) + '</p>') }
    foreach ($p in @($m.Problems)) { [void]$sb.Append('<p class="warnline">' + (Esc $p) + '</p>') }
    if ($m.Limited) { [void]$sb.Append('<p class="warnline">Results were limited; older records in the window may not be listed.</p>') }
    $st = @($m.Stability)
    if ($st.Count -gt 0) {
        [void]$sb.Append('<h3>Stability index (computed by Windows, scale 1 to 10)</h3><table><thead><tr><th>Date</th><th>Index</th></tr></thead><tbody>')
        foreach ($s in $st) { [void]$sb.Append('<tr><td>' + (Esc $s.Time) + '</td><td>' + (Esc $s.Index) + '</td></tr>') }
        [void]$sb.Append('</tbody></table>')
    }
    $cl = @($m.Clusters)
    if ($cl.Count -gt 0) {
        [void]$sb.Append('<h3>Related incidents</h3><p class="muted">Records close together in time. This is a time correlation only, not proof of cause.</p>')
        foreach ($c in $cl) { [void]$sb.Append('<details class="inc"><summary>' + (Esc $c.Start) + ' to ' + (Esc $c.End) + ' - ' + (Esc $c.Count) + ' records</summary><ul>'); foreach ($l in @($c.Lines)) { [void]$sb.Append('<li>' + (Esc $l) + '</li>') }; [void]$sb.Append('</ul></details>') }
    }
    $rc = @($m.Records)
    [void]$sb.Append('<h3>Timeline (' + (Esc $m.TotalRecords) + ' record(s) in the window)</h3>')
    if ($rc.Count -eq 0) { [void]$sb.Append('<p>No records to list.</p>') }
    else {
        [void]$sb.Append('<div class="scroll"><table><thead><tr><th>Date and time</th><th>Type</th><th>Component</th><th>Summary</th></tr></thead><tbody>')
        foreach ($r in @($rc | Select-Object -First 150)) {
            [void]$sb.Append('<tr class="' + $(if ($r.IsFailure) { 'rowfail' } else { '' }) + '"><td>' + (Esc $r.Time) + '</td><td>' + (Esc $r.Category) + '</td><td>' + (Esc $r.Component) + '</td><td><details><summary>' + (Esc $r.Summary) + '</summary><pre>' + (Esc $r.Details) + '</pre></details></td></tr>')
        }
        [void]$sb.Append('</tbody></table></div>')
        if ($rc.Count -gt 150) { [void]$sb.Append('<p class="muted">Only the newest 150 records are shown.</p>') }
    }
    return $sb.ToString()
}
function Hx-GamingSection($m) {
    if ($null -eq $m) { return '<p class="muted">Gaming diagnostics were not run in this session.</p>' }
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append('<p>Collected ' + (Esc $m.Generated) + ', window: last ' + (Esc $m.WindowHours) + ' hours. Observations and possible explanations are labeled separately.</p>')
    [void]$sb.Append((Hx-Findings $m.Findings))
    $gg = @($m.GameCrashGroups)
    if ($gg.Count -gt 0) {
        [void]$sb.Append('<h3>Game-related crash groups</h3><div class="scroll"><table><thead><tr><th>Count</th><th>Program</th><th>Module</th><th>Exception</th><th>First / last</th><th>Why classified as a game</th></tr></thead><tbody>')
        foreach ($g in $gg) { [void]$sb.Append('<tr><td>' + (Esc $g.Count) + '</td><td>' + (Esc $g.App) + '<br><span class="muted">' + (Esc $g.Path) + '</span></td><td>' + (Esc $g.Module) + '</td><td>' + (Esc (Show-Code ([string]$g.Code))) + '<br><span class="muted">' + (Esc $g.CodeText) + '</span></td><td>' + (Esc $g.First) + '<br>' + (Esc $g.Last) + '</td><td>' + (Esc ((@($g.Reasons)) -join '; ')) + '</td></tr>') }
        [void]$sb.Append('</tbody></table></div>')
    }
    return $sb.ToString()
}
function Event-SummaryFinding($m, [string]$name) {
    if ($null -eq $m) { return $null }
    if (-not $m.Complete) { return (New-Finding 'Events' ($name + ': Critical and Error events') 'UNKNOWN' 'Info' (@('The scan was incomplete. Zero results would not mean zero events.') + @($m.Problems)) 'Run the toolkit as administrator and try again.') }
    if ([int]$m.TotalEvents -eq 0) { return (New-Finding 'Events' ($name + ': Critical and Error events') 'PASSED' 'Info' @('No matching events in the last ' + [string]$m.WindowHours + ' hours (both logs were read successfully).') '') }
    return (New-Finding 'Events' ($name + ': ' + [string]$m.TotalEvents + ' event(s) in ' + [string]$m.GroupCount + ' group(s)') 'INFO' 'Info' @('Window: last ' + [string]$m.WindowHours + ' hours. Levels: ' + $m.Levels + '.', 'Events are observations. An isolated error is not a confirmed root cause.') 'Review the event table in this report or the System Error Analyzer.')
}

function Build-ReportHtml([bool]$basic) {
    $health = Load-Session 'health'; $errors = Load-Session 'errors'; $recent = Load-Session 'recent'
    $crash = Load-Session 'crash'; $rel = Load-Session 'reliability'; $game = Load-Session 'gaming'
    $sys = $null
    if ($health -and $health.System) { $sys = $health.System }
    elseif ($basic) { $sys = Load-Session 'basic_system' }
    if ($null -eq $sys) { try { $sys = Get-SystemSummary } catch { $sys = $null } }

    $all = New-Object System.Collections.ArrayList
    foreach ($m in @($health, $crash, $rel, $game)) { if ($m -and $m.Findings) { foreach ($x in @($m.Findings)) { [void]$all.Add($x) } } }
    foreach ($pair in @(@($errors, 'System Error Analyzer'), @($recent, 'Recent events'))) { $fe = Event-SummaryFinding $pair[0] $pair[1]; if ($fe) { [void]$all.Add($fe) } }
    $ov = Get-Overall @($all)
    $when = Get-Date

    # recommendations (from Issue and Warning findings, most severe first, unique)
    $recs = New-Object System.Collections.ArrayList
    $cand = @($all | Where-Object { ($_.Status -eq 'ISSUE' -or $_.Status -eq 'WARNING') -and $_.Next } | Sort-Object @{ Expression = { SevRank $_.Severity }; Descending = $true })
    foreach ($x in $cand) { if (-not $recs.Contains([string]$x.Next)) { [void]$recs.Add([string]$x.Next) } }

    # limitations and checks not performed
    $lim = New-Object System.Collections.ArrayList
    if ($basic) { [void]$lim.Add('This is a BASIC report. Only a system summary and the last 24 hours of Critical/Error events were collected. No full diagnostics were run.') }
    if (-not $health) { [void]$lim.Add('System Health Report: not run in this session.') }
    elseif ($health.Integrity) {
        if (-not $health.Integrity.Dism) { [void]$lim.Add('DISM CheckHealth was not run: component store health is unknown.') }
        if (-not $health.Integrity.Sfc) { [void]$lim.Add('SFC verify-only was not run: the state of protected system files is unknown.') }
    }
    if (-not $errors) { [void]$lim.Add('System Error Analyzer: not run in this session.') }
    if (-not $recent) { [void]$lim.Add('Recent Critical/Error events (24 hours): not run in this session.') }
    if (-not $crash) { [void]$lim.Add('Crash and BSOD Analyzer: not run in this session.') }
    if (-not $rel) { [void]$lim.Add('Reliability History: not run in this session.') }
    if (-not $game) { [void]$lim.Add('Gaming Diagnostics: not run in this session.') }
    foreach ($pair in @(@($errors, 'System Error Analyzer'), @($recent, 'Recent events'), @($crash, 'Crash and BSOD Analyzer'), @($rel, 'Reliability History'), @($game, 'Gaming Diagnostics'))) {
        $m = $pair[0]
        if ($m -and ($m.Complete -eq $false)) { [void]$lim.Add($pair[1] + ': the scan was incomplete, so missing results are not evidence of absence.') }
        if ($m -and $m.Limited -eq $true) { [void]$lim.Add($pair[1] + ': results were limited by the event cap.') }
    }
    [void]$lim.Add('Only the System and Application event logs (and Reliability Monitor data) were read. Other logs were not examined.')
    [void]$lim.Add('Crash dump contents were not analyzed; only file names, sizes and dates were inspected. A debugger such as WinDbg is needed for that.')
    [void]$lim.Add('Frame rate, stutter and frametimes are not measured, and game-file integrity is not verified.')
    [void]$lim.Add('Product keys are never read. User names inside file paths are masked in this report.')

    $css = @(
        ':root{--bg:#ffffff;--fg:#1d2330;--mut:#5b6475;--card:#f5f7fa;--bd:#dde2ea;--acc:#9a6b00;--ok:#1b7f3b;--bad:#c62828;--warn:#a85d00;--unk:#7b3fa0;--nc:#59616f;--inf:#0b6a9a}',
        '@media (prefers-color-scheme:dark){:root{--bg:#14171d;--fg:#e6e9ef;--mut:#9aa3b2;--card:#1c2028;--bd:#2c323d;--acc:#e0b84c;--ok:#4cc27a;--bad:#ff6b6b;--warn:#f0b04a;--unk:#c08be0;--nc:#98a0ad;--inf:#5bb5e6}}',
        '*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--fg);font:15px/1.5 "Segoe UI",Arial,sans-serif}',
        'header{padding:28px 32px;border-bottom:3px solid var(--acc);background:var(--card)}header h1{margin:0;font-size:26px}header .brand{color:var(--acc);font-weight:700;letter-spacing:.08em;font-size:13px}',
        'main{max-width:1100px;margin:0 auto;padding:20px 24px 60px}section{margin:34px 0}h2{border-bottom:1px solid var(--bd);padding-bottom:6px;font-size:20px}h3{font-size:16px;margin-top:22px}',
        '.muted{color:var(--mut)}.warnline{color:var(--warn)}nav a{margin-right:14px;color:var(--inf);text-decoration:none}nav{margin:14px 0}',
        '.overall{border:1px solid var(--bd);border-left:8px solid var(--nc);background:var(--card);padding:14px 18px;border-radius:6px;font-size:17px}',
        '.overall.st-passed{border-left-color:var(--ok)}.overall.st-issue{border-left-color:var(--bad)}.overall.st-warning{border-left-color:var(--warn)}.overall.st-unknown{border-left-color:var(--unk)}',
        '.badge{display:inline-block;padding:1px 9px;border-radius:10px;font-size:12px;font-weight:700;color:#fff;background:var(--nc)}',
        '.badge.st-passed{background:var(--ok)}.badge.st-issue{background:var(--bad)}.badge.st-warning{background:var(--warn)}.badge.st-unknown{background:var(--unk)}.badge.st-info{background:var(--inf)}.badge.st-notchecked{background:var(--nc)}',
        '.finding{border:1px solid var(--bd);border-left:5px solid var(--nc);background:var(--card);border-radius:6px;padding:10px 14px;margin:10px 0}',
        '.finding.st-passed{border-left-color:var(--ok)}.finding.st-issue{border-left-color:var(--bad)}.finding.st-warning{border-left-color:var(--warn)}.finding.st-unknown{border-left-color:var(--unk)}.finding.st-info{border-left-color:var(--inf)}',
        '.sev{font-size:12px;color:var(--mut);margin-left:6px}.finding ul{margin:6px 0 6px 18px;padding:0}.next{margin:6px 0 2px;color:var(--inf)}',
        'table{border-collapse:collapse;width:100%;font-size:14px}th,td{border:1px solid var(--bd);padding:6px 9px;text-align:left;vertical-align:top}th{background:var(--card)}',
        'table.kv th{width:190px}.scroll{overflow-x:auto}tr.rowfail td{background:rgba(198,40,40,.07)}',
        'details{margin:2px 0}summary{cursor:pointer}pre{white-space:pre-wrap;word-break:break-word;background:var(--card);border:1px solid var(--bd);padding:8px;border-radius:4px;font:12px/1.4 Consolas,monospace}',
        '.lvl{font-weight:700}.lvl-critical,.lvl-error{color:var(--bad)}.lvl-warning{color:var(--warn)}details.inc{border:1px solid var(--bd);border-radius:6px;padding:8px 12px;margin:8px 0;background:var(--card)}',
        'footer{border-top:1px solid var(--bd);padding:18px 32px;color:var(--mut);font-size:13px}',
        '@media print{details>*{display:block}header{background:none}}'
    ) -join [Environment]::NewLine

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('<!DOCTYPE html>')
    [void]$sb.AppendLine('<html lang="en"><head><meta charset="utf-8">')
    [void]$sb.AppendLine('<meta name="viewport" content="width=device-width, initial-scale=1">')
    [void]$sb.AppendLine('<meta http-equiv="Content-Security-Policy" content="default-src ''none''; style-src ''unsafe-inline''; img-src data:">')
    [void]$sb.AppendLine('<title>MeshalFix System Report</title><style>' + $css + '</style></head><body>')
    $title = $(if ($basic) { 'System Report (basic)' } else { 'System Diagnostic Report' })
    [void]$sb.AppendLine('<header><div class="brand">MESHALFIX</div><h1>' + (Esc $title) + '</h1><div class="muted">Generated ' + (Esc (Fmt $when)) + ' - built from diagnostics run during the current toolkit session. Read-only: nothing was changed on this PC.</div></header><main>')
    [void]$sb.AppendLine('<nav><a href="#status">Status</a><a href="#system">System</a><a href="#health">Health</a><a href="#events">Events</a><a href="#crash">Crashes</a><a href="#reliability">Reliability</a><a href="#gaming">Gaming</a><a href="#next">Next steps</a><a href="#limits">Limitations</a></nav>')
    if ($basic) { [void]$sb.AppendLine('<p class="warnline"><b>BASIC REPORT.</b> Only data that could be collected at generation time is included. No full diagnostics were run in this session.</p>') }
    [void]$sb.AppendLine('<section id="status"><h2>Overall diagnostic status</h2><div class="overall ' + (StCls $ov.Status) + '"><span class="badge ' + (StCls $ov.Status) + '">' + (Esc (StatusText $ov.Status)) + '</span> ' + (Esc $ov.Text) + '</div>')
    $cp = @($all | Where-Object { $_.Status -eq 'PASSED' }).Count; $ci = @($all | Where-Object { $_.Status -eq 'ISSUE' }).Count; $cw = @($all | Where-Object { $_.Status -eq 'WARNING' }).Count
    $cn = @($all | Where-Object { $_.Status -eq 'NOTCHECKED' }).Count; $cu = @($all | Where-Object { $_.Status -eq 'UNKNOWN' }).Count
    [void]$sb.AppendLine('<p class="muted">Passed: ' + $cp + ' - Issues detected: ' + $ci + ' - Warnings: ' + $cw + ' - Not checked: ' + $cn + ' - Unable to determine: ' + $cu + '. Not checked and Unable to determine are not passed checks.</p></section>')
    [void]$sb.AppendLine('<section id="system"><h2>Windows and hardware summary</h2>' + (Hx-SystemSection $sys) + '</section>')
    [void]$sb.AppendLine('<section id="health"><h2>System health findings</h2>')
    if ($health) { [void]$sb.AppendLine('<p class="muted">System Health Report collected ' + (Esc $health.Generated) + '.</p>' + (Hx-Findings $health.Findings)) } else { [void]$sb.AppendLine('<p class="muted">The System Health Report was not run in this session.</p>') }
    [void]$sb.AppendLine('</section>')
    [void]$sb.AppendLine('<section id="events"><h2>Critical and error event summaries</h2>' + (Hx-EventSection $errors 'System Error Analyzer') + '<h3>Recent Critical/Error events</h3>' + (Hx-EventSection $recent 'Recent events') + '</section>')
    [void]$sb.AppendLine('<section id="crash"><h2>Crash and BSOD findings</h2>')
    if ($crash -and $crash.Findings) { [void]$sb.AppendLine((Hx-Findings $crash.Findings)) }
    [void]$sb.AppendLine((Hx-CrashSection $crash) + '</section>')
    [void]$sb.AppendLine('<section id="reliability"><h2>Reliability history findings</h2>')
    if ($rel -and $rel.Findings) { [void]$sb.AppendLine((Hx-Findings $rel.Findings)) }
    [void]$sb.AppendLine((Hx-RelSection $rel) + '</section>')
    [void]$sb.AppendLine('<section id="gaming"><h2>Gaming diagnostics findings</h2>' + (Hx-GamingSection $game) + '</section>')
    [void]$sb.AppendLine('<section id="next"><h2>Recommended next steps</h2>')
    if ($recs.Count -gt 0) { [void]$sb.AppendLine('<ol>'); foreach ($r in @($recs | Select-Object -First 12)) { [void]$sb.AppendLine('<li>' + (Esc $r) + '</li>') }; [void]$sb.AppendLine('</ol>') }
    else { [void]$sb.AppendLine('<p>The checks that ran did not identify specific actions.' + $(if ($cn -gt 0 -or $cu -gt 0) { ' Some checks were not performed or could not be determined; consider running them.' } else { '' }) + '</p>') }
    [void]$sb.AppendLine('<p class="muted">Recommendations come from the findings above. An isolated error is not a confirmed root cause, and nothing here was changed automatically.</p></section>')
    [void]$sb.AppendLine('<section id="limits"><h2>Limitations and checks not performed</h2><ul>')
    foreach ($l in $lim) { [void]$sb.AppendLine('<li>' + (Esc $l) + '</li>') }
    [void]$sb.AppendLine('</ul></section></main><footer>Generated by MeshalFix Toolkit. This report is self-contained and works offline. Data reflects the moments the diagnostics ran.</footer></body></html>')
    return $sb.ToString()
}

function Make-Report([bool]$basic) {
    $stamp = (Get-Date).ToString('yyyyMMdd_HHmmss', $Inv)
    $base = $(if ($basic) { 'MeshalFix_BasicReport_' } else { 'MeshalFix_SystemReport_' }) + $stamp
    $marker = Join-Path $SessionDir 'last_report.txt'
    try { if (Test-Path -LiteralPath $marker) { Remove-Item -LiteralPath $marker -Force -ErrorAction SilentlyContinue } } catch { }
    $html = $null
    try { $html = Build-ReportHtml $basic } catch {
        Line ('  Report generation FAILED while building the page: ' + $_.Exception.Message) 'Red'
        Log ('Report build failed: ' + $_.Exception.Message)
        $script:ExitCode = 1
        return $false
    }
    $path = Join-Path $LogDir ($base + '.html')
    $n = 1
    while (Test-Path -LiteralPath $path) { $n++; $path = Join-Path $LogDir ($base + '_' + $n + '.html') }
    try {
        $fs = New-Object System.IO.FileStream($path, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
        try { $bytes = $Utf8.GetBytes($html); $fs.Write($bytes, 0, $bytes.Length) } finally { $fs.Close() }
        $info = Get-Item -LiteralPath $path -ErrorAction Stop
        $tail = [IO.File]::ReadAllText($path, $Utf8).TrimEnd()
        if ($info.Length -lt 500 -or -not $tail.EndsWith('</html>')) { throw 'The saved file failed the completeness check.' }
        [IO.File]::WriteAllText($marker, $path, $Utf8)
        Line ('  HTML report saved: ' + $path) 'Green'
        Log ('HTML report saved: ' + $path)
        return $true
    } catch {
        Line ('  Report generation FAILED while saving: ' + $_.Exception.Message) 'Red'
        Line '  No report was produced, so none will be offered for opening. Your diagnostic results are kept for this session.' 'Yellow'
        Log ('Report save failed: ' + $_.Exception.Message)
        try { if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue } } catch { }
        $script:ExitCode = 1
        return $false
    }
}

function Offer-Export {
    Blank
    if (Ask-YN '  Export the results of this session to an HTML report now?') {
        Blank
        [void](Make-Report $false)
    }
    Blank
    Wait-Enter 'Press Enter to return to MeshalFix'
}

function Run-Report {
    Head 'GENERATE & EXPORT HTML REPORT'
    $names = [ordered]@{ health = 'System Health Report'; errors = 'System Error Analyzer'; recent = 'Recent Critical/Error events'; crash = 'Crash & BSOD Analyzer'; reliability = 'Reliability History'; gaming = 'Gaming Diagnostics' }
    $have = New-Object System.Collections.ArrayList
    foreach ($k in $names.Keys) { if (Test-Path -LiteralPath (Join-Path $SessionDir ($k + '.json'))) { [void]$have.Add($k) } }
    $needEvents = (-not ($have -contains 'errors') -and -not ($have -contains 'recent'))
    $missing = New-Object System.Collections.ArrayList
    if (-not ($have -contains 'health')) { [void]$missing.Add('health') }
    if ($needEvents) { [void]$missing.Add('errors') }
    if (-not ($have -contains 'crash')) { [void]$missing.Add('crash') }
    if (-not ($have -contains 'reliability')) { [void]$missing.Add('reliability') }
    $choice = ''
    if ($have.Count -eq 0) {
        Line '  No diagnostics have been run in this session, so there are no current-session results to export.' 'Yellow'
        Blank
        Line '  [1] Run the standard diagnostics now, then generate the report' 'Cyan'
        Line '      (health without DISM/SFC, errors 7 days, crashes 30 days, reliability 30 days)' 'DarkGray'
        Line '  [2] Generate a clearly labeled BASIC report (system summary + last 24 hours of Critical/Error events)' 'Cyan'
        Line '  [0] Cancel' 'Cyan'
        while ($true) {
            $a = (Read-Host '  Select').Trim()
            if ($a -eq '1' -or $a -eq '2' -or $a -eq '0') { $choice = $a; break }
            Line '  Please enter 1, 2 or 0.' 'Yellow'
        }
        if ($choice -eq '0') { $script:ExitCode = 2; return }
        if ($choice -eq '2') { $choice = 'basic' } else { $choice = 'full' }
    } else {
        Line '  Results available from this session:' 'Yellow'
        foreach ($k in $have) { $m = Load-Session $k; Line ('    ' + $names[$k].PadRight(32) + 'collected ' + $(if ($m) { [string]$m.Generated } else { '(unreadable)' })) 'Gray' }
        if ($missing.Count -gt 0) {
            Blank
            Line '  Not yet run: ' 'Yellow'
            foreach ($k in $missing) { Line ('    ' + $names[$k]) 'DarkGray' }
        }
        Blank
        Line '  [1] Generate the report from the available results (missing parts are listed as not performed)' 'Cyan'
        if ($missing.Count -gt 0) { Line '  [2] Run the missing standard diagnostics first, then generate the report' 'Cyan' }
        Line '  [0] Cancel' 'Cyan'
        while ($true) {
            $a = (Read-Host '  Select').Trim()
            if ($a -eq '0' -or $a -eq '1' -or ($a -eq '2' -and $missing.Count -gt 0)) { $choice = $a; break }
            Line '  Please enter a number from the list.' 'Yellow'
        }
        if ($choice -eq '0') { $script:ExitCode = 2; return }
        if ($choice -eq '1') { $choice = 'now' } else { $choice = 'full' }
    }
    Blank
    if ($choice -eq 'full') {
        if ($missing.Count -eq 0 -or ($missing -contains 'health')) { [void](Do-Health $null $null) }
        if ($missing.Count -eq 0 -or ($missing -contains 'errors')) { $sc = Scan-Events 168 $false; Save-EventSession 'errors' $sc }
        if ($missing.Count -eq 0 -or ($missing -contains 'crash')) { [void](Do-Crash 720) }
        if ($missing.Count -eq 0 -or ($missing -contains 'reliability')) { [void](Do-Reliability 720) }
        Blank
    }
    $basic = $false
    if ($choice -eq 'basic') {
        $basic = $true
        Line '  Collecting the basic data...' 'Cyan'
        $sys = Get-SystemSummary
        [void](Save-Session 'basic_system' $sys)
        $sc = Scan-Events 24 $false
        Save-EventSession 'recent' $sc
        Blank
    }
    Line '  Building the HTML report...' 'Cyan'
    [void](Make-Report $basic)
    Blank
    Wait-Enter 'Press Enter to return to MeshalFix'
}

# ------------------------------------------------------------ dispatcher
try {
    switch ($Mode) {
        'Health'      { Run-Health }
        'Errors'      { Run-Errors }
        'Crash'       { Run-Crash }
        'Recent'      { Run-Recent }
        'Reliability' { Run-Reliability }
        'Gaming'      { Run-Gaming }
        'Report'      { Run-Report }
        default       { Line ('  Unknown mode: ' + $Mode) 'Red'; $script:ExitCode = 3; Wait-Enter }
    }
} catch {
    Line ''
    Line ('  An unexpected error stopped this diagnostic: ' + $_.Exception.Message) 'Red'
    Line '  Nothing on the PC was changed. The error was written to the toolkit log.' 'Yellow'
    Log ('Unexpected error in mode ' + $Mode + ': ' + $_.Exception.Message + ' at ' + $_.InvocationInfo.PositionMessage)
    $script:ExitCode = 1
    Wait-Enter 'Press Enter to return to MeshalFix'
}
exit $script:ExitCode
#SR_END
#CL_BEGIN
# ====================================================================
#  FixToolkit cleaning engine. Started only by the Cleaning Tools menu.
#    RADAR   : Space Reclaim Radar. Estimates how much space each cleaning
#              option can free. Prints only KEY=value lines
#              (DEEP, THUMB, ORPH, BIN, TOTAL). Never deletes anything.
#    ORPHANS : Orphaned File Scanner. Interactive, runs in its own window.
#              Shows folders that probably belong to programs that are no
#              longer installed. Nothing is removed unless the user picks
#              it and types DELETE. Removed folders go to the Recycle Bin.
#  ASCII only on purpose.
# ====================================================================
$ErrorActionPreference = 'SilentlyContinue'
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false } catch { }
try { [Threading.Thread]::CurrentThread.CurrentCulture = [Globalization.CultureInfo]::InvariantCulture } catch { }

$Mode       = $env:FT_CLMODE
$RadarMode  = $env:FT_RADAR
$OrphFile   = $env:FT_ORPHFILE
$LogDir     = $env:FT_LOGDIR
$ToolkitLog = $env:FT_LOGFILE
$SelfPath   = $env:FT_SELF

# Fast folder measuring (skips junctions, never stops on access denied)
if (-not ('FtScan' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.Collections.Generic;

public class FtInfo
{
    public long Bytes;
    public long Newest;
    public int Files;
    public int Exe;
}

public static class FtScan
{
    public static FtInfo Measure(string root, long cutoff, string pattern, bool recurse)
    {
        FtInfo r = new FtInfo();
        if (string.IsNullOrEmpty(root)) return r;
        if (string.IsNullOrEmpty(pattern)) pattern = "*";
        Stack<string> st = new Stack<string>();
        st.Push(root);
        while (st.Count > 0)
        {
            string d = st.Pop();
            DirectoryInfo di;
            try
            {
                di = new DirectoryInfo(d);
                if (!di.Exists) continue;
            }
            catch { continue; }
            try
            {
                foreach (FileInfo f in di.EnumerateFiles(pattern))
                {
                    try
                    {
                        long t = f.LastWriteTimeUtc.Ticks;
                        if (cutoff > 0 && t >= cutoff) continue;
                        r.Bytes += f.Length;
                        r.Files++;
                        if (t > r.Newest) r.Newest = t;
                        string x = f.Extension;
                        if (x.Equals(".exe", StringComparison.OrdinalIgnoreCase) || x.Equals(".dll", StringComparison.OrdinalIgnoreCase)) r.Exe++;
                    }
                    catch { }
                }
            }
            catch { }
            if (!recurse) continue;
            try
            {
                foreach (DirectoryInfo s in di.EnumerateDirectories())
                {
                    try
                    {
                        if ((s.Attributes & FileAttributes.ReparsePoint) != 0) continue;
                        st.Push(s.FullName);
                    }
                    catch { }
                }
            }
            catch { }
        }
        return r;
    }
}
'@
}

function Fmt([int64]$b) {
    if ($b -ge 1GB) { return ('{0:0.0} GB' -f ($b / 1GB)) }
    if ($b -ge 1MB) { return ('{0:0} MB' -f ($b / 1MB)) }
    if ($b -ge 1KB) { return ('{0:0} KB' -f ($b / 1KB)) }
    return '0 MB'
}

function Log([string]$m) {
    if ($ToolkitLog) {
        try { Add-Content -LiteralPath $ToolkitLog -Value ('[' + (Get-Date).ToString('yyyy-MM-dd HH:mm:ss', [cultureinfo]::InvariantCulture) + '] ORPHANSCAN - ' + $m) -ErrorAction SilentlyContinue } catch { }
    }
}

# ====================================================================
#  RADAR: how much each option can free (an estimate, nothing is deleted)
# ====================================================================
$script:Seen = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)

# Size of a whole folder. $Cut > 0 counts only files older than that moment (ticks, UTC).
function Add-Dir([string]$Path, [int64]$Cut = 0) {
    if (-not $Path) { return [int64]0 }
    if (-not $script:Seen.Add($Path.TrimEnd('\'))) { return [int64]0 }
    $i = [FtScan]::Measure($Path, $Cut, '*', $true)
    return [int64]$i.Bytes
}

# Size of the files that match a pattern inside a folder.
function Add-Pat([string]$Dir, [string]$Pattern, [bool]$Recurse) {
    if (-not $Dir) { return [int64]0 }
    if (-not $script:Seen.Add($Dir.TrimEnd('\') + '|' + $Pattern)) { return [int64]0 }
    $i = [FtScan]::Measure($Dir, 0, $Pattern, $Recurse)
    return [int64]$i.Bytes
}

# Cache folders of one Chromium based browser / app (cookies, logins and history are never listed)
function Get-ChromiumPaths([string]$Root) {
    $o = @()
    if ((-not $Root) -or (-not (Test-Path -LiteralPath $Root))) { return $o }
    $profiles = @($Root)
    foreach ($d in @(Get-ChildItem -LiteralPath $Root -Directory -Force -ErrorAction SilentlyContinue)) {
        if (($d.Name -eq 'Default') -or ($d.Name -like 'Profile *')) { $profiles += $d.FullName }
    }
    foreach ($p in $profiles) {
        foreach ($s in @('Cache', 'Code Cache', 'Media Cache', 'Application Cache', 'Service Worker\CacheStorage')) { $o += ($p + '\' + $s) }
    }
    $o += ($Root + '\Crashpad\reports')
    return $o
}

# Estimate for option 1 (Deep clean). Same folders the Deep clean empties.
# Disk Cleanup, component cleanup and Windows.old are not counted.
function Get-DeepBytes {
    $sum = [int64]0
    $day = (Get-Date).AddDays(-1).ToUniversalTime().Ticks
    $sr = $env:SystemRoot
    $sd = $env:SystemDrive
    $pd = $env:ProgramData
    $la = $env:LocalAppData
    $ra = $env:APPDATA
    $up = $env:USERPROFILE
    $pf86 = ${env:ProgramFiles(x86)}
    $users = @(Get-ChildItem -LiteralPath ($sd + '\Users') -Directory -Force -ErrorAction SilentlyContinue)

    # temp files older than 24 hours
    $tmp = @(($sr + '\Temp'))
    # %TEMP% often uses a short 8.3 name of the same folder the user loop below already covers
    if ($env:TEMP -and ($env:TEMP -notmatch '~\d')) { $tmp += $env:TEMP }
    foreach ($u in $users) { $tmp += ($u.FullName + '\AppData\Local\Temp') }
    foreach ($p in $tmp) { $sum += (Add-Dir $p $day) }

    # old Windows logs
    $sum += (Add-Pat ($sr + '\Logs\CBS') '*.cab' $false)
    $sum += (Add-Pat ($sr + '\Logs\CBS') 'CbsPersist_*.log' $false)
    $sum += (Add-Pat ($sr + '\Debug') '*.log' $false)
    $sum += (Add-Pat ($sr + '\Logs\DISM') '*.log' $false)
    $sum += (Add-Pat ($sr + '\Logs\MoSetup') '*.log' $true)
    $sum += (Add-Pat ($pd + '\Microsoft\Windows Defender\Support') '*.log' $true)
    $sum += (Add-Pat ($sd + '\') '*.chk' $false)
    foreach ($f in @(Get-ChildItem -LiteralPath ($sd + '\') -Directory -Force -Filter 'FOUND.*' -ErrorAction SilentlyContinue)) { $sum += (Add-Dir $f.FullName) }

    # memory dumps, error reports, crash dumps
    $sum += (Add-Pat ($sr + '\LiveKernelReports') '*.dmp' $true)
    $sum += (Add-Pat $sr 'MEMORY.DMP' $false)
    foreach ($u in $users) { $sum += (Add-Dir ($u.FullName + '\AppData\Local\CrashDumps')) }

    $dirs = @(
        ($sd + '\PerfLogs'),
        ($la + '\Microsoft\Windows\INetCache'), ($up + '\AppData\LocalLow\Temp'), ($la + '\Microsoft\Windows\Caches'),
        ($sr + '\System32\config\systemprofile\AppData\Local\Temp'),
        ($sr + '\ServiceProfiles\NetworkService\AppData\Local\Temp'), ($sr + '\ServiceProfiles\LocalService\AppData\Local\Temp'),
        ($sd + '\OneDriveTemp'),
        ($sr + '\Prefetch'),
        ($sr + '\SoftwareDistribution\Download'), ($sr + '\SoftwareDistribution\DeliveryOptimization'),
        ($sr + '\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Cache'),
        ($sr + '\Logs\WindowsUpdate'),
        ($pd + '\Microsoft\Windows\WER\ReportArchive'), ($pd + '\Microsoft\Windows\WER\ReportQueue'), ($pd + '\Microsoft\Windows\WER\Temp'),
        ($la + '\Microsoft\Windows\WER'),
        ($sr + '\Minidump'), ($sr + '\System32\SleepStudy'),
        ($pd + '\Microsoft\Diagnosis\EventsStore'), ($pd + '\Microsoft\Diagnosis\ETLLogs\AutoLogger'), ($pd + '\Microsoft\Diagnosis\ETLLogs\ShutdownLogger')
    )
    foreach ($p in $dirs) { $sum += (Add-Dir $p) }

    # browsers and Chromium based apps
    $chromium = @(
        ($la + '\Google\Chrome\User Data'), ($la + '\Microsoft\Edge\User Data'), ($la + '\BraveSoftware\Brave-Browser\User Data'),
        ($la + '\Opera Software\Opera Stable'), ($ra + '\Opera Software\Opera Stable'),
        ($la + '\Opera Software\Opera GX Stable'), ($ra + '\Opera Software\Opera GX Stable'),
        ($la + '\Vivaldi\User Data'), ($la + '\Yandex\YandexBrowser\User Data'), ($la + '\Chromium\User Data'),
        ($ra + '\discord'), ($ra + '\discordptb'), ($ra + '\discordcanary'),
        ($ra + '\Microsoft\Teams'), ($ra + '\Slack'), ($ra + '\Code')
    )
    foreach ($r in $chromium) { foreach ($p in @(Get-ChromiumPaths $r)) { $sum += (Add-Dir $p) } }
    foreach ($fr in @(($la + '\Mozilla\Firefox\Profiles'), ($la + '\librewolf\Profiles'), ($la + '\Waterfox\Profiles'))) {
        foreach ($pr in @(Get-ChildItem -LiteralPath $fr -Directory -ErrorAction SilentlyContinue)) {
            $sum += (Add-Dir ($pr.FullName + '\cache2'))
            $sum += (Add-Dir ($pr.FullName + '\OfflineCache'))
        }
    }
    $sum += (Add-Dir ($ra + '\Mozilla\Firefox\Crash Reports'))

    # app caches and logs
    $steam = $null
    try { $steam = [string](Get-ItemProperty -LiteralPath 'HKCU:\Software\Valve\Steam' -ErrorAction Stop).SteamPath } catch { }
    if ($steam) {
        $steam = $steam.Replace('/', '\')
        foreach ($s in @('appcache\httpcache', 'logs', 'dumps', 'depotcache')) { $sum += (Add-Dir ($steam + '\' + $s)) }
    }
    foreach ($w in @(Get-ChildItem -LiteralPath ($la + '\EpicGamesLauncher\Saved') -Directory -Filter 'webcache*' -ErrorAction SilentlyContinue)) { $sum += (Add-Dir $w.FullName) }
    $apps = @(
        ($la + '\Spotify\Data'), ($la + '\Packages\SpotifyAB.SpotifyMusic_zpdnekdrzrea0\LocalCache\Spotify\Data'),
        ($ra + '\Microsoft\Teams\tmp'), ($ra + '\Telegram Desktop\tdata\user_data\cache'), ($ra + '\Telegram Desktop\tdata\user_data\media_cache'),
        ($ra + '\Zoom\data\cache'), ($ra + '\Sun\Java\Deployment\cache'),
        ($ra + '\Adobe\Common\Media Cache Files'), ($ra + '\Adobe\Common\Media Cache'),
        ($la + '\Packages\Microsoft.WindowsStore_8wekyb3d8bbwe\LocalCache'),
        ($la + '\Packages\Microsoft.GamingApp_8wekyb3d8bbwe\LocalCache'),
        ($la + '\Packages\Microsoft.XboxGamingOverlay_8wekyb3d8bbwe\LocalCache'),
        ($ra + '\Code\CachedData'), ($ra + '\Code\CachedExtensionVSIXs'), ($ra + '\Code\logs'),
        ($la + '\Microsoft\OneDrive\logs'), ($la + '\Steam\htmlcache'),
        ($pd + '\Battle.net\Cache'), ($pd + '\Blizzard Entertainment\Battle.net\Cache'), ($la + '\Battle.net\Cache'), ($ra + '\Battle.net\Cache'), ($ra + '\Battle.net\Logs'),
        ($la + '\Electronic Arts\EA Desktop\Cache'),
        ($la + '\Ubisoft Game Launcher\cache'), ($pf86 + '\Ubisoft\Ubisoft Game Launcher\cache'), ($la + '\Ubisoft Game Launcher\logs'),
        ($la + '\EpicGamesLauncher\Saved\Logs'), ($la + '\Riot Games\Riot Client\Logs'), ($la + '\VALORANT\Saved\Logs'),
        ($pd + '\Origin\Logs'), ($la + '\Rockstar Games\Launcher\Cache'), ($la + '\GOG.com\Galaxy\logs'),
        ($ra + '\.minecraft\logs'), ($ra + '\.minecraft\crash-reports'),
        ($sd + '\NVIDIA'), ($sd + '\AMD'), ($sd + '\INTEL'), ($pd + '\NVIDIA Corporation\Downloader')
    )
    foreach ($p in $apps) { $sum += (Add-Dir $p) }
    return $sum
}

# Estimate for option 2 (icon and thumbnail cache)
function Get-ThumbBytes {
    $la = $env:LocalAppData
    $s = [int64]0
    $s += (Add-Pat $la 'IconCache.db' $false)
    $s += (Add-Pat ($la + '\Microsoft\Windows\Explorer') 'iconcache_*.db' $false)
    $s += (Add-Pat ($la + '\Microsoft\Windows\Explorer') 'thumbcache_*.db' $false)
    return $s
}

# Estimate for option 4 (Recycle Bin of the current user on every fixed drive)
function Get-BinBytes {
    $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    $s = [int64]0
    foreach ($d in [IO.DriveInfo]::GetDrives()) {
        if (($d.DriveType -eq 'Fixed') -and $d.IsReady) {
            $i = [FtScan]::Measure(($d.Name + '$Recycle.Bin\' + $sid), 0, '*', $true)
            $s += [int64]$i.Bytes
        }
    }
    return $s
}

# ====================================================================
#  ORPHANED FILE SCANNER (detection)
#  A top-level folder in Program Files, ProgramData or AppData is listed only when ALL of these are true:
#    - its name is not a protected Windows / driver folder,
#    - no installed program, service, startup entry, scheduled task or running process points into it,
#    - its name does not match any installed program or publisher,
#    - nothing inside it was changed in the last 30 days,
#    - it holds at least 1 MB.
#  It is a list of SUSPECTS for the user to review, never a proof.
# ====================================================================
$ProtectedRx = '^(microsoft.*|windows.*|\$.*|packages|package cache|temp|tmp|programs|common files|application data|desktop|documents|start menu|templates|crashdumps|d3dscache|connecteddevicesplatform|history|inetcache|publishers|virtualstore|dotnet|reference assemblies|msbuild|iis.*|internet explorer|uninstall information|modifiablewindowsapps|windowsapps|nvidia.*|amd.*|intel.*|realtek.*|qualcomm.*|mediatek.*|broadcom.*|synaptics.*|regid\..*|ssh|usoprivate|usoshared|softwaredistribution|comms|wer|diagnostics|elevateddiagnostics|system volume information|recovery|npm|npm-cache|pip|nuget|\.nuget|yarn|pnpm.*|node-gyp)$'

function Norm([string]$s) {
    if (-not $s) { return '' }
    return ($s.ToLowerInvariant() -replace '[^\p{L}\p{Nd}]', '')
}

# Adds every folder above each path found in $Text to the set (so a folder is "in use" when anything inside it is referenced)
function Add-PathStrings([string]$Text, $Set) {
    if (-not $Text) { return }
    foreach ($m in [regex]::Matches($Text, '[A-Za-z]:\\[^"*?<>|,;]*?(?=\s+[A-Za-z]:\\|["*?<>|,;]|$)')) {
        $p = $m.Value.Trim().TrimEnd('\').ToLowerInvariant()
        while ($p.Length -gt 3) {
            [void]$Set.Add($p)
            $i = $p.LastIndexOf('\')
            if ($i -lt 3) { break }
            $p = $p.Substring(0, $i)
        }
    }
}

# Collects what is installed or in use: folders (Anc) and name fragments (Tok)
function Build-Known {
    $anc = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    $tok = New-Object 'System.Collections.Generic.HashSet[string]'

    $ukeys = @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
               'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
               'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*')
    foreach ($it in @(Get-ItemProperty -Path $ukeys -ErrorAction SilentlyContinue)) {
        foreach ($f in @('DisplayName', 'Publisher', 'PSChildName')) {
            $n = Norm ([string]$it.$f)
            if ($n.Length -ge 3) { [void]$tok.Add($n) }
        }
        foreach ($f in @('InstallLocation', 'DisplayIcon', 'UninstallString', 'QuietUninstallString', 'ModifyPath')) {
            Add-PathStrings ([string]$it.$f) $anc
        }
    }
    foreach ($k in @(Get-ChildItem -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Services' -ErrorAction SilentlyContinue)) {
        $ip = $null
        try { $ip = $k.GetValue('ImagePath') } catch { }
        if ($ip) { Add-PathStrings ([string]$ip) $anc }
    }
    $runKeys = @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run', 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce',
                 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run',
                 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run', 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce')
    foreach ($rk in $runKeys) {
        $key = Get-Item -LiteralPath $rk -ErrorAction SilentlyContinue
        if ($key) { foreach ($vn in $key.GetValueNames()) { Add-PathStrings ([string]$key.GetValue($vn)) $anc } }
    }
    $apRoots = @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths',
                 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths',
                 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths')
    foreach ($ap in $apRoots) {
        foreach ($k in @(Get-ChildItem -LiteralPath $ap -ErrorAction SilentlyContinue)) {
            Add-PathStrings ([string]$k.GetValue('')) $anc
            Add-PathStrings ([string]$k.GetValue('Path')) $anc
        }
    }
    foreach ($p in @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue)) { Add-PathStrings ([string]$p.ExecutablePath) $anc }
    try {
        foreach ($t in @(Get-ScheduledTask -ErrorAction Stop)) {
            foreach ($a in @($t.Actions)) {
                Add-PathStrings ([string]$a.Execute) $anc
                Add-PathStrings ([string]$a.Arguments) $anc
                Add-PathStrings ([string]$a.WorkingDirectory) $anc
            }
        }
    } catch { }
    Add-PathStrings $SelfPath $anc
    return @{ Anc = $anc; Tok = @($tok) }
}

# True when the normalized folder name matches an installed program or publisher
function Is-Linked([string]$n, $Tokens) {
    foreach ($t in $Tokens) {
        if ($n.Length -ge 4) {
            if ($t.Contains($n)) { return $true }
            if (($t.Length -ge 5) -and $n.Contains($t)) { return $true }
        } else {
            if ($t.StartsWith($n)) { return $true }
        }
    }
    return $false
}

function Find-Orphans {
    $known = Build-Known
    $anc = $known.Anc
    $tok = $known.Tok
    $minAge = (Get-Date).ToUniversalTime().AddDays(-30)
    $res = New-Object System.Collections.ArrayList
    $roots = @(
        @{ Path = $env:ProgramFiles;                      Label = 'Program Files';       Kind = 'Program' },
        @{ Path = ${env:ProgramFiles(x86)};               Label = 'Program Files (x86)'; Kind = 'Program' },
        @{ Path = ($env:LocalAppData + '\Programs');      Label = 'AppData\Local\Programs'; Kind = 'Program' },
        @{ Path = $env:ProgramData;                       Label = 'ProgramData';         Kind = 'Data' },
        @{ Path = $env:LocalAppData;                      Label = 'AppData\Local';       Kind = 'Data' },
        @{ Path = $env:APPDATA;                           Label = 'AppData\Roaming';     Kind = 'Data' },
        @{ Path = ($env:USERPROFILE + '\AppData\LocalLow'); Label = 'AppData\LocalLow';  Kind = 'Data' }
    )
    foreach ($r in $roots) {
        if ((-not $r.Path) -or (-not (Test-Path -LiteralPath $r.Path))) { continue }
        foreach ($d in @(Get-ChildItem -LiteralPath $r.Path -Directory -Force -ErrorAction SilentlyContinue)) {
            if (($d.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { continue }
            if (($d.Attributes -band [IO.FileAttributes]::System) -ne 0) { continue }
            if ($d.Name.ToLowerInvariant() -match $ProtectedRx) { continue }
            $full = $d.FullName
            if ($anc.Contains($full.TrimEnd('\').ToLowerInvariant())) { continue }
            $n = Norm $d.Name
            if (-not $n) { continue }
            if (Is-Linked $n $tok) { continue }
            $info = [FtScan]::Measure($full, 0, '*', $true)
            if ($info.Bytes -lt 1MB) { continue }
            $newest = New-Object DateTime ([int64]$info.Newest), ([DateTimeKind]::Utc)
            if ($newest -gt $minAge) { continue }
            [void]$res.Add([pscustomobject]@{
                Name = $d.Name; Path = $full; Location = $r.Label; Kind = $r.Kind
                Bytes = [int64]$info.Bytes; Newest = $newest; Files = [int]$info.Files; Exe = [int]$info.Exe })
        }
    }
    return @($res | Sort-Object -Property Bytes -Descending)
}

# The scan result is kept in a small text file so the radar and the scanner window share it.
# Line 1: TOTAL=bytes. Other lines: bytes|newest ticks|location|name|path|files|exe|kind
function Save-Orphans($List) {
    if (-not $OrphFile) { return }
    $tot = [int64]0
    foreach ($o in $List) { $tot += [int64]$o.Bytes }
    $lines = New-Object System.Collections.ArrayList
    [void]$lines.Add('TOTAL=' + [string]$tot)
    foreach ($o in $List) {
        [void]$lines.Add((@([string]$o.Bytes, [string]$o.Newest.Ticks, $o.Location, $o.Name, $o.Path, [string]$o.Files, [string]$o.Exe, $o.Kind) -join '|'))
    }
    try { [IO.File]::WriteAllLines($OrphFile, [string[]]$lines, (New-Object Text.UTF8Encoding $false)) } catch { }
}

function Read-Orphans {
    $out = @()
    if ((-not $OrphFile) -or (-not (Test-Path -LiteralPath $OrphFile))) { return $null }
    $lines = @()
    try { $lines = @([IO.File]::ReadAllLines($OrphFile, (New-Object Text.UTF8Encoding $false))) } catch { return $null }
    foreach ($l in ($lines | Select-Object -Skip 1)) {
        $p = $l.Split('|')
        if ($p.Count -lt 8) { continue }
        $out += [pscustomobject]@{
            Bytes = [int64]$p[0]; Newest = (New-Object DateTime ([int64]$p[1]), ([DateTimeKind]::Utc)); Location = $p[2]; Name = $p[3]
            Path = $p[4]; Files = [int]$p[5]; Exe = [int]$p[6]; Kind = $p[7] }
    }
    return ,@($out)
}

function Read-OrphTotal {
    if ((-not $OrphFile) -or (-not (Test-Path -LiteralPath $OrphFile))) { return [int64]0 }
    try {
        $first = [IO.File]::ReadAllLines($OrphFile, (New-Object Text.UTF8Encoding $false)) | Select-Object -First 1
        if ($first -match '^TOTAL=(\d+)$') { return [int64]$Matches[1] }
    } catch { }
    return [int64]0
}

# ====================================================================
#  RADAR mode
# ====================================================================
if ($Mode -eq 'RADAR') {
    $deep = [int64]0; $thumb = [int64]0; $bin = [int64]0; $orph = [int64]0
    try { $deep = [int64](Get-DeepBytes) } catch { }
    try { $thumb = [int64](Get-ThumbBytes) } catch { }
    try { $bin = [int64](Get-BinBytes) } catch { }
    if ($RadarMode -eq 'FULL') {
        try {
            $list = @(Find-Orphans)
            Save-Orphans $list
            foreach ($o in $list) { $orph += [int64]$o.Bytes }
        } catch { }
    } else {
        $orph = Read-OrphTotal
    }
    [Console]::WriteLine('DEEP=' + (Fmt $deep))
    [Console]::WriteLine('THUMB=' + (Fmt $thumb))
    [Console]::WriteLine('ORPH=' + (Fmt $orph))
    [Console]::WriteLine('BIN=' + (Fmt $bin))
    [Console]::WriteLine('TOTAL=' + (Fmt ($deep + $thumb + $orph + $bin)))
    exit 0
}

# ====================================================================
#  ORPHANS mode (interactive)
# ====================================================================
function Line([string]$t, [string]$c = 'Gray') { Write-Host $t -ForegroundColor $c }

function Ask-YN([string]$q) {
    while ($true) {
        $a = Read-Host ($q + ' [Y/N]')
        if ($a -match '^(?i:y)$') { return $true }
        if ($a -match '^(?i:n)$') { return $false }
    }
}

# "1,3,5-7" -> 1 3 5 6 7. Returns $null when the text is not understood or a number is out of range.
function Parse-Selection([string]$Text, [int]$Count) {
    $out = New-Object System.Collections.ArrayList
    foreach ($part in ($Text -split '[,;\s]+')) {
        if (-not $part) { continue }
        if ($part.Length -gt 7) { return $null }
        if ($part -match '^(\d+)-(\d+)$') {
            $lo = [int]$Matches[1]
            $hi = [int]$Matches[2]
            if (($lo -lt 1) -or ($hi -gt $Count) -or ($lo -gt $hi)) { return $null }
            for ($i = $lo; $i -le $hi; $i++) { if ($out -notcontains $i) { [void]$out.Add($i) } }
        } elseif ($part -match '^\d+$') {
            $n = [int]$part
            if (($n -lt 1) -or ($n -gt $Count)) { return $null }
            if ($out -notcontains $n) { [void]$out.Add($n) }
        } else { return $null }
    }
    if ($out.Count -eq 0) { return $null }
    return ,@($out | Sort-Object)
}

function Show-OrphList($List, [int]$Max) {
    Line ''
    Line ('  ' + '#'.PadRight(4) + 'Size'.PadRight(10) + 'Unused'.PadRight(11) + 'Type'.PadRight(9) + 'Where'.PadRight(24) + 'Folder') 'DarkGray'
    $now = (Get-Date).ToUniversalTime()
    $shown = [math]::Min($List.Count, $Max)
    for ($i = 0; $i -lt $shown; $i++) {
        $o = $List[$i]
        $days = [int]($now - $o.Newest).TotalDays
        $row = '  ' + ([string]($i + 1)).PadRight(4) + (Fmt $o.Bytes).PadRight(10) + ([string]$days + ' days').PadRight(11) + ([string]$o.Kind).PadRight(9) + ([string]$o.Location).PadRight(24) + $o.Name
        $col = 'White'
        if ($o.Kind -eq 'Data') { $col = 'Gray' }
        Line $row $col
    }
    if ($List.Count -gt $shown) { Line ('  ...and ' + ($List.Count - $shown) + ' more smaller folder(s) (listed in the report file).') 'DarkGray' }
}

function Save-OrphReport($List) {
    if ((-not $LogDir) -or (-not (Test-Path -LiteralPath $LogDir))) { return $null }
    $stamp = (Get-Date).ToString('yyyyMMdd_HHmmss', [cultureinfo]::InvariantCulture)
    $f = Join-Path $LogDir ('OrphanedFiles_' + $stamp + '.txt')
    $now = (Get-Date).ToUniversalTime()
    $L = New-Object System.Collections.ArrayList
    [void]$L.Add('ORPHANED FILE SCANNER REPORT - ' + (Get-Date).ToString('yyyy-MM-dd HH:mm:ss', [cultureinfo]::InvariantCulture))
    [void]$L.Add('Folders that probably belong to programs that are no longer installed. They are SUSPECTS, not proof.')
    [void]$L.Add('')
    $tot = [int64]0
    foreach ($o in $List) {
        $tot += [int64]$o.Bytes
        [void]$L.Add((Fmt $o.Bytes) + ' | unused ' + [int](($now - $o.Newest).TotalDays) + ' days | ' + $o.Kind + ' | ' + $o.Path + ' | files: ' + $o.Files)
    }
    [void]$L.Add('')
    [void]$L.Add('Total: ' + (Fmt $tot))
    try { [IO.File]::WriteAllLines($f, [string[]]$L, (New-Object Text.UTF8Encoding $true)); return $f } catch { return $null }
}

function Remove-ToBin([string]$Path) {
    Add-Type -AssemblyName Microsoft.VisualBasic
    [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory($Path, [Microsoft.VisualBasic.FileIO.UIOption]::OnlyErrorDialogs, [Microsoft.VisualBasic.FileIO.RecycleOption]::SendToRecycleBin)
}

function Run-OrphansUi {
    try { $Host.UI.RawUI.WindowTitle = 'Orphaned File Scanner' } catch { }
    Clear-Host
    Line ''
    Line '  ORPHANED FILE SCANNER' 'Yellow'
    Line '  Finds folders that probably belong to programs that are no longer installed.' 'Gray'
    Line '  The list is for your review. Nothing is removed unless you pick it and type DELETE.' 'Gray'
    Line ''
    $list = Read-Orphans
    if ($null -eq $list) {
        Line '  Scanning Program Files, ProgramData and AppData - please wait...' 'Cyan'
        $list = @(Find-Orphans)
        Save-Orphans $list
    }
    $list = @($list)
    Log ('Scanner opened, ' + $list.Count + ' suspect folder(s)')
    $report = $null
    $first = $true
    while ($true) {
        if ($list.Count -eq 0) {
            Line ''
            Line '  No leftover folders were found. Nothing to review.' 'Green'
            break
        }
        if ($first) { $report = Save-OrphReport $list; $first = $false }
        $tot = [int64]0
        foreach ($o in $list) { $tot += [int64]$o.Bytes }
        Show-OrphList $list 50
        Line ''
        Line ('  Total of these folders: ' + (Fmt $tot)) 'White'
        Line '  Program = program files left behind.  Data = settings, caches or SAVES left behind (check before removing).' 'DarkGray'
        if ($report) { Line ('  Report saved: ' + $report) 'DarkGray' }
        Line ''
        Line '  Type the numbers to remove (example: 1,3,5-7)' 'White'
        Line '  O + number opens that folder so you can look inside (example: O2)    R = scan again    Enter or 0 = go back' 'DarkGray'
        $a = (Read-Host '  Your choice').Trim()
        if ((-not $a) -or ($a -eq '0')) { break }
        if ($a -match '^(?i:r)$') {
            Line ''
            Line '  Scanning again - please wait...' 'Cyan'
            $list = @(Find-Orphans)
            Save-Orphans $list
            $first = $true
            continue
        }
        if ($a -match '^(?i:o)\s*(\d+)$') {
            $n = [int]$Matches[1]
            if (($n -ge 1) -and ($n -le [math]::Min($list.Count, 50))) {
                try { Start-Process -FilePath 'explorer.exe' -ArgumentList ('"' + $list[$n - 1].Path + '"') } catch { }
            } else { Line '  That number is not in the list.' 'Yellow' }
            continue
        }
        $sel = Parse-Selection $a ([math]::Min($list.Count, 50))
        if ($null -eq $sel) { Line '  Not understood. Use numbers from the list, like 1,3,5-7.' 'Yellow'; continue }
        $picked = @()
        foreach ($i in $sel) { $picked += $list[[int]$i - 1] }
        Line ''
        Line '  You selected:' 'White'
        $sum = [int64]0
        foreach ($o in $picked) { Line ('    ' + (Fmt $o.Bytes).PadRight(9) + $o.Path) 'Gray'; $sum += [int64]$o.Bytes }
        Line ('  Total: ' + (Fmt $sum)) 'White'
        Line ''
        Line '  Folders are sent to the Recycle Bin, so you can restore them. A folder too big for the Recycle Bin' 'Yellow'
        Line '  is deleted for good by Windows. The space is freed after you empty the Recycle Bin (option 4).' 'Yellow'
        $t = Read-Host '  Type DELETE in capital letters to confirm, or press Enter to cancel'
        if ($t -cne 'DELETE') { Line '  Cancelled. Nothing was removed.' 'Gray'; continue }
        $running = @()
        foreach ($p in @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue)) { if ($p.ExecutablePath) { $running += [string]$p.ExecutablePath } }
        $removed = @()
        foreach ($o in $picked) {
            if (-not (Test-Path -LiteralPath $o.Path -PathType Container)) { Line ('  [SKIP] Already gone: ' + $o.Path) 'Yellow'; $removed += $o; continue }
            $busy = @($running | Where-Object { $_.StartsWith($o.Path + '\', [StringComparison]::OrdinalIgnoreCase) })
            if ($busy.Count -gt 0) { Line ('  [SKIP] A program from this folder is running: ' + $o.Path) 'Yellow'; continue }
            try {
                Remove-ToBin $o.Path
                if (Test-Path -LiteralPath $o.Path) { Line ('  [WARN] Only part of it could be removed: ' + $o.Path) 'Yellow' }
                else { Line ('  [ OK ] Removed: ' + $o.Path) 'Green'; $removed += $o; Log ('Removed to Recycle Bin: ' + $o.Path) }
            } catch {
                Line ('  [FAIL] ' + $o.Path + ' - ' + $_.Exception.Message) 'Red'
                Log ('Failed to remove ' + $o.Path + ' : ' + $_.Exception.Message)
            }
        }
        $keep = @()
        foreach ($o in $list) { $hit = $false; foreach ($r in $removed) { if ($r.Path -eq $o.Path) { $hit = $true } }; if (-not $hit) { $keep += $o } }
        $list = @($keep)
        Save-Orphans $list
        $first = $true
        Line ''
        [void](Read-Host '  Press Enter to continue')
        Clear-Host
        Line ''
        Line '  ORPHANED FILE SCANNER' 'Yellow'
    }
    Line ''
    [void](Read-Host '  Press Enter to close this window')
}

if ($Mode -eq 'ORPHANS') {
    try { Run-OrphansUi } catch { Line ('Unexpected problem: ' + $_.Exception.Message) 'Red'; Log ('Unexpected error: ' + $_.Exception.Message); [void](Read-Host 'Press Enter to close') ; exit 1 }
    exit 0
}
#CL_END
#RN_BEGIN
# ====================================================================
#  FixToolkit progress runner. Started by the :run_long helper in its own window.
#  It runs ONE command, shows a loading bar with elapsed time, and lets the user
#  cancel with the C key (after a Y/N confirmation). The whole process tree is
#  stopped when the user cancels.
#  Input (environment): FT_RUN_CMD or FT_RUN_PSMODE=1 (runs the code in FT_PS),
#    FT_RUN_TITLE, FT_RUN_HINT, FT_RUN_WARN, FT_RUN_NOCANCEL,
#    FT_RUN_OUT (cleaned output text), FT_RUN_RCFILE (exit code), FT_RUN_LOGFILE
#  Result: exit code of the command is saved in FT_RUN_RCFILE (1223 = cancelled).
#  ASCII only on purpose. Progress percent is read from the tool own output.
# ====================================================================
$ErrorActionPreference = 'Continue'
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false } catch { }
try { [Threading.Thread]::CurrentThread.CurrentCulture = [Globalization.CultureInfo]::InvariantCulture } catch { }
$Inv = [Globalization.CultureInfo]::InvariantCulture

$Title = $env:FT_RUN_TITLE
if (-not $Title) { $Title = 'Working' }
$Hint = $env:FT_RUN_HINT
$Warn = $env:FT_RUN_WARN
if (-not $Warn) { $Warn = 'The task is stopped before it finishes. You can run it again later.' }
$CanCancel = ($env:FT_RUN_NOCANCEL -ne '1')
$OutFile = $env:FT_RUN_OUT
$RcFile = $env:FT_RUN_RCFILE
$Cmd = $env:FT_RUN_CMD
if ($env:FT_RUN_PSMODE -eq '1') {
    $Cmd = 'powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "[Console]::OutputEncoding=New-Object System.Text.UTF8Encoding $false; & ([scriptblock]::Create($env:FT_PS))"'
}
$Raw = Join-Path $env:TEMP ('FixToolkit_run_' + [guid]::NewGuid().ToString('N') + '.raw')
$BarW = 40
$Full = [string][char]0x2588
$Empty = [string][char]0x2591
$script:Tick = 0
$script:Pct = -1.0
$Proc = $null
$Sw = [Diagnostics.Stopwatch]::StartNew()

function Log([string]$m) {
    if ($env:FT_RUN_LOGFILE) {
        try { Add-Content -LiteralPath $env:FT_RUN_LOGFILE -Value ('[' + (Get-Date).ToString('yyyy-MM-dd HH:mm:ss', $Inv) + '] RUNNER - ' + $m) -ErrorAction SilentlyContinue } catch { }
    }
}

function Save-Rc([int]$rc) {
    if ($RcFile) { try { [IO.File]::WriteAllText($RcFile, [string]$rc) } catch { } }
}

# Writes one full-width line at a fixed row, so the screen never scrolls or flickers
function Put([int]$row, [string]$text, [string]$color) {
    if (-not $color) { $color = 'Gray' }
    try {
        $w = [Console]::BufferWidth - 1
        if ($w -lt 20) { $w = 20 }
        if ($text.Length -gt $w) { $text = $text.Substring(0, $w) }
        [Console]::SetCursorPosition(0, $row)
        Write-Host ($text.PadRight($w)) -NoNewline -ForegroundColor $color
    } catch { }
}

function Wrap-Words([string]$s, [int]$w) {
    $out = @()
    $cur = ''
    foreach ($word in ($s -split '\s+')) {
        if (-not $word) { continue }
        if (($cur.Length + $word.Length + 1) -gt $w) {
            if ($cur) { $out += $cur }
            $cur = $word
        } elseif ($cur) { $cur = $cur + ' ' + $word }
        else { $cur = $word }
    }
    if ($cur) { $out += $cur }
    return ,$out
}

function Show-Msg([string[]]$lines, [string]$color) {
    for ($r = 0; $r -lt 3; $r++) {
        $t = ''
        if ($r -lt $lines.Count) { $t = $lines[$r] }
        Put (7 + $r) $t $color
    }
}

function Read-Bytes([int]$Max) {
    $fs = $null
    try {
        $fs = New-Object System.IO.FileStream($Raw, [IO.FileMode]::Open, [IO.FileAccess]::Read, ([IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete))
        $len = $fs.Length
        $start = [math]::Max(0, $len - $Max)
        $start = $start - ($start % 2)
        [void]$fs.Seek($start, [IO.SeekOrigin]::Begin)
        $buf = New-Object byte[] ($len - $start)
        $n = $fs.Read($buf, 0, $buf.Length)
        if ($n -lt $buf.Length) {
            $b2 = New-Object byte[] $n
            [Array]::Copy($buf, $b2, $n)
            return ,$b2
        }
        return ,$buf
    } catch { return ,(New-Object byte[] 0) }
    finally { if ($fs) { $fs.Dispose() } }
}

# sfc writes UTF-16, most other tools write the console code page (UTF-8 here)
function Decode([byte[]]$b) {
    if ($b.Length -eq 0) { return '' }
    $lim = [math]::Min($b.Length, 4096)
    $z = 0
    for ($i = 0; $i -lt $lim; $i++) { if ($b[$i] -eq 0) { $z++ } }
    if (($z * 4) -gt $lim) {
        $n = $b.Length - ($b.Length % 2)
        return [Text.Encoding]::Unicode.GetString($b, 0, $n)
    }
    return [Text.Encoding]::UTF8.GetString($b)
}

# Last percent number the tool printed (DISM, SFC, CHKDSK, curl, winget print one). -1 = none yet
function Get-Pct {
    $t = Decode (Read-Bytes 8192)
    if (-not $t) { return -1.0 }
    $m = [regex]::Matches($t, '(\d{1,3}(?:[.,]\d+)?)\s*%')
    for ($i = $m.Count - 1; $i -ge 0; $i--) {
        $s = $m[$i].Groups[1].Value.Replace(',', '.')
        $v = 0.0
        if ([double]::TryParse($s, [Globalization.NumberStyles]::Float, $Inv, [ref]$v)) {
            if (($v -ge 0) -and ($v -le 100)) { return $v }
        }
    }
    return -1.0
}

function Bar-Text([double]$pct, [int]$tick) {
    if ($pct -ge 0) {
        $n = [int][math]::Floor($BarW * $pct / 100.0)
        if ($n -gt $BarW) { $n = $BarW }
        if ($n -lt 0) { $n = 0 }
        return ('[' + ($Full * $n) + ($Empty * ($BarW - $n)) + ']  ' + ([int][math]::Round($pct)).ToString($Inv) + ' %')
    }
    $blk = 8
    $span = $BarW - $blk
    $cyc = 2 * $span
    $t = $tick % $cyc
    if ($t -gt $span) { $t = $cyc - $t }
    return ('[' + ($Empty * $t) + ($Full * $blk) + ($Empty * ($span - $t)) + ']  working...')
}

function Draw {
    Put 3 ('  ' + (Bar-Text $script:Pct $script:Tick)) 'Green'
    Put 4 ('  Elapsed: ' + $Sw.Elapsed.ToString('hh\:mm\:ss', $Inv)) 'White'
    $h = ''
    if ($Hint) { $h = '  Expected: ' + $Hint }
    Put 5 $h 'DarkGray'
}

function Idle-Msg {
    if ($CanCancel) { Show-Msg @('  Press C to cancel this task.') 'DarkGray' }
    else { Show-Msg @('  This task cannot be cancelled. Please wait until it finishes.') 'DarkGray' }
}

function Stop-Task {
    try { $o = & taskkill.exe /f /t /pid $Proc.Id 2>&1 } catch { }
    try { if (-not $Proc.HasExited) { $Proc.Kill() } } catch { }
}

# Y = cancel, N or Esc = keep going. The task keeps running while the question is shown.
function Ask-Cancel {
    $w = [Console]::BufferWidth - 6
    if ($w -lt 20) { $w = 20 }
    $wl = @(Wrap-Words ('Cancel this task? ' + $Warn) $w)
    $lines = @()
    foreach ($l in ($wl | Select-Object -First 2)) { $lines += ('  ' + $l) }
    $lines += '  Press Y to cancel it, or N to keep going.'
    Show-Msg $lines 'Yellow'
    $answer = $false
    while (-not $Proc.HasExited) {
        if ([Console]::KeyAvailable) {
            $k = [Console]::ReadKey($true)
            if ($k.Key -eq [ConsoleKey]::Y) { $answer = $true; break }
            if (($k.Key -eq [ConsoleKey]::N) -or ($k.Key -eq [ConsoleKey]::Escape)) { break }
        }
        $script:Tick++
        Draw
        Start-Sleep -Milliseconds 120
    }
    if (-not $answer) { Idle-Msg }
    return $answer
}

# Removes progress-bar noise: only the last line of each run of percent lines is kept
function Clean-Text([string]$t) {
    if (-not $t) { return '' }
    $t = $t.TrimStart([char]0xFEFF).Replace([string][char]0, '')
    $out = New-Object System.Collections.ArrayList
    $prev = $false
    foreach ($l in ($t -split '[\r\n]+')) {
        $s = $l.TrimEnd()
        if ($s.Trim().Length -eq 0) { continue }
        if ($s -match '^[\s\-\\|/]+$') { continue }
        $isProg = $false
        if ($s -match '[█▒░▓]') { $isProg = $true }
        elseif (($s.Length -lt 90) -and ($s -match '^\s*(\[[=\s\-#]*\d{1,3}([.,]\d+)?\s*%[=\s\-#]*\]|[A-Za-z .:\-]*\d{1,3}([.,]\d+)?\s*%[A-Za-z .]*)\s*$')) { $isProg = $true }
        if ($isProg) {
            if ($prev -and ($out.Count -gt 0)) { $out[$out.Count - 1] = $s } else { [void]$out.Add($s) }
            $prev = $true
        } else {
            [void]$out.Add($s)
            $prev = $false
        }
    }
    if ($out.Count -gt 80) {
        $keep = @($out | Select-Object -Last 80)
        return ((@('...(earlier lines not shown)') + $keep) -join [Environment]::NewLine)
    }
    return ($out -join [Environment]::NewLine)
}

# ------------------------------------------------------------------ main
$rc = 1
$cancelled = $false
try {
    try { $Host.UI.RawUI.WindowTitle = 'MeshalFix - ' + $Title } catch { }
    try { [Console]::CursorVisible = $false } catch { }
    try { Clear-Host } catch { }
    Put 1 ('  ' + $Title) 'Yellow'
    if (-not $Cmd) {
        Put 3 '  Nothing to run.' 'Red'
        Save-Rc 2
        Start-Sleep -Seconds 2
        exit 2
    }
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $env:ComSpec
    $psi.Arguments = '/d /s /c "(' + $Cmd + ') > "' + $Raw + '" 2>&1"'
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardInput = $true
    try {
        $Proc = [Diagnostics.Process]::Start($psi)
        $Proc.StandardInput.Close()
    } catch {
        Put 3 ('  Could not start the task: ' + $_.Exception.Message) 'Red'
        Log ('Could not start: ' + $_.Exception.Message)
        Save-Rc 1
        Start-Sleep -Seconds 3
        exit 1
    }
    Log ('Started: ' + $Title)
    Idle-Msg
    $lastRead = -1000
    while (-not $Proc.HasExited) {
        $ask = $false
        while ([Console]::KeyAvailable) {
            $k = [Console]::ReadKey($true)
            if ($CanCancel -and ($k.Key -eq [ConsoleKey]::C)) { $ask = $true }
        }
        if ($ask) {
            if (Ask-Cancel) {
                Show-Msg @('  Cancelling - stopping the task...') 'Yellow'
                Stop-Task
                $cancelled = $true
                break
            }
        }
        if (($Sw.ElapsedMilliseconds - $lastRead) -ge 700) {
            $lastRead = $Sw.ElapsedMilliseconds
            $v = Get-Pct
            if ($v -ge 0) { $script:Pct = $v }
        }
        $script:Tick++
        Draw
        Start-Sleep -Milliseconds 150
    }
    try { [void]$Proc.WaitForExit(15000) } catch { }
    if ($cancelled) { $rc = 1223 }
    else { try { $rc = [int]$Proc.ExitCode } catch { $rc = 1 } }
    Log ('Finished: ' + $Title + ' - code ' + $rc + ' - ' + $Sw.Elapsed.ToString('hh\:mm\:ss', $Inv))
    if ($OutFile) {
        $txt = ''
        try { if ($env:FT_RUN_RAW -eq '1') { $txt = (Decode (Read-Bytes 4000000)).TrimStart([char]0xFEFF) } else { $txt = Clean-Text (Decode (Read-Bytes 4000000)) } } catch { $txt = '' }
        try { [IO.File]::WriteAllText($OutFile, $txt, (New-Object Text.UTF8Encoding $false)) } catch { }
    }
    Save-Rc $rc
    if ($cancelled) {
        Draw
        Show-Msg @('  Cancelled.') 'Yellow'
    } elseif ($rc -eq 0) {
        Put 3 ('  [' + ($Full * $BarW) + ']  100 %') 'Green'
        Put 4 ('  Elapsed: ' + $Sw.Elapsed.ToString('hh\:mm\:ss', $Inv)) 'White'
        Show-Msg @('  Finished.') 'Green'
    } else {
        Draw
        Show-Msg @('  Finished with exit code ' + $rc + '.') 'Yellow'
    }
    Start-Sleep -Milliseconds 1200
}
finally {
    try { [Console]::CursorVisible = $true } catch { }
    try { if (Test-Path -LiteralPath $Raw) { Remove-Item -LiteralPath $Raw -Force -ErrorAction SilentlyContinue } } catch { }
}
exit 0
#RN_END
