local socket = require("socket")
            
local test = socket.tcp()
test:settimeout(1000)                   -- Set timeout to 1 second
            
local testResult = test:connect("www.google.com", 80)        -- Note that the test does not work if we put http:// in front
 
if not(testResult == nil) then
    print("Internet access is available")
else
    print("Internet access is not available")
end
            
test:close()
test = nil