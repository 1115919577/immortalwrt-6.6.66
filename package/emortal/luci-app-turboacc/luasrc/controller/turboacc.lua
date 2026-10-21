-- SPDX-License-Identifier: GPL-3.0-only
-- Controller for luci-app-turboacc

module("luci.controller.turboacc", package.seeall)

local fs   = require "nixio.fs"
local http = require "luci.http"
local sys  = require "luci.sys"

function index()
	if not fs.access("/etc/config/turboacc") then
		return
	end
	local page = entry({"admin", "network", "turboacc"}, cbi("turboacc"),
		_("Turbo ACC Center"), 101)
	page.i18n      = "turboacc"
	page.dependent = true

	entry({"admin", "network", "turboacc", "status"}, call("action_status")).leaf = true
end

local function call_status(target)
	return sys.call(string.format(
		"/etc/init.d/turboacc check_status %s 0 >/dev/null 2>&1", target)) == 0
end

local function fastpath_text()
	local text = sys.exec("/etc/init.d/turboacc check_status fastpath 1")
	if text == nil or text == "" then
		return nil
	end
	return text
end

local function uci_flag(name)
	return sys.exec("uci -q get firewall.@defaults[0]." .. name):gsub("%s+$", "") == "1"
end

function action_status()
	local sw_running = call_status("sw_flow")
	local hw_running = call_status("hw_flow")

	local fastpath_state = call_status("fastpath")

	-- Visibility rules:
	--   * Always show FastPath type row, so disabled offloading is explicit.
	--   * Show SW row if SW is enabled in firewall config OR currently running.
	--   * Show HW row if HW is enabled in firewall config OR currently running.
	local sw_visible = sw_running or uci_flag("flow_offloading")
	local hw_visible = hw_running or uci_flag("flow_offloading_hw")
	local fastpath_visible = true

	http.prepare_content("application/json")
	http.write_json({
		fastpath_state    = fastpath_state,
		fastpath_visible  = fastpath_visible,
		fastpath_text     = fastpath_text() or "",
		sw_flow_state     = sw_running,
		sw_flow_visible   = sw_visible,
		hw_flow_state     = hw_running,
		hw_flow_visible   = hw_visible,
		fullconenat_state = call_status("fullconenat"),
		bbr_state         = call_status("bbr"),
	})
end
