#
# Copyright (C) 2008-2014 The LuCI Team <luci@lists.subsignal.org>
#
# This is free software, licensed under the Apache License, Version 2.0 .
#
include $(TOPDIR)/rules.mk

LUCI_TITLE:=UPnP IGD & PCP/NAT-PMP configuration module | Universal Plug and Play
LUCI_DEPENDS:=+luci-base +miniupnpd +rpcd-mod-ucode

PKG_LICENSE:=Apache-2.0
PKG_MAINTAINER:=Jo-Philipp Wich <jo@mein.io>

PKG_NAME:=luci-app-upnp
PKG_VERSION:=1.0
PKG_RELEASE:=6

PKG_PO_VERSION:=$(PKG_VERSION)-r$(PKG_RELEASE)
PKG_SRC_VERSION:=$(PKG_VERSION)-r$(PKG_RELEASE)

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
