
function main()
	
		--create a local node
		local node = Node.new(job.me) 
  		log:print("APP START - node: "..job.position.." id: "..node:getID().." ip/port: ["..node:getIP()..":"..node:getPort().."]")

		--create a protocol coordinator for this node1
		local coordinator = Coordinator.new(node)

	-- setting PSS 
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
