--#################### CLASS UTILITIES ###################################
local Utilities={}
Utilities.__index=Utilities
------------------------------------------------
function Utilities.new()
  local self=setmetatable({}, Utilities)
  return self
end
------------------------------------------------
function Utilities.new(node)
	local self=setmetatable({}, Utilities)
	self.node = node 
	return self
end
------------------------------------------------
function set_of_peers_to_string(v)
		local ret = ""
		if #v > 0 then
			for i=1,#v do
				if v[i] == nil then
					ret = ret.."NIL".." "	
				else
					ret = ret..v[i].id.."("..v[i].age..") "	
				end
			end
		end
		return ret
end
------------------------------------------------
function Utilities.print_this_view(self, message, view, cycle, algoId)
	if message then 
		log:print("ALGO_ID:["..algoId.."] - "..message.." at node: "..job.position.." id: "..self.node:getID().." cycle: "..cycle.." view(#"..#view.."): [ "..set_of_peers_to_string(view).."]")
	else
		log:print("ALGO_ID:["..algoId.."] VIEW at node: "..job.position.." id: "..self.node:getID().." cycle: "..cycle.." view(# "..#view.." ): [ "..set_of_peers_to_string(view).."]")
	end
end
------------------------------------------------
function Utilities.remove_dup(self, set)
		for i,v in ipairs(set) do
			local j = i+1
			while(j <= #set and #set > 0) do
				if v.id == set[j].id then
					table.remove(set,j)
				else j = j + 1
				end
			end
		end
end
------------------------------------------------
function get_payload_as_string(peer)
	local mypayload = get_payload(peer)
		local res =""
		for i=1, #mypayload do
			res = res..mypayload[i].." " 
		end
		return "["..res.."] "
end
------------------------------------------------
function get_payload(peer)
		local payl = {}
		if type(peer) == "table" then 
			payl = peer.payload 
		else 
			payl = peer 
		end
		return payl
	end
------------------------ END OF CLASS UTILITIES --------------------------
