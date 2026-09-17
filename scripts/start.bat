@echo off
REM OpenChiip Harness — Windows 启动脚本
REM 启动后端服务器 + 自动打开浏览器

setlocal enabledelayedexpansion

set "DIR=%~dp0"
set "PYTHONPATH=%DIR%;%PYTHONPATH%"
set "AGENT_RUNTIME_HOME=%USERPROFILE%\.openchiip-harness\data"

REM 创建数据目录
if not exist "%AGENT_RUNTIME_HOME%" mkdir "%AGENT_RUNTIME_HOME%"

REM 检查 Python
where python >nul 2>&1
if errorlevel 1 (
    where py >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] 未找到 Python，请安装 Python 3.10+
        pause
        exit /b 1
    )
    set PYTHON=py
) else (
    set PYTHON=python
)

echo ═══ OpenChiip Harness ═══
echo.
echo  服务器: http://localhost:8900
echo  Web UI: http://localhost:8900/
echo  API:    http://localhost:8900/api/v1/status
echo.
echo  按 Ctrl+C 停止服务器
echo.

REM 延迟打开浏览器
start /b cmd /c "timeout /t 2 /nobreak >nul && start http://localhost:8900"

REM 启动服务器
%PYTHON% -m uvicorn agent_runtime.server.app:create_app --factory --host 127.0.0.1 --port 8900

pause
