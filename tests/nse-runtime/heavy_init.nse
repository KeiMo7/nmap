local stdnse = require "stdnse"

description = [[NSE runtime reuse benchmark with expensive top-level setup.]]
categories = {"safe"}

local seed = 0
for i = 1, 5000 do
  seed = (seed + i * 3) % 1000003
end

hostrule = function(host)
  return true
end

action = function(host)
  return host.ip .. ":" .. seed
end
