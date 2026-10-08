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
echo    %cC%[%cW%1%cC%]%cX% %cC%●%cX% Cleaning Tools
echo    %cC%[%cW%2%cC%]%cX% %cC%●%cX% System Repair 
echo    %cC%[%cW%3%cC%]%cX% %cC%●%cX% Tron Script 
echo    %cC%[%cW%4%cC%]%cX% %cC%●%cX% Gaming Fixes
echo    %cC%[%cW%5%cC%]%cX% %cC%●%cX% Network Fixes
echo    %cC%[%cW%6%cC%]%cX% %cC%●%cX% Tools
echo    %cC%[%cW%7%cC%]%cX% %cC%●%cX% Restore Default Settings
echo    %cC%[%cW%8%cC%]%cX% %cC%●%cX% System Information
echo    %cC%[%cW%9%cC%]%cX% %cC%●%cX% System Reports
echo    %cC%[%cW%C%cC%]%cX% %cC%●%cX% Create Restore Point
echo    %cC%[%cW%0%cC%]%cX% %cC%●%cX% Exit
echo.
echo   %cD%Logs are saved to: %LOGDIR%%cX%
echo.
set "M="
set /p "M=  %cC%●%cX% Select an option: "

if "%M%"=="1" goto :CLEAN_MENU
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
echo.
echo   Goodbye.
timeout /t 2 /nobreak >nul
endlocal
exit /b 0


rem ==================================================================
rem  1) CLEANING TOOLS
rem ==================================================================
:CLEAN_MENU
call :header "1) CLEANING TOOLS"
echo    %cC%[%cW%1%cC%]%cX% %cC%●%cX% Deep clean (temp, Prefetch, browsers, apps, and more)
echo    %cC%[%cW%2%cC%]%cX% %cC%●%cX% Empty Recycle Bin
echo    %cC%[%cW%3%cC%]%cX% %cC%●%cX% Clear thumbnail cache and icon cache
echo    %cC%[%cW%4%cC%]%cX% %cC%●%cX% Run Disk Cleanup (cleanmgr)
echo    %cC%[%cW%5%cC%]%cX% %cC%●%cX% Optimize drives (TRIM for SSD, defrag for HDD)
echo    %cC%[%cW%A%cC%]%cX% %cC%●%cX% Run ALL cleaning (options 1 to 4)
echo    %cC%[%cW%0%cC%]%cX% %cC%●%cX% Back to main menu
echo.
set "M="
set /p "M=  Select an option: "
set "ACT="
if "%M%"=="1" set "ACT=clean_deep"
if "%M%"=="2" set "ACT=clean_recycle"
if "%M%"=="3" set "ACT=rebuild_icons"
if "%M%"=="4" set "ACT=clean_cleanmgr"
if "%M%"=="5" set "ACT=clean_optimize"
if /i "%M%"=="A" set "ACT=clean_all"
if "%M%"=="0" goto :MAIN_MENU
call :run_clean %ACT%
goto :CLEAN_MENU

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
call :info "Cleans: temp files and logs, Prefetch, Windows Update cache, error reports and dumps, browser caches, app caches, cached RAM."
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
    call :warn "Close browsers and apps completely - also from the system tray - for the best result. Locked files will be skipped."
    call :ask "Continue anyway?"
    if "!CONFIRMED!"=="0" (
        call :info "Cancelled."
        exit /b
    )
)
set "DEEPCHK=1"
call :info "=== Part 1 of 8: Temp files and logs ==="
call :clean_temp
call :info "=== Part 2 of 8: Prefetch ==="
call :clean_prefetch
call :info "=== Part 3 of 8: Windows Update cache ==="
call :clean_wu_cache
call :info "=== Part 4 of 8: Error reports and dumps ==="
call :clean_wer
call :info "=== Part 5 of 8: Browser caches ==="
call :clean_browsers
call :info "=== Part 6 of 8: App caches ==="
call :clean_apps
call :info "=== Part 7 of 8: RAM cache ==="
call :clean_ram
call :info "=== Part 8 of 8: Windows.old ==="
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
:chromium_profile
if not exist "%~1\" exit /b 1
call :clear_folder "%~1\Cache"
call :clear_folder "%~1\Code Cache"
call :clear_folder "%~1\GPUCache"
call :clear_folder "%~1\DawnCache"
call :clear_folder "%~1\DawnGraphiteCache"
call :clear_folder "%~1\DawnWebGPUCache"
call :clear_folder "%~1\Media Cache"
call :clear_folder "%~1\Application Cache"
call :clear_folder "%~1\Service Worker\CacheStorage"
call :clear_folder "%~1\Service Worker\ScriptCache"
exit /b 0

rem --- Clears the caches of every profile of one Chromium browser (%~1 = User Data folder, %~2 = name) ---
:chromium_cache
if not exist "%~1\" exit /b 1
echo       %cD%- %~2%cX%
call :chromium_profile "%~1"
for /d %%P in ("%~1\Default" "%~1\Profile *") do call :chromium_profile "%%~P"
call :clear_folder "%~1\ShaderCache"
call :clear_folder "%~1\GrShaderCache"
call :clear_folder "%~1\GraphiteDawnCache"
call :clear_folder "%~1\extensions_crx_cache"
call :clear_folder "%~1\Crashpad\reports"
exit /b 0

rem --- Clears the caches of every profile of one Firefox-based browser (%~1 = Profiles folder, %~2 = name) ---
:firefox_cache
if not exist "%~1\" exit /b 1
echo       %cD%- %~2%cX%
for /d %%P in ("%~1\*") do (
    call :clear_folder "%%~P\cache2"
    call :clear_folder "%%~P\startupCache"
    call :clear_folder "%%~P\shader-cache"
    call :clear_folder "%%~P\thumbnails"
    call :clear_folder "%%~P\jumpListCache"
    call :clear_folder "%%~P\OfflineCache"
)
exit /b 0

rem --- Part of deep clean: browser caches only (never passwords, cookies, history or logins) ---
:clean_browsers
call :info "Only cache folders are cleaned. You stay signed in - cookies, passwords, history and bookmarks are NOT touched."
if defined DEEPCHK goto :browsers_go
call :step 1 4 "Checking that browsers are closed..."
call :check_running chrome.exe msedge.exe firefox.exe brave.exe opera.exe vivaldi.exe browser.exe chromium.exe librewolf.exe waterfox.exe
if defined RUNNING_LIST (
    call :warn "Still running:!RUNNING_LIST!"
    call :warn "Close them first for the best result. Locked files will be skipped."
    call :confirm "Continue anyway?"
    if "!CONFIRMED!"=="0" (
        call :info "Cancelled."
        exit /b
    )
)
:browsers_go
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

