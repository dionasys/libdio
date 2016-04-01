-- #################### CLASS COORDINATOR ###################################
Coordinator={}
Coordinator.algos={}
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


Coordinator.launch=function(running_time, delay)
	
	-- set termination thread
	events.thread(function() events.sleep(running_time) os.exit() end)
	-- TEST: init random number generator , removed for test: (initial view seems to be the same) 
	-- math.randomseed(job.position*os.time())
	local bootView=nil
	local desync_wait=nil
	-- test: wait for other nodes to start 
	events.sleep(10)
	
	-- init each added protocol	
	--for k,v in pairs(Coordinator.algos) do log:print(k, v.id, v.obj) end	
	for k, algo in pairs(Coordinator.algos) do
		log:print("COORDINATOR [launch] - ALGO CLASS: "..algo.obj:getProtocolClassName().." ALGO Seq: "..k.." ALGO ID: "..algo.id.." ALGO OBJ: "..tostring(algo.obj).." at node:"..job.position)
	  bootView=Coordinator.bootstrap(algo.obj:getViewSize())
	  algo.obj:init(bootView)
 	  desync_wait=(algo.obj:getCyclePeriod() * math.random())
    log:print("[Coordinator.launch()] at node: "..job.position.." desync_wait: "..desync_wait)
 	  events.sleep(desync_wait)
	  events.periodic(algo.obj:getCyclePeriod(), Coordinator.doActive)
	  log:print("[Coordinator.launch()] at node: "..job.position.." delay to next protocol: "..desync_wait)
    events.sleep(delay)
	end

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

Coordinator.send=function(algoId, dst, buf)

		local algo = nil
	  for k,v in pairs(Coordinator.algos) do 
   	    if v.id==algoId then
   	  		 algo = v.obj
   	    end
    end
		--local algo=Coordinator.algos[algoId]

	  log:print("Cycle / 2 "..algo.cycle_period)
		local ok, r = rpc.acall(dst.peer,{"Coordinator.passive_thread", algoId, job.position, buf}, algo.cycle_period/2)
		return ok, r
end

Coordinator.passive_thread=function(algoId, from, buffer)

		local algo = nil
	  for k,v in pairs(Coordinator.algos) do 
   	    if v.id==algoId then
   	  		 algo = v.obj
   	    end
    end
		--local algo=Coordinator.algos[algoId]
		
		log:print("[Coordinator.passive] - COORDINATOR PASSIVE THREAD at node: "..job.position.." received from sender id: "..from.." protocol: "..algoId)
		local ret = algo:passive_thread(from, buffer)
		--log:print("buffer size: "..#buffer)
		return ret
end


--Coordinator.bootstrap_algo=function(c, algoId)
--		local algo=Coordinator.algos[algoId]
--		log:print("[Coordinator.passive] - at node: "..job.position.." BOOTSTRAP protocol: ["..algoId.."]")
--		local ret = algo:bootstrap(c)
--		return ret
--end

Coordinator.bootstrap=function(c)
	local indexes = {}
	
	for i=1,#job.get_live_nodes() do 
		indexes[#indexes+1]=i 
	end
	--remove myself
	table.remove(indexes,job.position) 
	
	local selected_indexes = misc.random_pick(indexes,math.min(c, #indexes))
	
	local result = ""
	for i=1,#selected_indexes do
		result = result..selected_indexes[i].." "	
	end
	log:print("[Coordinator.bootstrap] - BOOTSTRAP VIEW at node: "..job.position.." received (selected): ["..result.."]")
	
	return selected_indexes
end

------------------------ END OF CLASS COORDINATOR --------------------------
