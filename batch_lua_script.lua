#!/usr/bin/lua

require "iwinfo"
local devices = {}
devices["5G"] = "wlan0"
devices["2.4G"] = "wlan1"

local packetHdr = ""
local IA = ""
local SysUp = ""
local radio0 =""
local radio1 =""
local Wup =""
local LuP = ""
local WConn=""
local LConn = "0"
local deviceNo = ""
local err1 =""
local err2 =""
local err3 =""
local dwnlink ="0" 
local ipChange = ""
local battStat = "0"
local comm
local dns
local fillBits = "0000000000000000000000000000000000000000000001"
tab = {}

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

function getinfo(ifname, func)
	local driver_type = iwinfo.type(ifname)
	if driver_type and iwinfo[driver_type][func] then
		return iwinfo[driver_type][func](ifname)
	end

	return nil
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

function getTime(seconds)
	local header = ""
	local uptime = ""
	if seconds/60 >= 60 then
		if (seconds/60)/60 >= 24 then
			if ((seconds/60)/60)/24 >=7 then
				header = "11"
				if (((seconds/60)/60)/24)/7 >=53 then
					uptime = 52
				else
					uptime = (((seconds/60)/60)/24)/7
				end
			else
				header ="10"
				uptime = ((seconds/60)/60)/24
			end
		else	
			header = "01"
			uptime = (seconds/60)/60
		end
	else
		header = "00"
		uptime = seconds/60	

	end
	
	local var = toBits(math.floor(uptime),6)

	local temp = ""
	for k, v in pairs(var) do
			temp =  temp..tostring(v)
	end
	return (header..temp)
end
---------------------------------------------
function checkIp(ipv4, dnsp, mask)

local arr1={}
local arr2={}
local arr3={}
local flag = true

	for w in ipv4:gmatch("([^.]+).?") do 
		table.insert(arr1, w) 
	end

	for w in dnsp:gmatch("([^.]+).?") do 
		table.insert(arr2, w)
	end
	
	for w in mask:gmatch("([^.]+).?") do 
		table.insert(arr3, w) 
	end
	
	if(arr1[1] ~= arr2[1]) then 
		flag = false
	end
	if(arr3[2] == "255") then
		if(arr1[2]~=arr2[2]) then
			flag = false
		end
	else
		local diff = 255-tonumber(arr3[2])
		if(tonumber(arr2[2])-tonumber(arr1[2])>diff) then 
			flag = false
		end
	end
	if(arr3[3] == "255") then
		if(arr1[3]~=arr2[3]) then
			flag = false
		end
	else
		local diff = 255-tonumber(arr3[3])
		if(tonumber(arr2[3])-tonumber(arr1[3])>diff) then 
			flag = false
		end
	end
	
	return flag

end



--------------------------------------------
local clock = os.clock
function sleep(n)  -- seconds
  local t0 = clock()
  while clock() - t0 <= n do end
end

----------------------------------
local ubus = require("ubus"); 
local conn = ubus.connect()
if not conn then
    error("Failed to connect to ubusd")
end
----------------------------------
local socket = require("socket")
----------------------------------
local control = false
local cntr = 0



