# EasyTier KoolShare 插件

简单、安全、去中心化的内网穿透 VPN 组网方案，专为华硕路由器 KoolSHARE 软件中心设计。

## 简介

[EasyTier](https://github.com/EasyTier/EasyTier) 是一个使用 Rust 语言和 Tokio 框架实现的去中心化 VPN 组网方案。本插件将其移植到 KoolSHARE 软件中心，方便在华硕路由器上快速部署。

## 功能特性

- 支持 ARM64 (aarch64) 和 ARM32 (armv7l/armv6l) 架构
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

1. 下载插件安装包
2. 将安装包上传到路由器 `/tmp` 目录
3. 解压并运行安装脚本：

```bash
cd /tmp
tar -xzvf easytier.tar.gz
sh /tmp/easytier/install.sh
```

4. 安装完成后访问软件中心即可看到 EasyTier 图标

## 使用说明

### 配置文件

<<<<<<< HEAD
1. 复制配置内容粘贴到插件的配置文件文本框
2. 点击「保存配置」
3. 示例-更多配置查看[EasyTier 官方文档](https://easytier.cn/)：
```toml
# ==========================================
# 1. 全局配置 (必须放在最前面)
# ==========================================
hostname = "asus-router"
ipv4 = "10.126.126.133"

# ==========================================
# 2. 网络身份验证
# ==========================================
[network_identity]
network_name = "binbatnet"
network_secret = "zhuanfalun"

# ==========================================
# 3. 对等节点配置 (每个节点必须单独写一个 [[peer]])
# ==========================================
[[peer]]
uri = "udp://mutton.binbat.com:11010"

[[peer]]
uri = "tcp://mutton.binbat.com:11010"

[[peer]]
uri = "wss://mutton.binbat.com:11011"

# ==========================================
# 4. 旁路路由/子网代理 (每个网段单独写一个 [[proxy_network]])
# ==========================================
[[proxy_network]]
cidr = "192.168.133.0/24"
```
=======
1. 访问 [EasyTier 官方配置生成工具](https://easytier.cn/web/index.html#/config_generator)
2. 根据向导生成配置文件
3. 复制配置内容粘贴到插件的配置文件文本框
4. 点击「保存配置」

### 服务控制

- **启动服务**：启动 EasyTier VPN 服务
- **停止服务**：停止正在运行的服务
- **重启服务**：重启服务以应用新配置

### 开机自启动

勾选「开机自启动」选项并保存，系统重启后会自动启动 EasyTier 服务。
>>>>>>> 8e323566b59f1c5809e6d0f29a1e1cd65d826a28

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
<<<<<<< HEAD
=======
- [配置生成工具](https://easytier.cn/web/index.html#/config_generator)
>>>>>>> 8e323566b59f1c5809e6d0f29a1e1cd65d826a28
