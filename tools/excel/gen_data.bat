@echo off
chcp 936 >nul 2>&1
set "PYTHONIOENCODING=gbk"
rem Export all Excel files to config files
rem Use pushd to handle UNC path (WSL path)
set "scriptdir=%~dp0"
pushd "%scriptdir%" || exit /b 1
echo Script directory: %scriptdir%
echo Current working directory: %CD%
echo Start exporting all Excel files...

for %%I in ("..\..\read_config") do set "READ_CONFIG_DIR=%%~fI"
if not exist "%READ_CONFIG_DIR%" (
  mkdir "%READ_CONFIG_DIR%"
)
echo Config output directory: %READ_CONFIG_DIR%

for /f "delims=" %%a in ('dir /b /a-d "excel\*.xlsx" 2^>nul ^| findstr /v /c:"~$"') do (
  echo Processing file: %%a
  python export_file.py -r ./excel/%%a -f lua -t "%READ_CONFIG_DIR%" -o s
  if errorlevel 1 (
    echo Failed to export %%a to lua format
  )
  python export_file.py -r ./excel/%%a -f json -t client -o c
  if errorlevel 1 (
    echo Failed to export %%a to json format
  )
  echo %%a export done
)

echo All files exported successfully.
popd
pause