rem --- [4] Disk Cleanup with a safe sagerun preset ---
:clean_cleanmgr
set "CM_VC=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
if defined ALLMODE (
    call :info "Run ALL mode: the safe Disk Cleanup preset is used (no window to choose options)."
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
Dism.exe /Online /Cleanup-Image /StartComponentCleanup
call :log "DISM StartComponentCleanup finished"
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

rem --- [5] Optimize drives: TRIM on SSD, defrag on HDD (not part of Run ALL) ---
:clean_optimize
call :info "Windows chooses the right method for each drive: TRIM for SSD (fast), defrag for HDD (can take a long time)."
call :ask "Optimize all drives now? You can keep using the PC, but it may feel slower on an HDD meanwhile."
if "%CONFIRMED%"=="0" (
    call :info "Cancelled."
    exit /b
)
call :step 1 1 "Optimizing drives - wait until it finishes..."
defrag.exe /C /O /U
call :log "Drive optimization finished"
call :ok "Drive optimization finished."
exit /b

rem --- [A] Run all safe cleaning (Windows.old is NOT included) ---
:clean_all
call :confirm "Runs ALL safe cleaning: deep clean (temp, Prefetch, update cache, error reports, browsers, apps), Recycle Bin, thumbnails and Disk Cleanup. Windows.old is NOT touched."
if "%CONFIRMED%"=="0" (
    call :info "Cancelled."
    exit /b
)
set "ALLMODE=1"
call :info "=== Task 1 of 4: Deep clean ==="
call :clean_deep
call :info "=== Task 2 of 4: Recycle Bin ==="
call :clean_recycle
call :info "=== Task 3 of 4: Thumbnail and icon cache ==="
call :rebuild_icons
call :info "=== Task 4 of 4: Disk Cleanup ==="
call :clean_cleanmgr
set "ALLMODE="
call :ok "All safe cleaning tasks finished."
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
echo    %cC%[%cW%1%cC%]%cX% %cC%●%cX% Core repair       (DISM / SFC / CHKDSK / WMI)
echo    %cC%[%cW%2%cC%]%cX% %cC%●%cX% Windows Update fixes
echo    %cC%[%cW%3%cC%]%cX% %cC%●%cX% Common Windows fixes (Search, Spooler, Store apps, Start menu, Firewall...)
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
echo    %cC%[%cW%1%cC%]%cX% %cC%●%cX% DISM CheckHealth   (quick check)
echo    %cC%[%cW%2%cC%]%cX% %cC%●%cX% DISM ScanHealth    (deep scan)
echo    %cC%[%cW%3%cC%]%cX% %cC%●%cX% DISM RestoreHealth (repair, needs internet)
echo    %cC%[%cW%4%cC%]%cX% %cC%●%cX% SFC /scannow       (repair system files)
echo    %cC%[%cW%5%cC%]%cX% %cC%●%cX% FULL repair sequence (1 to 4 in the correct order)
echo    %cC%[%cW%6%cC%]%cX% %cC%●%cX% CHKDSK             (check a drive for errors)
echo    %cC%[%cW%7%cC%]%cX% %cC%●%cX% WMI Repository Check (read-only report)
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
dism.exe /Online /Cleanup-Image /CheckHealth
call :log "DISM CheckHealth exit code %errorlevel%"
call :step 2 2 "Reading the health state..."
call :dism_state
exit /b

rem --- DISM ScanHealth ---
:dism_scan
call :info "ScanHealth can take 5 to 20 minutes. Do not close this window."
call :step 1 2 "Running DISM ScanHealth..."
dism.exe /Online /Cleanup-Image /ScanHealth
call :log "DISM ScanHealth exit code %errorlevel%"
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
dism.exe /Online /Cleanup-Image /RestoreHealth
set "RC=%errorlevel%"
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
call :info "SFC takes 10 to 30 minutes. Do not close this window."
call :step 1 3 "Recording the start time..."
set "SFC_START="
set "FT_PS=(Get-Date).ToString('yyyy-MM-dd HH:mm:ss', [cultureinfo]::InvariantCulture)"
call :psx
for /f "usebackq delims=" %%T in ("%FT_OUT%") do set "SFC_START=%%T"
call :step 2 3 "Running SFC - System File Checker..."
sfc /scannow
call :log "SFC finished, exit code %errorlevel%"
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
call :info "=== STEP 2 of 4: DISM ScanHealth ==="
call :dism_scan
call :info "=== STEP 3 of 4: DISM RestoreHealth ==="
call :dism_restore
call :info "=== STEP 4 of 4: SFC /scannow ==="
call :sfc_run
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
    chkdsk !DRV!: /scan
    set "CR=!errorlevel!"
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
echo Y| chkdsk %DRV%: /f /r
call :log "CHKDSK repair started on !DRV!"
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
echo    %cC%[%cW%1%cC%]%cX% %cC%●%cX% Run Tron Script in a separate window
echo    %cC%[%cW%2%cC%]%cX% %cC%●%cX% Remove the Defender exclusion for the Tools folder (use after Tron finishes)
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
echo    %cC%[%cW%1%cC%]%cX% %cC%●%cX% Crashes or stutter: clear GPU shader caches
echo    %cC%[%cW%2%cC%]%cX% %cC%●%cX% Launcher problems: clear launcher caches
echo    %cC%[%cW%3%cC%]%cX% %cC%●%cX% Reset Microsoft Store cache (wsreset)
echo    %cC%[%cW%4%cC%]%cX% %cC%●%cX% Repair Xbox app and Gaming Services
echo    %cC%[%cW%5%cC%]%cX% %cC%●%cX% Check DirectX and Visual C++ runtimes
echo    %cC%[%cW%6%cC%]%cX% %cC%●%cX% Game will not launch: restart game related services
echo    %cC%[%cW%7%cC%]%cX% %cC%●%cX% Fix game audio problems
echo    %cC%[%cW%8%cC%]%cX% %cC%●%cX% Rebuild font cache (missing or garbled text)
echo    %cC%[%cW%9%cC%]%cX% %cC%●%cX% Graphics driver clean install (DDU + NVCleanstall)
echo    %cC%[%cW%10%cC%]%cX% %cC%●%cX% Game Doctor (evidence-based diagnosis and repair for one game)
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
if "%M%"=="6" set "ACT=game_services"
if "%M%"=="7" set "ACT=fix_audio_tool"
if "%M%"=="8" set "ACT=fix_fontcache"
if "%M%"=="9" set "ACT=game_gpu_clean"
if "%M%"=="10" set "ACT=game_doctor"
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

rem --- Xbox app and Gaming Services (re-register packages) ---
:game_xbox
call :info "Re-registers the Xbox app, Gaming Services and Xbox overlays with Windows."
call :info "It does not delete anything. It can take a few minutes."
call :confirm "Repair the Xbox app and Gaming Services now?"
if "%CONFIRMED%"=="0" (
    call :info "Cancelled."
    exit /b
)
set "PKG_VERBOSE=1"
set "PKGS='Microsoft.GamingServices','Microsoft.GamingApp','Microsoft.XboxIdentityProvider','Microsoft.XboxGamingOverlay','Microsoft.XboxGameOverlay','Microsoft.Xbox.TCUI','Microsoft.XboxSpeechToTextOverlay'"
call :step 1 1 "Re-registering Xbox and Gaming Services packages..."
call :reregister_pkgs
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

rem --- Game will not launch: checklist + restart Xbox related services ---
:game_services
echo   %cC%Quick checklist for a game that will not start:%cX%
echo     1. Restart the PC once and try again.
echo     2. Update your graphics driver from the NVIDIA, AMD or Intel website.
echo     3. Verify the game files inside its launcher (Steam, Epic, Battle.net).
echo     4. Install missing runtimes - use option 5 of this menu.
echo     5. Clear shader and launcher caches - options 1 and 2 of this menu.
echo     6. Run Windows Update and the System Repair menu if crashes continue.
echo.
call :ask "Now restart the running Xbox and Gaming services (safe - they restart by themselves)?"
if "%CONFIRMED%"=="0" (
    call :info "Cancelled."
    exit /b
)
for %%S in (XblAuthManager XblGameSave XboxGipSvc XboxNetApiSvc GamingServices GamingServicesNet) do call :restart_service %%S
call :ok "Service check finished."
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
call :info "Fixes graphics driver problems: DDU removes the old driver completely, then NVCleanstall installs a clean NVIDIA driver."
call :info "Both are third-party tools (Wagnard and TechPowerUp). NVCleanstall works with NVIDIA cards only."
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
call :confirm "STEP 1 of 2 - Run DDU now? Answer N to skip this step, for example if DDU was already done."
if "%CONFIRMED%"=="1" (
    call :gpu_step_ddu
    if errorlevel 1 exit /b
)
call :confirm "STEP 2 of 2 - Run NVCleanstall now?"
if "%CONFIRMED%"=="1" (
    call :gpu_step_nvci
    if errorlevel 1 exit /b
)
echo.
call :ok "All steps are finished. The graphics driver was cleaned and reinstalled. Restarting the PC is recommended."
exit /b

rem --- Step 1: DDU (waits until the user closes it) ---
:gpu_step_ddu
call :find_ddu
if not defined DDU_EXE call :get_ddu
if not defined DDU_EXE (
    call :err "DDU is not available, so step 1 was stopped."
    exit /b 1
)
echo.
call :info "Opening DDU. Clean the driver, then CLOSE DDU to continue to step 2."
start "" /wait "!DDU_EXE!"
call :ok "DDU was closed."
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
echo.
call :info "Opening NVCleanstall. Pick and install your driver, then CLOSE NVCleanstall to finish."
start "" /wait "!NVCI_EXE!"
call :ok "NVCleanstall was closed."
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
call :info "Game Doctor checks ONE game with real evidence: files, config, dependencies, a real launch test and crash proof."
call :info "If nothing is wrong it says GAME HEALTHY and changes nothing. Every repair asks first and makes a backup."
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
echo    %cC%[%cW%1%cC%]%cX% %cC%●%cX% Flush DNS cache
echo    %cC%[%cW%2%cC%]%cX% %cC%●%cX% Release and renew IP address
echo    %cC%[%cW%3%cC%]%cX% %cC%●%cX% Reset Winsock and TCP/IP stack (restart needed)
echo    %cC%[%cW%4%cC%]%cX% %cC%●%cX% Reset network adapters
echo    %cC%[%cW%5%cC%]%cX% %cC%●%cX% Ping test (8.8.8.8 and 1.1.1.1)
echo    %cC%[%cW%6%cC%]%cX% %cC%●%cX% Show current IP, DNS and gateway
echo    %cC%[%cW%7%cC%]%cX% %cC%●%cX% Set DNS: Google or Cloudflare
echo    %cC%[%cW%8%cC%]%cX% %cC%●%cX% Set DNS back to automatic
echo    %cC%[%cW%9%cC%]%cX% %cC%●%cX% FIX MY INTERNET - runs the safe steps in order
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
echo    %cC%[%cW%1%cC%]%cX% %cC%●%cX% Repair Windows Update components (full reset)
echo    %cC%[%cW%2%cC%]%cX% %cC%●%cX% Delete the old backup folders made by option 1
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
echo    %cC%[%cW%1%cC%]%cX% %cC%●%cX% Rebuild icon cache and thumbnail cache
echo    %cC%[%cW%2%cC%]%cX% %cC%●%cX% Fix Windows Search (reset and rebuild the index)
echo    %cC%[%cW%3%cC%]%cX% %cC%●%cX% Fix Print Spooler (clear the print queue)
echo    %cC%[%cW%4%cC%]%cX% %cC%●%cX% Re-register ALL Microsoft Store apps (slow)
echo    %cC%[%cW%5%cC%]%cX% %cC%●%cX% Restart Bluetooth and Windows Audio services
echo    %cC%[%cW%6%cC%]%cX% %cC%●%cX% Re-register Start Menu and taskbar
echo    %cC%[%cW%7%cC%]%cX% %cC%●%cX% Restart Explorer
echo    %cC%[%cW%8%cC%]%cX% %cC%●%cX% Update Windows Defender definitions
echo    %cC%[%cW%9%cC%]%cX% %cC%●%cX% Reset Windows Firewall to default
echo    %cC%[%cW%10%cC%]%cX% %cC%●%cX% Repair app folder permissions
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
    echo    %cC%[%cW%!id:~-2!%cC%]%cX% %cC%●%cX% !CAT_%%n_TITLE!
)
echo    %cC%[%cW%00%cC%]%cX% %cC%●%cX% Back to main menu
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
    echo    %cC%[%cW%!id:~-2!%cC%]%cX% %cC%●%cX% !TL_%CUR_CAT%_%%n_NAME!
)
echo    %cC%[%cW%00%cC%]%cX% %cC%●%cX% Back to the tools menu
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

