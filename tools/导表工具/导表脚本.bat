
start export_file.py -r ./excel/hero.xlsx -f lua -t ../server -o s

@echo off
rem 指定存放文件的目录
set curdir=%cd%
set file_parse = export_file.py
echo %curdir%
for /f "delims=\" %%a in ('dir /b /a-d /o-d "%curdir%/excel/\*.*"') do (
  start %curdir%/export_file.py -r ./excel/%%a -f lua -t %curdir%/server -o s
  start %curdir%/export_file.py -r ./excel/%%a -f json -t %curdir%/client -o c

  echo %%a success
)
pause
