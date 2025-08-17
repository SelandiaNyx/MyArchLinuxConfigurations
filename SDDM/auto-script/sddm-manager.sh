#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# =============================================================================
# SDDM 管理器 (sddm-manager.sh)
#
# 功能：
#   - 安装 / 卸载 SDDM
#   - 安装 / 卸载 astronaut 主题
#   - 切换 astronaut 子主题
#   - 预览 / 更新 主题
#   - 检查当前状态
#   - 备份 / 恢复 SDDM 配置
#
# 适用系统：Arch Linux 及其衍生版
#
# 备份机制：
#   - 备份文件存放于 ~/backups/sddm
#   - 文件名追加 `.backup` 后缀
#   - 恢复时删除 /etc 下现有配置文件，再从备份去掉 `.backup` 后缀恢复
# =============================================================================

# -----------------------------------------------------------------------------
# 路径配置
# -----------------------------------------------------------------------------
THEME_DIR="/usr/share/sddm/themes/sddm-astronaut-theme"  # astronaut 主题安装路径
SDDM_CONF="/etc/sddm.conf"                               # SDDM 主配置文件
BACKUP_DIR="$HOME/backups/sddm"                          # 备份目录

# -----------------------------------------------------------------------------
# 安装 SDDM
# -----------------------------------------------------------------------------
install_sddm() {
    echo "==> 安装 SDDM..."
    sudo pacman -S --needed --noconfirm sddm
    sudo systemctl enable sddm.service
    echo "✅ SDDM 已安装并启用。"
}

# -----------------------------------------------------------------------------
# 卸载 SDDM
# -----------------------------------------------------------------------------
uninstall_sddm() {
    echo "==> 停止并卸载 SDDM..."
    sudo systemctl disable sddm.service || true
    sudo pacman -Rns --noconfirm sddm
    echo "✅ SDDM 已卸载。"
}

# -----------------------------------------------------------------------------
# 安装 astronaut 主题
# -----------------------------------------------------------------------------
install_theme() {
    echo "==> 安装依赖..."
    sudo pacman -S --needed --noconfirm qt6-svg qt6-virtualkeyboard qt6-multimedia-ffmpeg git

    echo "==> 检查 astronaut 主题目录..."
    if [ -d "$THEME_DIR" ]; then
        # 检查必要文件是否存在，否则删除重新克隆
        if [ ! -f "$THEME_DIR/metadata.desktop" ] || [ ! -d "$THEME_DIR/Fonts" ] || [ ! -d "$THEME_DIR/Themes" ]; then
            echo "==> 检测到不完整安装，正在删除并重新克隆..."
            sudo rm -rf "$THEME_DIR"
            sudo git clone --depth 1 https://github.com/keyitdev/sddm-astronaut-theme.git "$THEME_DIR"
        else
            echo "主题目录已存在且完整，跳过克隆。"
        fi
    else
        echo "==> 克隆 astronaut 主题仓库..."
        sudo git clone --depth 1 https://github.com/keyitdev/sddm-astronaut-theme.git "$THEME_DIR"
    fi

    echo "==> 安装字体..."
    if [ -d "$THEME_DIR/Fonts" ]; then
        sudo cp -r "$THEME_DIR/Fonts/"* /usr/share/fonts/ || true
        sudo fc-cache -fv
    else
        echo "❌ Fonts 目录缺失，请检查克隆是否成功。"
    fi

    echo "==> 配置 SDDM 使用 astronaut 主题..."
    sudo bash -c "cat > $SDDM_CONF" <<EOF
[Theme]
Current=sddm-astronaut-theme
EOF

    echo "==> 启用虚拟键盘..."
    sudo mkdir -p /etc/sddm.conf.d
    sudo bash -c "cat > /etc/sddm.conf.d/virtualkbd.conf" <<EOF
[General]
InputMethod=qtvirtualkeyboard
EOF

    echo "==> 设置默认子主题为 hyprland_kath..."
    if [ -f "$THEME_DIR/metadata.desktop" ]; then
        sudo sed -i 's|^ConfigFile=.*|ConfigFile=Themes/hyprland_kath.conf|' "$THEME_DIR/metadata.desktop"
    else
        echo "❌ metadata.desktop 文件缺失，请检查克隆是否成功。"
    fi

    echo "==> 重启 SDDM..."
    sudo systemctl restart sddm.service

    echo "✅ astronaut 主题 (默认 hyprland_kath) 已安装完成！"
}

# -----------------------------------------------------------------------------
# 卸载 astronaut 主题
# -----------------------------------------------------------------------------
uninstall_theme() {
    echo "==> 切换回 Breeze 默认主题..."
    sudo bash -c "cat > $SDDM_CONF" <<EOF
[Theme]
Current=breeze
EOF

    echo "==> 删除虚拟键盘配置..."
    sudo rm -f /etc/sddm.conf.d/virtualkbd.conf

    echo "==> 删除 astronaut 主题..."
    if [ -d "$THEME_DIR" ]; then
        sudo rm -rf "$THEME_DIR"
        echo "已删除 $THEME_DIR"
    else
        echo "未检测到 astronaut 主题目录，跳过。"
    fi

    echo "==> 清理字体缓存..."
    sudo fc-cache -fv

    echo "==> 重启 SDDM..."
    sudo systemctl restart sddm.service

    echo "✅ astronaut 主题已卸载，已恢复为 Breeze 登录界面。"
}

