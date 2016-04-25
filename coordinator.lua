-- #################### CLASS COORDINATOR ###################################
Coordinator={}
Coordinator.algos={}
--Coordinator.nodenode={}
--Coordinator.initAlgos=function(confObj)
-- For each algoId in confObj
--end

Coordinator.addProtocol=function(algo_id, algo_obj)
   
   local algo_seq = #Coordinator.algos+1
   
   algo_obj:setAlgoID(algo_id)   -- note: this method must be implemented by all protocols
--   log:print("COORDINATOR [addPROTOCOL] - at node: "..job.position.. " adding PROTOCOL seq: "..algo_seq.." id: "..algo_id.." table: "..tostring(algo_obj).." table set id:"..algo_obj:getAlgoID())
   local algo ={}
   algo.id=algo_id
   algo.obj=algo_obj
   Coordinator.algos[algo_seq]=algo

   
end


Coordinator.showProtocols=function()
    -- only for debud 
   log:print("#### Current added Protocols #######")
   for k,v in pairs(Coordinator.algos) do 
   	log:print(k, v.id, v.obj) 
   end
   log:print("####################################")
   
   
end

Coordinator.launch=function(node, running_time, delay)
	-- set termination thread
 	events.thread(function() events.sleep(running_time) os.exit() end)
	
	local peerToBoot = Coordinator.bootstrap(node)
	--if peerToBoot then
	log:print("[Coordinator.bootstrap] - at node: "..job.position.." will bootstrap with node: "..tostring(peerToBoot.id))
	for _, algo in pairs(Coordinator.algos) do
	  algo.obj:init(peerToBoot)   
		--events.periodic(algo:getCyclePeriod(), algo:active_thread())
		events.sleep(delay)
	end
	--end 
-- 
-- 	local bootstrapPeer = Coordinator.bootstrap(node)
-- 	log:print("COORDINATOR [launch] - at node: "..job.position.." will bootstrap with peer id: "..tostring(bootstrapPeer:getID()))
-- 	for k, algo in pairs(Coordinator.algos) do
-- 		log:print("COORDINATOR [launch] - at node: "..job.position.." ALGO CLASS: "..algo.obj:getProtocolClassName().." ALGO Seq: "..k.." ALGO ID: "..algo.id.." ALGO OBJ: "..tostring(algo.obj))
-- 		
-- 		if(bootstrapPeer) then
-- 			log:print("bootstrapPeer not nil")
-- 			log:print(bootstrapPeer:getID())
-- 			log:print(bootstrapPeer:getPort())
-- 		else
-- 			log:print("bootstrapPeer is nil")
-- 		end
-- 		algo.obj:init(bootstrapPeer)
-- 
-- 		--events.periodic(algo:getCyclePeriod(), algo:active_thread())
-- 		events.sleep(delay)
-- 	end

end

Coordinator.doActive=function()
	local algo=nil
  for k, algo in pairs(Coordinator.algos) do
    --algo=Coordinator.algos[k]
    if algo.obj~=nil then
    	log:print("[Coordinator.doActive] - COORDINATOR ACTIVE THREAD at node: "..job.position.." for ALGO Seq: "..k.." ALGO id: "..algo.id.." ALGO OBJ: "..tostring(algo.obj))
    	algo.obj:active_thread()
    else
    	log:print("[Coordinator.doActive] - ALGO Seq: "..k.." is not instantiated")
    end
  end
end

Coordinator.passive_thread=function(algoId, from, buffer)

		local algo = nil
	  for k,v in pairs(Coordinator.algos) do 
   	    if v.id==algoId then
   	  		 algo = v.obj
   	    end
    end
		if algo then
			log:print("[Coordinator.passive] - COORDINATOR PASSIVE THREAD at node: "..job.position.." received from sender id: "..from.id.." protocol: "..algoId)
			algo:passive_thread(from, buffer)
		else
			log:print("[Coordinator.passive] - COORDINATOR PASSIVE THREAD at node: "..job.position.." cannot run the passive thread of protocol: "..algoId)
		end	
			

end

