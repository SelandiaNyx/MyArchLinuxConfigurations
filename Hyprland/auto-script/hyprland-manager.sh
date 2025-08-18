#!/usr/bin/env bash
# ============================================================================
# hyprland-manager.sh - 自动化 Hyprland 配置管理器
# ============================================================================

CONFIG_FILE="$HOME/.config/hypr/hyprland.conf"
BACKUP_DIR="$HOME/backups/hyprland"
mkdir -p "$BACKUP_DIR"

backup_config() {
    cp "$CONFIG_FILE" "$BACKUP_DIR/hyprland.conf.$(date +%Y%m%d_%H%M%S)"
}

update_or_add() {
    local key="$1"
    local value="$2"
    if grep -q "^$key" "$CONFIG_FILE"; then
        sed -i "s|^$key.*|$key = $value|" "$CONFIG_FILE"
    else
        echo "$key = $value" >> "$CONFIG_FILE"
    fi
    echo "已更新: $key = $value"
}

menu_main() {
    while true; do
        option=$(printf "显示器配置\n程序变量\n自启动\n外观设置\n输入设备\n快捷键\n窗口规则\n备份配置\n退出" | fzf --prompt "选择要修改的项目: ")
        case $option in
            显示器配置) set_monitor ;;
            程序变量) set_programs ;;
            自启动) set_autostart ;;
            外观设置) set_appearance ;;
            输入设备) set_input ;;
            快捷键) set_keybinds ;;
            窗口规则) set_windowrules ;;
            备份配置) backup_config ;;
            退出) break ;;
        esac
    done
}

set_monitor() {
    current=$(grep '^monitor' "$CONFIG_FILE")
    echo "当前配置: $current"
    read -rp "请输入新的显示器配置 (示例: monitor=,preferred,auto,auto): " new
    update_or_add "monitor" "$new"
    hyprctl reload
}

set_programs() {
    current=$(grep '^\$terminal' "$CONFIG_FILE")
    echo "当前终端: $current"
    read -rp "请输入终端程序: " term
    update_or_add "\$terminal" "$term"

    current=$(grep '^\$fileManager' "$CONFIG_FILE")
    echo "当前文件管理器: $current"
    read -rp "请输入文件管理器: " fm
    update_or_add "\$fileManager" "$fm"

    current=$(grep '^\$menu' "$CONFIG_FILE")
    echo "当前菜单: $current"
    read -rp "请输入启动器: " menu
    update_or_add "\$menu" "$menu"
    hyprctl reload
}

set_autostart() {
    echo "当前自启动:"
    grep '^exec-once' "$CONFIG_FILE"
    read -rp "请输入自启动命令: " cmd
    echo "exec-once = $cmd" >> "$CONFIG_FILE"
    echo "已添加: exec-once = $cmd"
    hyprctl reload
}

set_appearance() {
    current=$(grep 'col.active_border' "$CONFIG_FILE")
    echo "当前边框颜色: $current"
    read -rp "请输入新的边框颜色 (示例: rgba(33ccffee) rgba(00ff99ee) 45deg): " border
    sed -i "s|col.active_border.*|col.active_border = $border|" "$CONFIG_FILE"
    hyprctl reload
}

set_input() {
    current=$(grep 'kb_layout' "$CONFIG_FILE")
    echo "当前键盘布局: $current"
    read -rp "请输入新的键盘布局 (如 us / jp): " layout
    sed -i "s|kb_layout.*|kb_layout = $layout|" "$CONFIG_FILE"
    hyprctl reload
}

set_keybinds() {
    echo "当前快捷键:"
    grep '^bind' "$CONFIG_FILE"
    read -rp "请输入新的快捷键 (如: bind = SUPER, X, exec, kitty): " kb
    echo "$kb" >> "$CONFIG_FILE"
    hyprctl reload
}

set_windowrules() {
    echo "当前窗口规则:"
    grep '^windowrule' "$CONFIG_FILE"
    read -rp "请输入新的窗口规则: " wr
    echo "windowrule = $wr" >> "$CONFIG_FILE"
    hyprctl reload
}

menu_main
