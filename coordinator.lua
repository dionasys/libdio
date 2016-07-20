-- #################### CLASS COORDINATOR ###################################
--TODO: remove commments and unused logs for more readable code.
Coordinator={}
Coordinator.algos={}

Coordinator.senderBuffer={} 
Coordinator.piggybackMsg=false
Coordinator.senderPeriod=7
Coordinator.sender_msgs_lock = events.lock()

-- for evaluation only
Coordinator.totalOkMsgs=0
Coordinator.totalFailedMsgs=0



Coordinator.setPiggyBackMsgs=function(value)
	Coordinator.piggybackMsg=value
end

Coordinator.addProtocol=function(algo_id, algo_obj)
   
   local algo_seq = #Coordinator.algos+1
   
   algo_obj:setAlgoID(algo_id)   -- note: this method must be implemented by all protocols
--log:print("COORDINATOR [addPROTOCOL] - at node: "..job.position.. " adding PROTOCOL seq: "..algo_seq.." id: "..algo_id.." table: "..tostring(algo_obj).." table set id:"..algo_obj:getAlgoID())
   local algo ={}
   algo.id=algo_id
   algo.obj=algo_obj
   Coordinator.algos[algo_seq]=algo
end

Coordinator.showProtocols=function()
   log:print("#### Current added Protocols #######")
   for k,v in pairs(Coordinator.algos) do 
   	log:print(k, v.id, v.obj) 
   end
   log:print("####################################")
end

Coordinator.launch=function(node, running_time, delay)
	-- set termination thread
 	events.thread(function() events.sleep(running_time) os.exit() end)
	
	-- this is the event for Coordinator.sender() thread
	if Coordinator.piggybackMsg then
		events.periodic(Coordinator.senderPeriod, function() Coordinator:sender() end)
	end
	
	local peerToBoot = Coordinator.bootstrap(node)
	if peerToBoot then
		log:print("[Coordinator.launch] - at node: "..job.position.." will bootstrap with node: "..tostring(peerToBoot.id))
	end
	
	for _, algo in pairs(Coordinator.algos) do
		algo.obj:init(peerToBoot)
		events.sleep(delay)
	end
	
end

-- Check if still needed
--Coordinator.doActive=function()
--	local algo=nil
--	for k, algo in pairs(Coordinator.algos) do
--		--algo=Coordinator.algos[k]
--		if algo.obj~=nil then
--			log:print("[Coordinator.doActive] - COORDINATOR ACTIVE THREAD at node: "..job.position.." for ALGO Seq: "..k.." ALGO id: "..algo.id.." ALGO OBJ: "..tostring(algo.obj))
--			algo.obj:active_thread()
--		else
--			log:print("[Coordinator.doActive] - ALGO Seq: "..k.." is not instantiated")
--		end
--	end
--end

Coordinator.passive_thread=function(algoId, from, buffer)
	-- msg1 = {"Coordinator.passive_thread", algoId1, sender, buf} 
	
	log:print(" DEBUG [Coordinator.passive] - testing variables at node: "..job.position.." INVOKED") 
	log:print(" DEBUG [Coordinator.passive] - testing variables at node: "..job.position.." received from: "..tostring(from))
	log:print(" DEBUG [Coordinator.passive] - testing variables at node: "..job.position.." received algoId: "..tostring(algoId))
	log:print(" DEBUG [Coordinator.passive] - testing variables at node: "..job.position.." received buffer: "..tostring(buffer))
	
	if Coordinator.piggybackMsg then
		for key, value in pairs(buffer) do
			local algoId = value[2]
			local sender = value[3]
			local buffer = value[4]
			
			local algo = nil
			for k,v in pairs(Coordinator.algos) do 
				if v.id==algoId then
				algo = v.obj
			end
		end
			if algo then
				--log:print("[Coordinator.passive] - COORDINATOR PASSIVE THREAD at node: "..job.position.." received msg "..key.." from sender id: "..from.id.." protocol: "..algoId)
				algo:passive_thread(from, buffer)
			else
				log:print("[Coordinator.passive] - COORDINATOR PASSIVE THREAD at node: "..job.position.." cannot run the passive thread of protocol: "..algoId)
			end
		end
	else
		-- regular passive 
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
			log:warning("[Coordinator.passive] - COORDINATOR PASSIVE THREAD at node: "..job.position.." cannot run the passive thread of protocol: "..algoId)
		end
	end
			

end

