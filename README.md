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

### 方式一：软件中心离线安装（推荐）

1. 在 [Releases](../../releases) 页面下载 `easytier.tar.gz`
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

### 开发者：自行打包

```bash
# 1. 下载对应架构的 easytier-core 二进制到 bin/ 目录
#    https://github.com/EasyTier/EasyTier/releases
# 2. 运行打包脚本
bash build.sh
# 3. 生成的 easytier.tar.gz 即可用于安装
```

## 使用说明

### 配置文件

1. 复制下方配置模板，修改为自己的参数后粘贴到插件的配置文件文本框
2. 点击「保存配置」→「启动服务」
3. 详细参数说明参考 [EasyTier 官方文档](https://easytier.cn/guide/network/configurations.html)

**场景一：路由器作为纯客户端**（只连别人，自己不暴露端口，适合没有公网 IP 的家庭路由器）

```toml
# 实例名称，同一台机器上唯一即可
instance_name = "default"
# 实例 ID，同一组网内必须唯一（可用 cat /proc/sys/kernel/random/uuid 生成）
instance_id = "e35ef2df-b325-47c7-9688-3d1ab7139dec"
# 主机名，用于在管理界面中标识此节点
hostname = "asus-router"
# 此节点在 VPN 网络中的虚拟 IP，组网内不能冲突
ipv4 = "10.126.126.2"
# 监听端口列表，客户端可以留空或仅监听本地
listeners = []
# RPC 管理门户地址
rpc_portal = "127.0.0.1:15888"

[network_identity]
# 组网名称，所有节点必须一致
network_name = "my-network"
# 组网密码，所有节点必须一致
network_secret = "your-secret-password"

# 对等节点，指向公网服务器或其它已在线节点（可配置多个）
[[peer]]
uri = "tcp://your-server.com:11010"

[[peer]]
uri = "udp://your-server.com:11010"

# 子网代理：让组网内其它节点可以访问路由器所在的局域网（可配置多个）
[[proxy_network]]
cidr = "192.168.50.0/24"

[flags]
# 虚拟网卡名称
dev_name = "easytier0"
# 启用延迟优先模式，自动选择最低延迟链路
latency_first = true
# 默认传输协议
default_protocol = "tcp"
```

**场景二：公网服务器**（监听端口接受连接，为其它节点提供中转）

```toml
instance_name = "default"
instance_id = "c0871c03-2a55-4708-a3b9-426666f46b1c"
hostname = "vps-server"
ipv4 = "10.126.126.1"
# 公网节点必须配置监听端口
listeners = [
    "tcp://0.0.0.0:11010",
    "udp://0.0.0.0:11010",
    "wss://0.0.0.0:11011",
]
rpc_portal = "127.0.0.1:15888"

[network_identity]
network_name = "my-network"
network_secret = "your-secret-password"

# 公网节点可以添加公共中继 peer 来帮助内网节点打洞
[[peer]]
uri = "tcp://public.easytier.top:11010"

[flags]
dev_name = "easytier0"
latency_first = true
default_protocol = "tcp"
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
