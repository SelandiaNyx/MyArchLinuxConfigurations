#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# =============================================================================
# 🎛 Waybar 管理器（统一结构版）
# 功能：
#   - 安装 / 卸载 Waybar
#   - 应用 / 删除 / 备份 / 恢复配置
#   - 检查状态
# =============================================================================

# ==== 常量 ====
readonly APP_NAME="Waybar"
readonly CONFIG_DIR="$HOME/.config/waybar"
readonly BACKUP_DIR="$HOME/backups/waybar"
readonly LOG_DIR="$BACKUP_DIR/logs"
readonly LOG_FILE="$LOG_DIR/action.log"
readonly CONF_URL="https://raw.githubusercontent.com/SelandiaNyx/MyArchLinuxConfigurations/HEAD/Waybar/configuration/config.jsonc"
readonly CSS_URL="https://raw.githubusercontent.com/SelandiaNyx/MyArchLinuxConfigurations/HEAD/Waybar/configuration/style.css"

# ==== 通用函数 ====
_log_action() { mkdir -p "$LOG_DIR"; echo "$(date '+%F %T') - $*" >> "$LOG_FILE"; }
_error_exit() { echo "[错误] $*"; _log_action "错误: $*"; return 1; }
_confirm() { read -r -p "$1 [y/N]: " ans; [[ "${ans:-N}" =~ ^[Yy]$ ]]; }
_check_environment() {
  local choice="${1:-}"
  command -v pacman >/dev/null || return $(_error_exit "仅支持 Arch Linux 系列系统")
  if ! command -v waybar >/dev/null && [[ "$choice" != "1" ]]; then
    return $(_error_exit "未安装 $APP_NAME，请先安装")
  fi
}
_ensure_dir_writable() { mkdir -p "$1" 2>/dev/null || _error_exit "无法创建目录: $1"; }

# ==== 功能区 ====
_install_app() {
  sudo pacman -S --needed --noconfirm waybar curl || _error_exit "安装失败"
  _log_action "安装成功"
}

_uninstall_app() {
  _confirm "确认卸载 $APP_NAME 吗？" || { echo "ℹ️ 取消卸载"; return; }
  sudo pacman -Rns --noconfirm waybar || _error_exit "卸载失败"
  _log_action "卸载成功"
}

_apply_config() {
  _ensure_dir_writable "$CONFIG_DIR"
  command -v curl >/dev/null || sudo pacman -S --needed --noconfirm curl
  curl -fsSL "$CONF_URL" -o "$CONFIG_DIR/config.jsonc" || _error_exit "下载 config.jsonc 失败"
  curl -fsSL "$CSS_URL" -o "$CONFIG_DIR/style.css" || _error_exit "下载 style.css 失败"
  _log_action "应用配置"
}

_remove_config() {
  [[ -d "$CONFIG_DIR" ]] || { echo "ℹ️ 无配置目录"; return; }
  _confirm "确认删除配置目录吗？" || return
  rm -rf "$CONFIG_DIR"
  _log_action "删除配置"
}

_backup_config() {
  _ensure_dir_writable "$BACKUP_DIR"
  find "$CONFIG_DIR" -type f -exec cp --parents {} "$BACKUP_DIR" \; || _error_exit "备份失败"
  _log_action "备份配置"
}

_restore_config() {
  [[ -d "$BACKUP_DIR" ]] || _error_exit "无备份目录"
  rm -rf "$CONFIG_DIR"
  cp -r "$BACKUP_DIR"/* "$CONFIG_DIR"/ || _error_exit "恢复失败"
  _log_action "恢复配置"
}

_check_status() {
  echo "$APP_NAME 状态: $(pgrep -x waybar >/dev/null && echo 运行中 || echo 未运行)"
  [[ -d "$CONFIG_DIR" ]] && ls "$CONFIG_DIR"
  _log_action "状态检查"
}

# ==== 菜单 ====
_show_menu() {
  clear
  echo "========== $APP_NAME 管理器 =========="
  echo "1) 安装"
  echo "2) 卸载"
  echo "3) 应用配置"
  echo "4) 删除配置"
  echo "5) 备份配置"
  echo "6) 恢复配置"
  echo "7) 检查状态"
  echo "0) 退出"
}

# ==== 主循环 ====
choice=""
while true; do
  _check_environment "$choice" || continue
  _show_menu
  read -rp "选择操作 [0-7]: " choice
  case "$choice" in
    1) _install_app ;;
    2) _uninstall_app ;;
    3) _apply_config ;;
    4) _remove_config ;;
    5) _backup_config ;;
    6) _restore_config ;;
    7) _check_status ;;
    0) echo "✅ 退出"; _log_action "退出"; exit 0 ;;
    *) _error_exit "无效选项" ;;
  esac
  read -rp "按回车继续..."
done
