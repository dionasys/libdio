--[[
 
myExample3.lua:  Similar to myExample1.lua. But in this case we have 2 tman protocols running at same time on top of the PSS. Each TMAN uses a different distance function

]] 

function id_based_ring_cw_distance(self, a, b)

	     local aux_parameters = self:get_distFunc_extraParams()

			if a[1]==nil or b[1]==nil then
				log:warning("DIST at node: "..job.position.." id_based_ring_distance: self either a[1]==nil or b[1]==nil")
				return 2^aux_parameters[1]-1
			end
			
			local k1 = a[1]
			local k2 = b[1]
			local distance = 0

			if k1 < k2 then 
				distance =  k2 - k1 
			else 
				distance =  2^aux_parameters[1] - k1 + k2 
			end

			
   		return distance
end


function id_based_ring_ccw_distance(self, a, b)

	local aux_parameters = self:get_distFunc_extraParams()

	if a[1]==nil or b[1]==nil then
		log:warning("DIST at node: "..job.position.." id_based_ring_distance: self either a[1]==nil or b[1]==nil")
		return 2^aux_parameters[1]-1
	end

	local k1 = a[1]
	local k2 = b[1]
	local distance = 0

	if k1 > k2 then 
		distance =  k1 - k2
	else 
		 distance =  2^aux_parameters[1] - k2 - k1 
	end
	--distance = (2^aux_parameters[1] + k1 - k2 ) % 2^aux_parameters[1]
	return distance
end

function main()
	
	local node = Node.new(job.me) 
	log:print("APP START - node: "..job.position.." id: "..node:getID().." ip/port: ["..node:getIP()..":"..node:getPort().."]")

-- setting PSS:
--parameters: c (view size) , h (healing), s (swappig), fanout, cyclePeriod, peer_selection_policy , me
	local pss = PSS.new(8, 1, 1, 4, 5, "tail", node)
	Coordinator.addProtocol("pss1", pss)

-- setting TMAN 1: 
	local tman_base_protocols={pss}
--parameters: me, view size, cycle_period, base_procotols, active_b_proto, algoId
	local tman1 = TMAN.new(node, 4, 5, tman_base_protocols, "pss1")
--Clockwise-ring distance function
	tman1:set_distance_function(id_based_ring_cw_distance)
	local m = {8} -- number of bits which is used by the distance function to calculate the distance in the ring
	tman1:set_distFunc_extraParams(m)  -- set_distFunc_extraParams() is a function sets a table with any extra parameter need for calculating the distance function. this table of parameters can be accessed in the provided distance function with the getter  ' self:get_distFunc_extraParams()'

-- setting TMAN 2: 
	-- uses the same base as before: local tman_base_protocols={pss}
--parameters: me, view size, cycle_period, base_procotols, active_b_proto, algoId
	local tman2 = TMAN.new(node, 4, 5, tman_base_protocols, "pss1")
--Counter-Clockwise-ring distance function
	tman2:set_distance_function(id_based_ring_ccw_distance)
	-- uses the same ring size:  local m = {8} -- number of bits which is used by the distance function to calculate the distance in the ring
	tman2:set_distFunc_extraParams(m)


-- same node representation for all protocols.
	local rep={} -- the node representation is a table where the information that distinguishes one node from another is stored. the node payload must be set with this information which is used in order to calculate the distance between 2 nodes.
	rep[1] = node:getID()
	node:setPayload(rep)

	Coordinator.addProtocol("tman1", tman1)
	Coordinator.addProtocol("tman2", tman2)
	Coordinator.setPiggyBackMsgs(false)


--launching protocols
	Coordinator.showProtocols()
	Coordinator.launch(node, 420, 0)  --parameters: local node ref, running time in seconds, delay to start each protocol

end

events.thread(main)
events.loop()
