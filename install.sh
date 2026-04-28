#!/bin/sh

# EasyTier 软件中心安装脚本 (优化配合版)
# 适用于华硕 arm64(aarch64) 和 arm32(armv7l) 架构的路由器

source /koolshare/scripts/base.sh
alias echo_date='echo 【$(date +"%Y年%m月%d日 %H:%M:%S")】'

# 模块基本信息
MODULE="easytier"
VERSION="1.0.0"

# 路径定义
KS_DIR="/koolshare"
BIN_DIR="$KS_DIR/bin"
SCRIPT_DIR="$KS_DIR/scripts"
WEB_DIR="$KS_DIR/webs"
RES_DIR="$KS_DIR/res"
INIT_DIR="$KS_DIR/init.d"
CONFIG_DIR="$KS_DIR/configs"
SOURCE_DIR="/tmp/easytier"

# 设置互斥锁
set_lock(){
    exec 1000>"/tmp/easytier_install.lock"
    flock -x 1000
}

unset_lock(){
    flock -u 1000
    exec 1000>&-
    rm -f /tmp/easytier_install.lock
}

check_arch(){
    ARCH=$(uname -m)
    case "$ARCH" in
        aarch64|armv7l|armv6l)
            echo_date "✅ 检测到支持的架构: $ARCH"
            ;;
        *)
            echo_date "❌ 错误: 不支持的架构: $ARCH"
            echo_date "仅支持 ARM64 (aarch64) 和 ARM32 (armv7l/armv6l)"
            exit 1
            ;;
    esac
}

check_space(){
    local available=$(df $KS_DIR | tail -1 | awk '{print $4}')
    local required=5000
    if [ "$available" -lt "$required" ]; then
        echo_date "⚠️ 警告: /koolshare 分区可用空间不足，可能导致安装失败！"
    fi
}

install_files(){
    echo_date "开始复制文件..."
    
    # 1. 拷贝并重命名二进制核心
    if [ "$ARCH" = "aarch64" ]; then
        BIN_SRC="$SOURCE_DIR/bin/easytier-core_arm64"
    else
        BIN_SRC="$SOURCE_DIR/bin/easytier-core_arm32"
    fi

    if [ -f "$BIN_SRC" ]; then
        cp -f "$BIN_SRC" $BIN_DIR/easytier-core
        chmod 755 $BIN_DIR/easytier-core
        echo_date "✓ 核心二进制文件复制成功"
    else
        echo_date "❌ 找不到核心文件: $BIN_SRC"
        exit 1
    fi
    
    # 2. 拷贝主控脚本
    if [ -f "$SOURCE_DIR/scripts/easytier_config.sh" ]; then
        cp -f "$SOURCE_DIR/scripts/easytier_config.sh" $SCRIPT_DIR/easytier_config.sh
        chmod 755 $SCRIPT_DIR/easytier_config.sh
        echo_date "✓ 主控脚本复制成功"
    fi
    
    # 3. 拷贝 Web UI
    if [ -f "$SOURCE_DIR/webs/Module_easytier.asp" ]; then
        cp -f "$SOURCE_DIR/webs/Module_easytier.asp" $WEB_DIR/Module_easytier.asp
        echo_date "✓ Web界面复制成功"
    fi
    
    # 4. 拷贝图标与配置
    if [ -f "$SOURCE_DIR/res/easytier.png" ]; then
        cp -f "$SOURCE_DIR/res/easytier.png" $RES_DIR/icon-easytier.png
    fi
    if [ -f "$SOURCE_DIR/config.json.js" ]; then
        cp -f "$SOURCE_DIR/config.json.js" $KS_DIR/
    fi
    
    # 确保配置目录存在
    mkdir -p $CONFIG_DIR
}

create_uninstall_script(){
    # 动态生成卸载脚本，注意清理我们在前后端用到的新 DBUS 变量和二进制文件
    cat > $SCRIPT_DIR/uninstall_easytier.sh <<-EOF
#!/bin/sh
source /koolshare/scripts/base.sh

echo_date "⏹️ 正在停止 EasyTier 服务..."
sh /koolshare/scripts/easytier_config.sh stop >/dev/null 2>&1

echo_date "🗑️ 正在清理文件..."
rm -f /koolshare/bin/easytier-core
rm -f /koolshare/webs/Module_easytier.asp
rm -f /koolshare/res/icon-easytier.png
rm -f /koolshare/scripts/easytier_config.sh
rm -f /koolshare/init.d/S99easytier.sh
rm -f /koolshare/init.d/N99easytier.sh
rm -rf /koolshare/configs/easytier.conf

echo_date "🧹 正在清理系统配置(dbus)..."
# 清理软件中心注册信息
dbus remove softcenter_module_easytier_version
dbus remove softcenter_module_easytier_install
dbus remove softcenter_module_easytier_name
dbus remove softcenter_module_easytier_title
dbus remove softcenter_module_easytier_description

# 清理咱们优化后的专有配置
dbus remove easytier_version
dbus remove easytier_autostart
dbus remove easytier_config_content
dbus remove easytier_config_content_encoded

# 兼容清理旧版残留
dbus remove easytier_enable
dbus remove easytier_ip
dbus remove easytier_name
dbus remove easytier_secret
dbus remove easytier_peers

rm -f /koolshare/scripts/uninstall_easytier.sh
echo_date "✅ EasyTier 已彻底卸载！"
EOF
    chmod 755 $SCRIPT_DIR/uninstall_easytier.sh
}

add_to_software_center(){
    echo_date "写入软件中心配置..."
    
    # 注册软件中心信息
    dbus set softcenter_module_easytier_version="$VERSION"
    dbus set softcenter_module_easytier_install="1"
    dbus set softcenter_module_easytier_name="easytier"
    dbus set softcenter_module_easytier_title="EasyTier"
    dbus set softcenter_module_easytier_description="简单、安全、去中心化的内网穿透 VPN"
    dbus set easytier_version="$VERSION"
    
    # 默认自启动
    [ -z "$(dbus get easytier_autostart)" ] && dbus set easytier_autostart="1"

    # 生成开机自启脚本 S99 (修复原版无脑自启的 Bug)
    cat > $INIT_DIR/S99easytier.sh <<-EOF
#!/bin/sh
source /koolshare/scripts/base.sh
# 检查是否勾选了开机自启动
if [ "\$(dbus get easytier_autostart)" = "1" ]; then
    if [ -f /koolshare/scripts/easytier_config.sh ]; then
        sh /koolshare/scripts/easytier_config.sh start
    fi
fi
EOF
    chmod 755 $INIT_DIR/S99easytier.sh
    
    # 生成关机停止脚本 N99
    cat > $INIT_DIR/N99easytier.sh <<-EOF
#!/bin/sh
if [ -f /koolshare/scripts/easytier_config.sh ]; then
    sh /koolshare/scripts/easytier_config.sh stop
fi
EOF
    chmod 755 $INIT_DIR/N99easytier.sh
}

main(){
    set_lock
    echo_date "======================================================="
    echo_date "开始安装 EasyTier v$VERSION ..."
    
    check_arch
    check_space
    install_files
    create_uninstall_script
    add_to_software_center
    
    # 清理安装包释放内存 (重要步骤)
    echo_date "清理临时安装文件..."
    rm -rf $SOURCE_DIR
    
    echo_date "✅ EasyTier 安装完成！"
    echo_date "请访问 http://$(nvram get lan_ipaddr)/Module_easytier.asp 进行配置"
    echo_date "======================================================="
    
    unset_lock
}

main "$@"