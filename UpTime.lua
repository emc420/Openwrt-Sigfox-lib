#!/usr/bin/lua

local ubus = require("ubus"); 
local conn = ubus.connect()
local status_1 = conn:call("system", "info",{}) 
print(status_1.uptime)