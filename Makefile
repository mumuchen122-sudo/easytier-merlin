# 定义 EasyTier 官方版本号 (后续更新只需改这里)
VERSION := 2.6.4
# 华硕路由器插件规范的文件夹名称
PLUGIN_NAME := easytier

.PHONY: all clean build pack

all: clean build pack

clean:
	@echo "清理临时文件..."
	rm -rf build_tmp
	rm -f $(PLUGIN_NAME).tar.gz

build:
	@echo "创建目录结构..."
	mkdir -p build_tmp/$(PLUGIN_NAME)/bin
	
	@echo "下载并提取 EasyTier ARM64 核心..."
	wget -qO build_tmp/arm64.zip https://github.com/EasyTier/EasyTier/releases/download/v$(VERSION)/easytier-linux-aarch64-v$(VERSION).zip
	mkdir -p build_tmp/arm64 && unzip -q build_tmp/arm64.zip -d build_tmp/arm64/
	# 自动在解压目录中寻找 easytier-core 并重命名放入 bin
	find build_tmp/arm64 -type f -name "easytier-core" -exec mv {} build_tmp/$(PLUGIN_NAME)/bin/easytier-core_arm64 \;
	
	@echo "下载并提取 EasyTier ARM32 (armv7) 核心..."
	# 已更新为正确的 armv7 链接
	wget -qO build_tmp/arm32.zip https://github.com/EasyTier/EasyTier/releases/download/v$(VERSION)/easytier-linux-armv7-v$(VERSION).zip
	mkdir -p build_tmp/arm32 && unzip -q build_tmp/arm32.zip -d build_tmp/arm32/
	find build_tmp/arm32 -type f -name "easytier-core" -exec mv {} build_tmp/$(PLUGIN_NAME)/bin/easytier-core_arm32 \;
	
	@echo "复制插件代码..."
	cp -r res scripts webs install.sh uninstall.sh config.json.js build_tmp/$(PLUGIN_NAME)/
	
	@echo "赋予执行权限..."
	chmod +x build_tmp/$(PLUGIN_NAME)/bin/*
	chmod +x build_tmp/$(PLUGIN_NAME)/scripts/*
	chmod +x build_tmp/$(PLUGIN_NAME)/install.sh
	chmod +x build_tmp/$(PLUGIN_NAME)/uninstall.sh

pack: build
	@echo "打包为 $(PLUGIN_NAME).tar.gz..."
	cd build_tmp && tar -zcvf ../$(PLUGIN_NAME).tar.gz $(PLUGIN_NAME)/
	@echo "打包完成！"