rem --- Pads a typed number to two digits: 1 becomes 01 (variable name in %~1) ---
:norm2
set "N2=0!%~1!"
set "%~1=!N2:~-2!"
exit /b

rem --- The tool catalog. A tool may appear in more than one category. ---
:tools_register
set "CAT_N=0"
call :cat_add BENCH "Benchmark Tools"
call :cat_add STORAGE "Storage Tools"
call :cat_add UNINST "Uninstaller Tools"
call :cat_add PERF "Performance Tools"
call :cat_add WINTOOLS "Windows Tools"

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
call :tool_add UNINST "Geek Uninstaller" "GeekUninstaller" "geek.exe" "https://geekuninstaller.com/download" "URL=https://geekuninstaller.com/geek.zip"
call :tool_add UNINST "Revo Uninstaller (portable)" "RevoUninstaller" "RevoUPort.exe Revo*.exe" "https://www.revouninstaller.com/revo-uninstaller-free-download/" "URL=https://download.revouninstaller.com/download/RevoUninstaller_Portable.zip"
call :tool_add UNINST "Bulk Crap Uninstaller" "BCUninstaller" "BCUninstaller.exe" "https://www.bcuninstaller.com/" "GH=Klocman/Bulk-Crap-Uninstaller|BCUninstaller_.*_portable\.zip$"
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
call :tool_add WINTOOLS "Device Manager" "-" "-" "-" "BI=devmgmt.msc"
call :tool_add WINTOOLS "Disk Management" "-" "-" "-" "BI=diskmgmt.msc"
call :tool_add WINTOOLS "Services" "-" "-" "-" "BI=services.msc"
call :tool_add WINTOOLS "Task Scheduler" "-" "-" "-" "BI=taskschd.msc"
call :tool_add WINTOOLS "Event Viewer" "-" "-" "-" "BI=eventvwr.msc"
call :tool_add WINTOOLS "Computer Management" "-" "-" "-" "BI=compmgmt.msc"
call :tool_add WINTOOLS "Resource Monitor" "-" "-" "-" "BI=resmon.exe"
call :tool_add WINTOOLS "System Information" "-" "-" "-" "BI=msinfo32.exe"
call :tool_add WINTOOLS "Registry Editor" "-" "-" "-" "BI=regedit.exe"
call :tool_add WINTOOLS "Group Policy Editor (not on Windows Home)" "-" "-" "-" "BI=gpedit.msc"
call :tool_add WINTOOLS "Windows Features (turn features on or off)" "-" "-" "-" "BI=optionalfeatures.exe"
set "TOOLS_READY=1"
exit /b

