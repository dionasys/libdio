--[[
myExample5 

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
	Coordinator.addProtocol("tman1", tman1)
	
	local extraParameters = {8} -- number of bits that defines the size of the ring
	
	log:print("APP at node: "..job.position.." id: "..node:getID().." Coordinator setting distance function and extra parameters")
	Coordinator.setProtoDistFunction("tman1", id_based_ring_cw_distance, extraParameters)

	local rep={}
	rep[1] = node:getID()
	node:setPayload(rep)
	

--launching protocols
	Coordinator.showProtocols()
	Coordinator.setDisseminationTTL(8)
	Coordinator.launch(node, 420, 0)  --parameters: local node ref, running time in seconds, delay to start each protocol
	
	--event to change the distance function after a time: 
	if job.position == 1 then 
		log:print("DEBUG DF_SET at node "..job.position.." id: "..node:getID().." scheduling thread for changing the distance function")
		events.thread(function() 
			events.sleep(120) 
			log:print("DEBUG DF_SET at node "..job.position.." changing function to ccw!")
			Coordinator.replaceDistFunctionAtLayer("tman1", id_based_ring_ccw_distance, extraParameters) 
		end)
	end

end

events.thread(main)
events.loop()
