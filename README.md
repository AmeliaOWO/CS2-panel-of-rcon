# 🎮 CS2 RCON 面板 ✨

> **诶嘿~ 你服务器的远程遥控器来啦！** 🎛️💚

跨平台（**Windows 🖥️ + Android 📱**）的 CS2 服务器 RCON 控制面板，全用 **Dart / Flutter** 打造，没有 Web 框架，纯原生应用哒！(◍•ᴗ•◍)✧

---

## 🌟 它能做什么？

| 功能 | 说明 |
|------|------|
| 🔌 **连上服务器** | IP + 端口 + RCON 密码，一键连接，断线自动重连~ |
| ℹ️ **看服务器信息** | 地图、玩家数、服务器名，一目了然！ |
| 👥 **管玩家** | 踢出 ⛔ / 封禁 🔨 / 处决 💀 一条龙服务 |
| ⚡ **快捷指令** | 开作弊、重启游戏、加 Bot、踢 Bot……点一下就好！ |
| 🗺️ **切换地图** | 官方图？创意工坊图？输入 ID 直接飞过去！ |
| 📋 **日志面板** | 所有指令和回复都记在小本本上 📝 |

---

## 🛠️ 技术栈

```
╔══════════════════════╗
║  🎯 Dart 3.x         ║
║  🎨 Flutter + M3     ║
║  📦 provider          ║
║  🔌 Socket (原生RCON) ║
║  🧵 Isolate (不卡UI)  ║
║  🌐 connectivity_plus ║
╚══════════════════════╝
```

所有代码都整整齐齐躺在 `lib/` 里 ✨

---

## 🎨 设计风格

- 🖤 深色主题 — CS2 内味儿！
- 💚 **Emerald 绿** + 🎯 **Slate 灰**
- 📐 间距基准 **4px**（4, 8, 12, 16… 强迫症狂喜）
- 🔤 **Noto Sans SC**（中文字体好看） + **JetBrains Mono**（代码等宽优雅）

---

## 🚀 下载 & 安装

### 📥 获取安装包

去 [**Releases**](https://github.com/AmeliaOWO/CS2-panel-of-rcon/releases) 页面下载最新版本！

| 平台 | 下载啥 |
|------|--------|
| 🖥️ **Windows** | `cs2-rcon-panel-windows.zip`（解压即玩） |
| 📱 **Android** | `cs2-rcon-panel.apk` |

> 💡 Windows 版下载后解压，双击 `cs2_rcon_panel.exe` 就能用啦！不用安装~ Android 直接装 APK~

### 你需要

- 一台 CS2 服务器（开了 RCON 的！设置了 `rcon_password`）
- Windows 10/11 或 Android 8+

### 🎯 怎么用？

1. 打开软件，输入服务器 **IP**、**端口**（默认 `27015`）和 **RCON 密码**
2. 点 **「连接」** ✨ 成功自动跳转主面板
3. **玩家** 标签 → 管人！ Kick / Ban / Slay
4. **指令** 标签 → 开作弊、换地图、重启游戏……随便玩！
5. **日志** 标签 → 所有操作都记着呢 📝

---

## 🗺️ 项目长这样

```
lib/
├── 🏠 main.dart                    # 入口
├── 🎨 design/
│   └── tokens.dart                 # 颜色、字体、主题
├── 🔌 services/
│   └── rcon_service.dart           # RCON 连接（在另一个线程跑！）
├── 📦 providers/
│   └── rcon_provider.dart          # 状态管理
├── 🖼️ screens/
│   ├── connect_screen.dart         # 连接页面
│   └── dashboard_screen.dart       # 主面板
└── 🧩 widgets/
    ├── command_button.dart          # 按钮
    ├── player_card.dart             # 玩家卡片
    └── log_output.dart              # 日志
```

---

## 🧸 小贴士

<details>
<summary><b>🔐 安全第一！</b></summary>

- 密码不会存代码里！每次都手输 (｀・ω・´)
- 断开连接后密码就消失啦~
- RCON 是明文传输的，**别在公共网络用**！
</details>

<details>
<summary><b>🔄 连不上？试试这些！</b></summary>

1. 服务器 `rcon_password` 设了吗？
2. 防火墙放行了 UDP 27015 吗？
3. `telnet <IP> 27015` 通吗？
4. 试试 `sv_rcon_whitelist_address 0.0.0.0`
</details>

<details>
<summary><b>🗺️ 创意工坊地图怎么用？</b></summary>

把 **Workshop ID** 或 **Steam 链接** 贴进去就行！比如：

```
https://steamcommunity.com/sharedfiles/filedetails/?id=3170756386
```

或者直接输数字 ID：`3170756386`

系统会自动提取 ID，执行 `host_workshop_map` 加载地图 ✨
</details>

---

## 📜 License

**MIT** — 想怎么改就怎么改，开心就好！🎉

---

<p align="center">
  <b>⭐ 如果觉得有用，点个 Star 嘛~ 喵~ 🐱</b>
</p>
