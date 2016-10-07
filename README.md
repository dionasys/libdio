# libdio: easily building self-organized overlays

Traditional mathods of building overlays topologies require nodes need to navigate in an existing structure in order to find their exact position. Explicitly creating and maintaining these structures in dynamic environments are clearly complex and error-prone tasks. An alternative to this approach is to profit from the self-organizing properties of gossip-based protocols to build overlay topologies. We are interested in the practical aspects of constructing overlay topologies at large scale,  which includes easing the construction and maintenance of such structures. 

To this end, we present libdio. 

libdio is a library used to coordinate the construction of distributed overlay topologies. 
lidbio has a very simple API based on node affinity declarations, that can automatically emerge and maintain the requested overlay structure.

The core of our solution relies on the idea of keeping apart the declaration of the structure and the process that builds it. Our main objective is to ease the process of creating, deploying and monitoring these overlays. libdio offers support in four axes: i) **programmability** by making it easy to program overlays, ii) **runtime support** by handling all the low-level details required to build and deploy overlays, iii) **overlay composition**: by offering a simple mechanism that allows the programmer to attach and detach different protocols as a stack of overlays, iv) **overlay adaptation**: by offering mechanisms that allow the programmer to adapt the protocols and topologies at runtime   

libdio is built upon SPLAY framework and this work was developed as a part of DIONASYS project. 




# The architecture

Here we have a representation of the main blocks of the library that gives an idea about its internals.


![Architecture in blocks - picture](docs/img/lib_architeture.png?raw=true =500x300 "libio_blocks")


# The API:

In the following we describe the main methods exposed by the API. Please note that this list is not extensive and other auxiliary methods and function can be found in the code.

* **Node.new(job.me)**: Instantiates a new Node object. This is the node running the application. The parameter *job.me* is the table identifying a node in SPLAY framework.


* **PSS.new(view_size, healing, swappig, fanout, cycle_period, peer_selection_policy, local_node)**: Instantiates an object of a peer sampling protocol (PSS). The description of each parameter is the following: *view_size*: size of the local view, *healing*: PSS paramenter H, *swappig*: PSS parameter S, *fanout*: PSS fanout parameter, *cycle_period*: defines the gossip cycle, *peer_selection_policy*: PSS parameter, can be "head, "tail" or "rand", *local_node*: reference to the instance of the Node object.


* **TMAN.new(local_node, view size, cycle_period, base_procotols, active_base_protocol, algoId)**: Instantiates an object of a TMAN protocol (TMAN). The description of the parameters are the following, for those not mention they follow the same description used to PSS.  *base_procotols*: a table containing the underlying protocols for each stacked TMAN layer, *active_base_protocol*: defines which base protocol is currently active, *algoId*: identifier string of the current TMAN layer. 


* **Coordinator.addProtocol(algoId, prot_obj)**: adds the protocols to the coordinator runtime. The argument *algoId* is a string representing the current instance, for instance 'proto1'. *prot_obj* is the protocol object. 
*

* **Coordinator.setProtoDistFunction(proto_id, ifunctionName, extra_parameters_table)**: sets the distance function used to rank nodes and create the target structure in a given stack layer. The parameter *proto_id* is the string identifier of a specific TMAN layer you want to set the function. Parameter *functionName* is the name of the function defined and implemented by the user. The parameter *extra_parameters_table* is a table containing extra parameters and settings for the distance function to be calculated. 


* **Node:setPayload(represent_table)**: sets the node semantic. This can be seen as node's profile, which is used to calculate the distance between nodes. The parameter *represent_table* is the table carrying the representation information.  For instance, in Chord overlay this table carries the node id, in a topic-based clustering overlay it is a vector representing the set of topics a node is interested in. 


* **Coordinator.launch(node, running_time, delay_protos)**: starts the protocols set to run at the local node. The parameter *node* is instance of the Node object, *running_time* is the parameter that defines how long (in seconds) the application will run in the SPLAY framework and *delay_protos* defines the delay (if any is required) used by the coordinator before starting each protocol. 


* **Coordinator:getView(proto_id)**: method that exposes the state (i.e., the views) of each node to the application. It returns the current view of a TMAN instance idetified by the parameter *proto_id*.


