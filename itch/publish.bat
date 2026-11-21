@echo off
REM Double-click friendly wrapper around publish.ps1.
REM Usage: publish.bat yourname/cjk-text-kit

setlocal
set "PROJECT=%~1"
if "%PROJECT%"=="" (
    echo usage: publish.bat ^<user^>/^<project-slug^>
    echo example: publish.bat yourname/cjk-text-kit
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0publish.ps1" -Project "%PROJECT%"
if errorlevel 1 (
    echo.
    echo Publish failed. See the messages above.
    pause
    exit /b 1
)

echo.
echo Publish finished. Now open the project page on itch.io and paste the description.
pause
