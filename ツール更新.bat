@echo off
setlocal
rem ==========================================================
rem  Update tool v5 - pushing to GitHub
rem  - Double-click : uses the newest .html in Downloads
rem  - Drag a file onto this bat : uses that file
rem  - Only .html files are accepted
rem  - MARK : a text that must be inside the html of THIS tool.
rem           If the file does not contain it, nothing is overwritten.
rem           (Leave empty to skip this check.)
rem ==========================================================
set "MARK=smileclub-tool"

set "DROPPED=%~1"
pushd "%~dp0"
if errorlevel 1 goto :nofolder

set "LOGFILE=%cd%\update_log.txt"
echo ============================================== > "%LOGFILE%"
echo Update started: %date% %time% >> "%LOGFILE%"
echo Folder: %cd% >> "%LOGFILE%"
echo ============================================== >> "%LOGFILE%"

echo ===============================================
echo   Update tool v5 - pushing to GitHub
echo   Current folder: %cd%
echo   (A full log is also being saved to: update_log.txt)
echo ===============================================
echo.

set "CAND="
if defined DROPPED goto :usedropped

set "DOWNLOADS=%USERPROFILE%\Downloads"
set "NEWEST="
for /f "delims=" %%F in ('dir /b /o-d /a-d "%DOWNLOADS%\*.html" 2^>nul') do (
  if not defined NEWEST set "NEWEST=%%F"
)
if not defined NEWEST goto :nofile
set "CAND=%DOWNLOADS%\%NEWEST%"
echo Newest .html file found in Downloads folder:
goto :checkfile

:usedropped
set "CAND=%DROPPED%"
echo File dropped onto this bat:
goto :checkfile

:checkfile
for %%A in ("%CAND%") do set "CANDNAME=%%~nxA"
for %%A in ("%CAND%") do set "CANDEXT=%%~xA"
for %%A in ("%CAND%") do set "CANDTIME=%%~tA"
for %%A in ("%CAND%") do set "CANDSIZE=%%~zA"
echo   %CANDNAME%
echo   Last modified: %CANDTIME%
echo   Size: %CANDSIZE% bytes
echo.

if not exist "%CAND%" goto :stopnotfound
if /i not "%CANDEXT%"==".html" goto :stopnothtml
if not defined MARK goto :askoverwrite
findstr /m /c:"%MARK%" "%CAND%" >nul 2>&1
if errorlevel 1 goto :stopwrongtool
echo Check OK: this file is for this tool.
echo.
goto :askoverwrite

:askoverwrite
set "CONFIRM="
set /p CONFIRM="Overwrite index.html with this file? (Y = overwrite / N = skip and just commit current files): "
if /i "%CONFIRM%"=="Y" goto :dooverwrite
goto :skipoverwrite

:dooverwrite
copy /Y "%CAND%" "index.html" >nul
if errorlevel 1 goto :copyfailed
echo.
echo index.html has been updated.
echo Overwrote index.html with: %CANDNAME% (%CANDSIZE% bytes, %CANDTIME%) >> "%LOGFILE%"
echo.
goto :commitpush

:nofile
echo No .html file was found in: %DOWNLOADS%
echo Skipping the overwrite step. Continuing with the files already in this folder.
echo No html file found in Downloads. Skipped overwrite. >> "%LOGFILE%"
echo.
goto :commitpush

:stopnotfound
echo [STOP] The file could not be found.
echo [STOP] File not found: %CAND% >> "%LOGFILE%"
goto :stopend

:stopnothtml
echo [STOP] Only .html files can be used. Nothing was changed.
echo [STOP] Not an html file: %CANDNAME% >> "%LOGFILE%"
goto :stopend

:stopwrongtool
echo [STOP] This html does not look like the file for this tool.
echo        (It does not contain: %MARK%)
echo        It may be a file for a different tool. Nothing was changed.
echo.
echo        If you meant another file, drag that file onto this bat.
echo [STOP] Wrong tool file (MARK not found): %CANDNAME% >> "%LOGFILE%"
goto :stopend

:stopend
echo.
pause
popd
exit /b 1

:copyfailed
echo.
echo [ERROR] Failed to copy the file into index.html.
echo [ERROR] Failed to copy %CANDNAME% into index.html >> "%LOGFILE%"
echo.
pause
popd
exit /b 1

:skipoverwrite
echo.
echo Skipped overwriting index.html. Continuing with files already in this folder.
echo User chose not to overwrite index.html. >> "%LOGFILE%"
echo.
goto :commitpush

:commitpush
git add -A

set "MSG="
set /p MSG="Commit message (leave blank and press Enter for default): "
if "%MSG%"=="" set "MSG=update"

echo. >> "%LOGFILE%"
echo --- git commit --- >> "%LOGFILE%"
set "COMMITTEMP=%temp%\commit_output_%random%.txt"
git commit -m "%MSG%" > "%COMMITTEMP%" 2>&1
set "COMMITRESULT=%errorlevel%"
type "%COMMITTEMP%"
type "%COMMITTEMP%" >> "%LOGFILE%"
del "%COMMITTEMP%" >nul 2>&1

if "%COMMITRESULT%"=="0" goto :dopush
goto :commitfailed

:commitfailed
echo.
echo No changes found, or commit failed.
echo (This can happen if there was nothing new to save.)
echo COMMIT RESULT: no changes or failed. >> "%LOGFILE%"
echo.
pause
popd
exit /b 1

:dopush
echo.
echo Uploading to GitHub...
echo. >> "%LOGFILE%"
echo --- git push --- >> "%LOGFILE%"
set "PUSHTEMP=%temp%\push_output_%random%.txt"
git push > "%PUSHTEMP%" 2>&1
set "PUSHRESULT=%errorlevel%"
type "%PUSHTEMP%"
type "%PUSHTEMP%" >> "%LOGFILE%"
del "%PUSHTEMP%" >nul 2>&1

if "%PUSHRESULT%"=="0" goto :pushsuccess
goto :pushfailed

:pushfailed
echo.
echo [ERROR] Push failed. Please check your network connection and login status.
echo PUSH RESULT: FAILED >> "%LOGFILE%"
echo.
pause
popd
exit /b 1

:pushsuccess
echo PUSH RESULT: SUCCESS >> "%LOGFILE%"
echo Update finished: %date% %time% >> "%LOGFILE%"
echo ============================================== >> "%LOGFILE%"
echo.
echo Update completed successfully.
echo In a few minutes, your changes will be live on GitHub Pages.
echo.
pause
popd
exit /b 0

:nofolder
echo Failed to move to folder: %~dp0
pause
exit /b 1
