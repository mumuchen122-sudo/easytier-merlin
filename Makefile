# EasyTier KoolShare 插件自动化打包 Makefile
PLUGIN_NAME := easytier
BUILD_DIR := build_tmp
OUTPUT := $(PLUGIN_NAME).tar.gz

.PHONY: all clean check-version prepare download copy pack

all: clean pack

check-version:
ifndef VERSION
	$(error ❌ 错误: 未提供版本号! 请使用类似 make VERSION=2.6.4 的命令)
endif

clean:
	@echo "清理旧文件..."
	rm -rf $(BUILD_DIR) $(OUTPUT)

prepare: check-version
	@echo "创建目录结构..."
	mkdir -p $(BUILD_DIR)/$(PLUGIN_NAME)/bin
	mkdir -p $(BUILD_DIR)/$(PLUGIN_NAME)/scripts
	mkdir -p $(BUILD_DIR)/$(PLUGIN_NAME)/webs
	mkdir -p $(BUILD_DIR)/$(PLUGIN_NAME)/res
	mkdir -p $(BUILD_DIR)/dl_tmp

download: prepare
	@echo "下载 EasyTier ARM64 核心 (v$(VERSION))..."
	wget -qO $(BUILD_DIR)/dl_tmp/arm64.zip "https://github.com/EasyTier/EasyTier/releases/download/v$(VERSION)/easytier-linux-aarch64-v$(VERSION).zip"
	unzip -q $(BUILD_DIR)/dl_tmp/arm64.zip -d $(BUILD_DIR)/dl_tmp/arm64/
	find $(BUILD_DIR)/dl_tmp/arm64 -type f -name "easytier-core" -exec mv {} $(BUILD_DIR)/$(PLUGIN_NAME)/bin/easytier-core_arm64 \;

	@echo "下载 EasyTier ARM32/armv7 核心 (v$(VERSION))..."
	wget -qO $(BUILD_DIR)/dl_tmp/arm32.zip "https://github.com/EasyTier/EasyTier/releases/download/v$(VERSION)/easytier-linux-armv7-v$(VERSION).zip"
	unzip -q $(BUILD_DIR)/dl_tmp/arm32.zip -d $(BUILD_DIR)/dl_tmp/arm32/
	find $(BUILD_DIR)/dl_tmp/arm32 -type f -name "easytier-core" -exec mv {} $(BUILD_DIR)/$(PLUGIN_NAME)/bin/easytier-core_arm32 \;

copy: download
	@echo "复制插件代码文件..."
	cp install.sh          $(BUILD_DIR)/$(PLUGIN_NAME)/
	cp config.json.js      $(BUILD_DIR)/$(PLUGIN_NAME)/
	cp scripts/easytier_config.sh $(BUILD_DIR)/$(PLUGIN_NAME)/scripts/
	cp webs/Module_easytier.asp   $(BUILD_DIR)/$(PLUGIN_NAME)/webs/
	cp res/easytier.png           $(BUILD_DIR)/$(PLUGIN_NAME)/res/
	
	@echo "=== 核心修复：注入 HND 平台离线安装专属免检标识 ==="
	echo "hnd" > $(BUILD_DIR)/$(PLUGIN_NAME)/.valid
	
	@echo "赋予执行权限..."
	chmod +x $(BUILD_DIR)/$(PLUGIN_NAME)/bin/*
	chmod +x $(BUILD_DIR)/$(PLUGIN_NAME)/scripts/*
	chmod +x $(BUILD_DIR)/$(PLUGIN_NAME)/*.sh

pack: copy
	@echo "生成 $(OUTPUT) ..."
	cd $(BUILD_DIR) && tar -czvf ../$(OUTPUT) $(PLUGIN_NAME)/
	@echo "清理临时文件..."
	rm -rf $(BUILD_DIR)
	@echo "✅ 打包完成: $(OUTPUT)"