rem --- Registers a category: KEY and Title ---
:cat_add
set /a CAT_N+=1
set "CAT_!CAT_N!_KEY=%~1"
set "CAT_!CAT_N!_TITLE=%~2"
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
call :info "Starting !T_NAME! - close it to come back to this menu."
call :log "Tool started: !T_EXE_PATH!"
start "" /wait /d "!T_EXE_DIR!" "!T_EXE_PATH!"
call :log "Tool closed: !T_NAME!"
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
echo    %cC%[%cW%01%cC%]%cX% %cC%●%cX% Restore GPU Settings
echo    %cC%[%cW%02%cC%]%cX% %cC%●%cX% Restore Windows Services
echo    %cC%[%cW%03%cC%]%cX% %cC%●%cX% Restore Network Settings
echo    %cC%[%cW%04%cC%]%cX% %cC%●%cX% Restore Firewall Settings
echo    %cC%[%cW%05%cC%]%cX% %cC%●%cX% Restore Windows Update
echo    %cC%[%cW%06%cC%]%cX% %cC%●%cX% Restore Power Settings
echo    %cC%[%cW%07%cC%]%cX% %cC%●%cX% Restore Windows Security
echo    %cC%[%cW%08%cC%]%cX% %cC%●%cX% Restore Windows Explorer
echo    %cC%[%cW%09%cC%]%cX% %cC%●%cX% Restore File Associations
echo    %cC%[%cW%10%cC%]%cX% %cC%●%cX% Restore Startup Configuration
echo    %cC%[%cW%11%cC%]%cX% %cC%●%cX% Back
echo.
set "M="
set /p "M=  Select an option [1-11]: "
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
if "!M!"=="9" (set "RS=FILEASSOC" & set "RT=Restore File Associations")
if "!M!"=="10" (set "RS=STARTUP" & set "RT=Restore Startup Configuration")
if "!M!"=="11" goto :MAIN_MENU
if defined RS call :rst_run "!RS!" "!RT!"
goto :RESTORE_MENU

rem --- GPU vendor menu ---
:RST_GPU
call :header "7) RESTORE DEFAULT SETTINGS - GPU"
echo    %cC%[%cW%01%cC%]%cX% %cC%●%cX% NVIDIA
echo    %cC%[%cW%02%cC%]%cX% %cC%●%cX% AMD
echo    %cC%[%cW%03%cC%]%cX% %cC%●%cX% Intel
echo    %cC%[%cW%04%cC%]%cX% %cC%●%cX% Back
echo.
set "M="
set /p "M=  Select an option [1-4]: "
if defined M if "!M:~0,1!"=="0" if not "!M!"=="0" set "M=!M:~1!"
set "RS="
if "!M!"=="1" set "RS=GPU_NVIDIA"
if "!M!"=="2" set "RS=GPU_AMD"
if "!M!"=="3" set "RS=GPU_INTEL"
if "!M!"=="4" goto :RESTORE_MENU
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
call :header "8) SYSTEM INFORMATION"
set "REPORT=%DESKTOP%\SystemInfo_%TODAY%.txt"
call :info "Collecting information - this takes 10 to 20 seconds..."
call :sysinfo_body > "%REPORT%" 2>&1
type "%REPORT%"
echo.
call :ok "Report saved to: %REPORT%"
call :pause
goto :MAIN_MENU

:sysinfo_body
echo ==============================================================
echo  SYSTEM INFORMATION REPORT - %TODAY% %time:~0,8%
echo ==============================================================
echo.
echo [Windows]
set "FT_PS=$o=Get-CimInstance Win32_OperatingSystem; ('OS      : ' + $o.Caption + ' (build ' + $o.BuildNumber + ', ' + $o.OSArchitecture + ')'); $u=(Get-Date)-$o.LastBootUpTime; ('Uptime  : {0} days {1} h {2} min' -f $u.Days,$u.Hours,$u.Minutes)"
set "FT_SHOW=1"
call :psx
echo.
echo [CPU]
set "FT_PS=Get-CimInstance Win32_Processor | ForEach-Object { 'CPU     : ' + $_.Name.Trim() + ' (' + $_.NumberOfCores + ' cores, ' + $_.NumberOfLogicalProcessors + ' threads)' }"
set "FT_SHOW=1"
call :psx
echo.
echo [Memory]
set "FT_PS=$c=Get-CimInstance Win32_OperatingSystem; $t=[math]::Round($c.TotalVisibleMemorySize/1MB,1); $f=[math]::Round($c.FreePhysicalMemory/1MB,1); ('RAM     : {0} GB total, {1} GB free' -f $t,$f)"
set "FT_SHOW=1"
call :psx
echo.
echo [Graphics]
set "FT_PS=Get-CimInstance Win32_VideoController | ForEach-Object { 'GPU     : ' + $_.Name + ' (driver ' + $_.DriverVersion + ')' }"
set "FT_SHOW=1"
call :psx
echo.
echo [Disk space]
set "FT_PS=Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' | ForEach-Object { ('Drive {0}  {1} GB free of {2} GB ({3}%% used)' -f $_.DeviceID,[math]::Round($_.FreeSpace/1GB,1),[math]::Round($_.Size/1GB,1),[math]::Round(100-100*$_.FreeSpace/$_.Size)) }"
set "FT_SHOW=1"
call :psx
echo.
echo [Disk health - SMART status]
set "FT_PS=Get-PhysicalDisk | ForEach-Object { ('Disk {0} : {1}, health {2}, status {3}' -f $_.FriendlyName,$_.MediaType,$_.HealthStatus,$_.OperationalStatus) }"
set "FT_SHOW=1"
call :psx
echo.
echo ==============================================================
exit /b


