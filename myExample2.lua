----------------------------------------------------
function jaccard_distance(self, a, b)

		if #a==0 and #b==0 then  -- if sets are empty similarity is considered 1.
			return 1
		end
		
		local intersec = get_intersection(a,b)
		local union = misc.merge(a,b)
		return 1-(#intersec/#union)

end

----------------------------------------------------
function get_intersection(set_a, set_b)
	local result = {}
	  	for i = 1,#set_a do
	    	if contains(set_b, set_a[i]) then 
			result[#result+1]=set_a[i] 
		end
	  	end	
	return result	
end

----------------------------------------------------
function contains(set, elem)
  for i = 1,#set do
    if set[i] == elem then 
			return true 
		end
  end
  return false
end

----------------------------------------------------
function select_topics_according_to_id()
-- TEST: this function is used to test the clustering
-- returns specific topics according to the id of the node. used to select topics to nodes

	local topics = {"Agriculture", "Health","Aid","Infrastructure","Climate",
		"Poverty","Economy","Education","Energy","Mining","Science","Technology",
		"Environment","Development","Debt" ,"Protection","Labor","Finances",
		"Trade","Gender"}
	local selected = {}
	local myposition = job.position
	local interval = myposition % 4
	
	if interval == 0 then
		for i=1, 5 do
		  selected[#selected+1] = topics[i]
		end
	end
	if interval == 1 then
		for i=6, 10 do
		  selected[#selected+1] = topics[i]
		end
	end
	if interval == 2 then
		for i=11, 15 do
		  selected[#selected+1] = topics[i]
		end
	end
	if interval == 3 then
		for i=16, 20 do
		  selected[#selected+1] = topics[i]
		end
	end
 	return selected
end

----------------------------------------------------
function main()

-- TODO: re-test this example after new updates regarding callback communication
	local node = Node.new(job.me) 

	log:print("APP START - node: "..job.position.." id: "..node:getID().." ip/port: ["..node:getIP()..":"..node:getPort().."]")

--setting PSS 
--parameters: c (view size) , h (healing), s (swappig), fanout, cyclePeriod, peer_selection_policy , me
	local pss = PSS.new(node, 8, 1, 1, 4, 5, "tail")  
	Coordinator.addProtocol("pss1", pss)

--setting TMAN 
--parameters: me, view size, cycle_period, base_procotols, active_b_proto, algoId
	local tman_base_protocols={pss}
	local tman = TMAN.new(node, 4, 5, tman_base_protocols, "pss1")   

	Coordinator.addProtocol("tman1", tman)
	Test: jaccard based distance function
	tman:set_distance_function(tman, jaccard_distance)
	tman:set_node_representation(select_topics_according_to_id())
	tman:set_node_representation(rep)  -- it might change to --		node:setPayload(rep) 
	
--launching protocols
	Coordinator.showProtocols()
	Coordinator.launch(node, 660, 0)  -- parameters: local node ref, running time in seconds, delay to start each protocol
end

events.thread(main)
events.loop()
