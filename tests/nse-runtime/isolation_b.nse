description = [[NSE runtime same-name global isolation probe B.]]
categories = {"safe"}
state_scope = "session"

shared_state = "B"

hostrule = function(host)
  return true
end

action = function(host)
  shared_state = shared_state .. "b"
  return shared_state
end