Coordinator.send=function(algoId, dst, buf, eventToFire)

		local algo = nil
	  for k,v in pairs(Coordinator.algos) do 
   	    if v.id==algoId then
   	  		 algo = v.obj
   	    end
    end
		if algo then
			local timeOut = math.ceil(algo.cycle_period/2)
			local sender = {ip=algo.me.peer.ip, port=algo.me.peer.port, id=algo.me.id}
			log:print("[Coordinator.send] - COORDINATOR SEND at node: "..job.position.." id: "..sender.id.." at protocol: "..algoId.." ")
			local ok = rpc.acall(dst.peer,{"Coordinator.passive_thread", algoId, sender, buf}, timeOut)
			if not ok then
				log:print("[Coordinator.send] - COORDINATOR at node: "..job.position.." id: "..sender.id.." exchange with peer "..dst.id.." not completed, continuing.")
				events.fire(eventToFire)
			end
		else
			log:print("[Coordinator.send] - COORDINATOR at node: "..job.position.." id: "..sender.id.." protocol "..algoId.." is not in the catalog")
			end
end


Coordinator.bootstrap=function(node)
	
-- 	log:print("[Coordinator.bootstrap] - BOOTSTRAP at node: "..job.position.." id: "..node:getID().." ip: "..node:getIP().." port: "..node:getPort())
-- 
--	if job.position ~= #job.get_live_nodes() then
--		local bootstrapPeer = job.get_live_nodes()[job.position + 1]
---- 		log:print("ip "..bootstrapPeer.peer.ip)
--		local dest = Node:new({ip=bootstrapPeer.ip, port=bootstrapPeer.port})
--
-- 		local bootstrapPeerID = nil
-- 		if node:get_computeID_function() == nil then 
-- 			log:print("[Coordinator.bootstrap] - BOOTSTRAP at node: "..job.position.." id: "..node:getID().." node:get_computeID_function = nil, using job.position as ID") 
-- 			bootstrapPeerID = job.position + 1
-- 		else
-- 			log:print(currentMethod.." at node: "..job.position.." id: "..node:getID().." node:getPeer().ip "..node:getIP().." node:getPeer().port"..node:getPort()) 
-- 			bootstrapPeerID = node:computeID_function(dest:getIP().ip , dest:getPort() )
-- 			log:print("[Coordinator.bootstrap] - BOOTSTRAP at node: "..job.position.." id: "..node:getID().." computed id: "..computedID.." for bootstrapPeer "..dest:getID().." : "..dest:getPort() ) 
-- 		end
-- 		dest:setID(bootstrapPeerID)
-- 		
-- 		
-- 		log:print("[Coordinator.bootstrap] - BOOTSTRAP selected at node: "..job.position.." id: "..node:getID().." selected to bootstrap: "..(job.position + 1).." with ID: "..dest:getID())
-- 		return dest
---- 		
--	else
--		log:print("[Coordinator.bootstrap] - BOOTSTRAP selected at node: "..job.position.." id: "..node:getID().." last node in the group: it will wait.")
--	end

 if job.position ~= #job.get_live_nodes() then
     local peer = job.get_live_nodes()[job.position + 1]
		 
		 local nodeBS = Node.new({ip=peer.ip, port=peer.port})
		 nodeBS:setID(job.position + 1)
     return nodeBS
   else return nil end
-- 
end


Coordinator.callAlgoMethod = function(algoId, method, payload, dst, srcId)

	log:print("[Coordinator.CALLALGOMETHOD] - COORDINATOR at node: "..job.position.." callAlgoMethod invoked from node: "..srcId.." for method: "..method.." of protocol: "..algoId.." at node: "..dst.id)
  local ok = rpc.acall(dst, {"Coordinator.dispatch", algoId, method, payload, srcId}, 3)
  if not ok then 
		log:print("[Coordinator.CALLALGOMETHOD] - COORDINATOR at node: "..job.position.." exchange with node "..dst.id.." did not complete, continuing") 
	end
end

Coordinator.dispatch = function(algoId, method, payload, srcId)
	log:print("[Coordinator.DISPATCH] - COORDINATOR at node: "..job.position.." request from node: "..srcId.." for method: "..method.." of protocol: "..algoId)
	
	local algo = nil
  for k,v in pairs(Coordinator.algos) do 
			--log:print(k,v.id)
 	    if v.id==algoId then
 	  		 algo = v.obj
 	    end
  end
	if algo then 
		algo[method](algo, payload)
	else 
		log:warning("[Coordinator.DISPATCH] - COORDINATOR at node: "..job.position.." No instance of algorithm "..algoId.." found") 
	end
end

------------------------ END OF CLASS COORDINATOR --------------------------
