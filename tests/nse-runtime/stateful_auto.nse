description = [[NSE runtime state-pollution fallback probe.]]
categories = {"safe"}

counter = 0

hostrule = function(host)
  return true
end

action = function(host)
  counter = counter + 1
  return host.ip .. ":" .. counter
end
