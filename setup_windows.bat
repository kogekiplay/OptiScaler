@echo off
if defined OPTISCALER_SETUP_UTF8_READY goto utf8_main
setlocal EnableExtensions DisableDelayedExpansion
for /f "tokens=2 delims=:" %%A in ('chcp') do set "_OPTI_OLD_CP=%%A"
set "_OPTI_OLD_CP=%_OPTI_OLD_CP: =%"
chcp 65001 >nul
set "OPTISCALER_SETUP_UTF8_READY=1"
"%ComSpec%" /d /c call "%~f0"
set "_OPTI_UTF8_EXIT=%errorlevel%"
chcp %_OPTI_OLD_CP% >nul
if not "%_OPTI_UTF8_EXIT%"=="42" goto utf8_wrapper_return
set "_OPTI_DELETE_TARGET=%~f0"
start "" /b powershell.exe -NoProfile -WindowStyle Hidden -Command "Start-Sleep -Milliseconds 1500; Remove-Item -LiteralPath $env:_OPTI_DELETE_TARGET -Force -ErrorAction SilentlyContinue" >nul 2>&1
endlocal
exit /b 0

:utf8_wrapper_return
endlocal & exit /b %_OPTI_UTF8_EXIT%

:utf8_main
setlocal EnableExtensions DisableDelayedExpansion
cls
echo  ::::::::  :::::::::  ::::::::::: :::::::::::  ::::::::   ::::::::      :::     :::        :::::::::: :::::::::  
echo :+:    :+: :+:    :+:     :+:         :+:     :+:    :+: :+:    :+:   :+: :+:   :+:        :+:        :+:    :+: 
echo +:+    +:+ +:+    +:+     +:+         +:+     +:+        +:+         +:+   +:+  +:+        +:+        +:+    +:+ 
echo +#+    +:+ +#++:++#+      +#+         +#+     +#++:++#++ +#+        +#++:++#++: +#+        +#++:++#   +#++:++#:  
echo +#+    +#+ +#+            +#+         +#+            +#+ +#+        +#+     +#+ +#+        +#+        +#+    +#+ 
echo #+#    #+# #+#            #+#         #+#     #+#    #+# #+#    #+# #+#     #+# #+#        #+#        #+#    #+# 
echo  ########  ###            ###     ###########  ########   ########  ###     ### ########## ########## ###    ### 
echo.
echo 这次一定能行……
echo v2.75 - 现已支持 OptiPatcher
echo.

del "!! README_EXTRACT ALL FILES TO GAME FOLDER !!.txt" 2>nul

setlocal enabledelayedexpansion

if not exist OptiScaler.dll (
    echo 未找到 OptiScaler 文件 "OptiScaler.dll"！
    echo 可能是文件夹权限有问题，或者你下载的是仓库源代码。
    echo.
    echo 如果 "OptiScaler.dll" 确实存在，请手动将它重命名为支持的文件名（例如 dxgi.dll 或 winmm.dll），这样就完成了！
	echo 手动重命名后无需再次运行安装脚本。
	echo.
    echo 如果文件夹里有 .sln 或 .git 文件，说明你下载的是源代码。请改为下载正确的发布包。
    echo 提示：请从 GitHub 的 Releases 页面下载，并先阅读说明文档。
    echo.
    echo.
    goto end
)


REM Check if old pre-0.9 additional files exist, along with an existing Opti installation
set "OLD_FILES_FOUND=0"
set "OPTI_DLL_LIST="
if exist nvapi64.dll set "OLD_FILES_FOUND=1"
if exist nvngx.dll set "OLD_FILES_FOUND=1"
if exist OptiScaler.asi set "OLD_FILES_FOUND=1"
if exist "Remove OptiScaler.bat" set "OLD_FILES_FOUND=1"

for %%F in (dxgi.dll winmm.dll d3d12.dll dbghelp.dll version.dll wininet.dll winhttp.dll) do (
    if exist "%%F" (
        set "origname="
        for /f "tokens=*" %%P in ('powershell -NoProfile -Command "(Get-Item '%%F').VersionInfo.OriginalFilename"') do (
            set "origname=%%P"
        )
        if /i "!origname!"=="OptiScaler.dll" (
            set "OLD_FILES_FOUND=1"
            set "OPTI_DLL_LIST=!OPTI_DLL_LIST! %%F"
        )
    )
)

