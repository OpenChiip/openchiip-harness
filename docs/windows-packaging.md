# OpenChiip Harness — Windows 打包指南

## 快速开始

### 方式一：便携包（无需安装）

1. 下载 `openchiip-harness-3.0.0-windows-x64.zip`
2. 解压到任意目录
3. 双击 `start.bat` 启动
4. 浏览器自动打开 `http://localhost:8900`

### 方式二：安装程序

1. 下载 `openchiip-harness-3.0.0-setup.exe`
2. 运行安装向导
3. 从开始菜单或桌面快捷方式启动

### 方式三：PyInstaller 单文件

1. 下载 `openchiip-harness.exe`
2. 直接运行（首次启动较慢）

---

## 开发者打包

### 前置要求

| 工具 | 用途 | 必须 |
|------|------|------|
| Python 3.10+ | 后端运行 | 是 |
| Node.js 20+ | 前端构建 | 是 |
| NSIS | 生成 setup.exe | 可选 |
| Rust/Cargo | Tauri 桌面包 | 可选 |

### 一键打包

```cmd
scripts\build-windows.bat
```

自动执行：
1. 安装 Python 依赖
2. 构建前端（npm run build）
3. 创建便携包（zip）
4. PyInstaller 打包（exe）
5. NSIS 安装包（setup.exe）

### 分步打包

#### 1. 构建前端

```cmd
cd web
npm install
npm run build
```

#### 2. 便携包

```cmd
mkdir dist\portable
xcopy /e agent_runtime dist\portable\agent_runtime\
xcopy /e web\dist dist\portable\web\dist\
copy pyproject.toml dist\portable\
copy scripts\start.bat dist\portable\
```

#### 3. PyInstaller

```cmd
pip install pyinstaller
pyinstaller openchiip-harness.spec --noconfirm
```

#### 4. NSIS 安装包

1. 安装 [NSIS](https://nsis.sourceforge.io/)
2. 运行:

```cmd
cd scripts
makensis installer.nsi
```

#### 5. Tauri 桌面应用

```cmd
cd desktop
npm install
npm run build
```

---

## 文件结构

```
scripts/
├── build-windows.bat      # 一键打包脚本
├── installer.nsi           # NSIS 安装脚本
├── start.bat               # 启动脚本（前台）
├── start-tray.bat          # 启动脚本（后台）
└── openchiip-harness.spec    # PyInstaller 配置

desktop/
├── src-tauri/              # Tauri 2.0 项目
│   ├── src/main.rs
│   ├── Cargo.toml
│   ├── tauri.conf.json
│   └── capabilities/
├── package.json
└── README.md
```

---

## 常见问题

### Q: 启动后浏览器没有自动打开？

手动访问 `http://localhost:8900`

### Q: 提示 "未找到 Python"？

安装 [Python 3.10+](https://www.python.org/downloads/) 并勾选 "Add to PATH"

### Q: 端口 8900 被占用？

```cmd
set PORT=8901
start.bat
```

### Q: 如何停止服务？

在命令行窗口按 `Ctrl+C`，或关闭命令行窗口
