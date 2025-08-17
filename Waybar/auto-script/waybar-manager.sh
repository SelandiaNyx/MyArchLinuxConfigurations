#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# 基本路径与链接
# -----------------------------------------------------------------------------
WAYBAR_CONF_DIR="$HOME/.config/waybar"
BACKUP_DIR="$HOME/backups/waybar"

RAW_BASE="https://raw.githubusercontent.com/SelandiaNyx/MyArchLinuxConfigurations/HEAD/Waybar/configuration"
CONF_URL="$RAW_BASE/config.jsonc"
CSS_URL="$RAW_BASE/style.css"

# -----------------------------------------------------------------------------
# 工具函数
# -----------------------------------------------------------------------------
need_cmd() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "==> 未找到命令：$1，正在安装..."
        case "$1" in
            curl) sudo pacman -S --needed --noconfirm curl ;;
            git)  sudo pacman -S --needed --noconfirm git ;;
            *)    echo "❌ 无法自动安装 $1，请手动安装后重试。"; exit 1 ;;
        esac
    }
}

confirm() {
    read -r -p "$1 [y/N]: " ans
    [[ "${ans:-N}" =~ ^[Yy]$ ]]
}

# -----------------------------------------------------------------------------
# 安装 / 卸载 Waybar
# -----------------------------------------------------------------------------
install_waybar() {
    echo "==> 安装 Waybar 及常用依赖（curl）..."
    sudo pacman -S --needed --noconfirm waybar curl
    echo "✅ Waybar 已安装。"
}

uninstall_waybar() {
    echo "==> 卸载 Waybar..."
    sudo pacman -Rns --noconfirm waybar || true
    echo "✅ Waybar 已卸载。"
}

# -----------------------------------------------------------------------------
# 应用 / 删除 配置
# -----------------------------------------------------------------------------
apply_config() {
    echo "==> 下载并应用 Waybar 配置..."
    need_cmd curl
    mkdir -p "$WAYBAR_CONF_DIR"

    # 下载配置文件
    curl -fsSL "$CONF_URL" -o "$WAYBAR_CONF_DIR/config.jsonc"
    curl -fsSL "$CSS_URL"  -o "$WAYBAR_CONF_DIR/style.css"

    echo "✅ 配置已写入："
    echo "   - $WAYBAR_CONF_DIR/config.jsonc"
    echo "   - $WAYBAR_CONF_DIR/style.css"
    echo
    echo "提示：Waybar 默认会读取 ~/.config/waybar/config 或 config.json / config.jsonc。"
    echo "若 Waybar 正在运行，可执行：killall waybar && waybar &"
}

remove_config() {
    if [ -d "$WAYBAR_CONF_DIR" ]; then
        echo "==> 将要删除目录：$WAYBAR_CONF_DIR"
        if confirm "确认删除当前 Waybar 配置目录吗？不可恢复（建议先备份）"; then
            rm -rf "$WAYBAR_CONF_DIR"
            echo "✅ 已删除 $WAYBAR_CONF_DIR"
        else
            echo "ℹ️ 已取消。"
        fi
    else
        echo "ℹ️ 未发现配置目录：$WAYBAR_CONF_DIR，跳过。"
    fi
}

# -----------------------------------------------------------------------------
# 备份 / 恢复 配置（追加 .backup 后缀，统一放在 ~/backups/waybar）
# -----------------------------------------------------------------------------
backup_config() {
    echo "==> 备份 Waybar 配置到 $BACKUP_DIR（追加 .backup 后缀）..."
    if [ ! -d "$WAYBAR_CONF_DIR" ]; then
        echo "❌ 未发现配置目录：$WAYBAR_CONF_DIR，无法备份。"
        exit 1
    fi

    mkdir -p "$BACKUP_DIR"

    # 逐文件备份，保留相对路径结构，文件名追加 .backup
    while IFS= read -r -d '' file; do
        rel="${file#"$WAYBAR_CONF_DIR"/}"                # 相对路径
        dest_dir="$BACKUP_DIR/$(dirname "$rel")"
        mkdir -p "$dest_dir"
        cp -f "$file" "$dest_dir/$(basename "$rel").backup"
        echo "已备份: $file -> $dest_dir/$(basename "$rel").backup"
    done < <(find "$WAYBAR_CONF_DIR" -type f -print0)

    echo "✅ 备份完成。"
}

restore_config() {
    echo "==> 从 $BACKUP_DIR 恢复 Waybar 配置（移除 .backup 后缀）..."
    if [ ! -d "$BACKUP_DIR" ]; then
        echo "❌ 未发现备份目录：$BACKUP_DIR"
        exit 1
    fi

    # 删除当前配置
    rm -rf "$WAYBAR_CONF_DIR"
    mkdir -p "$WAYBAR_CONF_DIR"

    # 逐文件恢复：去掉 .backup 后缀并还原相对路径
    restored=0
    while IFS= read -r -d '' backup_file; do
        rel="${backup_file#"$BACKUP_DIR"/}"             # 备份相对路径（含 .backup）
        rel_no_suffix="${rel%.backup}"                  # 去掉 .backup
        dest_dir="$WAYBAR_CONF_DIR/$(dirname "$rel_no_suffix")"
        mkdir -p "$dest_dir"
        cp -f "$backup_file" "$dest_dir/$(basename "$rel_no_suffix")"
        echo "已恢复: $backup_file -> $dest_dir/$(basename "$rel_no_suffix")"
        restored=$((restored+1))
    done < <(find "$BACKUP_DIR" -type f -name '*.backup' -print0)

    if [ "$restored" -eq 0 ]; then
        echo "❌ 未找到任何 *.backup 文件。请确认 $BACKUP_DIR 中存在备份。"
        exit 1
    fi

    echo "✅ 恢复完成。"
}

# -----------------------------------------------------------------------------
# 状态检查（可选）
# -----------------------------------------------------------------------------
check_status() {
    echo "========== Waybar 状态 =========="
    if command -v pgrep >/dev/null 2>&1 && pgrep -x waybar >/dev/null 2>&1; then
        echo "Waybar 进程: ✅ 运行中"
    else
        echo "Waybar 进程: ❌ 未检测到"
    fi

    if [ -d "$WAYBAR_CONF_DIR" ]; then
        echo "配置目录: $WAYBAR_CONF_DIR"
        ls -lah "$WAYBAR_CONF_DIR" || true
    else
        echo "配置目录: 未找到（$WAYBAR_CONF_DIR）"
    fi
    echo "================================="
}

# -----------------------------------------------------------------------------
# 菜单
# -----------------------------------------------------------------------------
menu() {
    echo "========== Waybar 管理器 =========="
    echo "1) 安装 Waybar"
    echo "2) 卸载 Waybar"
    echo "3) 应用（下载）配置"
    echo "4) 删除配置"
    echo "5) 备份当前配置 -> $BACKUP_DIR/*.backup"
    echo "6) 恢复备份配置 <- $BACKUP_DIR/*.backup"
    echo "7) 检查当前状态"
    echo "0) 退出"
    echo "==================================="
    read -r -p "请选择操作 [0-7]: " choice

    case "${choice:-}" in
        1) install_waybar ;;
        2) uninstall_waybar ;;
        3) apply_config ;;
        4) remove_config ;;
        5) backup_config ;;
        6) restore_config ;;
        7) check_status ;;
        0) exit 0 ;;
        *) echo "❌ 无效选项" ;;
    esac
}

menu
