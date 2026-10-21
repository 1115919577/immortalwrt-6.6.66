local fs = require "nixio.fs"
local sys = require "luci.sys"
local conffile = "/etc/dnsfilter/black.list"

local f = SimpleForm("custom")
local t = f:field(TextValue, "conf")
t.rmempty = true
t.rows = 13
t.description = translate("Will Always block these Domain")

function t.cfgvalue()
	return fs.readfile(conffile) or ""
end

function f.handle(self,state,data)
	if state == FORM_VALID then
		if data.conf then
			fs.writefile(conffile,data.conf:gsub("\r\n","\n"))
		else
			sys.call("> /etc/dnsfilter/black.list")
		end
		sys.exec("[ \"$(uci -q get dnsfilter.@dnsfilter[0].enable)\" = '1' ] && /etc/init.d/dnsfilter restart >/dev/null 2>&1 &")
	end
	return true
end

return f
