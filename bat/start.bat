
taskkill /f /im skynet.exe
ping -n 1 127.0.0.1>nul
cd ../
mkdir log
cd skynet
start skynet.exe ../config/main_node
::pause