if "!OLD_FILES_FOUND!"=="1" (
    echo 警告：检测到可能属于旧版 OptiScaler 的文件！
    if exist nvapi64.dll echo   - nvapi64.dll
    if exist nvngx.dll echo   - nvngx.dll
    if exist OptiScaler.asi echo   - OptiScaler.asi
    if exist "Remove OptiScaler.bat" echo   - Remove OptiScaler.bat
    for %%F in (!OPTI_DLL_LIST!) do echo   - %%F （原始文件名：OptiScaler.dll）
    echo.
    echo 这些文件可能与当前版本的 OptiScaler 冲突。
    echo 建议将它们删除。
    echo.
    set /p "USER_CHOICE=是否删除这些文件？请输入 y 或 n："
    echo.
    if /i "!USER_CHOICE!"=="y" (
        if exist nvapi64.dll (
            del nvapi64.dll
            echo 已删除 nvapi64.dll
        )
        if exist nvngx.dll (
            del nvngx.dll
            echo 已删除 nvngx.dll
        )
        if exist OptiScaler.asi (
            del OptiScaler.asi
            echo 已删除 OptiScaler.asi
        )
        if exist "Remove OptiScaler.bat" (
            del "Remove OptiScaler.bat"
            echo 已删除 Remove OptiScaler.bat
        )
        for %%F in (!OPTI_DLL_LIST!) do (
            del "%%F"
            echo 已删除 %%F
        )
        echo 完成！
    ) else (
        echo 已跳过删除。请注意，这些文件可能引发问题。
    )
    echo.
)

REM Set paths based on current directory
set "gamePath=%~dp0"
set "optiScalerFile=%gamePath%\OptiScaler.dll"
set setupSuccess=false

REM Check if the Engine folder exists
if exist "%gamePath%\Engine" (
    echo 检测到 Engine 文件夹。如果这是虚幻引擎游戏，请将 OptiScaler 解压到 #CODENAME#\Binaries\Win64
    echo.
    
    set /p continueChoice="是否仍安装到当前文件夹？请输入 y 或 n："
    set continueChoice=!continueChoice: =!

    if "!continueChoice!"=="y" (
        goto selectFilename
    )

    goto end
)

REM Prompt user to select a filename for OptiScaler
:selectFilename
echo.
echo 请选择 OptiScaler 使用的文件名（默认 dxgi.dll，兼容性最佳）：
echo （Vulkan 游戏请使用 winmm.dll；XGP/MS Store 游戏使用 winmm.dll 或 version.dll 可能更合适）
echo.
echo  [1] dxgi.dll
echo  [2] winmm.dll
echo  [3] version.dll
echo  [4] dbghelp.dll
echo  [5] d3d12.dll
echo  [6] wininet.dll
echo  [7] winhttp.dll
echo  [8] OptiScaler.asi
echo.
set /p filenameChoice="请输入 1-8（直接按 Enter 使用默认值）："

if "%filenameChoice%"=="" (
    set selectedFilename="dxgi.dll"
) else if "%filenameChoice%"=="1" (
    set selectedFilename="dxgi.dll"
) else if "%filenameChoice%"=="2" (
    set selectedFilename="winmm.dll"
) else if "%filenameChoice%"=="3" (
    set selectedFilename="version.dll"
) else if "%filenameChoice%"=="4" (
    set selectedFilename="dbghelp.dll"
) else if "%filenameChoice%"=="5" (
    set selectedFilename="d3d12.dll"
) else if "%filenameChoice%"=="6" (
    set selectedFilename="wininet.dll"
) else if "%filenameChoice%"=="7" (
    set selectedFilename="winhttp.dll"
) else if "%filenameChoice%"=="8" (
    set selectedFilename="OptiScaler.asi"
) else (
    echo 选择无效，请输入有效选项。
    echo.
    goto selectFilename
)

if exist %selectedFilename% (
    echo.
    echo 警告：当前文件夹中已存在 %selectedFilename%。
    echo.
    set /p overwriteChoice="是否覆盖 %selectedFilename%？请输入 y 或 n："
    set overwriteChoice=!overwriteChoice: =!
    
    echo.
    if "!overwriteChoice!"=="y" (
        goto checkWine
    )

    goto selectFilename
)

REM Wine doesn't support powershell
:checkWine
reg query HKEY_CURRENT_USER\Software\Wine >nul 2>&1
if %errorlevel%==0 (
    echo.
    echo 检测到 Wine，跳过显卡伪装检查。
    echo 如有需要，可在配置中设置 Dxgi=false 来禁用伪装。
    echo.
    call :pause_zh
    goto completeSetup
) 

if exist %windir%\system32\nvapi64.dll (
    echo.
    echo 检测到 NVIDIA 驱动文件。
    set isNvidia=true
) else (
    set isNvidia=false
)