# -----------------------------------------------------------------------------
# 切换 astronaut 子主题
# -----------------------------------------------------------------------------
switch_theme() {
    echo "==> 可用子主题列表："
    themes=($(ls "$THEME_DIR/Themes" | sed 's/\.conf$//'))  # 获取主题数组
    for i in "${!themes[@]}"; do
        echo "     $((i+1))  ${themes[i]}"
    done

    read -rp "请输入要切换的主题编号（例如 2）： " num

    if [[ $num =~ ^[0-9]+$ ]] && [ $num -ge 1 ] && [ $num -le ${#themes[@]} ]; then
        theme="${themes[$((num-1))]}"
        if [ -f "$THEME_DIR/Themes/${theme}.conf" ]; then
            sudo sed -i "s|^ConfigFile=.*|ConfigFile=Themes/${theme}.conf|" "$THEME_DIR/metadata.desktop"
            echo "✅ 已切换到子主题: $theme"
            sudo systemctl restart sddm.service
        else
            echo "❌ 主题 $theme 不存在"
        fi
    else
        echo "❌ 无效编号，请输入 1-${#themes[@]} 之间的数字"
    fi
}

# -----------------------------------------------------------------------------
# 预览 astronaut 主题
# -----------------------------------------------------------------------------
preview_theme() {
    echo "==> 预览当前主题..."
    sddm-greeter-qt6 --test-mode --theme "$THEME_DIR/"
}

# -----------------------------------------------------------------------------
# 更新 astronaut 主题
# -----------------------------------------------------------------------------
update_theme() {
    echo "==> 更新 astronaut 主题..."
    if [ -d "$THEME_DIR/.git" ]; then
        cd "$THEME_DIR"
        sudo git pull
        sudo cp -r Fonts/* /usr/share/fonts/ || true
        sudo fc-cache -fv
        echo "✅ astronaut 主题已更新。"
    else
        echo "❌ 未找到 Git 仓库，请先安装主题。"
    fi
}

# -----------------------------------------------------------------------------
# 检查 SDDM 状态
# -----------------------------------------------------------------------------
check_status() {
    echo "========== 当前 SDDM 状态 =========="
    if systemctl is-active --quiet sddm.service; then
        echo "SDDM 服务状态: ✅ 正在运行"
    else
        echo "SDDM 服务状态: ❌ 未运行"
    fi

    if [ -f "$SDDM_CONF" ]; then
        current_theme=$(grep -E '^Current=' "$SDDM_CONF" | cut -d= -f2)
        echo "当前主题: $current_theme"
    else
        echo "未找到 $SDDM_CONF"
    fi

    if [ -f "$THEME_DIR/metadata.desktop" ]; then
        sub_theme=$(grep -E '^ConfigFile=' "$THEME_DIR/metadata.desktop" | cut -d= -f2 | sed 's|Themes/||; s|\.conf||')
        echo "当前子主题: $sub_theme"
    fi
    echo "==================================="
}

# -----------------------------------------------------------------------------
# 备份配置（保存为 .backup 到 ~/backups/sddm）
# -----------------------------------------------------------------------------
backup_config() {
    echo "==> 备份 SDDM 配置到 $BACKUP_DIR ..."
    mkdir -p "$BACKUP_DIR"

    for file in /etc/sddm.conf*; do
        if [ -f "$file" ]; then
            base=$(basename "$file")
            cp "$file" "$BACKUP_DIR/${base}.backup"
            echo "已备份: $file -> $BACKUP_DIR/${base}.backup"
        fi
    done

    echo "✅ 已完成备份。"
}

# -----------------------------------------------------------------------------
# 恢复配置（删除现有配置，从 .backup 恢复）
# -----------------------------------------------------------------------------
restore_config() {
    echo "==> 恢复备份配置..."
    if [ ! -d "$BACKUP_DIR" ]; then
        echo "❌ 未找到备份目录 $BACKUP_DIR"
        return 1
    fi

    # 删除现有 /etc/sddm.conf*
    sudo rm -f /etc/sddm.conf*

    # 恢复 .backup 文件
    for backup in "$BACKUP_DIR"/*.backup; do
        if [ -f "$backup" ]; then
            base=$(basename "$backup" .backup)
            sudo cp "$backup" "/etc/$base"
            echo "已恢复: $backup -> /etc/$base"
        fi
    done

    echo "✅ 配置已恢复。"
    sudo systemctl restart sddm.service
}

# -----------------------------------------------------------------------------
# 菜单入口
# -----------------------------------------------------------------------------
menu() {
    echo "========== SDDM 管理器 =========="
    echo "1) 安装 SDDM"
    echo "2) 卸载 SDDM"
    echo "3) 安装 astronaut 主题 (默认 hyprland_kath)"
    echo "4) 卸载 astronaut 主题"
    echo "5) 切换 astronaut 子主题"
    echo "6) 预览当前主题"
    echo "7) 更新 astronaut 主题"
    echo "8) 检查当前状态"
    echo "9) 备份配置"
    echo "10) 恢复配置"
    echo "0) 退出"
    echo "================================="
    read -rp "请选择操作 [0-10]: " choice

    case $choice in
        1) install_sddm ;;
        2) uninstall_sddm ;;
        3) install_theme ;;
        4) uninstall_theme ;;
        5) switch_theme ;;
        6) preview_theme ;;
        7) update_theme ;;
        8) check_status ;;
        9) backup_config ;;
        10) restore_config ;;
        0) exit 0 ;;
        *) echo "❌ 无效选择" ;;
    esac
}

menu
