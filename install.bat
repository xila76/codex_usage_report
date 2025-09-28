@echo off
setlocal

set APP_NAME=codex_usage_report
set BIN_DIR=dist

:: Detect architecture (defaults to amd64)
set ARCH=amd64
if /i "%PROCESSOR_ARCHITECTURE%"=="ARM64" set ARCH=arm64

set BIN_FILE=%BIN_DIR%\%APP_NAME%_windows_%ARCH%.exe
set TARGET_DIR=C:\Windows\System32
set TARGET_FILE=%TARGET_DIR%\%APP_NAME%.exe

if not exist "%BIN_FILE%" (
    echo [ERROR] Binary not found: %BIN_FILE%
    echo Run "make build" or "make release" first.
    exit /b 1
)

echo [INFO] Copying %BIN_FILE% → %TARGET_FILE%
copy /Y "%BIN_FILE%" "%TARGET_FILE%" >nul

if errorlevel 1 (
    echo [ERROR] Failed to copy file. Try running as Administrator.
    exit /b 1
)

echo [OK] Installation complete!
echo You can now run: %APP_NAME% --help

endlocal

