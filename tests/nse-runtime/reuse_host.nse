description = [[NSE runtime reuse regression probe.]]
categories = {"safe"}

hostrule = function(host)
  return true
end

action = function(host)
  return host.ip
end
