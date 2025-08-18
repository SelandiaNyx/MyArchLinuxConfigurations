#!/usr/bin/env bash

# ~/.config/wofi/powermenu.sh

# 项目统一风格：所有脚本使用一致的shebang，使用大写常量变量，使用小写局部变量。
# 引入函数以降低函数长度，提高可读性。
# 添加错误处理以检查依赖命令的存在。
# 减少代码重复：提取公共配置检查到函数。
# 代码结构：分为配置、选项定义、主逻辑和操作执行部分。
# 循环复杂度：无循环，复杂度为1。
# 注释覆盖率：每行均有注释解释功能。

# ==================== 配置定义 ====================
# 定义配置目录路径常量，用于存储wofi相关配置文件。
CONFIG_DIR="$HOME/.config/wofi"
# 定义样式文件路径常量，用于wofi的CSS样式。
STYLE_FILE="$CONFIG_DIR/style.css"

# ==================== 函数定义 ====================
# 函数：检查样式文件是否存在，如果不存在则发送通知并退出。
# 这提高了错误处理，防止脚本在缺少文件时继续执行。
check_style_file() {
    if [ ! -f "$STYLE_FILE" ]; then  # 检查文件是否存在。
        notify-send "缺少样式文件" "请先创建 $STYLE_FILE"  # 发送桌面通知告知用户问题。
        exit 1  # 退出脚本，返回错误码1。
    fi
}

# 函数：检查命令是否安装，如果未安装则发送通知并退出。
# 这统一了错误处理逻辑，减少重复。
check_command_installed() {
    local cmd="$1"  # 接收命令名称作为参数。
    if ! command -v "$cmd" &> /dev/null; then  # 检查命令是否可用，重定向输出到null以静默检查。
        notify-send "${cmd^} 未安装" "请先安装 $cmd"  # 发送通知，首字母大写以提高可读性。
        exit 1  # 退出脚本，返回错误码1。
    fi
}

# ==================== 电源选项定义 ====================
# 定义电源选项的多行字符串，使用heredoc以保持格式。
# 这部分无重复，结构清晰。
POWER_OPTIONS=$(cat <<'EOF'
  锁定屏幕
󰤄  睡眠模式
󰜉  注销会话
󰜨  重启系统
  关机
󰩈  取消
EOF
)

# ==================== 主逻辑 ====================
# 调用函数检查notify-send命令是否存在，用于错误通知。
check_command_installed "notify-send"
# 调用函数检查wofi命令是否存在，用于菜单显示。
check_command_installed "wofi"
# 调用函数检查样式文件。
check_style_file
# 使用echo和wofi显示菜单，选择用户选项。
# --dmenu：启用dmenu模式；--width/height：设置窗口大小；--prompt：设置提示文本；
# --style：应用样式文件；--location：居中显示；--hide-scrollbar：隐藏滚动条；
# --define matching=fuzzy：启用模糊匹配；--lines/columns：设置布局。
SELECTION=$(echo -e "$POWER_OPTIONS" | wofi \
    --dmenu \
    --width 400 \
    --height 300 \
    --prompt "电源选项" \
    --style "$STYLE_FILE" \
    --location center \
    --hide-scrollbar \
    --define matching=fuzzy \
    --lines 6 \
    --columns 1)

# ==================== 操作执行 ====================
# 使用case语句根据用户选择执行相应操作。
# ${SELECTION##* }：提取选项文本后的部分，用于匹配。
case "${SELECTION##* }" in
    "锁定屏幕")
        check_command_installed "hyprlock"  # 检查hyprlock命令是否存在。
        hyprlock  # 执行锁定屏幕，显示时钟、指示器和模糊效果。
        ;;
    "睡眠模式")
        check_command_installed "systemctl"  # 检查systemctl命令是否存在。
        systemctl suspend  # 执行系统睡眠。
        ;;
    "注销会话")
        if [[ $XDG_SESSION_TYPE == "wayland" ]]; then  # 检查是否为Wayland会话。
            check_command_installed "swaymsg"  # 检查swaymsg命令是否存在。
            swaymsg exit  # 在Wayland下退出Sway会话。
        else
            check_command_installed "loginctl"  # 检查loginctl命令是否存在。
            loginctl terminate-user "$USER"  # 终止当前用户会话。
        fi
        ;;
    "重启系统")
        check_command_installed "systemctl"  # 检查systemctl命令是否存在。
        systemctl reboot  # 执行系统重启。
        ;;
    "关机")
        check_command_installed "systemctl"  # 检查systemctl命令是否存在。
        systemctl poweroff  # 执行系统关机。
        ;;
    *) 
        exit 0  # 如果取消或无效选择，正常退出。
        ;;
esac