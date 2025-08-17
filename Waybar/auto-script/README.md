# 🎛 Waybar 管理器

`waybar-manager.sh` 是一个统一结构的 Bash 脚本，用于在 **Arch Linux** 系统上管理 [Waybar](https://github.com/Alexays/Waybar) 状态栏的安装、配置、备份与恢复。  
它能自动下载配置文件与样式表，一键应用或还原，方便快速部署 Waybar。

---

## 📋 功能概览

- **安装/卸载 Waybar**（通过 `pacman`）
- **下载并应用配置**（自动拉取远程配置 + 样式）
- **删除配置目录**
- **备份/恢复配置**
- **状态检查**（进程与配置文件）

---

## 📂 配置与目录

- **Waybar 配置目录**：`~/.config/waybar/`
- **备份目录**：`~/backups/waybar/`
- **日志目录**：`~/backups/waybar/logs/`
- **配置来源**：
  - `config.jsonc`
  - `style.css`

---

## 📦 依赖

- 操作系统：**Arch Linux**
- 软件包：`waybar`、`curl`

---

## 🚀 使用方法

1. 下载脚本  

```bash
curl -fsSL -o waybar-manager.sh https://raw.githubusercontent.com/SelandiaNyx/MyArchLinuxConfigurations/refs/heads/main/Waybar/auto-script/waybar-manager.sh
chmod +x waybar-manager.sh
```

2. 运行脚本

```bash
./waybar-manager.sh
```

📜 菜单功能

```bash
========== Waybar 管理器 ==========
1) 安装
2) 卸载
3) 应用配置
4) 删除配置
5) 备份配置
6) 恢复配置
7) 检查状态
0) 退出
==================================
```

⚠️ 注意事项

1. 应用配置需要网络连接。
2. 删除配置会清空 ~/.config/waybar/，建议先执行备份。
3. 恢复时会覆盖当前配置，请谨慎操作。
