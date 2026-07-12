#!/usr/bin/env bash

show_help() {
    echo ""
    echo "用法：$0 [选项]"
    echo ""
    echo "选项："
    echo "  --filename=<string>        设置 OptiScaler.dll 的目标文件名，可选值："
    echo "                            - dxgi.dll"
    echo "                            - winmm.dll"
    echo "                            - version.dll"
    echo "                            - dbghelp.dll"
    echo "                            - d3d12.dll"
    echo "                            - wininet.dll"
    echo "                            - winhttp.dll"
    echo "                            - OptiScaler.asi"
    echo ""
    echo "  --overwrite=<y|n>       是否覆盖现有文件（y/n）"
    echo "  --using_nvidia=<y|n>    是否使用 NVIDIA GPU（y/n）"
    echo "  --using_dlss=<y|n>      是否使用 DLSS 输入/显卡伪装（y/n）"
    echo "  -h, --help              显示此帮助信息"
    echo ""
    echo "示例："
    echo "  $0 --filename=dxgi.dll --overwrite=y --using_nvidia=n --using_dlss=y"
    echo ""
    exit 0
}

for arg in "$@"; do
    case "$arg" in
        -h|--help) show_help ;;
        --filename=*) selected_filename="${arg#*=}" ;;
        --overwrite=*) overwrite_choice="${arg#*=}" ;;
        --using_nvidia=*) using_nvidia="${arg#*=}" ;;
        --using_dlss=*) using_dlss="${arg#*=}" ;;
    esac
done
clear

echo " ::::::::  :::::::::  ::::::::::: :::::::::::  ::::::::   ::::::::      :::     :::        :::::::::: :::::::::  "
echo ":+:    :+: :+:    :+:     :+:         :+:     :+:    :+: :+:    :+:   :+: :+:   :+:        :+:        :+:    :+: "
echo "#+:    +:+ +:+    +:+     +:+         +:+     +:+        +:+         +:+   +:+  +:+        +:+        +:+    +:+ "
echo "+#+    +:+ +#++:++#+      +#+         +#+     +#++:++#++ +#+        +#++:++#++: +#+        +#++:++#   +#++:++#:  "
echo "+#+    +#+ +#+            +#+         +#+            +#+ +#+        +#+     +#+ +#+        +#+        +#+    +#+ "
echo "#+#    #+# #+#            #+#         #+#     #+#    #+# #+#    #+# #+#     #+# #+#        #+#        #+#    #+# "
echo " ########  ###            ###     ###########  ########   ########  ###     ### ########## ########## ###    ### "
echo ""
echo "这次一定能行……"
echo ""

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPTISCALER_FILE="$SCRIPT_DIR/OptiScaler.dll"

# Remove junk files
rm -f "$SCRIPT_DIR/!! EXTRACT ALL FILES TO GAME FOLDER !!" 2>/dev/null
rm -f "$SCRIPT_DIR/setup_windows.bat" 2>/dev/null

# Check if OptiScaler.dll exists
if [ ! -f "OptiScaler.dll" ]; then
    echo "未找到 OptiScaler 文件 \"OptiScaler.dll\"！"
    echo "请确认已将 OptiScaler 的全部文件解压到游戏文件夹。"
    echo ""
    echo "对于虚幻引擎游戏，请在以下位置查找游戏可执行文件："
    echo "- <path-to-game>/Game-or-Project-name/Binaries/Win64/"
    echo "- 请忽略 Engine 文件夹"
    echo ""
    read -p "请按 Enter 键退出……"
    exit 1
fi

# Unreal Engine detection (skip for headless)
if [ -d "$SCRIPT_DIR/Engine" ] && [ -z "$selected_filename" ]; then
    echo "检测到 Engine 文件夹。如果这是虚幻引擎游戏，请将 OptiScaler 解压到 #CODENAME#/Binaries/Win64。"
    echo ""

    while true; do
        read -p "是否仍安装到当前文件夹？请输入 y 或 n：" continue_choice
        continue_choice=$(echo "$continue_choice" | tr -d ' ')

        if [ "$continue_choice" = "y" ] || [ "$continue_choice" = "Y" ]; then
            break
        elif [ "$continue_choice" = "n" ] || [ "$continue_choice" = "N" ]; then
            echo "安装已取消。"
            read -p "请按 Enter 键退出……"
            exit 0
        fi
    done
fi