REM Query user for GPU type
echo.
echo 你使用的是 NVIDIA GPU，还是 AMD/Intel GPU？
echo [1] AMD/Intel（AMD Radeon RX 9070 XT 请选择此项）
echo [2] NVIDIA
echo.

:gpuPrompt
if "%isNvidia%"=="true" (
    set /p gpuChoice="请输入 1 或 2（检测结果：NVIDIA）："
) else (
    set /p gpuChoice="请输入 1 或 2（检测结果：AMD/Intel）："
)

if "%gpuChoice%"=="1" goto gpuValid
if "%gpuChoice%"=="2" goto gpuValid
echo 输入无效，请输入 1 或 2。
echo.
goto gpuPrompt

:gpuValid

REM Skip spoofing if Nvidia
if "%gpuChoice%"=="2" (
    goto completeSetup
)

REM Query user for DLSS
echo.
echo 是否要使用游戏的 DLSS 接口并替换为 FSR/XeSS？（将启用 NVIDIA 显卡伪装；DLSS-FG 与 Reflex-^>AL2 需要此项）
echo 如需稍后更改，请编辑 OptiScaler.ini；设置 Dxgi=false 可禁用伪装，改回 auto 可重新启用。
echo.
echo [1] 是（推荐 AMD Radeon RX 9070 XT 使用）
echo [2] 否
echo.
set /p enablingSpoofing="请输入 1 或 2（直接按 Enter 默认为“是”）："

set configFile=OptiScaler.ini
if "%enablingSpoofing%"=="2" (
    if not exist "%configFile%" (
        echo 找不到配置文件：%configFile%
        call :pause_zh
    )

    powershell -Command "(Get-Content '%configFile%') -replace 'Dxgi=auto', 'Dxgi=false' | Set-Content '%configFile%'"
)

REM Decide whether to run OptiPatcher
echo.
if "%gpuChoice%"=="1" (
    echo 检测到 AMD/Intel GPU，正在检查 OptiPatcher。
    goto checkExistingOptiPatcher
)

:checkExistingOptiPatcher
set "foundOptiPatcher="
for %%F in (plugins\*OptiPatcher*.asi) do (
    set "foundOptiPatcher=%%F"
)

if defined foundOptiPatcher (
    echo.
    echo 已找到 OptiPatcher：!foundOptiPatcher!
    echo 如果现有版本运行正常，建议保留当前版本。
    set /p optiRedownload="是否重新下载可能更新的版本？请输入 y 或 n："
        
    if /i "!optiRedownload!"=="y" (
        echo.
        echo 正在删除 !foundOptiPatcher!……
        del "!foundOptiPatcher!"
        goto checkOptiPatcher
    ) else (
        echo.
        echo 保留现有 OptiPatcher，跳过下载。
        goto completeSetup
    )
)

REM Not installed - continue to download
goto checkOptiPatcher

:checkOptiPatcher
REM Check connectivity
echo.
echo 正在检查 OptiPatcher 兼容性……
echo 如果长时间没有响应，可按 Ctrl+C 跳过检查并继续完成安装。

ping -n 1 -w 3000 github.com >nul 2>&1
if %errorlevel% neq 0 (
    echo 当前离线或无法访问 GitHub，跳过 OptiPatcher 检查。
    goto completeSetup
)

set "OPTI_MATCH=NO"
for /f "usebackq tokens=*" %%A in (`powershell -Command "& { $rawUrl = 'https://raw.githubusercontent.com/optiscaler/OptiPatcher/main/OptiPatcher/dllmain.cpp'; try { $code = (Invoke-WebRequest -Uri $rawUrl -UseBasicParsing).Content } catch { return 'ERR' }; $supported = @(); $ueMatches = [Regex]::Matches($code, 'CHECK_UE\s*\(\s*([a-zA-Z0-9_]+)\s*\)'); foreach ($m in $ueMatches) { $base = $m.Groups[1].Value; $supported += ($base + '-win64-shipping.exe').ToLower(); $supported += ($base + '-wingdk-shipping.exe').ToLower(); }; $directMatches = [Regex]::Matches($code, 'exeName\s*==\s*[\x22\x27]([^\x22\x27]+)[\x22\x27]'); foreach ($m in $directMatches) { $supported += $m.Groups[1].Value.ToLower(); }; $localFiles = Get-ChildItem *.exe | Select-Object -ExpandProperty Name; foreach ($file in $localFiles) { if ($supported -contains $file.ToLower()) { Write-Output 'YES'; exit; } }; Write-Output 'NO'; }"`) do (
    set "OPTI_MATCH=%%A"
)

