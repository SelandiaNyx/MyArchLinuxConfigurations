#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# =============================================================================
# 🖼 Hyprpaper 壁纸管理器（统一结构版）
# 功能：
#   - 安装 / 卸载 Hyprpaper
#   - 生成 / 备份 / 恢复配置
#   - 设置单壁纸 / 多壁纸
#   - 重载 Hyprpaper 服务
# 适用系统：Arch Linux 及其衍生版
# =============================================================================

# ==== 常量 ====
readonly APP_NAME="Hyprpaper"
readonly CONFIG_DIR="$HOME/.config/hypr"
readonly CONFIG_FILE="$CONFIG_DIR/hyprpaper.conf"
readonly BACKUP_DIR="$HOME/backups/hyprpaper"
readonly LOG_DIR="$BACKUP_DIR/logs"
readonly LOG_FILE="$LOG_DIR/action.log"
readonly DEFAULT_WALLPAPER="$HOME/wallpapers/wallpaper1.png"

# ==== 通用函数 ====

# 写日志（追加模式）
_log_action() { mkdir -p "$LOG_DIR"; echo "$(date '+%F %T') - $*" >> "$LOG_FILE"; }

# 输出错误并记录日志
_error_exit() { echo "[错误] $*"; _log_action "错误: $*"; return 1; }

# 用户确认（是 / 否）
_confirm() { read -r -p "$1 [y/N]: " ans; [[ "${ans:-N}" =~ ^[Yy]$ ]]; }

# 检查系统和依赖
_check_environment() {
  local choice="${1:-}"
  command -v pacman >/dev/null || return $(_error_exit "仅支持 Arch Linux 系列系统")
  if ! command -v hyprpaper >/dev/null && [[ "$choice" != "1" ]]; then
    return $(_error_exit "未检测到 $APP_NAME，请先安装")
  fi
}

# 确保目录可写
_ensure_dir_writable() { mkdir -p "$1" 2>/dev/null || _error_exit "无法创建目录: $1"; }

# ==== 功能区 ====

# 安装
_install_app() { sudo pacman -S --needed --noconfirm hyprpaper && _log_action "安装成功" || _error_exit "安装失败"; }

# 卸载
_uninstall_app() {
  _confirm "确认卸载 $APP_NAME 吗？" || { echo "ℹ️ 取消卸载"; return; }
  sudo pacman -Rns --noconfirm hyprpaper && _log_action "卸载成功" || _error_exit "卸载失败"
}

# 生成默认配置
_generate_config() {
  _ensure_dir_writable "$CONFIG_DIR"
  local monitors
  monitors=$(hyprctl monitors | awk '/Monitor/{print $2}' | sort -u) || return $(_error_exit "读取显示器失败")
  [[ -n "$monitors" ]] || return $(_error_exit "未检测到显示器")
  {
    echo "preload = $DEFAULT_WALLPAPER"
    for m in $monitors; do echo "wallpaper = $m,contain:$DEFAULT_WALLPAPER"; done
    echo "ipc = off"
  } > "$CONFIG_FILE"
  _log_action "生成默认配置"
  echo "✅ 配置已生成"
}

# 更新壁纸
_update_wallpaper() {
  local path="$1" mon="${2:-}"
  [[ -f "$path" ]] || return $(_error_exit "文件不存在: $path")
  file "$path" | grep -qE 'image|bitmap' || return $(_error_exit "不是图片: $path")
  if [[ -n "$mon" ]]; then
    sed -i "/wallpaper = $mon,contain:.*/c\wallpaper = $mon,contain:$path" "$CONFIG_FILE"
    grep -q "preload = $path" "$CONFIG_FILE" || echo "preload = $path" >> "$CONFIG_FILE"
  else
    sed -i "s|^preload = .*|preload = $path|" "$CONFIG_FILE"
    sed -i "s|^wallpaper = .*|wallpaper = ,contain:$path|" "$CONFIG_FILE"
  fi
  _log_action "更新壁纸: $path ${mon:+($mon)}"
}

# 设置壁纸
_set_wallpaper() {
  local monitors mode wp
  monitors=$(hyprctl monitors | awk '/Monitor/{print $2}' | sort -u) || return $(_error_exit "读取显示器失败")
  [[ -n "$monitors" ]] || return $(_error_exit "无显示器")
  echo "1) 所有显示器使用同一壁纸"
  echo "2) 每个显示器使用不同壁纸"
  read -rp "选择模式 [1/2]: " mode
  case "$mode" in
    1)
      read -rp "壁纸路径（默认 $DEFAULT_WALLPAPER）: " wp
      wp="${wp:-$DEFAULT_WALLPAPER}"
      cp "$wp" "$DEFAULT_WALLPAPER" && for m in $monitors; do _update_wallpaper "$DEFAULT_WALLPAPER" "$m"; done
      ;;
    2)
      for m in $monitors; do
        read -rp "显示器 $m 壁纸（默认 $DEFAULT_WALLPAPER）: " wp
        wp="${wp:-$DEFAULT_WALLPAPER}"
        target="$HOME/wallpapers/wallpaper_$m.png"
        cp "$wp" "$target" && _update_wallpaper "$target" "$m"
      done
      ;;
    *) _error_exit "无效选项" ;;
  esac
  _reload_service
}

# 重载服务
_reload_service() {
  pkill -x hyprpaper 2>/dev/null || true
  nohup hyprpaper >/dev/null 2>&1 &
  sleep 0.5 && pgrep -x hyprpaper >/dev/null || _error_exit "启动失败"
  _log_action "服务已重载"
}

# 备份配置
_backup_config() {
  _ensure_dir_writable "$BACKUP_DIR"
  [[ -f "$CONFIG_FILE" ]] && cp "$CONFIG_FILE" "$BACKUP_DIR/" && _log_action "已备份配置" || echo "ℹ️ 未找到配置"
}

# 恢复配置
_restore_config() {
  [[ -f "$BACKUP_DIR/hyprpaper.conf" ]] || return $(_error_exit "无备份文件")
  cp "$BACKUP_DIR/hyprpaper.conf" "$CONFIG_FILE" && _reload_service && _log_action "已恢复配置"
}

# ==== 菜单 ====
_show_menu() {
  clear
  echo "========== $APP_NAME 管理器 =========="
  echo "当前壁纸: ${WALLPAPER:-未设置}"
  echo "状态: $(pgrep -x hyprpaper >/dev/null && echo 运行中 || echo 未运行)"
  echo "1) 安装"
  echo "2) 卸载"
  echo "3) 生成默认配置"
  echo "4) 设置壁纸"
  echo "5) 备份配置"
  echo "6) 恢复配置"
  echo "7) 重载服务"
  echo "0) 退出"
}

# ==== 主循环 ====
WALLPAPER="$DEFAULT_WALLPAPER"
choice=""
while true; do
  _check_environment "$choice" || continue
  _show_menu
  read -rp "选择操作 [0-7]: " choice
  case "$choice" in
    1) _install_app ;;
    2) _uninstall_app ;;
    3) _generate_config ;;
    4) _set_wallpaper ;;
    5) _backup_config ;;
    6) _restore_config ;;
    7) _reload_service ;;
    0) echo "✅ 退出"; _log_action "退出"; exit 0 ;;
    *) _error_exit "无效选项" ;;
  esac
  read -rp "按回车继续..."
done
