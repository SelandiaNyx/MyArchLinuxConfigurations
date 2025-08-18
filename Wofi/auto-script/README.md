# Wofi 管理器

`wofi-manager.sh` 是一个统一结构的 Bash 脚本，用于在 **Arch Linux** 系统上管理 [Wofi](https://hg.sr.ht/~scoopta/wofi) 启动器的安装、配置、备份与恢复。  
它能自动下载配置文件与样式表，一键应用或还原，方便快速部署 Wofi。

---

## 📋 功能概览

- **安装/卸载 Wofi**（通过 `pacman`）
- **下载并应用配置**（自动拉取远程 launcher、powermenu 脚本和样式表）
- **删除配置目录**
- **备份/恢复配置**

---

## 📂 配置与目录

- **Wofi 配置目录**：`~/.config/wofi/`
- **备份目录**：`~/backups/wofi/`
- **日志目录**：`~/backups/wofi/logs/`
- **配置来源**：
  - `launchermenu.sh`
  - `powermenu.sh`
  - `style.css`

---

## 📦 依赖

- 操作系统：**Arch Linux**
- 软件包：`wofi`、`curl`

---

## 🚀 使用方法

1. 下载脚本  

```bash
curl -fsSL -o wofi-manager.sh https://raw.githubusercontent.com/SelandiaNyx/MyArchLinuxConfigurations/refs/heads/main/Wofi/auto-script/wofi-manager.sh
chmod +x wofi-manager.sh
```

2. 运行脚本

```bash
./wofi-manager.sh
```

📜 菜单功能

```bash
========== Wofi 管理器 ==========
1) 安装
2) 卸载
3) 应用配置
4) 删除配置
5) 备份配置
6) 恢复配置
0) 退出
==================================
```

⚠️ 注意事项

1. 应用配置需要网络连接。

2. 删除配置会清空 ~/.config/wofi/，建议先执行备份。

3. 恢复时会覆盖当前配置，请谨慎操作。
