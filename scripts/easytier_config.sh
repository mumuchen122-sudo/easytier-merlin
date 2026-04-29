#!/bin/sh
# EasyTier 终极优化版核心脚本

source /koolshare/scripts/base.sh
eval $(dbus export easytier_) 2>/dev/null || true

CONFIG_FILE="/koolshare/configs/easytier.conf"
EASYTIER_BIN="/koolshare/bin/easytier-core"
PID_FILE="/var/run/easytier.pid"
LOG_FILE="/tmp/upload/easytier_log.txt"
RUNTIME_LOG="/tmp/upload/easytier_runtime.log"

# 精准解析参数 (直接从 $@ 中提取，彻底抛弃玄学嗅探)
OPERATION=""
WEB_SUBMIT=""
for arg in "$@"; do
    case "$arg" in
        start|stop|restart|status|save_config|save_autostart)
            OPERATION="$arg"
            ;;
        web_submit)
            WEB_SUBMIT="web_submit"
            ;;
    esac
done

# 1. 极速状态查询 (不写日志，防止污染 API 输出)
check_status() {
    if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE" 2>/dev/null) 2>/dev/null; then
        http_response "运行"
    else
        http_response "停止"
    fi
}

# 2. 保存配置
save_config() {
    local content=""
    if [ -n "$easytier_config_content_encoded" ]; then
        content=$(echo "$easytier_config_content_encoded" | base64 -d 2>/dev/null)
    fi
    
    if [ -z "$content" ]; then
        echo_date "❌ 配置文件为空，请先在页面填写配置！" >> $LOG_FILE
        return 1
    fi
    
    mkdir -p "$(dirname "$CONFIG_FILE")"
    echo "$content" > "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE"
    
    # 将核心数据写入 DBUS
    dbus set easytier_autostart="$easytier_autostart"
    dbus set easytier_config_content_encoded="$easytier_config_content_encoded"
    
    echo_date "✅ 配置文件已保存" >> $LOG_FILE
    return 0
}

# 3. 启动服务 (修复描述符死锁)
start_easytier() {
    echo_date "🚀 正在启动 EasyTier..." >> $LOG_FILE
    
    if [ -f "$PID_FILE" ] && kill -0 $(cat $PID_FILE 2>/dev/null) 2>/dev/null; then
        echo_date "✅ EasyTier 已在运行，请勿重复启动" >> $LOG_FILE
        return 0
    fi
    
    if [ ! -s "$CONFIG_FILE" ]; then
        echo_date "❌ 启动失败：配置文件不存在或为空" >> $LOG_FILE
        return 1
    fi
    
    cd /tmp
    # 核心修复：重定向所有输入输出，彻底断开与 Web 接口的关联，防止 Timeout
    nohup $EASYTIER_BIN -c "$CONFIG_FILE" >>$RUNTIME_LOG 2>&1 </dev/null &
    echo $! > $PID_FILE
    
    sleep 2
    if kill -0 $(cat $PID_FILE 2>/dev/null) 2>/dev/null; then
        echo_date "✅ EasyTier 启动成功" >> $LOG_FILE
        return 0
    else
        echo_date "❌ EasyTier 启动失败，进程意外退出" >> $LOG_FILE
        rm -f $PID_FILE
        return 1
    fi
}

# 4. 停止服务
stop_easytier() {
    echo_date "⏹️ 正在停止 EasyTier..." >> $LOG_FILE
    if [ -f "$PID_FILE" ]; then
        kill $(cat $PID_FILE 2>/dev/null) 2>/dev/null
        sleep 1
        kill -9 $(cat $PID_FILE 2>/dev/null) 2>/dev/null
        rm -f "$PID_FILE"
    fi
    killall easytier-core >/dev/null 2>&1
     
    echo_date "✅ EasyTier 已停止" >> $LOG_FILE
    return 0
}

# ================= 路由中枢 =================

# API 状态查询拦截 (必须第一时间处理且退出)
if [ "$OPERATION" = "status" ]; then
    check_status
    exit 0
fi

# Web 表单提交处理
if [ "$WEB_SUBMIT" = "web_submit" ]; then
    true > $LOG_FILE 2>/dev/null
    echo_date "========= EasyTier 任务执行 =========" >> $LOG_FILE
    
    case "$OPERATION" in
        save_config)
            save_config
            ;;
        start)
            save_config && start_easytier
            ;;
        stop)
            stop_easytier
            ;;
        restart)
            save_config && stop_easytier && start_easytier
            ;;
        save_autostart)
            dbus set easytier_autostart="$easytier_autostart"
            echo_date "✅ 自启动设置已保存" >> $LOG_FILE
            ;;
        *)
            echo_date "❌ 发生未知的操作: $OPERATION" >> $LOG_FILE
            ;;
    esac
    
    echo_date "✅ Web操作完成" >> $LOG_FILE
    echo "XU6J03M6" >> $LOG_FILE
    exit 0
fi
