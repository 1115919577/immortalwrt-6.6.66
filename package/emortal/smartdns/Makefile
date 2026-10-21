# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (c) 2018-2023 Nick Peng (pymumu@gmail.com)

include $(TOPDIR)/rules.mk

PKG_NAME:=smartdns
PKG_VERSION:=2026.8.30
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.xz
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://www.github.com/pymumu/smartdns.git
PKG_SOURCE_VERSION:=dfc9ef4bd947891178924c06070fbccc3ea370ba
PKG_MIRROR_HASH:=skip

PKG_MAINTAINER:=Nick Peng <pymumu@gmail.com>
PKG_LICENSE:=GPL-3.0-or-later
PKG_LICENSE_FILES:=LICENSE
PKG_CPE_ID:=cpe:/a:pymumu:smartdns

PKG_CONFIG_DEPENDS:=CONFIG_PACKAGE_smartdns-ui
PKG_BUILD_DEPENDS:=PACKAGE_smartdns-ui:node/host PACKAGE_smartdns-ui:rust-bindgen/host
PKG_BUILD_PARALLEL:=1

RUST_PKG_FEATURES:=build-release
RUST_PKG_LOCKED:=0

include $(INCLUDE_DIR)/package.mk
#include ../../lang/rust/rust-package.mk
include $(TOPDIR)/feeds/packages/lang/rust/rust-package.mk

MAKE_PATH:=src
MAKE_VARS+= VER=$(PKG_VERSION)

define Package/smartdns/Default
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=IP Addresses and Names
  TITLE:=smartdns
  URL:=https://www.github.com/pymumu/smartdns/
endef

define Package/smartdns
  $(call Package/smartdns/Default)
  TITLE+= server
  VERSION:=$(PKG_VERSION)-$(shell echo $(PKG_SOURCE_VERSION) | cut -c1-6)
  DEPENDS:=+i386:libatomic +libopenssl +zlib
endef

define Package/smartdns/description
SmartDNS is a local DNS server which accepts DNS query requests from local network clients,
gets DNS query results from multiple upstream DNS servers concurrently, and returns the fastest IP to clients.
Unlike dnsmasq's all-servers, smartdns returns the fastest IP, and encrypt DNS queries with DoT or DoH.
endef

define Package/smartdns-ui
  $(call Package/smartdns/Default)
  TITLE+= dashboard
  DEPENDS:=+smartdns $(RUST_ARCH_DEPENDS) @!i386
  # 版本号跟随 smartdns-webui 的 SOURCE_VERSION，使用 commit 哈希前 6 位
  VERSION:=$(subst -,.,$(SOURCE_DATE))-$(shell echo $(SOURCE_VERSION) | cut -c1-6)
endef

define Package/smartdns-ui/description
A dashboard ui for smartdns server.
endef

define Package/smartdns/conffiles
/etc/config/smartdns
/etc/smartdns/address.conf
/etc/smartdns/blacklist-ip.conf
/etc/smartdns/custom.conf
/etc/smartdns/domain-block.list
/etc/smartdns/domain-forwarding.list
endef

# smartdns-webui 下载定义
# SUBDIR 和 FILE 由 OpenWrt Download 宏自动生成，格式：smartdns-webui-日期~版本缩写.tar.zst
define Download/smartdns-webui
  PROTO:=git
  URL:=https://github.com/pymumu/smartdns-webui.git
  SOURCE_DATE:=2026-7-29
  SOURCE_VERSION:=1c06fee693434ec7c71f06010d3f87416baba9f0
  MIRROR_HASH:=skip
  SUBDIR:=smartdns-webui-$$$$(subst -,.,$$$$(SOURCE_DATE))~$$$$(call version_abbrev,$$$$(SOURCE_VERSION))
  FILE:=$$(SUBDIR).tar.zst
endef

# Build/Prepare：不再下载 webui，移到 Build/Compile 中按需下载
define Build/Prepare
	$(call Build/Prepare/Default)
endef

# Build/Clean：清理 smartdns-webui 独立目录（包含 cargo 编译缓存）
define Build/Clean
	$(call Build/Clean/Default)
	rm -rf $(BUILD_DIR)/smartdns-webui-*
endef

define Build/Compile
	$(call Build/Compile/Default)

