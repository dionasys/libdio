--[[ 

myExample4 is similar to myExample3 and 1 
But it is used to test the change of the distance function online

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
	local pss = PSS.new(8, 1, 1, 4, 5, "tail", node)
	Coordinator.addProtocol("pss1", pss)

-- setting TMAN 1: 
	local tman_base_protocols={pss}
	local tman1 = TMAN.new(node, 4, 5, tman_base_protocols, "pss1")
	log:print("APP at node: "..job.position.." id: "..node:getID().." Setting distance function")
	tman1:set_distance_function(id_based_ring_cw_distance)
	log:print("APP at node: "..job.position.." id: "..node:getID().." END Setting distance function")
	
	local m = {8}
	log:print("APP at node: "..job.position.." id: "..node:getID().." Setting extra parameters")
	tman1:set_distFunc_extraParams(m) 

	local rep={}
	rep[1] = node:getID()
	node:setPayload(rep)
	Coordinator.addProtocol("tman1", tman1)

--launching protocols
	Coordinator.showProtocols()
	Coordinator.launch(node, 420, 0)  --parameters: local node ref, running time in seconds, delay to start each protocol
	
	--event to change the distance function after a time: 
	if job.position == 1 then 
		log:print("APP at node: "..job.position.." id: "..node:getID().." scheduling thread to change distance function")
		events.thread(function() events.sleep(120) log:print("APP at node: "..job.position.." changing function to ccw!") tman1:set_distance_function(id_based_ring_ccw_distance) end)
	end

end

events.thread(main)
events.loop()