if "!OPTI_MATCH!"=="YES" (
    echo.
    echo 检测到游戏受 OptiPatcher 支持！
    echo 此 Opti 插件可在受支持的游戏中解锁 DLSS/DLSS-FG 输入，并避免显卡伪装及其性能开销。
    echo 更多信息请查看 OptiPatcher GitHub 页面。
    echo.
    set /p downloadOptiPatcher="是否下载 OptiPatcher.asi？请输入 y 或 n："
    set downloadOptiPatcher=!downloadOptiPatcher: =!
    
    if "!downloadOptiPatcher!"=="y" (
        echo.
        echo 正在准备 plugins 文件夹……
        if not exist "plugins" mkdir "plugins"
        
        echo 正在下载 OptiPatcher……
        echo 如果长时间没有响应，可按 Ctrl+C 跳过下载并继续完成安装。
        echo.
        powershell -Command "Invoke-WebRequest -Uri 'https://github.com/optiscaler/OptiPatcher/releases/download/rolling/OptiPatcher.asi' -OutFile 'plugins\OptiPatcher.asi'" >nul 2>&1
        if errorlevel 1 (
            echo OptiPatcher.asi 下载失败，跳过安装此插件。
            goto completeSetup
        )
        
        if exist "plugins\OptiPatcher.asi" (
            echo OptiPatcher.asi 下载成功。
            echo 正在 OptiScaler.ini 中启用 ASI 加载……
            if exist "%configFile%" (
                powershell -Command "(Get-Content '%configFile%') -replace 'LoadAsiPlugins=auto', 'LoadAsiPlugins=true' | Set-Content '%configFile%'"
                echo 已在 OptiScaler.ini 中启用 ASI 加载！
            ) else (
                echo 警告：找不到 OptiScaler.ini，无法启用 LoadAsiPlugins。
            )
        ) else (
            echo OptiPatcher.asi 下载失败。
        )
     timeout /t 3 >nul
    )
)
echo.

goto completeSetup

:completeSetup
REM Rename OptiScaler file
echo.
if "!overwriteChoice!"=="y" (
    echo 正在删除旧的 %selectedFilename%……
    del /F %selectedFilename% >nul 2>&1
)

echo 正在将 OptiScaler 文件重命名为 %selectedFilename%……
rename "%optiScalerFile%" %selectedFilename% >nul 2>&1
if errorlevel 1 (
    echo.
    echo 错误：无法将 OptiScaler 文件重命名为 %selectedFilename%，很可能是文件夹权限问题。
    echo 请手动将 OptiScaler.dll 重命名为 %selectedFilename%！完成后无需再次运行安装脚本。
    echo.
    goto end
)

goto create_uninstaller

:create_uninstaller_return

