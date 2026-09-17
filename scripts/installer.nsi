; OpenChiip Harness — NSIS 安装脚本
; 在 Windows 上用 makensis 编译: makensis installer.nsi
; 生成 openchiip-harness-3.0.0-setup.exe

!include "MUI2.nsh"
!include "nsDialogs.nsh"

; ── 基本信息 ──
Name "OpenChiip Harness"
OutFile "..\dist\openchiip-harness-3.0.0-setup.exe"
InstallDir "$LOCALAPPDATA\OpenChiipHarness"
InstallDirRegKey HKCU "Software\OpenChiip\Harness" "InstallDir"
RequestExecutionLevel user
Unicode true

; ── 版本信息 ──
VIProductVersion "3.0.0.0"
VIAddVersionKey "ProductName" "OpenChiip Harness"
VIAddVersionKey "CompanyName" "OpenChiip"
VIAddVersionKey "FileVersion" "3.0.0"
VIAddVersionKey "LegalCopyright" "Copyright 2024 OpenChiip"
VIAddVersionKey "FileDescription" "OpenChiip Harness Installer"

; ── MUI 配置 ──
!define MUI_ABORTWARNING
!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\modern-install.ico"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\modern-uninstall.ico"

; ── 页面 ──
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "..\README.md"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

; ── 语言 ──
!insertmacro MUI_LANGUAGE "SimpChinese"

; ── 安装区段 ──
Section "核心文件" SecCore
    SetOutPath "$INSTDIR"
    
    ; Python 后端
    File /r "..\agent_runtime"
    File "..\pyproject.toml"
    
    ; 前端构建产物
    File /r "..\web\dist"
    
    ; 启动脚本
    File "start.bat"
    File "start-tray.bat"
    
    ; 配置初始化
    IfFileExists "$PROFILE\.openchiip-harness\config.yaml" ConfigExists CreateConfig
    CreateConfig:
        CreateDirectory "$PROFILE\.openchiip-harness\data"
    ConfigExists:
    
    ; 写入注册表
    WriteRegStr HKCU "Software\OpenChiip\Harness" "InstallDir" "$INSTDIR"
    WriteRegStr HKCU "Software\OpenChiip\Harness" "Version" "3.0.0"
    
    ; 创建卸载程序
    WriteUninstaller "$INSTDIR\uninstall.exe"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\OpenChiipHarness" \
        "DisplayName" "OpenChiip Harness"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\OpenChiipHarness" \
        "UninstallString" '"$INSTDIR\uninstall.exe"'
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\OpenChiipHarness" \
        "DisplayVersion" "3.0.0"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\OpenChiipHarness" \
        "Publisher" "OpenChiip"
SectionEnd

Section "开始菜单" SecStartMenu
    CreateDirectory "$SMPROGRAMS\OpenChiip Harness"
    CreateShortCut "$SMPROGRAMS\OpenChiip Harness\启动 Harness.lnk" "$INSTDIR\start.bat" "" "" 0
    CreateShortCut "$SMPROGRAMS\OpenChiip Harness\Web UI.lnk" "http://localhost:8900" "" "" 0
    CreateShortCut "$SMPROGRAMS\OpenChiip Harness\卸载.lnk" "$INSTDIR\uninstall.exe" "" "" 0
SectionEnd

Section "桌面快捷方式" SecDesktop
    CreateShortCut "$DESKTOP\OpenChiip Harness.lnk" "$INSTDIR\start.bat" "" "" 0
SectionEnd

; ── 区段描述 ──
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${SecCore} "OpenChiip Harness 核心文件（后端 + 前端）"
    !insertmacro MUI_DESCRIPTION_TEXT ${SecStartMenu} "创建开始菜单快捷方式"
    !insertmacro MUI_DESCRIPTION_TEXT ${SecDesktop} "创建桌面快捷方式"
!insertmacro MUI_FUNCTION_DESCRIPTION_END

; ── 卸载区段 ──
Section "Uninstall"
    ; 删除文件
    RMDir /r "$INSTDIR\agent_runtime"
    RMDir /r "$INSTDIR\web"
    Delete "$INSTDIR\pyproject.toml"
    Delete "$INSTDIR\start.bat"
    Delete "$INSTDIR\start-tray.bat"
    Delete "$INSTDIR\uninstall.exe"
    RMDir "$INSTDIR"
    
    ; 删除注册表
    DeleteRegKey HKCU "Software\OpenChiip\Harness"
    DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\OpenChiipHarness"
    
    ; 删除快捷方式
    RMDir /r "$SMPROGRAMS\OpenChiip Harness"
    Delete "$DESKTOP\OpenChiip Harness.lnk"
    
    ; 注意：不删除用户数据 (~/.openchiip-harness/)
SectionEnd