function fetchParams()
	------------------------------
				--Packet Header--
				packetHdr = "100"
				----------------------------------------------- 
				--- Router Uptime
				local status_1 = conn:call("system", "info",{})
					--print("SysUp: "..status_1.uptime)
				SysUp = getTime(status_1.uptime)
				-----------------------------------------------
				--- Radio up/Down
				local key, device
				local count = 0
				deviceNo=""
				for key, device in pairs(devices) do
						local opmode = getinfo(device, "mode")
						if opmode == "Master" then 	
								if key == "2.4G" then 
									radio0 = "1"
								else	
									radio1 = "1"
								end
								--print(key .. " : 1")
								local assoclist = getinfo(device, "assoclist")
								if assoclist then
										local mac
										for mac in pairs(assoclist) do
												count = count + 1
										end
								end
						else
								if key == "2.4G" then 
									radio0 = "0"
								else	
									radio1 = "0"
								end
								--print(key .. " : 0")
						end
				end	
				local yso = toBits(math.floor(count),6)
				for k, v in pairs(yso) do
						deviceNo =  deviceNo..tostring(v)
				end
				-------------------------------------------------
				-- Check status for network interface WAN and check IP subnet 
				local ipadd =""
				local dns1=""
				local mask=""
				local status_wan = conn:call("network.interface.wan", "status", {})
				---print("WAN: ")
				for k, v in pairs(status_wan) do
					if tostring(k)=="up" then
					local flag = "0"
						if tostring(v) == "true" then
							flag = "1"
						end
						--print("W" .. k ..": " .. flag)
						Wup =  flag
					end
					if tostring(k)=="ipv4-address" then
						ipadd = v[1]["address"]
					end
					if tostring(k)=="dns-server" then
						dns1 = v[1]
					end
					
					---if tostring(k)=="uptime" then
					--	print("				" .. k ..": " .. tostring(v))
					--end
					--if tostring(k)=="available" then
					--	print("				" .. k ..": " .. tostring(v))
					--end
					--if tostring(k)=="device" then
					--	print("				" .. k ..": " .. tostring(v))
					--end
				end
				local ipChan = io.popen("ifconfig")
					while true do
						local line = ipChan:read("*l")
						if not line then break end
						if line:match("inet addr:"..ipadd) then
							local index = string.find(line, " Mask:")
							local subs = string.sub(line, index+6, string.len(line))
													
							mask= subs
						end
					end
				if(ipadd == "" or dns1 == "" or mask == "" ) then 
					ipChange = 0
				elseif(checkIp(ipadd, dns1, mask) == false) then
					ipChange = 1
				else
					ipChange = 0
				end
				-- Check status for network interface: LAN
				local status_lan = conn:call("network.interface.lan", "status", {})
				---print("LAN: ")
				for k, v in pairs(status_lan) do
					if tostring(k)=="up" then
						local flag = "0"
						if tostring(v) == "true" then
							flag = "1"
						end
						--print("L" .. k ..": " .. flag)
						LuP = flag
					end
					--if tostring(k)=="uptime" then
					--	print("				" .. k ..": " .. tostring(v))
					--end
					--if tostring(k)=="available" then
					--	print("				" .. k ..": " .. tostring(v))
					--end
					--if tostring(k)=="device" then
					--	print("				" .. k ..": " .. tostring(v))
					--end
				end
				-------------------------------------------------
				--- Check for wire connection:
				local fetch =io.popen("swconfig dev switch0 show")
				while true do
						local line = fetch:read("*l")
						if not line then break end
						if line:match("link: port:4 link:down") then
							--print("WConn : 0")
							WConn = "0"
						end
						if line:match("link: port:4 link:up") then 
							--print("WConn : 1")
							WConn = "1"
						end
						if line:match("link: port:0 link:up") then 
							
							LConn = "1"
						end
						if line:match("link: port:1 link:up") then 
							
							LConn = "1"
						end
						if line:match("link: port:2 link:up") then 
							
							LConn = "1"
						end
						if line:match("link: port:3 link:up") then 
							
							LConn = "1"
						end
						---if line:match("VLAN") then
						--	print(line)
						--end
						--if line:match("ports:") then
						--	print(line)
						--end
							
				end
				------------------------------------------------
				---Check GateWay Comm and DNS
				comm = "0"
				dns = "1"
				local ipv4 = "nil"
				local gatewayAdd = "nil"
				
				local sta = conn:call("network.interface.wan", "status", {})
				for k, v in pairs(sta) do
						if tostring(k)=="ipv4-address" then
							ipv4 = v[1]["address"]
						end
						if tostring(k)== "dns-server" then
							gatewayAdd = v[1]
						end
				end
				
				if(ipv4 == "nil") then	
					comm = "0" ---Data not going out of router
				else
				--- Check Comm to Gateway

					local testResult = io.popen("ping -c 3 "..gatewayAdd)        -- Note that the test does not work if we put http:// in front
					--local response = testResult:read("*a")
					while true do
							local line = testResult:read("*l")
							if not line then break end
							if line:match("3 packets received") then
								comm = "1"
							end
							if line:match("0 packets received") then 
								comm = "0"
							end
					end
				---- Check DNS is working
					local flag1 = "0"
					local flag2 = "0"
					local ipchk = io.popen("ping -c 3 8.8.8.8")
					while true do
							local line = ipchk:read("*l")
							if not line then break end
							if line:match("3 packets received") then
								flag1 = "1"
							end
							if line:match("0 packets received") then 
								flag1 = "0"
							end
					end
					local dnschk = io.popen("ping -c 3 www.google.com")
					while true do
							local line = dnschk:read("*l")
							if not line then break end
							if line:match("3 packets received") then
								flag2 = "1"
							end
							if line:match("0 packets received") or  line:match("bad address") then 
								flag2 = "0"
							end
					end	
					
					if flag1 == "1" then
						if flag2 == "0" then 
							dns = "0"
						end
					end
					
						
								
				end
				------------------------------------------------
				--- Last three Error types from System Log 
				tab ={}
				local errLogs = io.popen("logread")
				while true do
					local line = errLogs:read("*l")
					if not line then break end
					if line:match(".err ") then
						local flag = true
						for k,v in pairs(tab) do
							if tostring(v) == tostring(string.sub(line, 26)) then 
								flag = false
								break
							end
						end 
						if flag == true	then
							table.insert(tab, string.sub(line, 26))
						end
						
					end

				end
				local countr = 0
				countr = table.maxn(tab)
				for k,v in pairs(tab) do
					local var = ""
							if tostring(v):match(" kernel") then
								var = "00001"
							end
							if tostring(v):match(" dnsmasq") then
								var = "00010"
							end
							if tostring(v):match(" dnsmasq-dhcp") then
								var = "00011"
							end
							if tostring(v):match(" procd") then
								var = "00100"
							end
							if tostring(v):match(" ucitrack") then
								var = "00101"
							end
							if tostring(v):match(" netifd") then
								var = "00110"
							end
							if tostring(v):match(" odhcp6c") then
								var = "00111"
							end
							if tostring(v):match(" odhcpd") then
								var = "01000"
							end
							if tostring(v):match(" firewall") then
								var = "01001"
							end
							if tostring(v):match(" hostapd") then
								var = "01010"
							end
							if tostring(v):match(" uhttpd") then
								var = "01011"
							end
					countr= countr -1
					if countr ==2 then
						if tostring(v):match("kern.err") then 
							err1 = "01"
						end
						if tostring(v):match("user.err") then
							
							err1 = "10"
						end
						if tostring(v):match("daemon.err") then

							err1 = "11"
						end
						err1 = err1..var
					end
					if countr ==1 then
						if tostring(v):match("kern.err") then
							
							err2 = "01"
						end
						if tostring(v):match("user.err") then
							
							err2 = "10"
						end
						if tostring(v):match("daemon.err") then
							
							err2 = "11"
						end
						err2 = err2..var
					end
					if countr ==0 then
						if tostring(v):match("kern.err") then
							
							err3 = "01"
						end
						if tostring(v):match("user.err") then
							
							err3 = "10"
						end
						if tostring(v):match("daemon.err") then
							
							err3 = "11"
						end
						err3 = err3..var
					end
				end 

				if(err1 == "") then 
					err1 = "0000000"
				end
				if(err2 == "") then 
					err2 = "0000000"
				end
				if(err3 == "") then 
					err3 = "0000000"
				end
				------------------------------------------------



