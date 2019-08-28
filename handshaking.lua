#!/usr/bin/lua

local dwnLnk = ""
local fillBits="000000000000000000000000000000000001"
_G.value = ""


function fetchUSBPort()
		local fetchPort = io.popen("ls -l /dev/ttyACM*")
		local acm = fetchPort:read()

		if(acm==nil) then 
			fetchPort = io.popen("ls -l /dev/ttyUSB*")
			local usb = fetchPort:read()

			if(usb==nil) then 
			
				return "None"

			else

				local index = string.find(usb, "/dev/")
				local subs = string.sub(usb, index, string.len(usb))
				return subs

			end
			
		else

			local index = string.find(acm, "/dev/")
			local subs = string.sub(acm, index, string.len(acm))
			return subs

		end


end

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

local USBport = fetchUSBPort()
local file = io.open("test.lua", "r")
if file==nil then
	---print("No file")
	local deviceId=""
	local deviceType=""
	local packetHdr = "111"

	--- Linksys WRT1200AC -  000000001


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
	f:write(packetHdr..deviceId..deviceType..fillBits.."\n")
	f:close()
	
	io.popen("stty -F "..USBport.." 115200")
	io.open(USBport,"w")
	
	io.output(USBport)
	io.write(packetHdr..deviceId..deviceType..fillBits.."\r\n")
	
	dwnLnk = "1"
	file = io.open("test.lua", "a")
	file:write(packetHdr..deviceId..deviceType..fillBits.."\n")
	
	conn:close()
	
else	
	local dId = file:read()
	io.popen("stty -F "..USBport.." 115200")
	io.open(USBport,"w")
	
	io.output(USBport)
	print(dId.."\r\n")
	io.write(dId.."\r\n")
	local f = io.open("/root/test/log.txt", "a")
	f:write(dId.."\n")
	f:close()
	---print(file:read())
	dwnLnk = "1"
end

file:close()
_G.value = dwnLnk


