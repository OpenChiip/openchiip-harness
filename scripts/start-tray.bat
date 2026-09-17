@echo off
REM OpenChiip Harness — Windows 系统托盘启动
REM 后台运行服务器，显示系统托盘图标

setlocal enabledelayedexpansion

set "DIR=%~dp0"
set "PYTHONPATH=%DIR%;%PYTHONPATH%"
set "AGENT_RUNTIME_HOME=%USERPROFILE%\.openchiip-harness\data"

if not exist "%AGENT_RUNTIME_HOME%" mkdir "%AGENT_RUNTIME_HOME%"

REM 检查是否已运行
curl -s http://127.0.0.1:8900/api/v1/status >nul 2>&1
if not errorlevel 1 (
    echo Agent 已在运行: http://localhost:8900
    start http://localhost:8900
    exit /b 0
)

REM 后台启动
where python >nul 2>&1 && set PYTHON=python
where py >nul 2>&1 && set PYTHON=py

start /min "" %PYTHON% -m uvicorn agent_runtime.server.app:create_app --factory --host 127.0.0.1 --port 8900

REM 等待启动
timeout /t 2 /nobreak >nul

REM 打开浏览器
start http://localhost:8900

echo OpenChiip Harness 已在后台启动
echo Web UI: http://localhost:8900
echo.
echo 停止服务: taskkill /f /im python.exe (会停止所有 Python 进程)
