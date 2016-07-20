# libdio: Self-Organized Overlay Construction
libdio is a library used to coordinate the construction of distributed overlays on SPLAY. This work is developed as a part of DIONASYS project. 


# The API:

* **PSS.new(view_size, healing, swappig, fanout, cycle_period, peer_selection_policy, local_node): Instantiates an object of a peer sampling protocol (PSS).

* **TMAN.new(local_node, view size, cycle_period, base_procotols, active_base_protocol, algoId): Instantiates an object of a TMAN protocol (TMAN).

* **TMAN:set_distance_function(functionName)**: sets the distance function used to rank nodes and create the target structure. The parameter *functionName* is the name of the function defined and implemented by the user.

* **TMAN:set_payload(pl)**: sets the node semantic. This can be seen as node's profile, which is used to calculate the distance between nodes. For instance, in Chord overlay this is the node id. In a topic-based clustering overlay it is the set of topics a node is interested in. 

* **Coordinator.addProtocol(algoId, prot_obj)**: adds the protocols to the coordinator runtime. The argument *algoId* is a string representing the current instance, for instance 'proto1'. *prot_obj* is the protocol object. 

* **Coordinator.showProtocols()**: shows the current added and running protocols. 

* **Coordinator:getView(prot_id)**: method that exposes the state (view, connections) to the application. It returns the current view of a TMAN instance.





# Architeture:
![arch_lib.png](https://bitbucket.org/repo/R6kX8y/images/247039068-arch_lib.png)


# How to use it (examples):
* Currently, there are current two examples available in the source code: myExample1.lua and myExample2.lua. The former creates a ring overlay by using a clockwise distance function. The latter, is an example of an topic based overlay, where nodes are clustered according to the topics they have in their profiles (payload). Here it is an basic example of how to create/deploy a simple peer sampling protocol using libdio:


```
#!lua

function main()
	
--create a local node
  local node = Node.new(job.me) 
  log:print("APP START - node: "..job.position.." id: "..node:getID().." ip/port: ["..node:getIP()..":"..node:getPort().."]")

--create a protocol coordinator for this node1
  local coordinator = Coordinator.new(node)

-- setting PSS protocol 
-- parameters:  me, c (view size) , h (healing), s (swappig), fanout, cyclePeriod, peer_selection_policy, coordinator
local pss = PSS.new(node, 10, 1, 1, 4, 7, "rand", coordinator)   

		coordinator:addProtocol("pss1", pss)
		coordinator:showProtocols()



-- -- setting TMAN 
--local tman_base_protocols={pss}
--local tman = TMAN.new(node, 6, 7, tman_base_protocols, "pss1")   -- parameters: me, view size, cycle_period, base_procotols, active_b_proto, algoId
---		Coordinator.addProtocol("tman1", tman)
  --    	log:print("at node: "..job.position.." id: "..node:getID().." self tman: "..tostring(tman))
  --    	-- Test: jaccard based distance function
  --     --tman:set_distance_function(tman, jaccard_distance)
  --     --tman:set_node_representation(select_topics_according_to_id())
  --    	--tman:set_node_representation(rep)
  --     
  --    	-- Test: Clockwise-ring distance function
--		tman:set_distance_function(id_based_ring_distance)
--		local m = {10} -- number of bits which is used by the distance function to calculate the distance in the ring
--		tman:set_distFunc_extraParams(m)
--		local rep={}
--		rep[1] = node:getID()
--		node:setPayload(rep)
     
		-- setting logs on/off 
		--pss:setLog(true)
		--tman:setLog(true)
		--launching protocols


		coordinator:launch(node, 860, 0)  -- parameters: local node ref, running time in seconds, delay to start each protocol

end

events.thread(main)
events.loop()
```




# Versions:
v 0.1

# Note:
This documentation is under construction.