ifneq ($(CONFIG_PACKAGE_smartdns-ui),)
	# --- smartdns-webui 增量编译 ---
	# webui 和 cargo 编译缓存都放在 $(BUILD_DIR) 下独立目录，与 smartdns 源码隔离
	# smartdns 源码更新（Build/Prepare 重新解压）不会影响 webui 和 cargo 缓存
	# 1) eval Download 宏，展开 SUBDIR/FILE 等变量，构建 webui 目录路径
	$(eval $(call Download,smartdns-webui))
	$(eval $(Download/smartdns-webui))
	$(eval WEBUI_DIR:=$(BUILD_DIR)/$$(SUBDIR))
	$(eval WEBUI_STAMP:=$$(WEBUI_DIR)/.webui-built)
	# cargo 编译缓存放在 webui 目录下，和 webui 一起管理
	# 这样 webui 和 rust 插件的缓存都在同一个目录下，清理时一起清理
	$(eval RUSTUI_DIR:=$$(WEBUI_DIR)/rust-target)
	$(eval RUSTUI_STAMP:=$$(RUSTUI_DIR)/.smartdns-rustui-built)

	# 2) 下载并解压 webui 源码（目录不存在时才下载解压）
	if [ ! -f $(WEBUI_DIR)/package.json ]; then \
		mkdir -p $(WEBUI_DIR) ; \
		zstdcat $(DL_DIR)/$(FILE) | tar -C $(WEBUI_DIR) $(TAR_OPTIONS) --strip-components=1 ; \
	fi

	# 3) 编译 webui 前端（npm），源码无变化时跳过
	if [ ! -f $(WEBUI_STAMP) ] || [ "$(WEBUI_DIR)/package.json" -nt $(WEBUI_STAMP) ] || \
	   [ "$(WEBUI_DIR)/package-lock.json" -nt $(WEBUI_STAMP) ] || \
	   [ "$(WEBUI_DIR)/src" -nt $(WEBUI_STAMP) ]; then \
		cd $(WEBUI_DIR) && npm install && npm run build ; \
		touch $(WEBUI_STAMP) ; \
	fi

	# 4) 编译 rust 插件，源码或 webui 产物无变化时跳过
	# 使用 CARGO_TARGET_DIR 将 cargo 编译缓存指向 webui 目录下的 rust-target
	# 不检查 Cargo.lock，因为 cargo build 会修改它，导致下次编译误判为"源码变了"
	if [ ! -f $(RUSTUI_STAMP) ] || [ "$(WEBUI_STAMP)" -nt $(RUSTUI_STAMP) ] || \
	   [ "$(PKG_BUILD_DIR)/plugin/smartdns-ui/Cargo.toml" -nt $(RUSTUI_STAMP) ] || \
	   [ "$(PKG_BUILD_DIR)/plugin/smartdns-ui/src" -nt $(RUSTUI_STAMP) ]; then \
		mkdir -p $(RUSTUI_DIR) ; \
		cd $(PKG_BUILD_DIR)/plugin/smartdns-ui && \
		$(CARGO_PKG_CONFIG_VARS) \
		MAKEFLAGS="$(PKG_JOBS)" \
		TARGET_CFLAGS="$(filter-out -O%,$(TARGET_CFLAGS)) $(RUSTC_CFLAGS)" \
		BINDGEN_EXTRA_CLANG_ARGS="--sysroot=$(TOOLCHAIN_ROOT_DIR)" \
		CARGO_TARGET_DIR=$(RUSTUI_DIR) \
		cargo build -v --profile $(CARGO_PKG_PROFILE) \
		$(if $(strip $(RUST_PKG_FEATURES)),--features "$(strip $(RUST_PKG_FEATURES))") \
		$(if $(filter --jobserver%,$(PKG_JOBS)),,-j1) \
		$(CARGO_PKG_ARGS) ; \
		touch $(RUSTUI_STAMP) ; \
	fi
endif
endef

define Package/smartdns/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/etc/config $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/smartdns $(1)/etc/smartdns/domain-set $(1)/etc/smartdns/conf.d/
	$(INSTALL_DIR) $(1)/etc/smartdns/ip-set $(1)/etc/smartdns/download
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/smartdns $(1)/usr/sbin/smartdns
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/package/openwrt/files/etc/init.d/smartdns $(1)/etc/init.d/smartdns
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/package/openwrt/address.conf $(1)/etc/smartdns/address.conf
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/package/openwrt/blacklist-ip.conf $(1)/etc/smartdns/blacklist-ip.conf
#	$(INSTALL_CONF) $(PKG_BUILD_DIR)/package/openwrt/custom.conf $(1)/etc/smartdns/custom.conf
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/package/openwrt/domain-block.list $(1)/etc/smartdns/domain-block.list
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/package/openwrt/domain-forwarding.list $(1)/etc/smartdns/domain-forwarding.list
#	$(INSTALL_CONF) $(PKG_BUILD_DIR)/package/openwrt/files/etc/config/smartdns $(1)/etc/config/smartdns
	$(INSTALL_CONF) $(CURDIR)/conf/custom.conf $(1)/etc/smartdns/custom.conf
	$(INSTALL_CONF) $(CURDIR)/conf/smartdns.conf $(1)/etc/config/smartdns
endef

define Package/smartdns-ui/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_DIR) $(1)/usr/share/smartdns
	# cargo 编译产物从 CARGO_TARGET_DIR（webui 目录下的 rust-target）中获取
	$(CP) $(RUSTUI_DIR)/$(RUSTC_TARGET_ARCH)/$(CARGO_PKG_PROFILE)/libsmartdns_ui.so $(1)/usr/lib/smartdns_ui.so
	$(CP) $(WEBUI_DIR)/out $(1)/usr/share/smartdns/wwwroot
endef

$(eval $(call BuildPackage,smartdns))
$(eval $(call BuildPackage,smartdns-ui))

