description = [[NSE runtime failure continuation probe.]]
categories = {"safe"}

hostrule = function(host)
  return true
end

action = function(host)
  if host.ip == "192.0.2.1" then
    error("intentional runtime probe failure")
  end
  return host.ip
end
