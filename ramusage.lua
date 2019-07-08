#!/usr/bin/lua
--[[
get system ram usage
]]
local json = require('cjson')

local ubus = require("ubus"); 
local conn = ubus.connect()
local stats = conn:call("system", "info",{}) 
print(json.encode(stats.memory))