* **Coordinator.replaceDistFunctionAtLayer(proto_id, ifunctionName, extra_parameters_table) **: replaces the current distance function used at a specific layer defined by the parameter *proto_id*. The definition of these paramenters are the same used by the *setProtoDistFunction* method. Used to adapt the structures on-the-fly.


* **Coordinator.setDisseminationTTL(ttl)**: sets the chosen ttl used during the dissemination of a new distance function. This is only need if we want to change the distance function on the fly. The *ttl* parameter is used to make the dissemination faster. 


* **Coordinator.showProtocols()**: shows the current added and running protocols. 






# How to use libdio (by examples):

Currently, there are current few examples available in the source code showing how to use libdio in order to build overlay topologies. 

Lets check how we can deploy and adapt different structures and protocols by using some of these examples. Check more in the folder *examples*.

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
	-- clockwise distance function

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
	-- counter-clockwise distance function

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

* myExample4.lua: is similar to myExample3.lua. However, in this case the distance function is changed on-the-fly. The system will adapt itself into a completely new structure.

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
	return distance
end

function main()
	
	local node = Node.new(job.me) 

-- setting PSS:

	local pss = PSS.new(8, 1, 1, 4, 5, "tail", node)
	Coordinator.addProtocol("pss1", pss)
	
-- setting TMAN: 

	local tman_base_protocols={pss}
	local tman1 = TMAN.new(node, 4, 5, tman_base_protocols, "pss1")
	Coordinator.addProtocol("tman1", tman1)
	
	local extraPar = {8} -- number of bits that defines the size of the ring
	Coordinator.setProtoDistFunction("tman1", id_based_ring_cw_distance, extraPar)
	local rep={}
	rep[1] = node:getID()
	node:setPayload(rep)

--launching protocols:

	Coordinator.showProtocols()
	Coordinator.setDisseminationTTL(8)
	Coordinator.launch(node, 420, 0) 
		
--event to change the distance function after a time: 

	if job.position == 1 then 
		events.thread(function() 
		events.sleep(120) 
		log:print("at node "..job.position.." changing function to ccw!")
		Coordinator.replaceDistFunctionAtLayer("tman1", id_based_ring_ccw_distance, extraPar) 
		end)
	end
	
end
events.thread(main)
events.loop()

```

#Handling outputs

The script folder has a list of scripts that can be use to grab de raw output of all examples presented above. These scripts are simple bash commands (e.g., *grep* and *awk* ) that allows to capture the views of the nodes at any time. As mentioned before, the state of any protocol can be capture by the application by using the Coordinator:getView() method provided by the APi. See the folder scripts to check a list of scripts provided with the library. 

#Some results and evaluations

##Behavior under churn
This picture shows how a system deployed with libdio behaves under churn. This plot is made with the code deployed with *example3.lua*. The plot shows how the system converges to the expected structure and how it behaves during and after the churn. The blue and red lines represent the system without churn, while lines green and yellow represent the system with churn. Between 60 seconds and 180 seconds we can clearly see the impact of the churn on the convergence. We can also see that as soon as the churn stops, the system recovers and reconverge to the target state again.
![libdio_convergence - picture](docs/img/behavior_under_churn.png?raw=true "libio_converge")


##System adaptation
Another insteresting point see is the adaptation on-the-fly. This picture shows how the convergence of the target structure behaves when we change the distance function on-the-fly. The system which initially converged using a initial distance function, has this function replaced to another one at the second 120. At this point the red line shows the degradation of the system and the convergence of the new structure is shown by the green line. We see that as soon as all the nodes in the system get the new function through the dissemination protocol the new structure converges to 100% of the new expected structure. 
![libdio_convergence - picture](docs/img/function_adaptation_353.png?raw=true "libio_converge")

By the previous picture, we see that the convergence of the new structure depends on how fast the new function is disseminated. The following picture shows how we can improve this dissemination by introducing a speeding up mechanism that triggers a controlled flood to improve the time need to disseminate the new function. 
![libdio adaptation - picture](docs/img/function_adaptation_128n.png?raw=true "libio_adaptation128")



# Versions:
v 0.2

# Note:
This documentation is evolving. New updates must often appear.