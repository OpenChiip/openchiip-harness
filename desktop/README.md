# OpenChiip Harness Desktop

基于 Tauri 2.0 的桌面应用封装，内嵌 Python 后端。

## 架构

```
desktop/
├── src-tauri/          # Rust/Tauri 后端
│   ├── src/main.rs     # 入口：启动 Python 进程 + WebView
│   ├── Cargo.toml      # Rust 依赖
│   ├── tauri.conf.json # Tauri 配置
│   ├── capabilities/   # 权限配置
│   └── icons/          # 应用图标
├── src/                # 前端占位（实际由后端提供）
├── package.json        # Tauri CLI 依赖
└── README.md
```

## 工作原理

1. Tauri 启动时，`main.rs` 会启动 Python 后端进程
2. WebView 加载 `http://localhost:8900`（后端提供的 Web UI）
3. 关闭窗口时自动终止后端进程

## 构建

### 前置要求

- [Rust](https://rustup.rs/) (stable)
- [Node.js](https://nodejs.org/) 20+
- [Python](https://www.python.org/) 3.10+
- Windows: Visual Studio Build Tools (MSVC)

### 开发模式

```bash
cd desktop
npm install
npm run dev
```

### 生产构建

```bash
npm run build
```

产物位置: `src-tauri/target/release/bundle/`
- `openchiip-harness_3.0.0_x64.msi`
- `openchiip-harness_3.0.0_x64-setup.exe`

### 一键打包（推荐）

```bash
# 在 Windows 上
scripts\build-windows.bat
```

## 图标

将应用图标放入 `src-tauri/icons/` 目录:
- `icon.png` (1024x1024)
- `icon.ico` (Windows)
- `icon.icns` (macOS)
- `32x32.png`, `128x128.png`, `128x128@2x.png`

可使用 `npm run tauri icon` 从 1024x1024 PNG 自动生成。