cls
echo  OptiScaler 安装成功……
echo.
echo   ___                 
echo  (_         '        
echo  /__  /)   /  () (/  
echo          _/      /    
echo.

set setupSuccess=true

:end
call :pause_zh

endlocal & set "_SETUP_SUCCESS=%setupSuccess%"

if "%_SETUP_SUCCESS%"=="true" (
    del "setup_linux.sh" >nul 2>&1
    endlocal
    exit /b 42
)

endlocal
exit /b

:pause_zh
echo.
echo 请按任意键继续 . . .
>nul pause
exit /b

:create_uninstaller
setlocal DisableDelayedExpansion

(
echo @echo off
echo if defined OPTISCALER_REMOVE_UTF8_READY goto utf8_main
echo setlocal EnableExtensions DisableDelayedExpansion
echo for /f "tokens=2 delims=:" %%%%A in ^('chcp'^) do set "_OPTI_OLD_CP=%%%%A"
echo set "_OPTI_OLD_CP=%%_OPTI_OLD_CP: =%%"
echo chcp 65001 ^>nul
echo set "OPTISCALER_REMOVE_UTF8_READY=1"
echo "%%ComSpec%%" /d /c call "%%~f0"
echo set "_OPTI_UTF8_EXIT=%%errorlevel%%"
echo chcp %%_OPTI_OLD_CP%% ^>nul
echo if not "%%_OPTI_UTF8_EXIT%%"=="42" goto utf8_wrapper_return
echo set "_OPTI_DELETE_TARGET=%%~f0"
echo start "" /b powershell.exe -NoProfile -WindowStyle Hidden -Command "Start-Sleep -Milliseconds 1500; Remove-Item -LiteralPath $env:_OPTI_DELETE_TARGET -Force -ErrorAction SilentlyContinue" ^>nul 2^>^&1
echo endlocal
echo exit /b 0
echo.
echo :utf8_wrapper_return
echo endlocal ^& exit /b %%_OPTI_UTF8_EXIT%%
echo.
echo :utf8_main
echo setlocal EnableExtensions EnableDelayedExpansion
echo cls
echo echo  ::::::::  :::::::::  ::::::::::: :::::::::::  ::::::::   ::::::::      :::     :::        :::::::::: :::::::::  
echo echo :+:    :+: :+:    :+:     :+:         :+:     :+:    :+: :+:    :+:   :+: :+:   :+:        :+:        :+:    :+: 
echo echo +:+    +:+ +:+    +:+     +:+         +:+     +:+        +:+         +:+   +:+  +:+        +:+        +:+    +:+ 
echo echo +#+    +:+ +#++:++#+      +#+         +#+     +#++:++#++ +#+        +#++:++#++: +#+        +#++:++#   +#++:++#:  
echo echo +#+    +#+ +#+            +#+         +#+            +#+ +#+        +#+     +#+ +#+        +#+        +#+    +#+ 
echo echo #+#    #+# #+#            #+#         #+#     #+#    #+# #+#    #+# #+#     #+# #+#        #+#        #+#    #+# 
echo echo  ########  ###            ###     ###########  ########   ########  ###     ### ########## ########## ###    ### 
echo echo.
echo echo 这次一定能行……
echo echo v2.75 - 现已支持 OptiPatcher
echo echo.
echo REM Check if OptiScaler installation exists
echo set "OLD_FILES_FOUND=0"
echo set "OPTI_DLL_LIST="
echo if exist OptiScaler.asi set "OLD_FILES_FOUND=1"

echo for %%%%F in ^(dxgi.dll winmm.dll d3d12.dll dbghelp.dll version.dll wininet.dll winhttp.dll^) do ^(
echo     if exist "%%%%F" ^(
echo         set "origname="
echo         for /f "tokens=*" %%%%P in ^('powershell -NoProfile -Command "(Get-Item '%%%%F').VersionInfo.OriginalFilename"'^) do ^(
echo             set "origname=%%%%P"
echo         ^)
echo         if /i "!origname!"=="OptiScaler.dll" ^(
echo             set "OLD_FILES_FOUND=1"
echo             set "OPTI_DLL_LIST=!OPTI_DLL_LIST! %%%%F"
echo         ^)
echo     ^)
echo ^)

echo if "!OLD_FILES_FOUND!"=="1" ^(
echo     echo 检测到现有的 OptiScaler 安装！
echo     if exist OptiScaler.asi echo   - OptiScaler.asi
echo     for %%%%F in ^(!OPTI_DLL_LIST!^) do echo   - %%%%F （原始文件名：OptiScaler.dll）
echo     echo.
echo ^)

echo set /p removeChoice="是否卸载 OptiScaler？请输入 y 或 n："
echo echo.

echo if "%%removeChoice%%"=="y" ^(
echo     del OptiScaler.log ^>nul 2^>^&1
echo     del OptiScaler.ini ^>nul 2^>^&1
echo     del OptiScaler.asi ^>nul 2^>^&1
echo     del fakenvapi.dll ^>nul 2^>^&1
echo     del fakenvapi.ini ^>nul 2^>^&1
echo     del fakenvapi.log ^>nul 2^>^&1
echo     del dlssg_to_fsr3_amd_is_better.dll ^>nul 2^>^&1
echo     del dlssg_to_fsr3.log ^>nul 2^>^&1
echo     del /Q D3D12_Optiscaler\* ^>nul 2^>^&1
echo     rd D3D12_Optiscaler ^>nul 2^>^&1
echo     del /Q DlssOverrides\* ^>nul 2^>^&1
echo     rd DlssOverrides ^>nul 2^>^&1
echo     del /Q Licenses\* ^>nul 2^>^&1
echo     rd Licenses ^>nul 2^>^&1
echo     for %%%%F in ^(!OPTI_DLL_LIST!^) do ^(del "%%%%F" ^>nul 2^>^&1^)
echo     echo.
echo     echo 正在删除 OptiPatcher（如果存在）……
echo     del plugins\OptiPatcher.asi ^>nul 2^>^&1
echo     rd plugins ^>nul 2^>^&1
echo     echo.
echo     echo OptiScaler 已卸载！
echo     echo.
echo ^) else ^(
echo     echo.
echo     echo 操作已取消。
echo     echo.
echo ^)

echo.
echo echo 请按任意键退出 . . .
echo ^>nul pause
echo if "%%removeChoice%%"=="y" ^(
echo     endlocal
echo     exit /b 42
echo ^)
echo endlocal
echo exit /b 0
) > "Remove OptiScaler.bat"

endlocal
echo.
echo 卸载器已创建。
echo.

goto create_uninstaller_return
