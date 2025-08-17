# 🖼 Hyprpaper 管理器

`hyprpaper-manager.sh` 是一个统一结构的 Bash 脚本，用于在 **Arch Linux** 系统上管理 [Hyprpaper](https://hyprland.org/hyprpaper/)。  
它支持安装、卸载、配置、壁纸切换、多显示器管理、备份与恢复，并可一键重载 Hyprpaper 服务。

---

## 📋 功能概览

- **安装/卸载 Hyprpaper**（通过 `pacman`）
- **生成默认配置**（多显示器支持）
- **设置壁纸**：
  - 所有显示器使用相同壁纸
  - 每个显示器使用独立壁纸
- **重载服务**（避免手动重启）
- **备份/恢复配置**（保存恢复 `hyprpaper.conf`）
- **日志记录**（所有操作记录在专用日志文件中）

---

## 📂 配置与目录

- **配置文件**：`~/.config/hypr/hyprpaper.conf`
- **备份目录**：`~/backups/hyprpaper/`
- **日志目录**：`~/backups/hyprpaper/logs/`
- **默认壁纸路径**：`~/wallpapers/wallpaper1.png`

---

## 📦 依赖

- 操作系统：**Arch Linux**（必须有 `pacman`）
- 软件包：`hyprpaper`、`hyprctl`、`file`

---

## 🚀 使用方法

1. 下载脚本  

```bash
curl -fsSL -o hyprpaper-manager.sh https://raw.githubusercontent.com/SelandiaNyx/MyArchLinuxConfigurations/refs/heads/main/Hyprpaper/auto-script/hyprpaper-manager.sh
chmod +x hyprpaper-manager.sh
```

2. 运行脚本

```bash
./hyprpaper-manager.sh
```

📜 菜单功能

```bsh
========== Hyprpaper 管理器 ==========
当前壁纸: ~/wallpapers/wallpaper1.png
状态: 运行中
1) 安装
2) 卸载
3) 生成默认配置
4) 设置壁纸
5) 备份配置
6) 恢复配置
7) 重载服务
0) 退出
=====================================
```

⚠️ 注意事项

1. 执行设置壁纸的功能前，请确保 Hyprland 正在运行。
2. 仅支持常见图片格式（如 .png、.jpg）。
3. 建议在修改配置前先执行备份。
