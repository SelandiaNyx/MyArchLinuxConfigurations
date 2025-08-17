#!/usr/bin/env bash

# ============================================================================
# hyprpaper-manager.sh - Hyprpaper 壁纸管理脚本
# 仅支持 Arch Linux
# 功能：安装 / 卸载 / 备份 / 恢复 / 壁纸设置 / 重载
# 配置文件路径：~/.config/hypr/hyprpaper.conf
# 备份路径：~/backups/hyprpaper/
# ============================================================================

# 定义常量
readonly CONFIG_DIR="$HOME/.config/hypr"
readonly CONFIG_FILE="$CONFIG_DIR/hyprpaper.conf"
readonly BACKUP_DIR="$HOME/backups/hyprpaper"
readonly DEFAULT_WALLPAPER="$HOME/wallpapers/wallpaper1.png"
readonly LOG_FILE="$BACKUP_DIR/hyprpaper.log"

# 日志记录函数
log_action() {
    mkdir -p "$BACKUP_DIR"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# 检查环境
check_environment() {
    if ! command -v pacman &>/dev/null; then
        echo "错误：此脚本仅支持基于 Arch Linux 的系统（需要 pacman）。"
        log_action "环境检查失败：非 Arch Linux 系统"
        exit 1
    fi
    if ! command -v hyprpaper &>/dev/null && [[ "$choice" != "1" ]]; then
        echo "错误：Hyprpaper 未安装，请先选择选项 1 进行安装。"
        log_action "环境检查失败：Hyprpaper 未安装"
        return 1
    fi
    return 0
}

# 菜单函数
show_menu() {
    clear
    echo "========== Hyprpaper 管理器 =========="
    echo "当前壁纸：${WALLPAPER:-未设置}"
    echo "Hyprpaper 状态：$(pgrep -x hyprpaper >/dev/null && echo "运行中" || echo "未运行")"
    echo "1) 安装 Hyprpaper"
    echo "2) 卸载 Hyprpaper"
    echo "3) 生成默认配置"
    echo "4) 选择壁纸"
    echo "5) 备份配置"
    echo "6) 恢复配置"
    echo "7) 重载 Hyprpaper"
    echo "0) 退出"
    echo "====================================="
}

# 安装 Hyprpaper
install_hyprpaper() {
    echo "正在安装 Hyprpaper..."
    if sudo pacman -S --needed hyprpaper >/dev/null 2>&1; then
        echo "安装完成。"
        log_action "Hyprpaper 安装成功"
    else
        echo "错误：安装失败。"
        log_action "Hyprpaper 安装失败"
        return 1
    fi
}

# 卸载 Hyprpaper
uninstall_hyprpaper() {
    echo "正在卸载 Hyprpaper..."
    if sudo pacman -Rns hyprpaper >/dev/null 2>&1; then
        echo "卸载完成。"
        log_action "Hyprpaper 卸载成功"
    else
        echo "错误：卸载失败。"
        log_action "Hyprpaper 卸载失败"
        return 1
    fi
}

# 更新配置文件中的壁纸路径
update_config_wallpaper() {
    local wallpaper_path="$1"
    local monitor="$2"
    if [[ -n "$monitor" ]]; then
        # 为指定显示器更新壁纸
        sed -i "/wallpaper = $monitor,contain:.*/c\wallpaper = $monitor,contain:$wallpaper_path" "$CONFIG_FILE"
        if ! grep -q "preload = $wallpaper_path" "$CONFIG_FILE"; then
            sed -i "/preload = .*/a preload = $wallpaper_path" "$CONFIG_FILE"
        fi
    else
        # 为所有显示器更新单一壁纸
        sed -i "s|wallpaper = .*|wallpaper = ,contain:$wallpaper_path|" "$CONFIG_FILE"
        sed -i "s|preload = .*|preload = $wallpaper_path\nwallpaper = ,contain:$wallpaper_path|" "$CONFIG_FILE"
    fi
    if [[ $? -eq 0 ]]; then
        log_action "配置文件更新：壁纸设置为 $wallpaper_path (显示器: ${monitor:-所有})"
    else
        echo "错误：更新配置文件失败。"
        log_action "配置文件更新失败"
        return 1
    fi
}

# 生成默认配置文件
generate_config() {
    echo "正在生成默认配置..."
    if [[ ! -w "$CONFIG_DIR" ]]; then
        echo "错误：无权限写入 $CONFIG_DIR"
        log_action "生成配置失败：无权限写入 $CONFIG_DIR"
        return 1
    fi
    mkdir -p "$CONFIG_DIR"
    # 获取显示器列表
    local monitors
    monitors=$(hyprctl monitors | grep 'Monitor' | awk '{print $2}' | sort -u)
    if [[ -z "$monitors" ]]; then
        echo "错误：未检测到显示器，请确保 Hyprland 正在运行。"
        log_action "生成配置失败：未检测到显示器"
        return 1
    fi
    > "$CONFIG_FILE"
    echo "# 预加载壁纸文件到内存" >> "$CONFIG_FILE"
    echo "preload = $WALLPAPER" >> "$CONFIG_FILE"
    echo "# 设置指定显示器的壁纸" >> "$CONFIG_FILE"
    echo "# 使用 hyprctl monitors 查看显示器名称" >> "$CONFIG_FILE"
    for monitor in $monitors; do
        echo "wallpaper = $monitor,contain:$WALLPAPER" >> "$CONFIG_FILE"
    done
    echo "# 禁用 IPC 功能以减少后台轮询" >> "$CONFIG_FILE"
    echo "ipc = off" >> "$CONFIG_FILE"
    if [[ $? -eq 0 ]]; then
        echo "默认配置已生成：$CONFIG_FILE"
        log_action "默认配置生成：$CONFIG_FILE"
    else
        echo "错误：生成配置文件失败。"
        log_action "生成配置失败"
        return 1
    fi
}

# 重载 Hyprpaper
reload_hyprpaper() {
    echo "正在重载 Hyprpaper..."
    if pgrep -x "hyprpaper" >/dev/null; then
        if pkill -x hyprpaper; then
            for i in {1..20}; do
                if ! pgrep -x "hyprpaper" >/dev/null; then
                    break
                fi
                sleep 0.1
            done
            if pgrep -x "hyprpaper" >/dev/null; then
                echo "错误：无法终止 Hyprpaper 进程。"
                log_action "重载失败：无法终止 Hyprpaper 进程"
                return 1
            fi
        else
            echo "错误：终止 Hyprpaper 进程失败。"
            log_action "重载失败：终止 Hyprpaper 进程失败"
            return 1
        fi
    fi
    if nohup hyprpaper >/dev/null 2>&1 & then
        sleep 0.5
        if pgrep -x "hyprpaper" >/dev/null; then
            echo "Hyprpaper 已重载。"
            log_action "Hyprpaper 重载成功"
        else
            echo "错误：Hyprpaper 启动失败。"
            log_action "重载失败：Hyprpaper 启动失败"
            return 1
        fi
    else
        echo "错误：Hyprpaper 启动失败。"
        log_action "重载失败：Hyprpaper 启动失败"
        return 1
    fi
}

# 用户选择壁纸
choose_wallpaper() {
    echo "检测到以下显示器："
    local monitors
    monitors=$(hyprctl monitors | grep 'Monitor' | awk '{print $2}' | sort -u)
    if [[ -z "$monitors" ]]; then
        echo "错误：未检测到显示器，请确保 Hyprland 正在运行。"
        log_action "壁纸选择失败：未检测到显示器"
        return 1
    fi
    echo "$monitors" | nl -w1 -s") "
    echo "选择设置壁纸的方式："
    echo "1) 为所有显示器设置单一壁纸"
    echo "2) 为每个显示器设置不同壁纸"
    read -rp "请选择 [1-2]: " mode
    case $mode in
        1)
            echo "请输入壁纸路径（默认：$WALLPAPER）："
            read -r NEW_WALLPAPER
            NEW_WALLPAPER="${NEW_WALLPAPER:-$WALLPAPER}"
            NEW_WALLPAPER=$(realpath "$NEW_WALLPAPER" 2>/dev/null)
            if [[ -f "$NEW_WALLPAPER" ]] && file "$NEW_WALLPAPER" | grep -qE 'image|bitmap'; then
                mkdir -p "$(dirname "$WALLPAPER")"
                if cp "$NEW_WALLPAPER" "$WALLPAPER"; then
                    if [[ -f "$CONFIG_FILE" ]]; then
                        for monitor in $monitors; do
                            update_config_wallpaper "$WALLPAPER" "$monitor"
                        done
                        echo "配置文件已更新：$CONFIG_FILE"
                    else
                        echo "未找到配置文件，自动生成默认配置..."
                        generate_config
                    fi
                    reload_hyprpaper
                    echo "壁纸已更新：$WALLPAPER"
                    log_action "壁纸更新：$WALLPAPER (所有显示器)"
                else
                    echo "错误：复制壁纸失败。"
                    log_action "壁纸复制失败：$NEW_WALLPAPER"
                    return 1
                fi
            else
                echo "错误：无效的图像文件或文件不存在。"
                log_action "壁纸选择失败：无效文件 $NEW_WALLPAPER"
                return 1
            fi
            ;;
        2)
            for monitor in $monitors; do
                echo "请输入显示器 $monitor 的壁纸路径（默认：$WALLPAPER）："
                read -r NEW_WALLPAPER
                NEW_WALLPAPER="${NEW_WALLPAPER:-$WALLPAPER}"
                NEW_WALLPAPER=$(realpath "$NEW_WALLPAPER" 2>/dev/null)
                if [[ -f "$NEW_WALLPAPER" ]] && file "$NEW_WALLPAPER" | grep -qE 'image|bitmap'; then
                    local target_wallpaper="$HOME/wallpapers/wallpaper_$monitor.png"
                    mkdir -p "$(dirname "$target_wallpaper")"
                    if cp "$NEW_WALLPAPER" "$target_wallpaper"; then
                        if [[ -f "$CONFIG_FILE" ]]; then
                            update_config_wallpaper "$target_wallpaper" "$monitor"
                            echo "配置文件已更新：$CONFIG_FILE (显示器 $monitor)"
                        else
                            echo "未找到配置文件，自动生成默认配置..."
                            generate_config
                        fi
                        log_action "壁纸更新：$target_wallpaper (显示器 $monitor)"
                    else
                        echo "错误：复制壁纸失败。"
                        log_action "壁纸复制失败：$NEW_WALLPAPER (显示器 $monitor)"
                        return 1
                    fi
                else
                    echo "错误：无效的图像文件或文件不存在。"
                    log_action "壁纸选择失败：无效文件 $NEW_WALLPAPER (显示器 $monitor)"
                    return 1
                fi
            done
            reload_hyprpaper
            echo "所有显示器的壁纸已更新。"
            ;;
        *)
            echo "无效选项，请重试。"
            log_action "壁纸选择失败：无效选项 $mode"
            return 1
            ;;
    esac
}

