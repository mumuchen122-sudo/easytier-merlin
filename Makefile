# EasyTier KoolShare 插件自动化双平台打包 Makefile
PLUGIN_NAME := easytier
BUILD_DIR := build_tmp
PLATFORMS := hnd qca

# 定义最终输出的包名列表
OUTPUT_PKGS := $(foreach p,$(PLATFORMS),$(PLUGIN_NAME)_$(p).tar.gz)

.PHONY: all clean check-version prepare download copy pack_all $(PLATFORMS)

# 默认执行的动作：清理 -> 准备 -> 下载基础文件 -> 生成所有平台的包
all: clean prepare download pack_all

# 检查是否传入了 VERSION 变量
check-version:
ifndef VERSION
	$(error ❌ 错误: 未提供版本号! 请使用类似 make VERSION=2.6.4 的命令)
endif

clean:
	@echo "清理旧文件..."
	rm -rf $(BUILD_DIR) $(OUTPUT_PKGS)

prepare: check-version
	@echo "创建通用下载目录结构..."
	mkdir -p $(BUILD_DIR)/dl_tmp

download: prepare
	@echo "下载 EasyTier ARM64 核心 (v$(VERSION))..."
	wget -qO $(BUILD_DIR)/dl_tmp/arm64.zip "https://github.com/EasyTier/EasyTier/releases/download/v$(VERSION)/easytier-linux-aarch64-v$(VERSION).zip"
	unzip -q $(BUILD_DIR)/dl_tmp/arm64.zip -d $(BUILD_DIR)/dl_tmp/arm64/

	@echo "下载 EasyTier ARM32/armv7 核心 (v$(VERSION))..."
	wget -qO $(BUILD_DIR)/dl_tmp/arm32.zip "https://github.com/EasyTier/EasyTier/releases/download/v$(VERSION)/easytier-linux-armv7-v$(VERSION).zip"
	unzip -q $(BUILD_DIR)/dl_tmp/arm32.zip -d $(BUILD_DIR)/dl_tmp/arm32/

# 这一步是核心！遍历所有的 PLATFORMS (hnd 和 qca) 进行独立组装和打包
pack_all: $(PLATFORMS)

# 定义如何为一个特定的平台(hnd 或 qca)进行组装和打包
$(PLATFORMS):
	@echo "================================================="
	@echo "🚀 开始构建 $@ 平台安装包..."
	@echo "================================================="
	
	# 1. 为当前平台创建一个专属的组装目录
	mkdir -p $(BUILD_DIR)/$@/$(PLUGIN_NAME)/bin
	mkdir -p $(BUILD_DIR)/$@/$(PLUGIN_NAME)/scripts
	mkdir -p $(BUILD_DIR)/$@/$(PLUGIN_NAME)/webs
	mkdir -p $(BUILD_DIR)/$@/$(PLUGIN_NAME)/res
	
	# 2. 复制二进制核心
	find $(BUILD_DIR)/dl_tmp/arm64 -type f -name "easytier-core" -exec cp {} $(BUILD_DIR)/$@/$(PLUGIN_NAME)/bin/easytier-core_arm64 \;
	find $(BUILD_DIR)/dl_tmp/arm32 -type f -name "easytier-core" -exec cp {} $(BUILD_DIR)/$@/$(PLUGIN_NAME)/bin/easytier-core_arm32 \;
	
	# 3. 复制前端和脚本代码
	cp install.sh          $(BUILD_DIR)/$@/$(PLUGIN_NAME)/
	cp config.json.js      $(BUILD_DIR)/$@/$(PLUGIN_NAME)/
	cp scripts/easytier_config.sh $(BUILD_DIR)/$@/$(PLUGIN_NAME)/scripts/
	cp webs/Module_easytier.asp   $(BUILD_DIR)/$@/$(PLUGIN_NAME)/webs/
	cp res/easytier.png           $(BUILD_DIR)/$@/$(PLUGIN_NAME)/res/
	
	# 4. 注入当前平台专属的 .valid 文件 (核心操作)
	echo "$@" > $(BUILD_DIR)/$@/$(PLUGIN_NAME)/.valid
	
	# 5. 赋予执行权限
	chmod +x $(BUILD_DIR)/$@/$(PLUGIN_NAME)/bin/*
	chmod +x $(BUILD_DIR)/$@/$(PLUGIN_NAME)/scripts/*
	chmod +x $(BUILD_DIR)/$@/$(PLUGIN_NAME)/*.sh
	
	# 6. 生成最终的压缩包，退出到根目录执行 tar
	@echo "📦 正在打包 $(PLUGIN_NAME)_$@.tar.gz ..."
	cd $(BUILD_DIR)/$@ && tar -czvf ../../$(PLUGIN_NAME)_$@.tar.gz $(PLUGIN_NAME)/
	@echo "✅ $@ 平台打包完成！\n"