end

local port = fetchUSBPort()
IA = "1"
fetchParams()
io.popen("stty -F "..port.." 115200")
io.open(port,"w")
io.output(port)
io.write(packetHdr..IA..radio0..radio1..deviceNo..Wup..LuP..WConn..LConn..comm..dns..SysUp..ipChange..err1..err2..err3..dwnlink..battStat..fillBits.."\r\n")

while true do
		local test = socket.tcp()
		test:settimeout(2000)
		local testResult = test:connect("openwrt.org", 80)

		if testResult == nil then
			if control == false then
				cntr = cntr + 1
				--- Internet status 
					--print("IA: 0")
					IA = "0"
				fetchParams()
				
				io.popen("stty -F "..port.." 115200")
				io.open(port,"w")
	
				io.output(port)
				io.write(packetHdr..IA..radio0..radio1..deviceNo..Wup..LuP..WConn..LConn..comm..dns..SysUp..ipChange..err1..err2..err3..dwnlink..battStat..fillBits.."\r\n")
				
				local f = io.open("/root/test/log.txt", "a")
				f:write(packetHdr..IA..radio0..radio1..deviceNo..Wup..LuP..WConn..LConn..comm..dns..SysUp..ipChange..err1..err2..err3..dwnlink..battStat..fillBits.."\n")
				f:write("pktHdr"..packetHdr.."Int Accs"..IA.."radio0"..radio0.."rad1"..radio1.."devNo"..deviceNo.."Wup"..Wup.."Lup"..LuP.."Wconn"..WConn.."LConn"..LConn.."comm"..comm.."dns"..dns.."Sysup"..SysUp.."Ipchange"..ipChange.."Err1"..err1.."err2"..err2.."err3"..err3.."DL"..dwnlink..battStat..fillBits.."\n")
				f:close()
				---print(packetHdr..IA..radio0..radio1..deviceNo..Wup..LuP..WConn..LConn..comm..dns..SysUp..err1..err2..err3..dwnlink)
				if cntr==2 then
					control = true
					cntr = 0
				end
			end
		else
			control = false
			----- For test ------
			---local var =  "Bohot Hard"
			---io.open("/dev/ttyACM0", "w")
			---io.popen("stty -F /dev/ttyACM0 9600")
			---io.output("/dev/ttyACM0")
			---io.write(var)
			--print(var)
		end

dofile("/root/test/geoLoc.lua")
test = nil
sleep(5)
local file = io.open("/tmp/test.log", "r")
if file ~= nil then
	local devStat = tostring(file:read())
	if devStat == "DeviceRemoved" then
		break;
	end
end
file:close()
end		
conn:close()					