Coordinator.sender=function()
	-- This msg table will be like  this: sender_buffer={ {dest={peer1}, msgs={msg1, msg2}}  {dest={peer2}, msgs={msg3}}  ... }
	-- ex: msg1 = {"Coordinator.passive_thread", algoId1, sender, buf, eventToFire, timeout, dst} 
	-- ex: peer1={ip = "127.0.0.1", port = 200}
	-- TODO: remove commented logs later
		--log:print(" DEBUG - [Coordinator.sender] - at node: "..job.position.." RUNNING.")
	
		Coordinator.sender_msgs_lock:lock()
			if #Coordinator.senderBuffer > 0 then
				--log:print(" DEBUG - [Coordinator.sender] - at node: "..job.position.." # of destinations in the SENDERS_BUFFER: "..#Coordinator.senderBuffer)
				for k,v in pairs(Coordinator.senderBuffer) do 
					log:print("destination: "..tostring(v.dest[1].id).." "..tostring(v.dest[1].peer.ip).."/"..tostring(v.dest[1].peer.port)..": has ".. tostring(#v.msgs).." messages ")
					allEventsToFire = {}

					for g,h in pairs(v.msgs) do 
						--log:print(" DEBUG - [Coordinator.sender] - destination: "..tostring(v.dest[1].id).." "..tostring(v.dest[1].peer.ip).."/"..tostring(v.dest[1].peer.port)..": has ".. tostring(#v.msgs))
						--log:print(" DEBUG - [Coordinator.sender] - destination: "..tostring(v.dest[1].id).." messages: "..tostring(h[1]).." algoId: "..tostring(h[2]) )

						--log:print(" DEBUG - [Coordinator.sender] - filling events to fire with: "..h[5] )
						allEventsToFire[#allEventsToFire+1] = h[5]
						timeout = h[6]
						sender = h[3]
					end
					events.thread(function() Coordinator.ship(sender, v, timeout, allEventsToFire) end)
				end 
				--log:print(" DEBUG - [Coordinator.sender] - all msgs handled, cleaning Coordinator.senderBuffer ")
				Coordinator.senderBuffer={} 
			else
				--log:print(" DEBUG - [Coordinator.sender]  at node: "..job.position.." #Coordinator.senderBuffer not > 0 : Nothing to send")
			end
		Coordinator.sender_msgs_lock:unlock()

		
end

Coordinator.ship=function(sender, v, timeout, allEventsToFire)

		--log:print("[Coordinator.ship] - ship THREAD at node: "..job.position.." id: "..sender.id.." sending "..#v.msgs.." protocols")

		local ok = rpc.acall(v.dest[1].peer,{"Coordinator.passive_thread", "msgs",   sender, v.msgs}, timeOut)

		if not ok then
			Coordinator.totalFailedMsgs=Coordinator.totalFailedMsgs+1
			--log:print("[Coordinator.send] - COORDINATOR at node: "..job.position.." id: "..sender.id.." exchange with peer "..v.dest[1].id.." not completed, continuing.")
			--log:print("[Coordinator.send] - COORDINATOR at node: "..job.position.." events to fire: "..#allEventsToFire)
			for k,ev in pairs(allEventsToFire) do
				--log:print("[Coordinator.send] - COORDINATOR at node: "..job.position.." event: "..tostring(ev))
				events.fire(ev)
			end
		else
			Coordinator.totalOkMsgs=Coordinator.totalOkMsgs+1
			--log:print("[Coordinator.ship] - ship THREAD received OK from RPC.ACALL() at node: "..job.position.." id: "..sender.id.." sending "..#v.msgs.." to "..v.dest[1].id)	
		end
		--log:print("[Coordinator.send] - at node: "..job.position.." COORDINATOR at node: "..job.position.." id: "..sender.id.." TOTAL_OK_MSGS: "..Coordinator.totalOkMsgs.." TOTAL_FAILED_MSGS: "..Coordinator.totalFailedMsgs)
end

Coordinator.send=function(algoId, dst, buf, eventToFire, invokingProtocolID)
	---- This msg table will be like  this: sender_buffer={ {dest={peer1}, msgs={msg1, msg2}}  {dest={peer2}, msgs={msg3}}  ... }
	-- ex: msg1 = {"Coordinator.passive_thread", algoId1, sender, buf, eventToFire, timeout, dst} 
	-- ex: peer1={ip = "127.0.0.1", port = 200}
	-- TODO: remove commented logs later

		--log:print(" DEBUG - [Coordinator.SEND] - at node: "..job.position.." - COORDINATOR SEND method invoked at node: "..job.position.." by protocol: "..invokingProtocolID)

		local algo = nil
		for k,v in pairs(Coordinator.algos) do 
				if v.id==algoId then
					algo = v.obj
				end
		end

		if algo then
			local timeOut = math.ceil(algo.cycle_period/2)
			local sender = {ip=algo.me.peer.ip, port=algo.me.peer.port, id=algo.me.id}

			if Coordinator.piggybackMsg then
				--log:print(" DEBUG - [Coordinator.SEND] -  at node: "..job.position.." COORDINATOR SEND - Coordinator.piggybackMsg active")
				--log:print(" DEBUG - [Coordinator.SEND] -  at node: "..job.position.." preparing new msg ")
				newMsg = {"Coordinator.passive_thread", algoId, sender, buf, eventToFire, timeOut, dst} 

				Coordinator.sender_msgs_lock:lock()

					if #Coordinator.senderBuffer == 0 then
						--log:print(" DEBUG - [Coordinator.SEND] -  at node: "..job.position.." COORDINATOR SEND -  #Coordinator.senderBuffer == 0 ")
						Coordinator.senderBuffer[#Coordinator.senderBuffer+1] = { dest={dst}, msgs={newMsg} }
						--log:print(" DEBUG - [Coordinator.SEND] - at node: "..job.position.." adding newMSG dest.id: "..tostring(dst.id).." newMSG dest.ip: "..tostring(dst.peer.ip).." newMSG dest.port: "..tostring(dst.peer.port))
					else
						--log:print(" DEBUG - [Coordinator.SEND] - at node: "..job.position.." COORDINATOR SEND -  #Coordinator.senderBuffer not equal 0 ")
						found = false
						for k,v in pairs(Coordinator.senderBuffer) do 
							if (v.dest[1]==dst) then 
								v.msgs[#v.msgs+1] = newMsg
								found = true
							end 
						end
						if not found then
							Coordinator.senderBuffer[#Coordinator.senderBuffer+1] = { dest={dst}, msgs={newMsg} }
							--log:print(" DEBUG - [Coordinator.SEND] - at node: "..job.position.." adding newMSG dest.id: "..tostring(dst.id).." newMSG dest.ip: "..tostring(dst.peer.ip).." newMSG dest.port: "..tostring(dst.peer.port))
						end
						
					end
					--log:print(" DEBUG - [Coordinator.SEND] - at node: "..job.position.." - COORDINATOR SEND - print Coordinator.senderBuffer: ")
					Coordinator.printSenderBuffer()
				Coordinator.sender_msgs_lock:unlock()  -- note: it seems to be too long this lock(), change to work with a copy to improve performance?
				
				
			else
				--local timeOut = math.ceil(algo.cycle_period/2)
				--local sender = {ip=algo.me.peer.ip, port=algo.me.peer.port, id=algo.me.id}
				--log:print("[Coordinator.send] - at node: "..job.position.." COORDINATOR SEND at node: "..job.position.." id: "..sender.id.." at protocol: "..algoId.." ")
				local ok = rpc.acall(dst.peer,{"Coordinator.passive_thread", algoId, sender, buf}, timeOut)
				if not ok then
					Coordinator.totalFailedMsgs=Coordinator.totalFailedMsgs+1
					--log:print("[Coordinator.send] - at node: "..job.position.." COORDINATOR at node: "..job.position.." id: "..sender.id.." exchange with peer "..dst.id.." not completed, continuing.")
					events.fire(eventToFire)
				else
					Coordinator.totalOkMsgs=Coordinator.totalOkMsgs+1
				end
			end
			log:print("[Coordinator.send] - at node: "..job.position.." COORDINATOR at node: "..job.position.." id: "..sender.id.." TOTAL_OK_MSGS: "..Coordinator.totalOkMsgs.." TOTAL_FAILED_MSGS: "..Coordinator.totalFailedMsgs)
		else
			log:warning("[Coordinator.send] - at node: "..job.position.." COORDINATOR at node: "..job.position.." protocol "..algoId.." is not in the catalog")
		end

end

Coordinator.printSenderBuffer = function()
	log:print(" DEBUG - [Coordinator.PRINTSENDERBUFFER] - at node: "..job.position.." printing invoked ")
	if #Coordinator.senderBuffer > 0 then
		log:print(" DEBUG - [Coordinator.PRINTSENDERBUFFER] - at node: "..job.position.." destinations at SENDERS_BUFFER: "..tostring(#Coordinator.senderBuffer) )
		for k,v in pairs(Coordinator.senderBuffer) do 
				for g,h in pairs(v.msgs) do 
					log:print(" DEBUG - [Coordinator.PRINTSENDERBUFFER] - at node: "..job.position.." destination: "..tostring(v.dest[1].id)..": "..tostring(v.dest[1].peer.ip).."/"..tostring(v.dest[1].peer.port)..": has ".. tostring(#v.msgs).." messages "..tostring(h[1]).." algoId: "..tostring(h[2]) )
				end  
		end
	else
		log:print(" DEBUG - [Coordinator.PRINTSENDERBUFFER] - at node: "..job.position.." #Coordinator.senderBuffer= "..tostring(#Coordinator.senderBuffer) )
	end
	
end

Coordinator.callAlgoMethod = function(algoId, method, payload, dst, srcId)
-- TODO: possible change in the callback if changes in the send for piggybacked msgs show satisfying results. 
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


Coordinator.bootstrap=function(node)
	
	
	if job.position ~= #job.get_live_nodes() then
		local peer = job.get_live_nodes()[job.position + 1]
		local nodeBS = Node.new({ip=peer.ip, port=peer.port})
		nodeBS:setID(job.position + 1)
		log:print("Coordinator.bootstrap retuning nodeBS: "..nodeBS.id)
		return nodeBS
		else 
			log:print("Coordinator.bootstrap retuning nil: ")
			return nil 
	end

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

	
-- 
end






------------------------ END OF CLASS COORDINATOR --------------------------
