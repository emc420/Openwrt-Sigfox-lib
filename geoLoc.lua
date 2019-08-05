#!/usr/bin/lua


function check(dt1, dt2)
	local index = string.find(dt1, "/")
	local subs = string.sub(dt1, index+1, index+1)
	local index2 = string.find(dt2, "/")
	local subs2 = string.sub(dt2, index2+1, index2+1)
	if(subs == subs2) then
		return false
	else
		return true
	end
end

pktHdr = "01"


	--- Router Uptime
	local systym = os.date('*t')

	---- ReadFile and Check-----
	local file = io.open("test.lua", "r")
	local line1 = file:read()
	local line2 = file:read()
	file:close()
	if line2 == nil then
			local f = io.open("/root/test/log.txt", "a")
			f:write("Geo Loc Service Exec".."\n")
			f:close()
		local file = io.open("test.lua", "a")
		print(pktHdr)
		io.open("/dev/ttyUSB0","w")
		io.popen("stty -F /dev/ttyUSB0 9600")
		io.output("/dev/ttyUSB0")
		io.write(pktHdr)
		file:write(systym.day.."/"..systym.month.."/"..systym.year)
		file:close()
	elseif line2 ~=nil then
		if check(line2, systym.day.."/"..systym.month.."/"..systym.year) then
					local f = io.open("/root/test/log.txt", "a")
					f:write("Geo Loc Service Exec".."\n")
					f:close()

			print(pktHdr)
			io.open("/dev/ttyUSB0","w")
			io.popen("stty -F /dev/ttyUSB0 9600")
			io.output("/dev/ttyUSB0")
			io.write(pktHdr)
			file = io.open("test.lua", "w")
			file:write(line1.."\n")
			file:write(systym.day.."/"..systym.month.."/"..systym.year)
			file:close()
		end
	
	end
