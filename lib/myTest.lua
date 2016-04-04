-- user defined ID settings
function myComputeIDFunc1(self, ip, port, parameters)
	
	local bits = parameters[1]
	log:print(parameters)
	log:print("par 1: "..parameters[1])
	
	local r = 0
	
	if bits%4 == 0 then
		r = bits/4
	else
		r= bits/4 + 1
	end

	print("[myComputeIDFunction] - At node: "..job.position.." setting ID,  selected number of bits: "..bits.." hexa need to represent it: "..r)
	local resultHexa = string.sub(crypto.evp.new("sha1"):digest(tostring(ip)..":"..tostring(port)), 1, r)
	log:print("[myComputeIDFunction] - At node: "..job.position.." id: "..self.id.." setting ID,  hashed(ip port) resultHexa: "..resultHexa)
	local resultNumb = tonumber(resultHexa,16)

	print("[myComputeIDFunction] - At node: "..job.position.." returning ID,  resultHexa to number: "..resultNumb)
  return resultNumb
		
end

-- user defined ID settings
function myComputeIDFunc2(self, ip, port, parameters)
	
	local digits = parameters[1]

	print("[myComputeIDFunction] - At node: "..job.position.." setting ID,  selected number of digits: "..digits.." for ip: "..ip.." port "..port)
	local resultHexa = string.sub(crypto.evp.new("sha1"):digest(tostring(ip)..":"..tostring(port)), 1, digits)
	log:print("[myComputeIDFunction] - At node: "..job.position.." id: "..self.id.." setting ID,  hashed(ip port) resultHexa: "..resultHexa)
	local resultNumb = tonumber(resultHexa,16)

	print("[myComputeIDFunction] - At node: "..job.position.." returning ID,  resultHexa to number: "..resultNumb)
  return resultNumb
		
end




function main()
	
	
		local node = Node.new(job.me) 
	-- this below is used only if we want to set an id different than job.position, a computeID_function can be added (examples above) for specific app requirements
	--local idHexaDigits = {8}
	--node:set_computeID_function(myComputeIDFunc2, idHexaDigits)
	--local myid = node:computeID_function(node:getIP(), node:getPort())
	--node:setID(myid)
	
		log:print("APP START - node: "..job.position.." id: "..node:getID().." ip/port: ["..node:getIP()..":"..node:getPort().."]")
	
	-- setting PSS 
		local pss = PSS.new(10, 3, 3, 5, 5, "tail", node)   -- parameters: c (view size) , h (healing), s (swappig), fanout, cyclePeriod, peer_selection_policy , me
		Coordinator.addProtocol("pss1", pss)
	
	-- -- setting TMAN 
  	local tman_base_protocols={pss}
  	local tman = TMAN.new(node, 6, 5, tman_base_protocols, "pss1")   -- parameters: me, view size, cycle_period, base_procotols, active_b_proto, algoId
  	log:print("at node: "..job.position.." id: "..node:getID().." self tman: "..tostring(tman))
  	Coordinator.addProtocol("tman1", tman)
  	-- Test: jaccard based distance function
   --tman:set_distance_function(tman, jaccard_distance)
   --tman:set_node_representation(select_topics_according_to_id())
  	--tman:set_node_representation(rep)
   
  	-- Test: Clockwise-ring distance function
  	tman:set_distance_function(id_based_ring_distance)
  	local m = {8} -- number of bits which is used by the distance function to calculate the distance in the ring
  	tman:set_distFunc_extraParams(m)
  	local rep={}
  	rep[1] = node:getID()
  	node:setPayload(rep)
   
   -- setting logs on/off 
		pss:setLog(true)
		tman:setLog(true)
		-- launching protocols
		Coordinator.launch(1200, 5)  -- parameters: running time in seconds, delay to start each protocol

end

events.thread(main)
events.loop()
