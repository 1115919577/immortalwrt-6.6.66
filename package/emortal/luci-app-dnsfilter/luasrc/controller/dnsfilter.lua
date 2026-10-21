module("luci.controller.dnsfilter", package.seeall)

local fs   = require "nixio.fs"
local http = require "luci.http"
local sys  = require "luci.sys"

function index()
	if not fs.access("/etc/config/dnsfilter") then
		return
	end

	local page = entry({"admin", "services", "dnsfilter"}, alias("admin", "services", "dnsfilter", "base"), _("DNS Filter"), 9)
	page.dependent = true
	page.acl_depends = { "luci-app-dnsfilter" }

	entry({"admin", "services", "dnsfilter", "base"}, cbi("dnsfilter/base"), _("Base Setting"), 10).leaf = true
	entry({"admin", "services", "dnsfilter", "white"}, form("dnsfilter/white"), _("White Domain List"), 20).leaf = true
	entry({"admin", "services", "dnsfilter", "black"}, form("dnsfilter/black"), _("Block Domain List"), 30).leaf = true
	entry({"admin", "services", "dnsfilter", "ip"}, form("dnsfilter/ip"), _("Block IP List"), 40).leaf = true
	entry({"admin", "services", "dnsfilter", "log"}, form("dnsfilter/log"), _("Update Log"), 50).leaf = true
	entry({"admin", "services", "dnsfilter", "run"}, call("act_status")).leaf = true
	entry({"admin", "services", "dnsfilter", "refresh"}, call("refresh_data"))
end

function act_status()
	local e = {}
	e.running = sys.call([[
		cfg="$(uci -q show dhcp.@dnsmasq[0] | awk 'NR==1 {split($0, conf, /[.=]/); print conf[2]}')"
		dir="/tmp/dnsmasq.d"
		if [ -n "$cfg" ] && [ -f "/tmp/etc/dnsmasq.conf.$cfg" ]; then
			d="$(awk -F '=' '/^conf-dir=/ {print $2}' "/tmp/etc/dnsmasq.conf.$cfg" | tail -n 1)"
			d="${d%%,*}"
			d="${d%*/}"
			[ -n "$d" ] && dir="$d"
		fi
		[ -s "$dir/dnsfilter.rules.conf" ] ||
		[ -s /tmp/dnsmasq.d/dnsfilter.rules.conf ] ||
		[ -s /var/dnsmasq.d/dnsfilter.rules.conf ] ||
		nft list table inet dnsfilter >/dev/null 2>&1
	]]) == 0
	http.prepare_content("application/json")
	http.write_json(e)
end

function refresh_data()
	local icount = 0
	local newhash = ""
	local oldhash = ""
	local retstring = "-1"

	sys.exec("/usr/share/dnsfilter/dnsfilter down")
	icount = sys.exec("cat /tmp/ad_tmp/rules.conf 2>/dev/null | wc -l")
	if tonumber(icount)>0 then
		newhash = sys.exec("md5sum /tmp/ad_tmp/rules.conf 2>/dev/null | awk '{print $1}'"):gsub("%s+$", "")
		oldhash = sys.exec("md5sum /tmp/dnsfilter/rules.conf 2>/dev/null | awk '{print $1}'"):gsub("%s+$", "")
		if newhash ~= oldhash then
			sys.exec("[ -h /tmp/dnsfilter/url ] && (mkdir -p /etc/dnsfilter/rules;rm -f /etc/dnsfilter/rules/*;cp -a /tmp/ad_tmp/* /etc/dnsfilter/rules) || (mkdir -p /tmp/dnsfilter;rm -f /tmp/dnsfilter/*;cp -a /tmp/ad_tmp/* /tmp/dnsfilter)")
			sys.exec("/etc/init.d/dnsfilter restart >/dev/null 2>&1 &")
			retstring = tostring(math.ceil(tonumber(icount)))
		else
			retstring = 0
		end
		sys.call("mkdir -p /tmp/dnsfilter && date +'%Y-%m-%d %H:%M:%S' > /tmp/dnsfilter/dnsfilter.updated")
	else
		retstring = "-1"
	end
	sys.exec("rm -rf /tmp/ad_tmp")

	http.prepare_content("application/json")
	http.write_json({ret=retstring,retcount=icount})
end
