# Hyprpaper Manager

`hyprpaper-manager.sh` 是一个用于管理 [Hyprpaper](https://hyprland.org/hyprpaper/) 壁纸的 Bash 脚本，专为 **Arch Linux** 系统设计。它提供了一个交互式菜单，方便用户安装、配置和切换 Hyprpaper 壁纸，支持单显示器和多显示器设置，适用于 [Hyprland](https://hyprland.org/) 桌面环境。

## 简介

Hyprpaper 是 Hyprland 的轻量级壁纸管理工具，`hyprpaper-manager.sh` 通过自动化操作简化了壁纸管理和配置流程。脚本支持动态检测显示器，允许用户为所有显示器设置单一壁纸或为每个显示器设置不同壁纸，同时提供备份和恢复功能以确保配置安全。

## 脚本功能

- **安装/卸载 Hyprpaper**：通过 `pacman` 安装或卸载 Hyprpaper。
- **生成默认配置**：创建默认的 `hyprpaper.conf` 文件，支持多显示器。
- **选择壁纸**：
  - 为所有显示器设置单一壁纸。
  - 为每个显示器分别设置不同壁纸。
- **备份/恢复配置**：备份和恢复 `hyprpaper.conf` 文件。
- **重载 Hyprpaper**：重新加载 Hyprpaper 以应用壁纸和配置更改。
- **日志记录**：记录所有操作到日志文件，便于调试。

备份/恢复逻辑：
- **备份时**：将 `hyprpaper.conf` 复制到 `~/backups/hyprpaper/`，并添加 `.backup` 后缀。
- **恢复时**：删除现有配置，将备份文件还原并复制回 `~/.config/hypr/`。

## 依赖

- **操作系统**：Arch Linux（需要 `pacman` 包管理器）。
- **软件**：
  - `hyprpaper`：Hyprland 的壁纸管理工具。
  - `hyprctl`：用于检测显示器（通常随 Hyprland 安装）。
  - `file`：用于验证壁纸文件格式。
- **权限**：需要对 `~/.config/hypr/` 和 `~/backups/hyprpaper/` 目录的写权限。

## 安装与准备

1. **下载脚本**：
   ```bash
   curl -fsSL -o hyprpaper-manager.sh https://raw.githubusercontent.com/<your-username>/<your-repo>/main/hyprpaper/hyprpaper-manager.sh
   ```

2. **赋予执行权限**：
   ```bash
   chmod +x hyprpaper-manager.sh
   ```

3. **运行脚本**：
   ```bash
   ./hyprpaper-manager.sh
   ```

**注**：将 `<your-username>` 和 `<your-repo>` 替换为你的 GitHub 用户名和仓库名。如果脚本未托管在 GitHub，可提供本地路径。

## 功能菜单

运行脚本后，会显示以下交互式菜单：

```
========== Hyprpaper 管理器 ==========
当前壁纸：/home/user/wallpapers/wallpaper1.png
Hyprpaper 状态：运行中
1) 安装 Hyprpaper
2) 卸载 Hyprpaper
3) 生成默认配置
4) 选择壁纸
5) 备份配置
6) 恢复配置
7) 重载 Hyprpaper
0) 退出
=====================================
```

## 功能详解

1. **安装 Hyprpaper**：
   - 使用 `pacman` 安装 Hyprpaper 包。
2. **卸载 Hyprpaper**：
   - 卸载 Hyprpaper 及其依赖。
3. **生成默认配置**：
   - 创建 `~/.config/hypr/hyprpaper.conf`，为每个检测到的显示器设置默认壁纸（`~/wallpapers/wallpaper1.png`）。
4. **选择壁纸**：
   - **单一壁纸**：为所有显示器设置同一壁纸，保存到 `~/wallpapers/wallpaper1.png`。
   - **不同壁纸**：为每个显示器分别设置壁纸，保存为 `~/wallpapers/wallpaper_$monitor.png`（例如 `wallpaper_DP-1.png`）。
   - 输入壁纸的绝对路径（支持 `.png`、`.jpg` 等图像格式），或按 Enter 使用默认路径。
5. **备份配置**：
   - 将 `hyprpaper.conf` 备份到 `~/backups/hyprpaper/hyprpaper.conf.backup`。
6. **恢复配置**：
   - 删除现有 `hyprpaper.conf`，从备份文件还原。
7. **重载 Hyprpaper**：
   - 终止并重新启动 Hyprpaper 以应用配置更改。

## 配置文件目录结构

配置完成后，目录结构如下：

```bash
~/.config/hypr/
└── hyprpaper.conf   # 主配置文件
```

备份目录结构：

```bash
~/backups/hyprpaper/
├── hyprpaper.conf.backup   # 备份配置文件
└── hyprpaper.log           # 操作日志
```

壁纸目录结构：

```bash
~/wallpapers/
├── wallpaper1.png           # 默认单一壁纸
├── wallpaper_DP-1.png       # 显示器 DP-1 的壁纸（多显示器模式）
├── wallpaper_HDMI-A-1.png   # 显示器 HDMI-A-1 的壁纸（多显示器模式）
└── ...
```

## 注意事项

- **Hyprland 运行**：脚本依赖 `hyprctl monitors` 获取显示器列表，确保 Hyprland 正在运行。
- **壁纸格式**：仅支持图像文件（如 `.png`、`.jpg`），脚本会验证文件格式。
- **权限**：确保对 `~/.config/hypr/` 和 `~/backups/hyprpaper/` 有写权限。
- **日志查看**：操作日志保存在 `~/backups/hyprpaper/hyprpaper.log`，可用于调试。
- **重载问题**：如果脚本卡在“正在重载 Hyprpaper...”，检查日志文件或手动运行 `hyprpaper` 查看错误。
- **多显示器支持**：脚本会自动检测显示器（如 `DP-1`、`HDMI-A-1`），确保壁纸路径有效。

## 快速上手示例

```bash
========== Hyprpaper 管理器 ==========
当前壁纸：/home/user/wallpapers/wallpaper1.png
Hyprpaper 状态：运行中
1) 安装 Hyprpaper
2) 卸载 Hyprpaper
3) 生成默认配置
4) 选择壁纸
5) 备份配置
6) 恢复配置
7) 重载 Hyprpaper
0) 退出
=====================================
请选择操作 [0-7]: 4
检测到以下显示器：
1) DP-1
2) HDMI-A-1
选择设置壁纸的方式：
1) 为所有显示器设置单一壁纸
2) 为每个显示器设置不同壁纸
请选择 [1-2]: 2
请输入显示器 DP-1 的壁纸路径（默认：/home/user/wallpapers/wallpaper1.png）：
/home/user/Pictures/wall1.png
配置文件已更新：/home/user/.config/hypr/hyprpaper.conf (显示器 DP-1)
请输入显示器 HDMI-A-1 的壁纸路径（默认：/home/user/wallpapers/wallpaper1.png）：
/home/user/Pictures/wall2.png
配置文件已更新：/home/user/.config/hypr/hyprpaper.conf (显示器 HDMI-A-1)
正在重载 Hyprpaper...
Hyprpaper 已重载。
所有显示器的壁纸已更新。
```

## 调试

如果遇到问题，请检查以下内容：

1. **日志文件**：
   ```bash
   cat ~/backups/hyprpaper/hyprpaper.log
   ```
2. **配置文件**：
   ```bash
   cat ~/.config/hypr/hyprpaper.conf
   ```
3. **显示器信息**：
   ```bash
   hyprctl monitors
   ```
4. **Hyprpaper 输出**：
   ```bash
   hyprpaper
   ```

## 贡献

欢迎提交问题或建议！请通过 GitHub Issues 或 Pull Requests 提供反馈。

## 许可证

[MIT 许可证](LICENSE)