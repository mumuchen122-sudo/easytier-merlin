#!/bin/bash

# EasyTier 配置管理脚本 (深度优化版)
# 用于软件中心Web界面

# 安全地加载 base.sh
if [ -f /koolshare/scripts/base.sh ]; then
    source /koolshare/scripts/base.sh 2>/dev/null || true
fi

if [ -d "/koolshare" ]; then
    # Merlin环境
    CONFIG_FILE="/koolshare/configs/easytier.conf"
    EASYTIER_BIN="/koolshare/bin/easytier-core"
    PID_FILE="/var/run/easytier.pid"
    LOCK_FILE="/var/lock/easytier.lock"
    LOG_FILE="/tmp/upload/easytier_log.txt"
else
    alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
    # 测试环境
    CONFIG_FILE="/tmp/easytier/easytier.conf"
    EASYTIER_BIN="./easytier/bin/easytier-core"
    PID_FILE="/tmp/easytier.pid"
    LOCK_FILE="/tmp/easytier.lock"
    LOG_FILE="/tmp/easytier_log.txt"
fi

# 批量导出所有 easytier 相关的 dbus 变量
eval $(dbus export easytier_) 2>/dev/null || true

# 文件锁机制 (保留了框架注入的魔法 $ACTION)
set_lock() {
    exec 233>${LOCK_FILE}
    flock -n 233 || {
        # 锁冲突时，将当前被拦截的操作指令返回给前端
        http_response "$ACTION"
        exit 1
    }
}

unset_lock() {
    flock -u 233
    rm -rf ${LOCK_FILE}
}

# 从 dbus 加载配置
load_config_from_dbus() {
    config_content_encoded=${easytier_config_content_encoded:-$(dbus get easytier_config_content_encoded 2>/dev/null)}
    config_content=${easytier_config_content:-$(dbus get easytier_config_content 2>/dev/null)}
    autostart=${easytier_autostart:-$(dbus get easytier_autostart 2>/dev/null)}
    
    if [ -n "$config_content_encoded" ]; then
        config_content=$(echo "$config_content_encoded" | base64 -d 2>/dev/null || echo "$config_content")
    fi
}

# 验证配置参数
validate_config() {
    local has_error=0
    dbus set easytier_config_content_error=0 2>/dev/null || true
    
    if [ -z "$config_content" ]; then
        echo_date "❌ 配置文件内容不能为空" >> $LOG_FILE
        dbus set easytier_config_content_error=1 2>/dev/null || true
        has_error=1
    elif ! echo "$config_content" | grep -qE "(hostname|network_name|instance_name)"; then
        echo_date "⚠️ 警告：配置文件内容可能无效，缺少核心关键词" >> $LOG_FILE
    fi
    return $has_error
}

# 保存配置到文件
save_config_to_file() {
    mkdir -p "$(dirname "$CONFIG_FILE")" 2>/dev/null || true
    
    if ! validate_config; then
        return 1
    fi
    
    if [ -n "$config_content" ]; then
        echo "$config_content" > "$CONFIG_FILE" 2>/dev/null || return 1
        chmod 600 "$CONFIG_FILE" 2>/dev/null || true
        return 0
    fi
    return 1
}

# 保存配置到 dbus
save_config_to_dbus() {
    if command -v dbus >/dev/null 2>&1; then
        dbus set easytier_autostart="$autostart" 2>/dev/null || true
        dbus set easytier_config_content="$config_content" 2>/dev/null || true
        if [ -n "$config_content_encoded" ]; then
            dbus set easytier_config_content_encoded="$config_content_encoded" 2>/dev/null || true
        fi
        dbus set easytier_version="1.2.0" 2>/dev/null || true
        return 0
    fi
    return 1
}

# 检查服务状态
check_status() {
    if [ -f "$PID_FILE" ]; then
        local PID=$(cat "$PID_FILE" 2>/dev/null)
        if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
            http_response "运行"
        else
            http_response "异常"
        fi
    else
        http_response "停止"
    fi
}

# 启动 EasyTier
start_easytier() {
    echo_date "🚀 正在启动 EasyTier..." | tee -a ${LOG_FILE}
    if [ -f "$PID_FILE" ] && kill -0 $(cat $PID_FILE 2>/dev/null) 2>/dev/null; then
        echo_date "✅ EasyTier 已在运行" | tee -a ${LOG_FILE}
        return 0
    fi
    if [ ! -f "$CONFIG_FILE" ] || [ ! -s "$CONFIG_FILE" ]; then
        echo_date "❌ 配置文件不存在或为空" | tee -a ${LOG_FILE}
        return 1
    fi
    if [ ! -f "$EASYTIER_BIN" ]; then
        echo_date "❌ 二进制文件不存在: $EASYTIER_BIN" | tee -a ${LOG_FILE}
        return 1
    fi

    cd /tmp
    nohup $EASYTIER_BIN -c "$CONFIG_FILE" > /dev/null 2>&1 &
    echo $! > $PID_FILE
    sleep 2 # 给予进程初始化时间
    
    if [ -f $PID_FILE ] && kill -0 $(cat $PID_FILE 2>/dev/null) 2>/dev/null; then
        echo_date "✅ EasyTier 启动成功" | tee -a ${LOG_FILE}
        return 0
    else
        echo_date "❌ EasyTier 启动失败，进程意外退出" | tee -a ${LOG_FILE}
        rm -f $PID_FILE
        return 1
    fi
}

