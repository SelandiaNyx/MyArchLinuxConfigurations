# Waybar Manager - 一体化 Waybar 配置管理脚本

## 简介

`waybar-manager.sh` 是一个 bash 脚本，用于在 **Arch Linux** 上自动化管理 [Waybar](https://github.com/Alexays/Waybar) 及其配置文件。
脚本支持安装、卸载、配置、删除配置、备份配置和恢复配置，能快速切换和维护你的 Waybar 环境。

配置文件来自：

* [config.jsonc](https://github.com/SelandiaNyx/MyArchLinuxConfigurations/blob/main/Waybar/configuration/config.jsonc)
* [style.css](https://github.com/SelandiaNyx/MyArchLinuxConfigurations/blob/main/Waybar/configuration/style.css)

配置存放路径：`~/.config/waybar/`

## 脚本功能

* 安装/卸载 Waybar。
* 下载并配置 Waybar（自动拉取 JSONC 配置和 CSS 样式）。
* 删除配置（清空 `~/.config/waybar`）。
* 备份/恢复配置（存放在 `~/backups/waybar/`）。

备份/恢复逻辑：

* **备份时**：将现有配置文件添加 `.backup` 后缀并存放在 `~/backups/waybar/`。
* **恢复时**：删除现有配置，将 `.backup` 文件还原为原名并复制回 `~/.config/waybar/`。

## 安装与准备

1. 下载脚本

```bash
curl -fsSL -o waybar-manager.sh https://github.com/SelandiaNyx/MyArchLinuxConfigurations/raw/main/Waybar/auto-script/waybar-manager.sh
```

2. 赋予执行权限

```bash
chmod +x waybar-manager.sh
```

3. 运行脚本

```bash
./waybar-manager.sh
```

## 功能菜单

========== Waybar 管理器 ==========

1. 安装 Waybar
2. 卸载 Waybar
3. 配置 Waybar
4. 删除配置
5. 备份配置
6. 恢复配置
7. 退出

==================================

## 功能详解

1. **安装 Waybar**

   * 使用 `pacman` 安装 Waybar 包。

2. **卸载 Waybar**

   * 卸载 Waybar 及其依赖。

3. **配置 Waybar**

   * 创建 `~/.config/waybar/` 目录（如不存在）。
   * 下载 `config.jsonc` 和 `style.css` 到该目录。
   * 覆盖现有配置。

4. **删除配置**

   * 删除 `~/.config/waybar/` 目录及所有配置文件。

5. **备份配置**

   * 创建 `~/backups/waybar/` 文件夹（如不存在）。
   * 将 `~/.config/waybar/` 下的文件复制到备份目录，并加 `.backup` 后缀。

6. **恢复配置**

   * 删除 `~/.config/waybar/` 当前文件。
   * 将 `~/backups/waybar/` 内的 `.backup` 文件还原为原名并复制回 `~/.config/waybar/`。

## 配置文件目录结构

安装/配置完成后，目录结构如下：

```bash
~/.config/waybar/
├── config.jsonc   # 主配置文件
└── style.css      # 样式文件
```

备份目录结构：

```bash
~/backups/waybar/
├── config.jsonc.backup
└── style.css.backup
```

## 注意事项

* **依赖**：脚本基于 Arch Linux，使用 `pacman`。其他发行版需手动调整。
* **权限**：部分操作需要 `sudo`（安装/卸载软件），配置文件相关操作不需要。
* **备份机制**：与 `sddm-manager.sh` 一致，确保配置安全。
* **推荐**：使用 `waybar --log-level debug` 调试配置问题。
* **配置源**：直接拉取自 [MyArchLinuxConfigurations](https://github.com/SelandiaNyx/MyArchLinuxConfigurations)。

## 快速上手示例

* 安装 Waybar：选择 `1`。
* 配置 Waybar：选择 `3`，会直接下载最新配置。
* 修改配置前：选择 `5` 备份。
* 配置出错：选择 `6` 恢复备份。
* 删除配置：选择 `4`。
