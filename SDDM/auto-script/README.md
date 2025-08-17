# SDDM Manager - 一体化 SDDM 和 astronaut 主题管理脚本

## 简介

`sddm-manager.sh` 是一个 bash 脚本，用于管理 SDDM (Simple Desktop Display Manager) 和 sddm-astronaut-theme 主题（基于 [sddm-astronaut-theme](https://github.com/keyitdev/sddm-astronaut-theme)
）。脚本支持 Arch Linux 及其衍生版，使用 pacman 安装依赖。

主题特点（来自仓库介绍）：

- 使用 Qt6，支持虚拟键盘、动画壁纸。
- 10 个预定义子主题，通过修改 metadata.desktop 的 ConfigFile 行切换。
- 默认分辨率 1080p，但兼容其他分辨率。
- 许可证：GPLv3+，版权 2022-2025 Keyitdev。

脚本功能：

- 安装/卸载 SDDM。
- 安装/卸载 astronaut 主题（默认子主题 hyprland_kath，所有子主题可用）。
- 切换子主题（支持编号输入）。
- 预览主题（无需注销）。
- 更新主题（git pull）。
- 检查状态（服务、主题、子主题）。
- 备份/恢复配置（防止黑屏）。

已修复问题：

- 安装时检测不完整目录（缺失 Fonts/ 或 metadata.desktop），自动重克隆。
- 切换主题时支持输入编号，避免名称输入错误。

## 安装与准备

按照以下步骤即可下载并运行 `sddm-manager.sh` 脚本：

1. 下载脚本

```bash
curl -fsSL -o sddm-manager.sh https://github.com/SelandiaNyx/MyArchLinuxConfigurations/raw/main/SDDM/auto-script/sddm-manager.sh
```

2. 赋予执行权限

```bash
chmod +x sddm-manager.sh
```

3. 运行脚本

```bash
./sddm-manager.sh
```

- 菜单出现，选择操作。

## 功能菜单

========== SDDM 管理器 ==========

1. 安装 SDDM
2. 卸载 SDDM
3. 安装 astronaut 主题 (默认 hyprland_kath)
4. 卸载 astronaut 主题
5. 切换 astronaut 子主题
6. 预览当前主题
7. 更新 astronaut 主题
8. 检查当前状态
9. 备份配置
10. 恢复配置
11. 退出

================================

## 功能详解

1. **安装 SDDM**：
   - 安装 `sddm` 包并启用服务。

2. **卸载 SDDM**：
   - 禁用服务并移除包。

3. **安装 astronaut 主题 (默认 hyprland_kath)**：
   - 安装依赖：`qt6-svg qt6-virtualkeyboard qt6-multimedia-ffmpeg git`。
   - 克隆仓库到 `/usr/share/sddm/themes/sddm-astronaut-theme`（如果不完整，重克隆）。
   - 复制 Fonts/* 到 `/usr/share/fonts/` 并刷新缓存。
   - 配置 `/etc/sddm.conf`：Current=sddm-astronaut-theme。
   - 启用虚拟键盘：`/etc/sddm.conf.d/virtualkbd.conf`。
   - 修改 metadata.desktop：ConfigFile=Themes/hyprland_kath.conf。
   - 重启 SDDM。

4. **卸载 astronaut 主题**：
   - 切换回 Breeze 主题。
   - 删除虚拟键盘配置和主题目录。
   - 刷新字体缓存，重启 SDDM。

5. **切换 astronaut 子主题**：
   - 列出子主题（编号 1-10，例如 1 astronaut, 2 black_hole）。
   - 输入编号切换（修改 metadata.desktop 的 ConfigFile）。
   - 重启 SDDM。

6. **预览当前主题**：
   - 运行 `sddm-greeter-qt6 --test-mode --theme ...`（预览可能与实际略异）。

7. **更新 astronaut 主题**：
   - git pull 更新仓库，刷新字体。

8. **检查当前状态**：
   - 显示 SDDM 服务、当前主题、子主题。

9. **备份配置**：
   - 备份 `/etc/sddm.conf*` 到 `/etc/sddm.backup/`。

10. **恢复配置**：
    - 从备份恢复，重启 SDDM。

## 可用子主题列表（基于仓库）

1. astronaut
2. black_hole
3. japanese_aesthetic
4. pixel_sakura_static
5. purple_leaves
6. cyberpunk
7. post-apocalyptic_hacker
8. hyprland_kath
9. pixel_sakura
10. jake_the_dog

## 主题目录结构（安装后）

/usr/share/sddm/themes/sddm-astronaut-theme/

├── Fonts/  # 主题字体

├── Themes/# 子主题 .conf 文件

├── metadata.desktop        # 主题配置（ConfigFile 行控制子主题）

└── ...                     # 其他文件（如壁纸、QML）

## 注意事项

- **权限**：脚本使用 sudo 执行系统操作，确保有 sudo 权限。
- **兼容性**：针对 Arch Linux (pacman)。其他发行版（如 Fedora）需修改依赖命令（参考仓库：dnf 等）。
- **风险**：修改前备份配置（选项9）。如果黑屏，重启到 TTY (Ctrl+Alt+F2) 运行选项10恢复。
- **预览限制**：可能与实际登录界面略异，取决于系统配置。
- **依赖**：SDDM >= 0.21.0, Qt6 >= 6.8。推荐安装 h.264 视频编解码器以支持动画壁纸。
- **安全**：运行前阅读脚本。克隆自官方 GitHub，始终检查源代码。
- **支持项目**：如仓库所述，给 GitHub star 或帮助开发。

## 快速上手示例

- 安装主题：选择 3，重启后见 hyprland_kath。
- 切换到 black_hole：选择 5，输入 2。
- 预览：选择 6。
- 更新：选择 7。
- 卸载：选择 4。

如果问题，检查 SDDM 日志：`journalctl -u sddm`。仓库最新验证于 2025 年 8 月 17 日，无重大变化。
