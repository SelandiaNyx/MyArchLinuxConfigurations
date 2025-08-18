#!/usr/bin/env bash
set -euo pipefail     # 开启严格模式：出错退出、未定义变量报错、管道出错时返回失败
IFS=$'\n\t'           # 设置内部字段分隔符为换行和制表符，避免空格分割错误

# =============================================================================
# Wofi 管理器（统一结构版）
# 功能：
#   - 安装 / 卸载 Wofi
#   - 应用 / 删除 / 备份 / 恢复配置
# =============================================================================

# ==== 常量 ====
readonly APP_NAME="Wofi"  # 应用名称
readonly CONFIG_DIR="$HOME/.config/wofi"  # Wofi 配置目录
readonly BACKUP_DIR="$HOME/backups/wofi"  # 配置备份目录
readonly LOG_DIR="$BACKUP_DIR/logs"       # 日志存放目录
readonly LOG_FILE="$LOG_DIR/action.log"   # 日志文件路径
readonly LAUNCHER_URL="https://raw.githubusercontent.com/SelandiaNyx/MyArchLinuxConfigurations/refs/heads/main/Wofi/configuration/launchermenu.sh"  # launcher 脚本下载链接
readonly POWER_URL="https://raw.githubusercontent.com/SelandiaNyx/MyArchLinuxConfigurations/refs/heads/main/Wofi/configuration/powermenu.sh"         # powermenu 脚本下载链接
readonly CSS_URL="https://raw.githubusercontent.com/SelandiaNyx/MyArchLinuxConfigurations/refs/heads/main/Wofi/configuration/style.css"               # CSS 样式下载链接

# ==== 通用函数 ====
_log_action() { mkdir -p "$LOG_DIR"; echo "$(date '+%F %T') - $*" >> "$LOG_FILE"; }  # 记录日志函数，自动创建日志目录
_error_exit() { echo "[错误] $*"; _log_action "错误: $*"; return 1; }                # 错误提示并记录日志
_confirm() { read -r -p "$1 [y/N]: " ans; [[ "${ans:-N}" =~ ^[Yy]$ ]]; }           # 用户确认函数，返回 true/false
_check_environment() {                                                              # 检查运行环境函数
  local choice="${1:-}"                                                              # 获取传入参数
  command -v pacman >/dev/null || return $(_error_exit "仅支持 Arch Linux 系列系统") # 检查 pacman 是否存在
  if ! command -v wofi >/dev/null && [[ "$choice" != "1" ]]; then                   # 检查 wofi 是否安装
    return $(_error_exit "未安装 $APP_NAME，请先安装")
  fi
}
_ensure_dir_writable() { mkdir -p "$1" 2>/dev/null || _error_exit "无法创建目录: $1"; }  # 确保目录存在且可写

# ==== 功能区 ====
_install_app() {                                                                 # 安装 Wofi
  sudo pacman -S --needed --noconfirm wofi curl || _error_exit "安装失败"         # 安装 wofi 和 curl
  _log_action "安装成功"                                                         # 记录安装成功日志
}

_uninstall_app() {                                                              # 卸载 Wofi
  _confirm "确认卸载 $APP_NAME 吗？" || { echo "ℹ️ 取消卸载"; return; }          # 提示用户确认
  sudo pacman -Rns --noconfirm wofi || _error_exit "卸载失败"                    # 卸载 wofi
  _log_action "卸载成功"                                                        # 记录日志
}

_apply_config() {                                                               # 应用配置
  _ensure_dir_writable "$CONFIG_DIR"                                             # 确保配置目录存在
  command -v curl >/dev/null || sudo pacman -S --needed --noconfirm curl         # 检查 curl，若缺失则安装
  curl -fsSL "$LAUNCHER_URL" -o "$CONFIG_DIR/launchermenu.sh" || _error_exit "下载 launchermenu.sh 失败"  # 下载 launcher 脚本
  curl -fsSL "$POWER_URL" -o "$CONFIG_DIR/powermenu.sh" || _error_exit "下载 powermenu.sh 失败"          # 下载 powermenu 脚本
  curl -fsSL "$CSS_URL" -o "$CONFIG_DIR/style.css" || _error_exit "下载 style.css 失败"                  # 下载 CSS 文件
  chmod +x "$CONFIG_DIR"/*.sh                                                   # 赋予下载的脚本执行权限
  _log_action "应用配置"                                                         # 记录日志
}

_remove_config() {                                                              # 删除配置
  [[ -d "$CONFIG_DIR" ]] || { echo "ℹ️ 无配置目录"; return; }                  # 如果配置目录不存在，提示并返回
  _confirm "确认删除配置目录吗？" || return                                       # 用户确认
  rm -rf "$CONFIG_DIR"                                                          # 删除配置目录
  _log_action "删除配置"                                                        # 记录日志
}

_backup_config() {                                                              # 备份配置
  _ensure_dir_writable "$BACKUP_DIR"                                            # 确保备份目录存在
  find "$CONFIG_DIR" -type f -exec cp --parents {} "$BACKUP_DIR" \; || _error_exit "备份失败"  # 复制配置文件到备份目录
  _log_action "备份配置"                                                        # 记录日志
}

_restore_config() {                                                             # 恢复配置
  [[ -d "$BACKUP_DIR" ]] || _error_exit "无备份目录"                             # 检查备份目录是否存在
  rm -rf "$CONFIG_DIR"                                                          # 删除原有配置
  cp -r "$BACKUP_DIR"/* "$CONFIG_DIR"/ || _error_exit "恢复失败"                  # 复制备份文件到配置目录
  _log_action "恢复配置"                                                        # 记录日志
}

# ==== 菜单 ====
_show_menu() {                                                                  # 显示操作菜单
  clear                                                                         # 清屏
  echo "========== $APP_NAME 管理器 =========="                                   # 菜单标题
  echo "1) 安装"                                                                 # 选项 1：安装
  echo "2) 卸载"                                                                 # 选项 2：卸载
  echo "3) 应用配置"                                                             # 选项 3：应用配置
  echo "4) 删除配置"                                                             # 选项 4：删除配置
  echo "5) 备份配置"                                                             # 选项 5：备份配置
  echo "6) 恢复配置"                                                             # 选项 6：恢复配置
  echo "0) 退出"                                                                 # 选项 0：退出
}

# ==== 主循环 ====
choice=""                                                                       # 初始化用户选择
while true; do                                                                  # 无限循环菜单
  _check_environment "$choice" || continue                                      # 检查环境，失败则重新显示菜单
  _show_menu                                                                    # 显示菜单
  read -rp "选择操作 [0-6]: " choice                                            # 用户输入选择
  case "$choice" in                                                             # 根据选择执行操作
    1) _install_app ;;                                                          # 安装
    2) _uninstall_app ;;                                                        # 卸载
    3) _apply_config ;;                                                         # 应用配置
    4) _remove_config ;;                                                        # 删除配置
    5) _backup_config ;;                                                        # 备份配置
    6) _restore_config ;;                                                       # 恢复配置
    0) echo "✅ 退出"; _log_action "退出"; exit 0 ;;                           # 退出程序
    *) _error_exit "无效选项" ;;                                               # 无效选项报错
  esac
  read -rp "按回车继续..."                                                     # 等待用户回车
done