# 停止 EasyTier
stop_easytier() {
    echo_date "⏹️ 正在停止 EasyTier..." | tee -a ${LOG_FILE}
    if [ -f $PID_FILE ]; then
        local PID=$(cat $PID_FILE 2>/dev/null)
        if kill -0 $PID 2>/dev/null; then
            kill $PID
            local i=1
            while [ $i -le 5 ]; do
                ! kill -0 $PID 2>/dev/null && break
                sleep 1
                i=$((i + 1))
            done
            # 强制清理
            kill -0 $PID 2>/dev/null && kill -9 $PID 2>/dev/null
        fi
        rm -f $PID_FILE
    fi
    killall easytier-core >/dev/null 2>&1
    echo_date "✅ EasyTier 已停止" | tee -a ${LOG_FILE}
    return 0
}

# 保存全部配置
save_config() {
    autostart="$easytier_autostart"
    config_content_encoded="$easytier_config_content_encoded"
    
    if [ -n "$config_content_encoded" ]; then
        config_content=$(echo "$config_content_encoded" | base64 -d 2>/dev/null)
    fi
    
    if validate_config && save_config_to_dbus && save_config_to_file; then
        echo_date "✅ 配置保存成功" | tee -a ${LOG_FILE}
        return 0
    else
        echo_date "❌ 配置保存失败" | tee -a ${LOG_FILE}
        return 1
    fi
}

# 保存自启动配置
save_autostart_config() {
    autostart="$easytier_autostart"
    if command -v dbus >/dev/null 2>&1; then
        dbus set easytier_autostart="$autostart" 2>/dev/null || true
        echo_date "✅ 自启动配置保存成功" | tee -a ${LOG_FILE}
        return 0
    fi
    return 1
}

# 输出配置 (前端获取)
get_config() {
    local autostart_val="" config_content_val="" version_val="1.2.0"
    if command -v dbus >/dev/null 2>&1; then
        autostart_val=$(dbus get easytier_autostart 2>/dev/null)
        config_content_val=$(dbus get easytier_config_content 2>/dev/null)
        version_val=$(dbus get easytier_version 2>/dev/null || echo "1.2.0")
    fi
    
    [ -z "$config_content_val" ] && [ -f "$CONFIG_FILE" ] && config_content_val=$(cat "$CONFIG_FILE" 2>/dev/null)
    
    # 兼容 Busybox 的 base64：使用 tr 删除换行符
    local config_encoded=""
    [ -n "$config_content_val" ] && config_encoded=$(echo "$config_content_val" | base64 2>/dev/null | tr -d '\n')
    
    echo "easytier_autostart=${autostart_val}"
    echo "easytier_config_content_encoded=${config_encoded}"
    echo "easytier_version=${version_val}"
}

# 统一错误处理
handle_error() {
    echo_date "❌ 操作失败: $1" | tee -a ${LOG_FILE}
    echo "XU6J03M6" | tee -a ${LOG_FILE}
    unset_lock
    exit 1
}

# ----------------- 路由执行逻辑 -----------------
OPERATION="$1"
WEB_SUBMIT="$2"

echo_date "==================== EasyTier 运行 ====================" > $LOG_FILE
echo_date "参数接收: OPERATION=$OPERATION, WEB_SUBMIT=$WEB_SUBMIT" >> $LOG_FILE

# 如果来源于 Web 提交，走统一的界面日志处理流程
if [ "$WEB_SUBMIT" = "web_submit" ]; then
    set_lock
    case "$OPERATION" in
        save_config)
            save_config || handle_error "配置保存出错"
            ;;
        save_autostart)
            save_autostart_config || handle_error "自启动配置保存出错"
            ;;
        start)
            save_config && load_config_from_dbus && start_easytier || handle_error "服务启动出错"
            ;;
        stop)
            save_config && stop_easytier || handle_error "服务停止出错"
            ;;
        restart)
            save_config && load_config_from_dbus && stop_easytier && start_easytier || handle_error "服务重启出错"
            ;;
        *)
            handle_error "未知的操作: $OPERATION"
            ;;
    esac
    echo_date "✅ 操作完成" | tee -a ${LOG_FILE}
    echo "XU6J03M6" | tee -a ${LOG_FILE}
    unset_lock
    exit 0
fi

# 命令行直接调用
case "$OPERATION" in
    status) check_status ;;
    start)  load_config_from_dbus; start_easytier ;;
    stop)   stop_easytier ;;
    restart) load_config_from_dbus; stop_easytier; start_easytier ;;
    get_config) get_config ;;
    *) echo "Usage: $0 {status|start|stop|restart|get_config} [web_submit]"; exit 1 ;;
esac