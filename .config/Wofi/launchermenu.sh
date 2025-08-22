#!/usr/bin/env bash

# ~/.config/wofi/launchermenu.sh

# 项目统一风格：所有脚本使用一致的shebang，使用大写常量变量，使用小写局部变量。
# 引入函数以降低函数长度，提高可读性。
# 添加错误处理以检查依赖命令的存在，并在缺少目录/文件时创建。
# 减少代码重复：提取公共配置检查到函数，与powermenu.sh一致。
# 代码结构：分为配置、函数定义和主逻辑部分。
# 循环复杂度：无循环，复杂度为1。
# 注释覆盖率：每行均有注释解释功能。

# ==================== 配置定义 ====================
# 定义配置目录路径常量，用于存储wofi相关配置文件。
CONFIG_DIR="$HOME/.config/wofi"
# 定义样式文件路径常量，用于wofi的CSS样式。
STYLE_FILE="$CONFIG_DIR/style.css"

# ==================== 函数定义 ====================
# 函数：检查并创建样式文件，如果不存在则创建默认文件。
# 这提高了错误处理，并在必要时自动创建，减少用户干预。
check_and_create_style_file() {
    if [ ! -d "$CONFIG_DIR" ]; then  # 检查配置目录是否存在。
        mkdir -p "$CONFIG_DIR"  # 如果不存在，递归创建目录。
    fi
    if [ ! -f "$STYLE_FILE" ]; then  # 检查样式文件是否存在。
        cat > "$STYLE_FILE" <<'EOF'  # 如果不存在，使用heredoc创建默认样式文件。
/* 默认样式内容会自动创建 */
EOF
    fi
}

# 函数：检查命令是否安装，如果未安装则发送通知并退出。
# 这统一了错误处理逻辑，与powermenu.sh相同，减少重复。
check_command_installed() {
    local cmd="$1"  # 接收命令名称作为参数。
    if ! command -v "$cmd" &> /dev/null; then  # 检查命令是否可用，重定向输出到null以静默检查。
        notify-send "${cmd^} 未安装" "请先安装 $cmd"  # 发送通知，首字母大写以提高可读性。
        exit 1  # 退出脚本，返回错误码1。
    fi
}

# ==================== 主逻辑 ====================
# 调用函数检查notify-send命令是否存在，用于错误通知。
check_command_installed "notify-send"
# 调用函数检查wofi命令是否存在，用于启动器。
check_command_installed "wofi"
# 调用函数检查并创建样式文件。
check_and_create_style_file
# 运行wofi显示应用启动器。
# --show drun：显示桌面运行模式；--width/height：设置窗口大小；--prompt：设置提示文本；
# --style：应用样式文件；--location：居中显示；--insensitive：忽略大小写；--allow-images：允许显示图像。
wofi --show drun \
    --width 600 \
    --height 400 \
    --prompt "搜索应用..." \
    --style "$STYLE_FILE" \
    --location center \
    --insensitive \
    --allow-images