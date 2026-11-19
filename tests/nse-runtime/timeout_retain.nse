local stdnse = require "stdnse"

description = [[NSE runtime timeout retention probe.]]
categories = {"safe"}
state_scope = "session"

hostrule = function(host)
  return true
end

action = function(host)
  if host.ip == "192.0.2.1" then
    stdnse.sleep(3)
  end
  return host.ip
end
