description = [[NSE runtime same-name global isolation probe A.]]
categories = {"safe"}
state_scope = "session"

shared_state = "A"

hostrule = function(host)
  return true
end

action = function(host)
  shared_state = shared_state .. "a"
  return shared_state
end
