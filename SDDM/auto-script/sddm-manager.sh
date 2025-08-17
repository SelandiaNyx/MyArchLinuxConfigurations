#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# =============================================================================
# 🔐 SDDM 管理器（统一结构版）
# 功能：
#   - 安装 / 卸载 SDDM
#   - 安装 / 卸载 astronaut 主题
#   - 切换 / 预览 / 更新子主题
#   - 检查状态
#   - 备份 / 恢复配置
# 适用系统：Arch Linux 及其衍生版
# =============================================================================

# ==== 常量 ====
readonly APP_NAME="SDDM"
readonly THEME_DIR="/usr/share/sddm/themes/sddm-astronaut-theme"
readonly SDDM_CONF="/etc/sddm.conf"
readonly SDDM_CONF_DIR="/etc/sddm.conf.d"
readonly BACKUP_DIR="$HOME/backups/sddm"
readonly LOG_DIR="$BACKUP_DIR/logs"
readonly LOG_FILE="$LOG_DIR/action.log"

# ==== 通用函数 ====
_log_action() { mkdir -p "$LOG_DIR"; echo "$(date '+%F %T') - $*" >> "$LOG_FILE"; }
_error_exit() { echo "[错误] $*"; _log_action "错误: $*"; return 1; }
_confirm() { read -r -p "$1 [y/N]: " ans; [[ "${ans:-N}" =~ ^[Yy]$ ]]; }
_check_environment() {
  local choice="${1:-}"
  command -v pacman >/dev/null || return $(_error_exit "仅支持 Arch Linux 系列系统")
  if ! command -v sddm >/dev/null && [[ "$choice" != "1" ]]; then
    return $(_error_exit "未安装 $APP_NAME，请先安装")
  fi
}
_ensure_dir_writable() { mkdir -p "$1" 2>/dev/null || _error_exit "无法创建目录: $1"; }

# ==== 功能区 ====
_install_app() {
  sudo pacman -S --needed --noconfirm sddm && sudo systemctl enable sddm.service || _error_exit "安装失败"
  _log_action "安装成功"
}

_uninstall_app() {
  _confirm "确认卸载 $APP_NAME 吗？" || { echo "ℹ️ 取消卸载"; return; }
  sudo systemctl disable sddm.service || true
  sudo pacman -Rns --noconfirm sddm && _log_action "卸载成功" || _error_exit "卸载失败"
}

_install_theme_deps() {
  sudo pacman -S --needed --noconfirm qt6-svg qt6-virtualkeyboard qt6-multimedia-ffmpeg git || _error_exit "依赖安装失败"
}

_clone_theme_repo() {
  if [[ -d "$THEME_DIR" ]]; then
    sudo rm -rf "$THEME_DIR"
  fi
  sudo git clone --depth 1 https://github.com/keyitdev/sddm-astronaut-theme.git "$THEME_DIR" || _error_exit "克隆主题失败"
}

_install_theme_fonts() {
  [[ -d "$THEME_DIR/Fonts" ]] || _error_exit "Fonts 目录缺失"
  sudo cp -r "$THEME_DIR/Fonts/"* /usr/share/fonts/ || true
  sudo fc-cache -fv
}

_configure_theme() {
  sudo bash -c "cat > $SDDM_CONF" <<EOF
[Theme]
Current=sddm-astronaut-theme
EOF
  sudo mkdir -p "$SDDM_CONF_DIR"
  sudo bash -c "cat > $SDDM_CONF_DIR/virtualkbd.conf" <<EOF
[General]
InputMethod=qtvirtualkeyboard
EOF
  sudo sed -i 's|^ConfigFile=.*|ConfigFile=Themes/hyprland_kath.conf|' "$THEME_DIR/metadata.desktop"
}

_install_theme() {
  _install_theme_deps
  _clone_theme_repo
  _install_theme_fonts
  _configure_theme
  sudo systemctl restart sddm.service || _error_exit "SDDM 重启失败"
  _log_action "astronaut 主题安装成功"
  echo "✅ astronaut 主题已安装"
}

