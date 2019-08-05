#!/usr/bin/lua

local dwnLnk = ""
_G.value = ""

local file = io.open("test.lua", "r")
if file==nil then
	---print("No file")
	local deviceId=""
	local deviceType=""
	local packetHdr = "11"

	--- Linksys WRT1200AC -  000000001
	function toBits(num,bits)
		-- returns a table of bits, most significant first.
		bits = bits or math.max(1, select(2, math.frexp(num)))
		local t = {} -- will contain the bits        
		for b = bits, 1, -1 do
			t[b] = math.fmod(num, 2)
			num = math.floor((num - t[b]) / 2)
		end
		return t
	end

	local strMachine = io.popen("dmesg | grep Machine")

	while true do	
		local line = strMachine:read("*l")
		if not line then break end
		local index = string.find(line, "Machine")
		local subs = string.sub(line, index+8, string.len(line))
		local ind = string.find(subs, ":")
		local deviceTy = string.sub(subs, ind+2, string.len(subs))
		deviceType = "000000001"
	end


	local ubus = require("ubus"); 
	local conn = ubus.connect()
	if not conn then
		error("Failed to connect to ubusd")
	end

	local status_1 = conn:call("system", "info",{})
	local var1 = status_1.localtime
	math.randomseed(os.time())
	local var2 = math.floor(math.random(1000, 9999))
	local temp1 = var1..var2

	local tab = toBits(temp1,48)
	local temp = ""
	for k, v in pairs(tab) do
		temp =  temp..tostring(v)
	end

	deviceId = temp
	local f = io.open("/root/test/log.txt", "a")
	f:write(packetHdr..deviceId..deviceType.."\n")
	f:close()
	
	io.open("/dev/ttyUSB0","w")
	io.popen("stty -F /dev/ttyUSB0 9600")
	io.output("/dev/ttyUSB0")
	io.write(packetHdr..deviceId..deviceType)
	
	dwnLnk = "1"
	file = io.open("test.lua", "a")
	file:write(packetHdr..deviceId..deviceType)
	
	conn:close()
	
else	
	local dId = file:read()
	io.open("/dev/ttyUSB0","w")
	io.popen("stty -F /dev/ttyUSB0 9600")
	io.output("/dev/ttyUSB0")
	io.write(dId)
	
	local f = io.open("/root/test/log.txt", "a")
	f:write(dId.."\n")
	f:close()
	---print(file:read())
	dwnLnk = "1"
end

file:close()
_G.value = dwnLnk


