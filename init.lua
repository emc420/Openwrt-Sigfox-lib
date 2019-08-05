#!/usr/bin/lua

local posix = require("posix")
local copas = require ("copas")
local flag = ""

pid = posix.fork()
if pid == 0 then
    loop = copas.loop()
	
--------------Code Goes Here----------------
	while true do
			local port = io.popen("lsusb -t")
			local cntrr = 0
			while true do
					local text = port:read("*l")
					if not text then break end
					if text:match("Driver=cp210x") then	
						cntrr = cntrr+1
					end
			end 
			if (cntrr==0) then 
				flag = false
			else
				flag = true
			end
			port:close()
			local file = io.open("/tmp/test.log", "r")
			if file ~= nil then
				local devStat = tostring(file:read())
				if (devStat == "DeviceAdded" and flag==true) then
					dofile("/root/test/handshaking.lua")
					local f = io.open("/root/test/log.txt", "a")
					f:write("Global".._G.value.."\n")
					f:close()
					if(_G.value == "1") then 
						file:close()
						dofile("/root/test/geoLoc.lua")
						dofile("/root/test/batch_lua_script.lua")
					end
					if (_G.value == "0") then 
						file:close()
						file = io.open("/tmp/test.log", "a")
						file:write("DeviceRemoved")
						file:close()
					end
				end
			else
				if( file ~= nil) then 
					file:close()
				end
			end

			--break;
	end
--------------------------------------------
else
    os.exit()
end
