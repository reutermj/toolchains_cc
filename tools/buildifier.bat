@echo off
setlocal enabledelayedexpansion

REM Detect system architecture using environment variable
if /i "%PROCESSOR_ARCHITECTURE%"=="ARM64" (
    set "buildifier=%~dp0buildifier-windows-arm64.exe"
) else (
    set "buildifier=%~dp0buildifier-windows-amd64.exe"
)

REM Check if the executable exists
if not exist "%buildifier%" (
    echo Error: %buildifier% not found.
    echo Detected architecture: %PROCESSOR_ARCHITECTURE%
    echo Please ensure the appropriate buildifier executable is available.
    exit /b 1
)

REM Execute buildifier with all arguments passed to this script
"%buildifier%" %*

exit /b %ERRORLEVEL%