_uninstall_theme() {
  _confirm "确认卸载 astronaut 主题吗？" || { echo "ℹ️ 取消卸载"; return; }
  sudo bash -c "cat > $SDDM_CONF" <<EOF
[Theme]
Current=breeze
EOF
  sudo rm -f "$SDDM_CONF_DIR/virtualkbd.conf"
  sudo rm -rf "$THEME_DIR"
  sudo fc-cache -fv
  sudo systemctl restart sddm.service || _error_exit "SDDM 重启失败"
  _log_action "astronaut 主题卸载成功"
  echo "✅ 已恢复 Breeze 主题"
}

_switch_subtheme() {
  [[ -d "$THEME_DIR/Themes" ]] || _error_exit "未找到主题目录"
  local themes=($(ls "$THEME_DIR/Themes" | sed 's/\.conf$//'))
  for i in "${!themes[@]}"; do echo "$((i+1))) ${themes[$i]}"; done
  read -rp "选择主题编号: " num
  [[ "$num" -ge 1 && "$num" -le ${#themes[@]} ]] || _error_exit "无效编号"
  sudo sed -i "s|^ConfigFile=.*|ConfigFile=Themes/${themes[$((num-1))]}.conf|" "$THEME_DIR/metadata.desktop"
  sudo systemctl restart sddm.service || _error_exit "SDDM 重启失败"
  _log_action "切换子主题: ${themes[$((num-1))]}"
}

_preview_theme() {
  [[ -d "$THEME_DIR" ]] || _error_exit "未找到主题目录"
  sddm-greeter-qt6 --test-mode --theme "$THEME_DIR/" || _error_exit "预览失败"
  _log_action "预览主题"
}

_update_theme() {
  [[ -d "$THEME_DIR/.git" ]] || _error_exit "未找到主题 Git 仓库"
  sudo git -C "$THEME_DIR" pull || _error_exit "更新失败"
  _install_theme_fonts
  sudo systemctl restart sddm.service || _error_exit "SDDM 重启失败"
  _log_action "主题已更新"
}

_check_status() {
  echo "SDDM 服务: $(systemctl is-active --quiet sddm.service && echo 运行中 || echo 未运行)"
  [[ -f "$SDDM_CONF" ]] && grep -E '^Current=' "$SDDM_CONF" | sed 's/^Current=//'
  [[ -f "$THEME_DIR/metadata.desktop" ]] && grep -E '^ConfigFile=' "$THEME_DIR/metadata.desktop" | sed 's|Themes/||; s|\.conf||'
  _log_action "状态检查"
}

_backup_config() {
  _ensure_dir_writable "$BACKUP_DIR"
  for file in /etc/sddm.conf*; do
    [[ -f "$file" ]] && cp "$file" "$BACKUP_DIR/"
  done
  _log_action "备份配置"
}

_restore_config() {
  [[ -d "$BACKUP_DIR" ]] || _error_exit "无备份目录"
  sudo rm -f /etc/sddm.conf*
  for file in "$BACKUP_DIR"/*; do sudo cp "$file" /etc/; done
  sudo systemctl restart sddm.service || _error_exit "重启失败"
  _log_action "恢复配置"
}

# ==== 菜单 ====
_show_menu() {
  clear
  echo "========== $APP_NAME 管理器 =========="
  echo "1) 安装 SDDM"
  echo "2) 卸载 SDDM"
  echo "3) 安装 astronaut 主题"
  echo "4) 卸载 astronaut 主题"
  echo "5) 切换子主题"
  echo "6) 预览主题"
  echo "7) 更新主题"
  echo "8) 检查状态"
  echo "9) 备份配置"
  echo "10) 恢复配置"
  echo "0) 退出"
}

# ==== 主循环 ====
choice=""
while true; do
  _check_environment "$choice" || continue
  _show_menu
  read -rp "选择操作 [0-10]: " choice
  case "$choice" in
    1) _install_app ;;
    2) _uninstall_app ;;
    3) _install_theme ;;
    4) _uninstall_theme ;;
    5) _switch_subtheme ;;
    6) _preview_theme ;;
    7) _update_theme ;;
    8) _check_status ;;
    9) _backup_config ;;
    10) _restore_config ;;
    0) echo "✅ 退出"; _log_action "退出"; exit 0 ;;
    *) _error_exit "无效选项" ;;
  esac
  read -rp "按回车继续..."
done
