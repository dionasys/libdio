# libdio: easily building self-organized overlays

libdio is a library used to coordinate the construction of distributed overlays on SPLAY. This work is developed as a part of DIONASYS project. 


# The API:

* **PSS.new(view_size, healing, swappig, fanout, cycle_period, peer_selection_policy, local_node)**: Instantiates an object of a peer sampling protocol (PSS).

* **TMAN.new(local_node, view size, cycle_period, base_procotols, active_base_protocol, algoId)**: Instantiates an object of a TMAN protocol (TMAN).

* **TMAN:set_distance_function(functionName)**: sets the distance function used to rank nodes and create the target structure. The parameter *functionName* is the name of the function defined and implemented by the user.

* **TMAN:set_payload(pl)**: sets the node semantic. This can be seen as node's profile, which is used to calculate the distance between nodes. For instance, in Chord overlay this is the node id. In a topic-based clustering overlay it is the set of topics a node is interested in. 

* **Coordinator.addProtocol(algoId, prot_obj)**: adds the protocols to the coordinator runtime. The argument *algoId* is a string representing the current instance, for instance 'proto1'. *prot_obj* is the protocol object. 

* **Coordinator.showProtocols()**: shows the current added and running protocols. 

* **Coordinator:getView(prot_id)**: method that exposes the state (view, connections) to the application. It returns the current view of a TMAN instance.




# How to use it (by examples):

Currently, there are current few examples available in the source code showing how to use libdio in order to build overlay topologies. 

Lets check some of these examples : 

* myPSSExample.lua: this example show how to run a Peer Sampling Service (PSS) using libdio. As we can see in this example, we start by instantiating a node, 



```
-- myPSSExample.lua:

function main()		
		
	local node = Node.new(job.me) 
	log:print("APP START - node: "..job.position.." id: "..node:getID().." ip/port: ["..node:getIP()..":"..node:getPort().."]")

	--setting PSS 
	--parameters: c(view size), h(healing), s(swappig), fanout, cyclePeriod, peer_selection_policy, node_ref 
	
	local pss = PSS.new(5, 1, 1, 4, 5, "tail", node)
		
	-- add PSS protocol into Coordinator 	
	Coordinator.addProtocol("pss1", pss)
	
	--show added protocol
	Coordinator.showProtocols()

	--launching protocol
	--parameters: local node ref, running time in seconds, delay to start the protocol
	Coordinator.launch(node, 300, 0)  
		

end

events.thread(main)
events.loop()
```

* myExample1.lua: In this example we create a ring structure by using a simple function that calculates the clockwise distance between nodes in the target ring structure. In the target structure nodes will be connected to their successors neighbors. 
Besides the intantiation of PSS and TMAN there are other fundamental and important functions used in this example. The function ***set_distance_function()*** sets the function used to calculate the distance between nodes. Function ***set_distFunc_extraParams()*** sets a table with any extra parameter required by the distance function. This table of parameters can be accessed in the provided distance getter function ***get_distFunc_extraParams()***. Finally, a function ***setPayload()*** sets the payload that is the information that distinguishes one node from another. In this example, the table **node_representation** carries the identifier of the node, which is used by the distance function to rank the nodes. 

```
-- myExample1.lua: 

function id_based_ring_cw_distance(self, a, b)
	
	-- clockwise distance function
	
	local aux_parameters = self:get_distFunc_extraParams()
	if a[1]==nil
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

function main()
		
	local node = Node.new(job.me) 

	-- setting PSS 
	local pss = PSS.new(8, 1, 1, 4, 5, "tail", node)
	
	-- setting PSS as a base protocol of TMAN
	local tman_base_protocols={pss}
	
	-- creating a new TMAN instance
	-- parameters: node, view_size, cycle_period, base_procotol, active_base_protocol
	local tman = TMAN.new(node, 4, 5, tman_base_protocols, "pss1")

	-- add the clockwise-ring distance function to tman 
	tman:set_distance_function(id_based_ring_cw_distance)
	local m = {8} --number of bits used to calculate the distance in the ring
	tman:set_distFunc_extraParams(m)  
	
	local node_representation={} 
	node_representation[1] = node:getID()
	node:setPayload(node_representation)
	
	-- add protocols to the Coordinator
	Coordinator.addProtocol("pss1", pss)
	Coordinator.addProtocol("tman1", tman)

	--launching protocols
	Coordinator.showProtocols()
	Coordinator.launch(node, 300, 0)  
end

events.thread(main)
events.loop()
```

* myExample3.lua: is similar to myExample1.lua. But in this case we have 2 tman protocols concurrently running on top of one PSS. Each protocol has a different distance function.


```
-- myExample3.lua:


function id_based_ring_cw_distance(self, a, b)

	local aux_parameters = self:get_distFunc_extraParams()

	if a[1]==nil or b[1]==nil then
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
	return distance
end

function main()
	
	local node = Node.new(job.me) 

	-- setting PSS:
	local pss = PSS.new(8, 1, 1, 4, 5, "tail", node)
	Coordinator.addProtocol("pss1", pss)

	-- setting TMAN 1: 
	local tman_base_protocols={pss}
	local tman1 = TMAN.new(node, 4, 5, tman_base_protocols, "pss1")

	-- clockwise-ring distance function
	tman1:set_distance_function(id_based_ring_cw_distance)
	local m = {9} 
	tman1:set_distFunc_extraParams(m)
	
	-- setting TMAN 2: 
	local tman2 = TMAN.new(node, 4, 5, tman_base_protocols, "pss1")

	-- counter-clockwise-ring distance function
	tman2:set_distance_function(id_based_ring_ccw_distance)
	tman2:set_distFunc_extraParams(m)

	-- same node representation for all protocols.
	local node_representation={} 
	node_representation[1] = node:getID()
	node:setPayload(node_representation)

	Coordinator.addProtocol("tman1", tman1)
	Coordinator.addProtocol("tman2", tman2)

	--launching protocols
	Coordinator.showProtocols()
	Coordinator.launch(node, 320, 0)

end

events.thread(main)
events.loop()

```

* myExample4.lua: is similar to myExample3.lua. However, in this case the distance function is changed on-the-fly in order to check how the system can be adapted from one structure to another. When the function is changed, a new structure arises.   

```
-- myExample4: 



function id_based_ring_cw_distance(self, a, b)

	local aux_parameters = self:get_distFunc_extraParams()
	if a[1]==nil or b[1]==nil then
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

```


# Versions:
v 0.1

# Note:
This documentation is under construction.