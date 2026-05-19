# EasyTier KoolShare 插件

简单、安全、去中心化的内网穿透 VPN 组网方案，专为华硕路由器 KoolSHARE 软件中心设计。

## 简介

[EasyTier](https://github.com/EasyTier/EasyTier) 是一个使用 Rust 语言和 Tokio 框架实现的去中心化 VPN 组网方案。本插件将其移植到 KoolSHARE 软件中心，方便在华硕路由器上快速部署。

## 功能特性

- 支持 ARM64 (aarch64) 和 ARM32 (armv7l/armv6l) 架构 , 固件 qca 和 hnd
- Web 界面配置管理
- 开机自启动支持
- 配置文件在线编辑
- 服务状态实时监控
- 完整的日志输出

## 系统要求

- 华硕路由器 (梅林固件 / KoolSHARE 固件)
- 已安装 KoolSHARE 软件中心
- ARM64 或 ARM32 架构处理器

## 安装方法

### 方式一：软件中心离线安装（推荐）

1. 在 [Releases](../../releases) 页面下载 `easytier_qac.tar.gz`或者`easytier_hnd.tar.gz`
2. 打开路由器软件中心，点击「离线安装」
3. 上传 `easytier.tar.gz`，等待安装完成
4. 刷新页面，在软件中心列表中看到 EasyTier 图标即安装成功

### 方式二：手动安装（SSH）

```bash
# 上传 easytier.tar.gz 到路由器 /tmp 目录后执行
cd /tmp
tar -xzvf easytier.tar.gz
sh /tmp/easytier/install.sh
```


## 使用说明

### 配置文件

1. 复制下方配置模板，修改为自己的参数后粘贴到插件的配置文件文本框
2. 点击「保存配置」→「启动服务」
3. 详细参数说明参考 (https://github.com/EasyTier/EasyTier/blob/811f15115593a15e036d1247244054aca8308592/script/install.sh#L241-L275

https://aur.archlinux.org/cgit/aur.git/tree/config.toml?h=easytier)

**简单示例配置

```toml
# ==========================================
# 1. 全局配置 
# ==========================================
hostname = ""
ipv4 = ""

# ==========================================
# 2. 网络身份验证
# ==========================================
[network_identity]
network_name = ""
network_secret = ""

# ==========================================
# 3. 对等节点配置
# ==========================================
[[peer]]
uri = "udp://example.com:11010"

[[peer]]
uri = "tcp://example.com:11010"

[[peer]]
uri = "wss://example.com:11011"

# ==========================================
# 4. 子网代理 
# ==========================================
[[proxy_network]]
cidr = "192.168.1.0/24"
```


## 文件结构

```
.
├── bin/                        # 二进制文件目录
│   ├── easytier-core_arm64     # ARM64 核心程序
│   └── easytier-core_arm32     # ARM32 核心程序
├── scripts/
│   └── easytier_config.sh      # 配置管理脚本
├── webs/
│   └── Module_easytier.asp     # Web 管理界面
├── res/
│   └── easytier.png            # 插件图标
├── .valid                      # 固件认证qca hnd
├── Makefile                    # 打包脚本
├── config.json.js              # 插件元信息
├── install.sh                  # 安装脚本
└── uninstall.sh                # 卸载脚本
```

## 卸载

在软件中心中点击卸载按钮，或手动执行：

```bash
sh /koolshare/scripts/uninstall_easytier.sh
```

## 相关链接

- [EasyTier 官方项目](https://github.com/EasyTier/EasyTier)
- [EasyTier 官方文档](https://easytier.cn/)
- [配置文件相关链接](https://github.com/EasyTier/EasyTier/blob/811f15115593a15e036d1247244054aca8308592/script/install.sh#L241-L275

https://aur.archlinux.org/cgit/aur.git/tree/config.toml?h=easytier)
