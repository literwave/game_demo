@echo off
chcp 936 >nul 2>&1
rem 导出所有 Excel 文件为配置文件
rem 使用 pushd 处理 UNC 路径（WSL 路径）
set "scriptdir=%~dp0"
pushd "%scriptdir%" || exit /b 1
echo 脚本目录: %scriptdir%
echo 当前工作目录: %CD%
echo 开始导出所有 Excel 文件...

for /f "delims=" %%a in ('dir /b /a-d "excel\*.xlsx" 2^>nul ^| findstr /v /c:"~$"') do (
  echo 正在处理: %%a
  python export_file.py -r ./excel/%%a -f lua -t server -o s
  if errorlevel 1 (
    echo 导出 %%a 为 lua 格式时出错
  )
  python export_file.py -r ./excel/%%a -f json -t client -o c
  if errorlevel 1 (
    echo 导出 %%a 为 json 格式时出错
  )
  echo %%a 导出成功
)

echo 所有文件导出完成！
popd
pause