select_filename() {
    # Skip if filename already set and valid
    if [ -n "$selected_filename" ]; then
        case "$selected_filename" in
            dxgi.dll|winmm.dll|version.dll|dbghelp.dll|d3d12.dll|wininet.dll|winhttp.dll|OptiScaler.asi)
                return
                ;;
            *)
                echo "无效的文件名：$selected_filename"
                exit 1
                ;;
        esac
    fi
    
    while true; do
        echo ""
        echo "请选择 OptiScaler 使用的文件名（默认 dxgi.dll，兼容性最佳）："
        echo "（Vulkan 游戏建议使用 winmm.dll）"
        echo " [1] dxgi.dll"
        echo " [2] winmm.dll"
        echo " [3] version.dll"
        echo " [4] dbghelp.dll"
        echo " [5] d3d12.dll"
        echo " [6] wininet.dll"
        echo " [7] winhttp.dll"
        echo " [8] OptiScaler.asi"

        read -p "请输入 1-8（直接按 Enter 使用默认值）：" filename_choice

        case "$filename_choice" in
            ""|"1")
                selected_filename="dxgi.dll"
                ;;
            "2")
                selected_filename="winmm.dll"
                ;;
            "3")
                selected_filename="version.dll"
                ;;
            "4")
                selected_filename="dbghelp.dll"
                ;;
            "5")
                selected_filename="d3d12.dll"
                ;;
            "6")
                selected_filename="wininet.dll"
                ;;
            "7")
                selected_filename="winhttp.dll"
                ;;
            "8")
                selected_filename="OptiScaler.asi"
                ;;
            *)
                clear
                echo "选择无效，请输入有效选项。"
                echo ""
                continue
                ;;
        esac

        # Check if file already exists
        if [ -f "$selected_filename" ]; then
            echo ""
            echo "警告：当前文件夹中已存在 $selected_filename。"
            echo ""
            
            if [ -n "$overwrite_choice" ]; then
                if [[ "$overwrite_choice" =~ ^(yes|y)$ ]]; then
                    break
                else
                    echo "文件已存在，且 overwrite_choice=$overwrite_choice；正在退出。"
                    exit 1
                fi
            fi

            while true; do
                read -p "是否覆盖此文件？请输入 y 或 n：" overwrite_choice
                overwrite_choice=${overwrite_choice,,} 

                if [[ "$overwrite_choice" =~ ^(yes|y)$ ]]; then
                    break 2  # Break out of both loops
                elif [[ "$overwrite_choice" =~ ^(no|n)$ ]]; then
                    clear
                    break  # Break out of the inner loop, continue filename selection
                else
                    clear
                    echo "选择无效，请输入 y 或 n。"
                fi
            done
	    else
            break  # File doesn't exist, proceed
        fi
    done
}

select_filename

# Try to detect Nvidia
NVIDIA_DETECTED=false
if command -v nvidia-smi >/dev/null 2>&1; then
    if nvidia-smi >/dev/null 2>&1; then
        NVIDIA_DETECTED=true
        echo "检测到 NVIDIA GPU。"
    fi
fi

while [ -z "$using_nvidia" ]; do
    echo ""
    echo "AMD Radeon RX 9070 XT 属于 AMD，请选择 n。"
    if [ "$NVIDIA_DETECTED" = true ]; then
        default_value="y"
        read -r -p "你使用的是 NVIDIA GPU 吗？[Y/n]：" using_nvidia
    else
        default_value="n"
        read -r -p "你使用的是 NVIDIA GPU 吗？[y/N]：" using_nvidia
    fi

    using_nvidia=${using_nvidia,,}
    using_nvidia=${using_nvidia:-$default_value}
    
    if [[ "$using_nvidia" =~ ^(no|n)$ ]]; then
        while [ -z "$using_dlss" ]; do
            echo ""
            echo "AMD Radeon RX 9070 XT 推荐启用此项。"
            read -r -p "是否使用游戏的 DLSS 输入？（会启用显卡伪装；DLSS-FG 与 Reflex→AL2 需要此项）[Y/n]：" using_dlss

            using_dlss=${using_dlss,,}
            using_dlss=${using_dlss:-y}

            if [[ "$using_dlss" =~ ^(no|n)$ ]]; then
                # Disable spoofing
                config_file="OptiScaler.ini"
                if [ ! -f "$config_file" ]; then
                    echo "找不到配置文件：$config_file"
                    read -p "请按 Enter 键继续……"
                else
                    # Use sed to replace Dxgi=auto with Dxgi=false
                    sed -i 's/Dxgi=auto/Dxgi=false/g' "$config_file"
                    echo "已在配置中禁用显卡伪装。"
                fi
                break
            elif [[ "$using_dlss" =~ ^(yes|y)$ ]]; then
                break
            else
                echo "选择无效，请输入 y 或 n。"
                continue
            fi
        done
        break
    elif [[ "$using_nvidia" =~ ^(yes|y)$ ]]; then
        break
    else
        echo "选择无效，请输入 y 或 n。"
        continue
    fi
done