# 备份配置
backup_config() {
    echo "正在备份配置..."
    if [[ ! -w "$BACKUP_DIR" ]]; then
        echo "错误：无权限写入 $BACKUP_DIR"
        log_action "备份失败：无权限写入 $BACKUP_DIR"
        return 1
    fi
    mkdir -p "$BACKUP_DIR"
    if [[ -f "$CONFIG_FILE" ]]; then
        if cp "$CONFIG_FILE" "$BACKUP_DIR/hyprpaper.conf.backup"; then
            echo "配置已备份到 $BACKUP_DIR/hyprpaper.conf.backup"
            log_action "配置备份成功：$BACKUP_DIR/hyprpaper.conf.backup"
        else
            echo "错误：备份失败。"
            log_action "备份失败"
            return 1
        fi
    else
        echo "未找到配置文件，无需备份。"
        log_action "备份跳过：未找到配置文件"
    fi
}

# 恢复配置
restore_config() {
    echo "正在恢复配置..."
    if [[ -f "$BACKUP_DIR/hyprpaper.conf.backup" ]]; then
        if [[ ! -w "$CONFIG_DIR" ]]; then
            echo "错误：无权限写入 $CONFIG_DIR"
            log_action "恢复失败：无权限写入 $CONFIG_DIR"
            return 1
        fi
        mkdir -p "$CONFIG_DIR"
        if cp "$BACKUP_DIR/hyprpaper.conf.backup" "$CONFIG_FILE"; then
            echo "配置已恢复到 $CONFIG_FILE"
            log_action "配置恢复成功：$CONFIG_FILE"
            reload_hyprpaper
        else
            echo "错误：恢复失败。"
            log_action "恢复失败"
            return 1
        fi
    else
        echo "未找到备份文件。"
        log_action "恢复失败：未找到备份文件"
    fi
}

# 初始化壁纸路径
WALLPAPER=$(realpath "$DEFAULT_WALLPAPER" 2>/dev/null || echo "$DEFAULT_WALLPAPER")

# 主循环
while true; do
    check_environment || continue
    show_menu
    read -rp "请选择操作 [0-7]: " choice
    case $choice in
        1) install_hyprpaper ;;
        2) uninstall_hyprpaper ;;
        3) generate_config ;;
        4) choose_wallpaper ;;
        5) backup_config ;;
        6) restore_config ;;
        7) reload_hyprpaper ;;
        0) echo "退出。"; log_action "脚本退出"; exit 0 ;;
        *) echo "无效选项，请重试。" ;;
    esac
    echo "按 Enter 键继续..."
    read -r
done