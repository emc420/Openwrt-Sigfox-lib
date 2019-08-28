#!/usr/bin/lua


function fetchUSBPort()
		local fetchPort = io.popen("ls -l /dev/ttyACM*")
		local acm = fetchPort:read()

		if(acm==nil) then 
			print("Inside This ")
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


function getMacs()
	local pktHdr = "101"
	local fillbits = "000000000000000000000000000000000000000000000000000000000000000000001"
	local add1
		local add2


		local sig
		local sig1=""
		local sig2=""


		local macList = io.popen("iwinfo wlan0 scan")
						while true do
							local line = macList:read("*l")
							--print(line)
							if not line then break end
							if line:match("Address:") then
								local index = string.find(line, ":")
								local subs = string.sub(line, index+2, string.len(line))
								
								add = subs
							end
							
							if line:match("Signal:") then
								local index = string.find(line, ":")
								local index2 = string.find(line, "dBm")
								local subs = string.sub(line, index+2, index2-2)
								sig = subs 
								
								if(sig1=="" and sig2=="") then
									sig1= tonumber(sig)
									sig2= tonumber(sig)
									add1 = add
									add2 = add
								elseif sig1<tonumber(sig) then
									sig1 = tonumber(sig)
									add1 = add
								elseif sig1>tonumber(sig) and sig2<tonumber(sig) then
									sig2 = tonumber(sig)
									add2 = add
								end
							end
					
						end 

		---print(add1.." "..sig1)
		---print(add2.." "..sig2)
		return (pktHdr..string.gsub(add1, ":", "")..string.gsub(add2, ":", "")..fillbits.."\r\n")

end 

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
				---print(getMacs())
				
				local port = fetchUSBPort()
				local macStr = getMacs()
				io.popen("stty -F "..port.." 115200")
				io.open(port,"w")
				
				io.output(port)
				io.write(macStr)
		file:write(systym.day.."/"..systym.month.."/"..systym.year)
		file:close()
	elseif line2 ~=nil then
		if check(line2, systym.day.."/"..systym.month.."/"..systym.year) then
					local f = io.open("/root/test/log.txt", "a")
					f:write("Geo Loc Service Exec".."\n")
					f:close()

			---print(getMacs())
			local port = fetchUSBPort()
			local macStr = getMacs()
			io.popen("stty -F "..port.." 115200")
			io.open(port,"w")
				
			io.output(port)
			io.write(macStr)
			file = io.open("test.lua", "w")
			file:write(line1.."\n")
			file:write(systym.day.."/"..systym.month.."/"..systym.year)
			file:close()
		end
	
	end