rem ==================================================================
rem  9) SYSTEM REPORTS
rem ==================================================================
:Diagnostics
call :header "9) SYSTEM REPORTS"
echo    %cC%[%cW%1%cC%]%cX% %cC%●%cX% System Diagnostic Report (perfmon /report)  [~60 sec]
echo    %cC%[%cW%2%cC%]%cX% %cC%●%cX% Reliability Monitor (crash/error history)
echo    %cC%[%cW%3%cC%]%cX% %cC%●%cX% Event Viewer (full log browser)
echo    %cC%[%cW%4%cC%]%cX% %cC%●%cX% Recent Critical/Error events (last 24h, quick view)
echo    %cC%[%cW%5%cC%]%cX% %cC%●%cX% Resource Monitor (CPU/RAM/Disk/Network live)
echo    %cC%[%cW%6%cC%]%cX% %cC%●%cX% Task Manager
echo    %cC%[%cW%7%cC%]%cX% %cC%●%cX% Performance Monitor (live counters)
echo    %cC%[%cW%0%cC%]%cX% %cC%●%cX% Back to main menu
echo.
set "M="
set /p "M=  Select an option: "
if "%M%"=="0" goto :MAIN_MENU
if "%M%"=="1" goto :DIAG_REPORT
if "%M%"=="2" goto :DIAG_RELIABILITY
if "%M%"=="3" goto :DIAG_EVENT_VIEWER
if "%M%"=="4" goto :DIAG_RECENT_EVENTS
if "%M%"=="5" goto :DIAG_RESOURCE_MONITOR
if "%M%"=="6" goto :DIAG_TASK_MANAGER
if "%M%"=="7" goto :DIAG_PERFMON
goto :Diagnostics

:DIAG_REPORT
call :header "SYSTEM DIAGNOSTIC REPORT"
call :info "Generating the report in Performance Monitor - this takes about 60 seconds..."
start "" perfmon /report
call :pause
goto :Diagnostics

:DIAG_RELIABILITY
call :header "RELIABILITY MONITOR"
start "" perfmon /rel
call :pause
goto :Diagnostics

:DIAG_EVENT_VIEWER
call :header "EVENT VIEWER"
start "" eventvwr.msc
call :pause
goto :Diagnostics

:DIAG_RECENT_EVENTS
call :header "RECENT CRITICAL/ERROR EVENTS"
call :info "Reading System and Application logs from the last 24 hours..."
set "FT_PS=$start=(Get-Date).AddHours(-24); $events=Get-WinEvent -FilterHashtable @{LogName='System','Application'; StartTime=$start; Level=1,2,3} -ErrorAction SilentlyContinue; if ($events) { $events | Select-Object -First 100 TimeCreated,LogName,LevelDisplayName,ProviderName,Id,Message | Format-List } else { 'No critical or error events found in the last 24 hours.' }"
set "FT_SHOW=1"
call :psx
call :pause
goto :Diagnostics

:DIAG_RESOURCE_MONITOR
call :header "RESOURCE MONITOR"
start "" resmon.exe
call :pause
goto :Diagnostics

:DIAG_TASK_MANAGER
call :header "TASK MANAGER"
start "" taskmgr.exe
call :pause
goto :Diagnostics

:DIAG_PERFMON
call :header "PERFORMANCE MONITOR"
start "" perfmon.exe
call :pause
goto :Diagnostics









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

rem --- Downloads a file. %~1 = NAME of a variable that holds the URL, %~2 = destination file.
rem --- Uses curl.exe (built into Windows 10/11) and falls back to PowerShell.
:download
set "DL_URL=!%~1!"
del /f /q "%~2" >nul 2>&1
where curl.exe >nul 2>&1
if not errorlevel 1 (
    if defined DL_REF (
        curl.exe -L --fail --retry 3 --connect-timeout 20 -A "Mozilla/5.0" -e "!DL_REF!" -# -o "%~2" "!DL_URL!"
    ) else (
        curl.exe -L --fail --retry 3 --connect-timeout 20 -A "Mozilla/5.0" -# -o "%~2" "!DL_URL!"
    )
    if not errorlevel 1 exit /b 0
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
#  Game Doctor engine. Started only by Gaming Fixes, option 10.
#  Evidence-based game diagnostics and repair. It is NOT an optimizer.
#  Rule 1: no evidence = no problem. Nothing is reported without proof.
#  Rule 2: nothing is changed without asking, and a backup comes first.
#  Rule 3: DRM, anti-cheat and launchers are never bypassed.
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
          [string]$Recommended = '', [string]$RepairId = '', $RepairData = $null)
    $status = 'Informational'
    if ($Confidence -eq 'CONFIRMED') { $status = 'Confirmed' }
    elseif (($Confidence -eq 'HIGH') -or ($Confidence -eq 'MEDIUM')) { $status = 'Likely' }
    elseif ($Confidence -eq 'LOW') { $status = 'Possible' }
    [void]$script:Findings.Add([pscustomobject]@{
        Category = $Category; Title = $Title; Evidence = @($Evidence); Confidence = $Confidence
        Status = $status; Recommended = $Recommended; RepairId = $RepairId; RepairData = $RepairData })
    Log ('Finding [' + $Confidence + '] ' + $Category + ' - ' + $Title)
}

function Is-Issue($f) { return (@('CONFIRMED', 'HIGH', 'MEDIUM') -contains $f.Confidence) }

