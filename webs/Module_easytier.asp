<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="X-UA-Compatible" content="IE=Edge" />
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta http-equiv="Pragma" content="no-cache" />
<meta http-equiv="Expires" content="-1" />
<link rel="shortcut icon" href="/res/icon-easytier.png" />
<link rel="icon" href="/res/icon-easytier.png" />
<title>软件中心 - EasyTier</title>
<link rel="stylesheet" type="text/css" href="index_style.css">
<link rel="stylesheet" type="text/css" href="form_style.css">
<link rel="stylesheet" type="text/css" href="usp_style.css">
<link rel="stylesheet" type="text/css" href="css/element.css">
<link rel="stylesheet" type="text/css" href="/device-map/device-map.css">
<link rel="stylesheet" type="text/css" href="/js/table/table.css">
<link rel="stylesheet" type="text/css" href="/res/layer/theme/default/layer.css">
<link rel="stylesheet" type="text/css" href="/res/softcenter.css">
<script language="JavaScript" type="text/javascript" src="/js/jquery.js"></script>
<script language="JavaScript" type="text/javascript" src="/state.js"></script>
<script language="JavaScript" type="text/javascript" src="/popup.js"></script>
<script language="JavaScript" type="text/javascript" src="/help.js"></script>
<script language="JavaScript" type="text/javascript" src="/js/httpApi.js"></script>
<script language="JavaScript" type="text/javascript" src="/client_function.js"></script>
<script language="JavaScript" type="text/javascript" src="/general.js"></script>
<script language="JavaScript" type="text/javascript" src="/js/table/table.js"></script>
<script language="JavaScript" type="text/javascript" src="/res/softcenter.js"></script>
<style>
a:focus { outline: none; }
.SimpleNote { padding:5px 5px; }
i { color: #FC0; font-style: normal; } 
.loadingBarBlock{ width:740px; }
.popup_bar_bg_ks{ position:fixed; margin: auto; top: 0; left: 0; width:100%; height:100%; z-index:99; filter:alpha(opacity=90); visibility:hidden; background:rgba(68, 79, 83, 0.85); }
.FormTitle em { color: #00ffe4; font-style: normal; }
.FormTable th { width: 30%; }
.formfonttitle { font-family: Roboto-Light, "Microsoft JhengHei"; font-size: 18px; margin-left: 5px; }
.FormTitle, .FormTable th, .FormTable td { font-size: 14px; font-family: Roboto-Light, "Microsoft JhengHei"; }
</style>
<script type="text/javascript">
var dbus = {};
var refresh_flag = 0;
var count_down;

function init() {
    show_menu(menu_hook);
    register_event();
    get_dbus_data();
    check_status();
}

function get_dbus_data() {
    $.ajax({
        type: "GET", url: "/_api/easytier_", dataType: "json", async: false,
        success: function(data) {
            dbus = (data && data.result && data.result[0]) ? data.result[0] : {};
            conf2obj();
        },
        error: function() { conf2obj(); }
    });
}

function conf2obj() {
    // 兼容解析包含中文的 Base64 配置
    if (dbus['easytier_config_content_encoded']) {
        try {
            E("easytier_config_content").value = decodeURIComponent(escape(atob(dbus['easytier_config_content_encoded'])));
        } catch(e) { console.log("Base64解码失败:", e); }
    }
    if (dbus['easytier_autostart']) E("easytier_autostart").checked = dbus['easytier_autostart'] !== "0";
    if (dbus["easytier_version"]) E("easytier_version").innerHTML = " - " + dbus["easytier_version"];
    
    E("easytier_status").style.display = "";
    update_autostart_availability();
}

function update_autostart_availability() {
    var content = E("easytier_config_content").value.trim();
    E("easytier_autostart").disabled = !content;
    E("autostart_warning").style.display = content ? "none" : "";
}

function menu_hook(title, tab) {
    tabtitle[tabtitle.length - 1] = new Array("", "easytier");
    tablink[tablink.length - 1] = new Array("", "Module_easytier.asp");
}

function register_event() {
    $(".popup_bar_bg_ks").click(function() { count_down = -1; });
    $(window).resize(function(){
        if($('.popup_bar_bg_ks').css("visibility") == "visible"){
            var log_h_offset = ((window.innerHeight || document.documentElement.clientHeight) - E("loadingBarBlock").clientHeight) / 2;
            var log_w_offset = ((window.innerWidth || document.documentElement.clientWidth) - E("loadingBarBlock").clientWidth) / 2 + 90;
            $('#loadingBarBlock').offset({top: log_h_offset, left: log_w_offset});
        }
    });
}

function check_status() {
    var postData = {"id": parseInt(Math.random() * 100000000), "method": "easytier_config.sh", "params": ['status'], "fields": ""};
    $.ajax({
        type: "POST", url: "/_api/", data: JSON.stringify(postData), dataType: "json", timeout: 5000,
        success: function(response) {
            var text = (response && response.result) ? response.result : "停止";
            E("easytier_status_text").innerHTML = text;
            E("service_start").style.display = (text === "运行") ? "none" : "";
            E("service_stop").style.display = (text === "运行") ? "" : "none";
            E("service_restart").style.display = (text === "运行") ? "" : "none";
            setTimeout(check_status, 10000);
        },
        error: function() {
            E("easytier_status_text").innerHTML = "停止";
            setTimeout(check_status, 5000);
        }
    });
}

// 封装表单提取逻辑
function get_config_data() {
    var content = E("easytier_config_content").value.trim();
    if (!content) { alert("配置文件内容不能为空！"); return null; }
    var data = {};
    // 安全地将含中文文本转为Base64
    data['easytier_config_content_encoded'] = btoa(unescape(encodeURIComponent(content)));
    data['easytier_autostart'] = E("easytier_autostart").checked ? '1' : '0';
    return data;
}

function save_config() {
    var data = get_config_data();
    if (!data) return false;
    var postData = {"id": parseInt(Math.random()*100000000), "method": "easytier_config.sh", "params": ["save_config", "web_submit"], "fields": data};
    $.ajax({
        type: "POST", url: "/_api/", data: JSON.stringify(postData), dataType: "json", timeout: 10000,
        success: function() { get_log(0); },
        error: function() { alert("配置保存超时或失败！"); }
    });
}

function service_action(action) {
    var data = get_config_data();
    if (!data) return false;
    var postData = {"id": parseInt(Math.random()*100000000), "method": "easytier_config.sh", "params": [action, "web_submit"], "fields": data};
    $.ajax({
        type: "POST", url: "/_api/", data: JSON.stringify(postData), dataType: "json", timeout: 15000,
        success: function() { get_log(0); },
        error: function() { alert("服务操作超时或失败！"); }
    });
}

function save_autostart_config() {
    var val = E("easytier_autostart").checked ? '1' : '0';
    var postData = {"id": parseInt(Math.random()*100000000), "method": "easytier_config.sh", "params": ["save_autostart", "web_submit"], "fields": {"easytier_autostart": val}};
    $.ajax({
        type: "POST", url: "/_api/", data: JSON.stringify(postData), dataType: "json", timeout: 10000,
        success: function() { get_log(0); },
        error: function() { alert("自启动设置保存失败！"); }
    });
}

function get_log(action) {
    E("ok_button").style.visibility = "hidden";
    showWBLoadingBar();
    $.ajax({
        url: '/_temp/easytier_log.txt', type: 'GET', cache: false, dataType: 'text',
        success: function(response) {
            var retArea = E("log_content");
            if (response.indexOf("XU6J03M6") !== -1) {
                retArea.value = response.replace(/XU6J03M6/g, " ");
                E("ok_button").style.visibility = "visible";
                retArea.scrollTop = retArea.scrollHeight;
                if (action == 1) { count_down = -1; refresh_flag = 0; } else { count_down = 5; refresh_flag = 1; }
                count_down_close();
                setTimeout(function(){ check_status(); get_dbus_data(); }, 1000);
                return false;
            }
            setTimeout(function(){ get_log(action); }, 300);
            retArea.value = response.replace(/XU6J03M6/g, " ");
            retArea.scrollTop = retArea.scrollHeight;
        },
        error: function() {
            E("loading_block_title").innerHTML = "暂无日志信息 ...";
            E("log_content").value = "日志文件为空，请关闭本窗口！";
        }
    });
}

function showWBLoadingBar() {
    document.scrollingElement.scrollTop = 0;
    E("loading_block_title").innerHTML = "&nbsp;&nbsp;EasyTier日志信息";
    E("LoadingBar").style.visibility = "visible";
    var log_h_offset = ((window.innerHeight || document.documentElement.clientHeight) - E("loadingBarBlock").clientHeight) / 2;
    var log_w_offset = ((window.innerWidth || document.documentElement.clientWidth) - E("loadingBarBlock").clientWidth) / 2 + 90;
    $('#loadingBarBlock').offset({top: log_h_offset, left: log_w_offset});
}

function hideWBLoadingBar() {
    E("LoadingBar").style.visibility = "hidden";
    E("ok_button").style.visibility = "hidden";
    if (refresh_flag == 1) refreshpage();
}

function count_down_close() {
    if (count_down === 0) { hideWBLoadingBar(); return; }
    if (count_down < 0) { E("ok_button1").value = "手动关闭"; return; }
    E("ok_button1").value = "自动关闭（" + count_down + "）";
    --count_down;
    setTimeout(count_down_close, 1000);
}

function clear_config() {
    if (confirm("确定要清空配置文件内容吗？")) {
        E("easytier_config_content").value = "";
        update_autostart_availability();
    }
}
</script>
</head>
<body id="app" skin='<% nvram_get("sc_skin"); %>' onload="init();">
    <div id="TopBanner"></div>
    <div id="Loading" class="popup_bg"></div>
    <div id="LoadingBar" class="popup_bar_bg_ks" style="z-index: 201;" >
        <table cellpadding="5" cellspacing="0" id="loadingBarBlock" class="loadingBarBlock" align="center">
            <tr>
                <td height="100">
                    <div id="loading_block_title" style="margin:10px auto;margin-left:10px;width:85%; font-size:12pt;"></div>
                    <div id="loading_block_spilt" style="margin:10px 0 10px 5px;">
                        <li><font color="#ffcc00">请等待日志显示完毕，并出现自动关闭按钮！</font></li>
                        <li><font color="#ffcc00">在此期间请不要刷新本页面，不然可能导致问题！</font></li>
                    </div>
                    <div style="margin-left:15px;margin-right:15px;margin-top:10px;outline: 1px solid #3c3c3c;overflow:hidden">
                        <textarea cols="50" rows="25" wrap="off" readonly="readonly" id="log_content" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" style="border:1px solid #000;width:99%; font-family:'Lucida Console'; font-size:11px;background:transparent;color:#FFFFFF;outline: none;padding-left:5px;padding-right:22px;overflow-x:hidden"></textarea>
                    </div>
                    <div id="ok_button" class="apply_gen" style="background:#000;visibility:hidden;">
                        <input id="ok_button1" class="button_gen" type="button" onclick="hideWBLoadingBar()" value="确定">
                    </div>
                </td>
            </tr>
        </table>
    </div>
    <iframe name="hidden_frame" id="hidden_frame" width="0" height="0" frameborder="0"></iframe>
    <table class="content" align="center" cellpadding="0" cellspacing="0">
        <tr>
            <td width="17">&nbsp;</td>
            <td valign="top" width="202">
                <div id="mainMenu"></div>
                <div id="subMenu"></div>
            </td>
            <td valign="top">
                <div id="tabMenu" class="submenuBlock"></div>
                <table width="98%" border="0" align="left" cellpadding="0" cellspacing="0">
                    <tr>
                        <td align="left" valign="top">
                            <table width="760px" border="0" cellpadding="5" cellspacing="0" bordercolor="#6b8fa3" class="FormTitle" id="FormTitle">
                                <tr>
                                    <td bgcolor="#4D595D" colspan="3" valign="top">
                                        <div>&nbsp;</div>
                                        <div class="formfonttitle">EasyTier <label id="easytier_version"></label></div>
                                        <div style="float: right; width: 15px; height: 25px; margin-top: -20px">
                                            <img id="return_btn" alt="" onclick="reload_Soft_Center();" align="right" style="cursor: pointer; position: absolute; margin-left: -30px; margin-top: -25px;" title="返回软件中心" src="/images/backprev.png" onmouseover="this.src='/images/backprevclick.png'" onmouseout="this.src='/images/backprev.png'" />
                                        </div>
                                        <div style="margin: 10px 0 10px 5px;" class="splitLine"></div>
                                        <div class="SimpleNote">
                                            <a href="https://github.com/EasyTier/EasyTier" target="_blank"><em>EasyTier</em></a>是一个简单、安全、去中心化的内网穿透VPN组网方案。<br />
                                            <span><a type="button" href="https://github.com/EasyTier/EasyTier" target="_blank" class="ks_btn" style="margin-left:5px;" >项目地址</a></span>
                                            <span><a type="button" class="ks_btn" href="javascript:void(0);" onclick="get_log(1)" style="margin-left:5px;">插件日志</a></span>
                                        </div>
                                        <div id="easytier_status_pannel">
                                            <table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
                                                <thead><tr><td colspan="2">EasyTier - 状态</td></tr></thead>
                                                <tr id="easytier_status" style="display: none;">
                                                    <th>状态</th>
                                                    <td><span style="margin-left:4px" id="easytier_status_text"></span></td>
                                                </tr>
                                            </table>
                                        </div>
                                        <div style="margin-top:10px">
                                            <table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
                                                <thead><tr><td colspan="2">EasyTier - 配置文件</td></tr></thead>
                                                <tr>
                                                    <th style="width: 20%;">配置文件内容</th>
                                                    <td>
                                                        <textarea id="easytier_config_content" style="width: 98%; height: 300px; font-family: 'Courier New', monospace; font-size: 12px;" class="input_3_table" autocorrect="off" autocapitalize="off" placeholder="请粘贴 easytier 配置文件内容..." onchange="update_autostart_availability();"></textarea>
                                                        <div style="margin-top:5px;">
                                                            <input class="button_gen" onClick="clear_config()" type="button" value="清空" style="font-size:12px; padding:2px 8px; margin-right:10px;" />
                                                        </div>
                                                    </td>
                                                </tr>
                                            </table>
                                        </div>
                                        <div class="apply_gen">
                                            <input class="button_gen" onClick="save_config()" type="button" value="保存配置" />
                                        </div>
                                        <div style="margin-top:10px">
                                            <table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
                                                <thead><tr><td colspan="2">EasyTier - 服务控制</td></tr></thead>
                                                <tr>
                                                    <td colspan="2" style="text-align:center;">
                                                        <input class="button_gen" style="margin:5px;" id="service_start" onClick="service_action('start')" type="button" value="启动服务" />
                                                        <input class="button_gen" style="margin:5px; display:none;" id="service_stop" onClick="service_action('stop')" type="button" value="停止服务" />
                                                        <input class="button_gen" style="margin:5px; display:none;" id="service_restart" onClick="service_action('restart')" type="button" value="重启服务" />
                                                    </td>
                                                </tr>
                                            </table>
                                        </div>
                                        <div style="margin-top:10px" id="autostart_section">
                                            <table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
                                                <thead><tr><td colspan="2">EasyTier - 自启动设置</td></tr></thead>
                                                <tr>
                                                    <th>开机自启动</th>
                                                    <td>
                                                        <input type="checkbox" id="easytier_autostart" style="vertical-align:middle;">
                                                        <span style="color:#FC0;margin-left:5px;">勾选后系统重启时自动启动EasyTier服务</span>
                                                        <div id="autostart_warning" style="margin-top:5px; color:#ff6666; display:none;">
                                                            <i class="fa fa-exclamation-triangle"></i> 请先粘贴配置文件内容后再设置自启动
                                                        </div>
                                                    </td>
                                                </tr>
                                                <tr>
                                                    <td colspan="2" style="text-align:center;">
                                                        <input class="button_gen" style="margin:5px;" onClick="save_autostart_config()" type="button" value="保存自启动设置" />
                                                    </td>
                                                </tr>
                                            </table>
                                        </div>
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
    <div id="footer"></div>
</body>
</html>