# Rename OptiScaler file
echo ""
if [ "$overwrite_choice" = "y" ] || [ "$overwrite_choice" = "Y" ]; then
    echo "正在删除旧的 $selected_filename……"
    rm -f "$selected_filename"
fi

echo "正在将 OptiScaler 文件重命名为 $selected_filename……"
if ! mv "$OPTISCALER_FILE" "$selected_filename"; then
    echo ""
    echo "错误：无法将 OptiScaler 文件重命名为 $selected_filename。"
    echo "请检查文件权限后重试。"
    read -p "请按 Enter 键退出……"
    exit 1
fi

# Create uninstaller
create_uninstaller() {
    cat > "remove_optiscaler.sh" << 'EOF'
#!/usr/bin/env bash

show_help() {
    echo ""
    echo "用法：$0 [选项]"
    echo ""
    echo "选项："
    echo "  --remove=<y|n>    确认是否卸载（y/n）"
    echo "  -h, --help        显示此帮助信息"
    echo ""
    exit 0
}

for arg in "$@"; do
    case "$arg" in
        -h|--help) show_help ;;
        --remove=*) remove_choice="${arg#*=}" ;;
    esac
done

clear
echo " ::::::::  :::::::::  ::::::::::: :::::::::::  ::::::::   ::::::::      :::     :::        :::::::::: :::::::::  "
echo ":+:    :+: :+:    :+:     :+:         :+:     :+:    :+: :+:    :+:   :+: :+:   :+:        :+:        :+:    :+: "
echo "#+:    +:+ +:+    +:+     +:+         +:+     +:+        +:+         +:+   +:+  +:+        +:+        +:+    +:+ "
echo "+#+    +:+ +#++:++#+      +#+         +#+     +#++:++#++ +#+        +#++:++#++: +#+        +#++:++#   +#++:++#:  "
echo "+#+    +#+ +#+            +#+         +#+            +#+ +#+        +#+     +#+ +#+        +#+        +#+    +#+ "
echo "#+#    #+# #+#            #+#         #+#     #+#    #+# #+#    #+# #+#     #+# #+#        #+#        #+#    #+# "
echo " ########  ###            ###     ###########  ########   ########  ###     ### ########## ########## ###    ### "
echo ""
echo "这次一定能行……"
echo ""

if [ -z "$remove_choice" ]; then
    read -p "是否卸载 OptiScaler？请输入 y 或 n：" remove_choice
fi

if [ "$remove_choice" = "y" ] || [ "$remove_choice" = "Y" ]; then
    echo ""
    echo "正在删除 OptiScaler 文件……"
    
    # Remove OptiScaler files
    rm -f OptiScaler.log
    rm -f OptiScaler.ini
    rm -f SELECTED_FILENAME_PLACEHOLDER
    rm -f fakenvapi.dll
    rm -f fakenvapi.ini
    rm -f fakenvapi.log
    rm -f dlssg_to_fsr3_amd_is_better.dll
    rm -f dlssg_to_fsr3.log
    
    # Remove directories
    rm -rf D3D12_Optiscaler
    rm -rf DlssOverrides
    rm -rf Licenses
    
    echo ""
    echo "OptiScaler 已卸载！"
    echo ""
    
    # Remove this uninstaller
    rm -f "$0"
else
    echo ""
    echo "操作已取消。"
    echo ""
fi

if [ $# -eq 0 ]; then
    read -p "请按 Enter 键退出……"
fi
EOF

    # Replace the placeholder with the actual selected filename
    sed -i "s/SELECTED_FILENAME_PLACEHOLDER/$selected_filename/g" "remove_optiscaler.sh"
    
    # Make the uninstaller executable
    chmod +x "remove_optiscaler.sh"
    
    echo ""
    echo "卸载器已创建：remove_optiscaler.sh"
    echo ""
}

# Create the uninstaller
create_uninstaller

# Success message
clear
echo " OptiScaler 安装成功……"
echo ""
echo "  ___                 "
echo " (_         '        "
echo " /__  /)   /  () (/  "
echo "         _/      /    "
echo ""

# Display Wine DLL override information
echo "Linux/Wine 用户请注意："
echo "你可能需要将重命名后的 DLL 添加到 Wine 覆盖设置中。"
echo "例如使用 Steam 时，请在启动选项中加入："
echo ""
echo "WINEDLLOVERRIDES=$selected_filename=n,b %COMMAND%"
echo ""
echo "提示：Insert 键可打开 OptiScaler 叠加层，Page Up/Down 键可查看性能统计。"
echo ""

# Cleanup - remove setup script
if [ $# -eq 0 ]; then
    read -p "请按 Enter 键退出……"
fi

rm -f "$0"

exit 0