function Issues { return @($script:Findings | Where-Object { Is-Issue $_ }) }

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
        Add-Finding 'Game Files' 'Game executable missing' @('Expected executable does not exist: ' + $g.ExpectedExe, 'Expected path comes from the launcher manifest.') 'CONFIRMED' $rec $rid $g.AppId
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
                Add-Finding 'Game Files' 'Game executable is empty' @('The executable has a size of 0 bytes: ' + $g.Exe) 'CONFIRMED' $rec $rid $g.AppId; $any = $true
            } elseif (($n -eq 2) -and (($buf[0] -ne 0x4D) -or ($buf[1] -ne 0x5A))) {
                Add-Finding 'Game Files' 'Game executable is not a valid program file' @('The file does not start with a valid executable header: ' + $g.Exe) 'CONFIRMED' $rec $rid $g.AppId; $any = $true
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
            Add-Finding 'Game Files' 'Known required game file missing' @($miss | ForEach-Object { 'Missing: ' + $_ }) 'CONFIRMED' $rec $rid $g.AppId; $any = $true
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
        if ($unreadHard) { $cf = 'HIGH'; $rc = $rec + ' Read errors can also point to a failing drive.' }
        Add-Finding 'Game Files' 'Game files that cannot be read' $ev $cf $rc $rid $g.AppId; $any = $true
    }
    # launcher-provided integrity information (Steam)
    if ($g.Acf) {
        try {
            $d = Parse-Acf $g.Acf
            if ($d.ContainsKey('StateFlags')) {
                $fl = [int]$d['StateFlags']
                if (($fl -band 4) -eq 0) {
                    Add-Finding 'Game Files' 'Steam reports the game is not fully installed' @('Steam StateFlags = ' + $fl + ' (the "fully installed" bit is not set).', 'Source: ' + $g.Acf) 'MEDIUM' 'Let Steam finish installing / updating, or verify the files.' $rid $g.AppId; $any = $true
                } elseif (($fl -band 2) -ne 0) {
                    Add-Finding 'Game Files' 'Steam reports a pending update' @('Steam StateFlags = ' + $fl + ' (update required bit is set).') 'INFORMATIONAL' 'Let Steam finish the update.'
                }
            }
        } catch { }
    }
    if ($any) { $script:Sec['Game Files'] = '[!] Problem detected - see Detected Issues' }
    else { $script:Sec['Game Files'] = $TICK + ' No obvious problems detected (' + $all.Count + ' files examined' + $limitTxt + ')' }
    $script:Sec['Integrity'] = 'Not independently verified'
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
function Test-ConfigFile([IO.FileInfo]$f) {
    $ext = $f.Extension.ToLower()
    if ($f.Length -gt 8MB) { return $null }
    $bytes = [IO.File]::ReadAllBytes($f.FullName)
    if ($ext -eq '.json') {
        if ($bytes.Length -eq 0) { return @{ Reason = 'JSON file is empty'; Confidence = 'MEDIUM' } }
        $txt = [Text.Encoding]::UTF8.GetString($bytes).TrimStart([char]0xFEFF)
        try { [void]($txt | ConvertFrom-Json -ErrorAction Stop) } catch { return @{ Reason = 'invalid JSON data'; Confidence = 'MEDIUM' } }
        return $null
    }
    if ($ext -eq '.xml') {
        if ($bytes.Length -eq 0) { return @{ Reason = 'XML file is empty'; Confidence = 'MEDIUM' } }
        try { $x = New-Object System.Xml.XmlDocument; $x.XmlResolver = $null; $x.Load($f.FullName) } catch { return @{ Reason = 'invalid XML data'; Confidence = 'HIGH' } }
        return $null
    }
    # ini / cfg / conf
    if ($bytes.Length -eq 0) { return $null }
    $bom16 = ($bytes.Length -ge 2) -and ((($bytes[0] -eq 0xFF) -and ($bytes[1] -eq 0xFE)) -or (($bytes[0] -eq 0xFE) -and ($bytes[1] -eq 0xFF)))
    $nz = 0
    foreach ($b in $bytes) { if ($b -ne 0) { $nz++; break } }
    if ($nz -eq 0) { return @{ Reason = 'file is filled with zero bytes'; Confidence = 'HIGH' } }
    if (-not $bom16) {
        foreach ($b in $bytes) { if ($b -eq 0) { return @{ Reason = 'text configuration contains binary NUL bytes'; Confidence = 'MEDIUM' } } }
    }
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
            if ($m.Kind -eq 'uri') { Start-Process -FilePath $m.Uri -ErrorAction Stop }
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

function Build-LaunchFindings {
    Clear-Findings 'Launch'
    Clear-Findings 'Mods'
    $g = $script:G
    $att = @($script:Attempts)
    if ($att.Count -eq 0) { return }
    $ok = @($att | Where-Object { ($_.State -eq 'RUNNING') -or ($_.State -eq 'RUNNING_NO_WINDOW') -or ($_.State -eq 'EXITED_NORMALLY') })
    $bad = @($att | Where-Object { $ok -notcontains $_ })
    if (($ok.Count -gt 0) -and ($bad.Count -gt 0)) {
        Add-Finding 'Launch' 'Inconsistent launch behavior' @($att | ForEach-Object { 'Attempt ' + $_.Attempt + ': ' + $_.State }) 'MEDIUM' 'No automatic repair is recommended. Check the crash evidence below, if any.'
    } elseif ($bad.Count -gt 0) {
        $l = $bad[$bad.Count - 1]
        if ($l.State -eq 'CRASHED') {
            $ev = @()
            foreach ($e in $l.Events) { $ev += ('Windows Application Error: ' + $e.App + ' | exception ' + $e.Code + ' | faulting module ' + $e.Module) }
            foreach ($c in @($l.ExitCodes | Where-Object { $_ -ge 3221225472 })) { $ev += ('Process exit code is an exception status: 0x{0:X8}' -f $c) }
            foreach ($f in $l.Files) { $ev += ('Crash file created during the test: ' + $f) }
            Add-Finding 'Launch' 'Confirmed launch crash' $ev 'CONFIRMED' 'Check the evidence above. No game-file repair is recommended unless a file problem is also detected.'
        } elseif ($l.State -eq 'BLOCKED_BY_LAUNCHER') {
            Add-Finding 'Launch' 'Launch blocked by the launcher' (@('Launch request was sent, but no game process was created.') + @($l.LauncherErrors)) 'MEDIUM' 'Resolve the message shown by the launcher, then run the test again.'
        } elseif ($l.State -eq 'LAUNCH_FAILED') {
            Add-Finding 'Launch' 'Windows could not start the game' @($l.Notes) 'CONFIRMED' 'Resolve the Windows error above.'
        }
        # EXITED_WITH_ERROR / TIMEOUT / UNKNOWN: no evidence of a cause - reported as UNKNOWN, never invented
    }
    # mod correlation
    $modNames = @($g.Mods | ForEach-Object { (Split-Path $_ -Leaf).ToLower() })
    foreach ($a in $att) {
        foreach ($e in $a.Events) {
            if ($modNames -contains $e.Module.ToLower()) {
                Add-Finding 'Mods' 'Possible mod-related crash' @('Crash occurred inside detected third-party module: ' + $e.Module) 'MEDIUM' 'Test without that file. Game Doctor never removes mods automatically.'
            }
        }
    }
}

function Check-CrashHistory {
    $g = $script:G
    Clear-Findings 'CrashHistory'
    $names = @()
    if ($g.Exe) { $names += (Split-Path $g.Exe -Leaf).ToLower() }
    foreach ($a in $script:Attempts) { foreach ($n in $a.ExeNames) { if ($names -notcontains $n) { $names += $n } } }
    $ev = @(Get-CrashEvents $names (Get-Date).AddDays(-7) $g.Root)
    $script:CrashInfo = $ev
    $launchCrash = @($script:Attempts | Where-Object { $_.State -eq 'CRASHED' })
    if ($launchCrash.Count -gt 0) { $script:Sec['Crash Evidence'] = '[!] CRASH DETECTED during the launch test' }
    elseif ($ev.Count -gt 0) {
        $codes = (($ev | Group-Object -Property Code | Sort-Object Count -Descending | Select-Object -First 3 | ForEach-Object { $_.Name + ' x' + $_.Count }) -join ', ')
        $script:Sec['Crash Evidence'] = 'None during the launch test. Informational: ' + $ev.Count + ' Windows Application Error event(s) for this game in the last 7 days (' + $codes + ')'
        $modNames = @($g.Mods | ForEach-Object { (Split-Path $_ -Leaf).ToLower() })
        foreach ($e in $ev) {
            if ($modNames -contains $e.Module.ToLower()) {
                Add-Finding 'Mods' 'Possible mod-related crash (history)' @('Crash on ' + $e.Time + ' occurred inside detected third-party module: ' + $e.Module) 'MEDIUM' 'Test without that file. Game Doctor never removes mods automatically.'
                break
            }
        }
    } else { $script:Sec['Crash Evidence'] = $TICK + ' None detected' }
}

# ------------------------------------------------------------- diagnosis
function Get-Overall {
    $iss = @(Issues)
    $att = @($script:Attempts)
    $launchState = 'NOT_TESTED'
    if ($att.Count -gt 0) { $launchState = $att[$att.Count - 1].State }
    if ($iss.Count -gt 0) { return @{ Kind = 'issue'; Text = '[!] ISSUE DETECTED (' + $iss.Count + ')' } }
    if ($launchState -eq 'RUNNING') { return @{ Kind = 'healthy'; Text = $TICK + ' GAME HEALTHY' } }
    if ($launchState -eq 'RUNNING_NO_WINDOW') { return @{ Kind = 'healthy2'; Text = $TICK + ' NO PROBLEMS DETECTED - the process is running but no window was detected (it may still be loading)' } }
    if ($launchState -eq 'NOT_TESTED') { return @{ Kind = 'nolaunch'; Text = $TICK + ' NO PROBLEMS DETECTED - launch test not run' } }
    return @{ Kind = 'unknown'; Text = '? UNKNOWN - insufficient evidence to determine the cause' }
}

function Show-Result {
    $o = Get-Overall
    Line ''
    Line '--------------------------------------------------' 'DarkGray'
    Line 'RESULT' 'White'
    Line ''
    if ($o.Kind -eq 'healthy') { Line $o.Text 'Green'; Line ''; Line 'No problems detected.' 'Green'; Line ''; Line 'No repair is required.' 'Green' }
    elseif ($o.Kind -eq 'healthy2') { Line $o.Text 'Green'; Line ''; Line 'No repair is required.' 'Green' }
    elseif ($o.Kind -eq 'nolaunch') { Line $o.Text 'Green'; Line ''; Line 'No repair is required. Run Test Launch for a complete diagnosis.' 'Gray' }
    elseif ($o.Kind -eq 'unknown') {
        Line $o.Text 'Yellow'
        $last = $script:Attempts[$script:Attempts.Count - 1]
        Line ('Launch test result: ' + $last.State) 'Yellow'
        if (@($script:Findings | Where-Object { ($_.Category -eq 'Game Files') -and (Is-Issue $_) }).Count -eq 0) {
            Line 'Game files and configuration show no evidence of a problem.' 'Gray'
            Line 'Problem does not appear to be caused by missing game files.' 'Gray'
            Line 'Further system-level investigation may be required.' 'Gray'
        }
    } else {
        Line $o.Text 'Red'
        $i = 0
        foreach ($f in @(Issues)) {
            $i++
            Line ''
            Line ('  ' + $i + '. ' + $f.Title + '   [' + $f.Category + ']') 'Red'
            foreach ($e in $f.Evidence) { Line ('     Evidence : ' + $e) 'Gray' }
            Line ('     Confidence: ' + $f.Confidence + ' (' + $f.Status + ')') 'Gray'
            if ($f.Recommended) { Line ('     Recommended: ' + $f.Recommended) 'Yellow' }
        }
        $launchBad = @($script:Attempts | Where-Object { @('CRASHED', 'BLOCKED_BY_LAUNCHER', 'LAUNCH_FAILED') -contains $_.State }).Count -gt 0
        $fileIssue = @($script:Findings | Where-Object { (@('Game Files', 'Configuration', 'Dependencies') -contains $_.Category) -and (Is-Issue $_) }).Count -gt 0
        if ($launchBad -and (-not $fileIssue)) {
            Line ''
            Line '  Game files, configuration and dependencies show no evidence of a problem.' 'Gray'
            Line '  Problem does not appear to be caused by missing game files.' 'Gray'
            Line '  Further system-level investigation may be required.' 'Gray'
        }
    }
    $info = @($script:Findings | Where-Object { -not (Is-Issue $_) })
    foreach ($f in $info) { Line ''; Line ('  [' + $f.Confidence + '] ' + $f.Title) 'DarkGray'; foreach ($e in $f.Evidence) { Line ('     ' + $e) 'DarkGray' } }
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
        [void]$L.Add('Informational / Possible:')
        foreach ($f in $info) { [void]$L.Add('  - [' + $f.Confidence + '] ' + $f.Title); foreach ($e in $f.Evidence) { [void]$L.Add('      ' + $e) } }
    }
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
    Step 6 8 'Testing Game Launch...'
    Run-LaunchTest
    Step 7 8 'Checking Crash Evidence...'
    Build-LaunchFindings
    Check-CrashHistory
    Step 8 8 'Building Diagnosis...'
    Show-Sections
    Show-Result
    Save-Report
}

