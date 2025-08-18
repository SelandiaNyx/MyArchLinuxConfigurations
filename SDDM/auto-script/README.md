# SDDM 管理器

`sddm-manager.sh` 是一个统一结构的 Bash 脚本，用于管理 [SDDM](https://github.com/sddm/sddm/) 和 [sddm-astronaut-theme](https://github.com/keyitdev/sddm-astronaut-theme) 主题。  
它支持安装、卸载、子主题切换、主题更新、预览、备份和恢复，专为 **Arch Linux** 系列发行版设计。

---

## 📋 功能概览

- **安装/卸载 SDDM**（通过 `pacman`）
- **安装/卸载 astronaut 主题**（含字体自动安装）
- **切换子主题**（编号选择）
- **预览主题**（`sddm-greeter-qt6` 测试模式）
- **更新主题**（`git pull` 并刷新字体）
- **状态检查**（服务状态、当前主题与子主题）
- **备份/恢复配置**（防止因错误配置导致黑屏）

---

## 📂 配置与目录

- **主题目录**：`/usr/share/sddm/themes/sddm-astronaut-theme`
- **SDDM 主配置**：`/etc/sddm.conf`
- **SDDM 子配置目录**：`/etc/sddm.conf.d/`
- **备份目录**：`~/backups/sddm/`
- **日志目录**：`~/backups/sddm/logs/`

---

## 📦 依赖

- 操作系统：**Arch Linux**
- 软件包：
  - `sddm`
  - `qt6-svg qt6-virtualkeyboard qt6-multimedia-ffmpeg git`

---

## 🚀 使用方法

1. 下载脚本  

```bash
curl -fsSL -o sddm-manager.sh https://raw.githubusercontent.com/SelandiaNyx/MyArchLinuxConfigurations/refs/heads/main/SDDM/auto-script/sddm-manager.sh
chmod +x sddm-manager.sh
```

2. 运行脚本

```bash
./sddm-manager.sh
```

📜 菜单功能

```bash
========== SDDM 管理器 ==========
1) 安装 SDDM
2) 卸载 SDDM
3) 安装 astronaut 主题
4) 卸载 astronaut 主题
5) 切换子主题
6) 预览主题
7) 更新主题
8) 检查状态
9) 备份配置
10) 恢复配置
0) 退出
================================
```

⚠️ 注意事项

1. 首次安装主题时需要网络连接和 sudo 权限。
2. 切换子主题需要重启 SDDM 才能生效。
3. 预览功能可能与实际登录体验略有差异。
4. 建议在变更配置前先执行备份。
