@echo off
REM ═══════════════════════════════════════════════════════════
REM  OpenChiip Harness — Windows 一键打包脚本
REM  
REM  产物:
REM    1. dist/openchiip-harness-3.0.0-windows-x64.zip  (便携包)
REM    2. dist/openchiip-harness-3.0.0-setup.exe        (NSIS 安装包)
REM    3. dist/openchiip-harness.exe                     (PyInstaller 单文件)
REM
REM  依赖:
REM    - Python 3.10+ (需 pip)
REM    - Node.js 20+ (需 npm)
REM    - 可选: NSIS (makensis) — 生成 setup.exe
REM    - 可选: Rust/Cargo — 生成 Tauri MSI
REM ═══════════════════════════════════════════════════════════

setlocal enabledelayedexpansion

set VERSION=3.0.0
set PROJECT_DIR=%~dp0..
set BUILD_DIR=%PROJECT_DIR%\build\windows
set DIST_DIR=%PROJECT_DIR%\dist
set WEB_DIR=%PROJECT_DIR%\web

echo.
echo  ╔═══════════════════════════════════════════╗
echo  ║  OpenChiip Harness Windows 打包工具       ║
echo  ║  版本: %VERSION%                          ║
echo  ╚═══════════════════════════════════════════╝
echo.

REM ── 检查依赖 ──
echo [检查] 依赖...
set HAS_PYTHON=0
set HAS_NODE=0
set HAS_NSIS=0
set HAS_CARGO=0

where python >nul 2>&1 && set HAS_PYTHON=1 && (python --version 2>&1 | findstr /i "3.1" >nul && echo   [OK] Python || echo   [WARN] Python 版本可能不满足 3.10+)
where py >nul 2>&1 && set HAS_PYTHON=1
if %HAS_PYTHON%==0 (echo   [ERROR] 未找到 Python 3.10+ && goto :fail)

where node >nul 2>&1 && set HAS_NODE=1 && (for /f "tokens=1 delims=v" %%a in ('node --version') do echo   [OK] Node.js %%a)
if %HAS_NODE%==0 echo   [WARN] Node.js 未安装，将跳过前端构建

where makensis >nul 2>&1 && set HAS_NSIS=1 && echo   [OK] NSIS
if %HAS_NSIS%==0 echo   [INFO] NSIS 未安装，将跳过 setup.exe 生成

where cargo >nul 2>&1 && set HAS_CARGO=1 && echo   [OK] Rust/Cargo
if %HAS_CARGO%==0 echo   [INFO] Rust 未安装，将跳过 Tauri 桌面包

echo.

REM ── 清理 ──
echo [1/6] 清理旧构建...
if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%"
if exist "%DIST_DIR%" rmdir /s /q "%DIST_DIR%"
mkdir "%BUILD_DIR%\portable"
mkdir "%DIST_DIR%"

REM ── 安装 Python 依赖 ──
echo [2/6] 安装 Python 依赖...
cd /d "%PROJECT_DIR%"
pip install websockets psutil PyYAML fastapi "uvicorn[standard]" python-multipart aiofiles -q 2>nul
pip install pyinstaller -q 2>nul
echo   [OK] 依赖已安装

REM ── 构建前端 ──
echo [3/6] 构建前端...
if %HAS_NODE%==1 (
    cd /d "%WEB_DIR%"
    if not exist "node_modules" call npm install
    call npm run build
    if exist "dist\index.html" (
        echo   [OK] 前端已构建
    ) else (
        echo   [ERROR] 前端构建失败
        goto :fail
    )
) else (
    echo   [SKIP] 无 Node.js
)

REM ── 创建便携包 ──
echo [4/6] 创建便携包...
cd /d "%PROJECT_DIR%"
xcopy /e /y /q "agent_runtime" "%BUILD_DIR%\portable\agent_runtime\" >nul
if exist "%WEB_DIR%\dist" xcopy /e /y /q "%WEB_DIR%\dist" "%BUILD_DIR%\portable\web\dist\" >nul
copy /y "pyproject.toml" "%BUILD_DIR%\portable\" >nul
copy /y "scripts\start.bat" "%BUILD_DIR%\portable\" >nul
copy /y "scripts\start-tray.bat" "%BUILD_DIR%\portable\" >nul

REM 创建便携包启动脚本
(
echo @echo off
echo set "DIR=%%~dp0"
echo set "PYTHONPATH=%%DIR%%;%%PYTHONPATH%%"
echo set "AGENT_RUNTIME_HOME=%%USERPROFILE%%\.openchiip-harness\data"
echo if not exist "%%AGENT_RUNTIME_HOME%%" mkdir "%%AGENT_RUNTIME_HOME%%"
echo echo 启动 OpenChiip Harness...
echo start http://localhost:8900
echo python -m uvicorn agent_runtime.server.app:create_app --factory --host 127.0.0.1 --port 8900
echo pause
) > "%BUILD_DIR%\portable\start.bat"

REM 打包 zip
cd /d "%BUILD_DIR%"
powershell -Command "Compress-Archive -Path 'portable\*' -DestinationPath '%DIST_DIR%\openchiip-harness-%VERSION%-windows-x64.zip' -Force"
if exist "%DIST_DIR%\openchiip-harness-%VERSION%-windows-x64.zip" (
    for %%F in ("%DIST_DIR%\openchiip-harness-%VERSION%-windows-x64.zip") do echo   [OK] 便携包: %%~nxF ^(%%~zF bytes^)
) else (
    echo   [ERROR] 便携包创建失败
)

REM ── PyInstaller 单文件打包 ──
echo [5/6] PyInstaller 打包...
cd /d "%PROJECT_DIR%"
pyinstaller openchiip-harness.spec --noconfirm 2>nul
if exist "dist\openchiip-harness\openchiip-harness.exe" (
    copy /y "dist\openchiip-harness\openchiip-harness.exe" "%DIST_DIR%\" >nul
    for %%F in ("%DIST_DIR%\openchiip-harness.exe") do echo   [OK] EXE: %%~nxF ^(%%~zF bytes^)
) else (
    echo   [SKIP] PyInstaller 未生成输出
)

REM ── NSIS 安装包 ──
echo [6/6] NSIS 安装包...
if %HAS_NSIS%==1 (
    cd /d "%PROJECT_DIR%\scripts"
    makensis installer.nsi
    if exist "%DIST_DIR%\openchiip-harness-%VERSION%-setup.exe" (
        for %%F in ("%DIST_DIR%\openchiip-harness-%VERSION%-setup.exe") do echo   [OK] 安装包: %%~nxF ^(%%~zF bytes^)
    ) else (
        echo   [WARN] NSIS 编译未生成 setup.exe
    )
) else (
    echo   [SKIP] NSIS 未安装
)

goto :done

:fail
echo.
echo [ERROR] 打包过程中出现错误
exit /b 1

:done
echo.
echo  ═══════════════════════════════════════════
echo   打包完成！产物列表:
echo  ═══════════════════════════════════════════
echo.
dir /b "%DIST_DIR%" 2>nul
echo.
echo  使用方式:
echo    便携包: 解压 zip 后运行 start.bat
echo    安装包: 运行 setup.exe（需 NSIS 编译）
echo    EXE:    直接运行 openchiip-harness.exe
echo.
