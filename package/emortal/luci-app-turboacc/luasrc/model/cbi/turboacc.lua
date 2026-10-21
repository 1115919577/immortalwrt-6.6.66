-- SPDX-License-Identifier: GPL-3.0-only
-- LuCI configuration for luci-app-turboacc (firewall4 / nftables)

local sys = require "luci.sys"

local kernel_version = sys.exec("uname -r"):gsub("%s+$", "")

-- 兼容旧版匿名配置段：旧包可能是 config turboacc，而不是 config turboacc 'config'。
-- 如果不先归一化，CBI 会写 turboacc.config，但 init 读不到旧匿名段，表现为“保存配置无效”。
sys.call([[
	uci -q get turboacc.config >/dev/null 2>&1 || {
		uci -q rename turboacc.@turboacc[0]=config 2>/dev/null || uci -q set turboacc.config=turboacc
		uci -q commit turboacc
	}
]])

local function has_module(name)
	local base = name:gsub("%.ko$", "")
	return sys.call("test -d /sys/module/" .. base ..
		" || ls /lib/modules/" .. kernel_version .. "/" .. base .. ".ko* >/dev/null 2>&1") == 0
end

local function has_bbr()
	return has_module("tcp_bbr") or
		sys.call("grep -qw bbr /proc/sys/net/ipv4/tcp_available_congestion_control 2>/dev/null") == 0
end

local m = Map("turboacc",
	translate("Turbo ACC Acceleration Settings"),
	translate("Opensource Flow Offloading driver (Fast Path or Hardware NAT). Settings are written into firewall4 (nftables) defaults."))

m:append(Template("turboacc/turboacc_status"))

local s = m:section(NamedSection, "config", "turboacc", "")
s.addremove = false

-- ===== Software flow offloading (firewall.@defaults[0].flow_offloading) =====
if has_module("nft_flow_offload") then
	local sw_flow = s:option(Flag, "sw_flow", translate("Software flow offloading"))
	sw_flow.default     = "1"
	sw_flow.rmempty     = false
	sw_flow.description = translate("Kernel based flow offloading via nftables (flow_offloading). Not fully compatible with QoS/SQM.")
end

-- ===== Hardware flow offloading (firewall.@defaults[0].flow_offloading_hw) =====
-- firewall4 hard rule: hardware offloading requires software offloading to be enabled.
if has_module("nft_flow_offload") then
	local hw_flow = s:option(Flag, "hw_flow", translate("Hardware flow offloading"))
	hw_flow.default     = "1"
	hw_flow.rmempty     = false
	hw_flow.description = translate("Hardware offloading uses NIC/SoC offload engines (e.g. MTK PPE/HNAT, Rockchip GMAC). Requires Software flow offloading to be enabled (firewall4 constraint).")
	hw_flow:depends("sw_flow", "1")
end

-- ===== MTK WED (Wireless Ethernet Dispatcher) =====
if has_module("nft_flow_offload") and sys.call("grep -Eq 'mediatek' /etc/openwrt_release") == 0 and has_module("mt7915e") then
	local hw_wed = s:option(Flag, "hw_wed", translate("MTK WED WO offloading"))
	hw_wed.default     = "0"
	hw_wed.rmempty     = false
	hw_wed.description = translate("Requires hardware support, implemented at least for Filogic 8x0")
	hw_wed:depends({ sw_flow = "1", hw_flow = "1" })
end

-- ===== nftables FullCone NAT =====
if has_module("nft_fullcone") then
	local fullcone_nat = s:option(Flag, "fullcone_nat", translate("FullCone NAT"))
	fullcone_nat.default     = "1"
	fullcone_nat.rmempty     = false
	fullcone_nat.description = translate("Using FullCone NAT can improve gaming performance effectively")

	local fullcone6 = s:option(Flag, "fullcone6", translate("IPv6 Full Cone NAT"))
	fullcone6.default     = "0"
	fullcone6.rmempty     = false
	fullcone6.description = translate("Enabling IPv6 Full Cone NAT adds an extra layer of NAT to IPv6. In IPv6, if you obtain an IPv6 prefix through IPv6 Prefix Delegation, each device can be assigned a public IPv6 address, eliminating the need for IPv6 Full Cone NAT.")
	fullcone6:depends("fullcone_nat", "1")
end

-- ===== BBR congestion control =====
if has_bbr() then
	local bbr_cca = s:option(Flag, "bbr_cca", translate("BBR CCA"))
	bbr_cca.default     = "1"
	bbr_cca.rmempty     = false
	bbr_cca.description = translate("Using BBR CCA can improve TCP network performance effectively")
end

return m