function Run-ScanOnly {
    Run-Scan $false
    Check-CrashHistory
    Show-Sections
    Show-Result
    Save-Report
}

function Run-LaunchOnly {
    if (-not $script:ScanDone) {
        Line 'Preparing: detecting the game first...' 'Cyan'
        Do-Detection
        Detect-Mods
    }
    Run-LaunchTest
    Build-LaunchFindings
    Check-CrashHistory
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
    Line '  Steam will verify and repair the files with its own official function.' 'White'
    Line '  Steam shows the progress in its own window.' 'Gray'
    if (-not (Ask-YN '  Ask Steam to verify the game files now?')) { Line '  Skipped.' 'Gray'; return }
    $f0 = Get-AcfFlags
    try { Start-Process -FilePath ('steam://validate/' + $g.AppId) -ErrorAction Stop } catch { Line ('  Could not send the request to Steam: ' + $_.Exception.Message) 'Red'; return }
    [void]$script:Actions.Add('Asked Steam to verify game files (App ID ' + $g.AppId + ').')
    Log ('Steam verify requested for ' + $g.AppId)
    $t0 = Get-Date
    $changed = $false
    $done = $false
    Write-Host '  Waiting for Steam' -NoNewline
    while (((Get-Date) - $t0).TotalMinutes -lt 60) {
        Start-Sleep -Seconds 5
        Write-Host '.' -NoNewline
        $fl = Get-AcfFlags
        if ($fl -ne $null) {
            if ($fl -ne $f0) { $changed = $true }
            if ($changed -and ($fl -eq 4)) { $done = $true; break }
        }
        if ((-not $changed) -and (((Get-Date) - $t0).TotalSeconds -ge 90)) { break }
    }
    Write-Host ''
    if ($done) { Line '  Steam finished and reports the game as fully installed.' 'Green' }
    else {
        Line '  Game Doctor could not confirm the end of the verification from Steam data.' 'Yellow'
        [void](Read-Host '  When Steam shows that verification is complete, press Enter')
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
    $fixable = @(Issues | Where-Object { $_.RepairId })
    $iss = @(Issues)
    if ($iss.Count -eq 0) {
        Line ''
        Line ($TICK + ' No problems with evidence were found, so no repair is required.') 'Green'
        return
    }
    if ($fixable.Count -eq 0) {
        Line ''
        Line 'The detected issues have no automatic repair:' 'Yellow'
        foreach ($f in $iss) { Line ('  - ' + $f.Title + ' : ' + $f.Recommended) 'Gray' }
        return
    }
    $done = @{}
    foreach ($f in $fixable) {
        $key = $f.RepairId + '|' + $f.Category
        Line ''
        Line ('[!] ' + $f.Title.ToUpper()) 'Red'
        foreach ($e in $f.Evidence) { Line ('    Evidence: ' + $e) 'Gray' }
        Line ('    Confidence: ' + $f.Confidence) 'Gray'
        if ($f.RepairId -eq 'steamverify') { if ($done.ContainsKey('steamverify')) { continue }; $done['steamverify'] = $true; Repair-SteamVerify $f }
        elseif ($f.RepairId -eq 'config') { Repair-Config $f }
        elseif ($f.RepairId -eq 'dep') { Repair-Dep $f }
    }
    Line ''
    Line 'Running Game Doctor verification...' 'Cyan'
    Check-Files
    Check-Config
    Check-Deps
    $left = @(Issues)
    if ($left.Count -eq 0) { Line ('[' + $TICK + '] Re-scan completed - no problems with evidence remain.') 'Green'; [void]$script:Verify.Add('Re-scan completed: no issues with evidence remain.') }
    else {
        Line ('[!] Re-scan completed - ' + $left.Count + ' issue(s) still have evidence:') 'Yellow'
        foreach ($f in $left) { Line ('    - ' + $f.Title) 'Yellow' }
        [void]$script:Verify.Add('Re-scan completed: ' + $left.Count + ' issue(s) still present.')
    }
    Save-Report
}

# ------------------------------------------------------------------- UI
function Box([string]$t) { return ([string][char]0x2551 + ' ' + $t.PadRight(50).Substring(0, 50) + ' ' + [string][char]0x2551) }

function Show-Menu {
    Clear-Host
    $h = [string][char]0x2550
    $p = $script:GamePath
    if ($p.Length -gt 48) { $p = '...' + $p.Substring($p.Length - 45) }
    Line ([string][char]0x2554 + ($h * 52) + [string][char]0x2557) 'Yellow'
    Line (Box '                  GAME DOCTOR') 'Yellow'
    Line ([string][char]0x2560 + ($h * 52) + [string][char]0x2563) 'Yellow'
    Line (Box '') 'Yellow'
    Line (Box 'Game Path:') 'Yellow'
    Line (Box $p) 'White'
    Line (Box '') 'Yellow'
    foreach ($l in @('[1] Scan Game', '[2] Test Launch', '[3] Full Diagnosis', '[4] Repair Detected Problems', '[5] View Report', '[6] Exit', '[7] Change Game Path')) { Line (Box $l) 'Yellow' }
    Line (Box '') 'Yellow'
    Line ([string][char]0x255A + ($h * 52) + [string][char]0x255D) 'Yellow'
    Line ''
}

function Read-GamePath {
    while ($true) {
        Line ''
        Line 'Enter Game Path (leave empty to exit):' 'White'
        $p = (Read-Host '>').Trim().Trim('"')
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
    Line 'GAME DOCTOR - evidence-based game diagnostics and repair' 'Yellow'
    Line 'No evidence = no problem. Nothing is changed without your approval.' 'Gray'
    if (-not (Read-GamePath)) { exit 0 }
    while ($true) {
        Show-Menu
        $c = (Read-Host 'Select an option').Trim()
        Line ''
        if ($c -eq '1') { Run-ScanOnly; Pause-Key }
        elseif ($c -eq '2') { Run-LaunchOnly; Pause-Key }
        elseif ($c -eq '3') { Run-Full; Pause-Key }
        elseif ($c -eq '4') {
            if (-not $script:ScanDone) { Line 'No diagnosis has been run yet. Running a scan first...' 'Cyan'; Run-Scan $false; Check-CrashHistory }
            Run-Repair; Pause-Key
        }
        elseif ($c -eq '5') {
            if ($script:G) { Save-Report }
            if ($script:ReportFile -and (Test-Path -LiteralPath $script:ReportFile)) { Get-Content -LiteralPath $script:ReportFile | ForEach-Object { Write-Host $_ } }
            else { Line 'No report yet. Run Scan Game or Full Diagnosis first.' 'Yellow' }
            Pause-Key
        }
        elseif ($c -eq '6') { break }
        elseif ($c -eq '7') { [void](Read-GamePath) }
    }
} catch {
    Line ('Unexpected problem: ' + $_.Exception.Message) 'Red'
    Log ('Unexpected error: ' + $_.Exception.Message)
    Pause-Key
    exit 1
}
exit 0
#GD_END
