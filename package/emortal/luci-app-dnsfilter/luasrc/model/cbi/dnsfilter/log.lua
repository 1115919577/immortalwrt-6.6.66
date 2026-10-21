local fs = require "nixio.fs"
local http = require "luci.http"
local conffile = "/tmp/adupdate.log"

if http.formvalue("clear_log") == "1" then
	fs.writefile(conffile, "")
end

local f = SimpleForm("logview")
f.reset = false
f.submit = false

local clear = f:field(DummyValue, "_clear_log")
clear.rawhtml = true
function clear.cfgvalue()
	return '<div style="text-align:left;margin:0 0 10px 0;">' ..
		'<button type="submit" class="cbi-button cbi-button-reset" name="clear_log" value="1">' ..
		translate("Clear Log") ..
		'</button></div>'
end

local t = f:field(TextValue, "conf")
t.rmempty = true
t.rows = 20

function t.cfgvalue()
	local content = fs.readfile(conffile) or ""
	local lines = {}

	for line in content:gmatch("[^\r\n]+") do
		if line:match("^%d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d %[[^%]]+%]") then
			lines[#lines + 1] = line
		end
	end

	return table.concat(lines, "\n")
end
t.readonly = "readonly"

return f
