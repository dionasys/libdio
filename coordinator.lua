-- #################### CLASS COORDINATOR ###################################
Coordinator={}
Coordinator.algos={}

Coordinator.senderBuffer={} 
Coordinator.piggybackMsg=true
Coordinator.senderPeriod=7
Coordinator.sender_msgs_lock = events.lock()

-- for evaluation only
Coordinator.totalOkMsgs=0
Coordinator.totalFailedMsgs=0



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
	log:print("[Coordinator.launch] - at node: "..job.position.." Coordinator.piggybackMsg : "..tostring(Coordinator.piggybackMsg))
	if Coordinator.piggybackMsg then
		log:print("[Coordinator.launch] - at node: "..job.position.." scheduling a periodic task ")
		events.periodic(Coordinator.senderPeriod, function() Coordinator:sender() end)
		log:print("[Coordinator.launch] - at node: "..job.position.." END scheduling a periodic task ")
	end
	
	local peerToBoot = Coordinator.bootstrap(node)
	if peerToBoot then
		log:print("[Coordinator.launch] - at node: "..job.position.." will bootstrap with node: "..tostring(peerToBoot.id))
	end
	
	for _, algo in pairs(Coordinator.algos) do
		log:print("[Coordinator.launch] - at node: "..job.position.." will invoke init of protocol "..algo.id)
	  algo.obj:init(peerToBoot)
		log:print("[Coordinator.launch] - at node: "..job.position.." ended invokation of init of protocol "..algo.id)
		events.sleep(delay)
		log:print("[Coordinator.launch] - at node: "..job.position.." delay ended")
	end
	log:print("[Coordinator.launch] - at node: "..job.position.." finished INITs ")
	
	
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
				--log:print("[Coordinator.passive] - COORDINATOR PASSIVE THREAD at node: "..job.position.." received from sender id: "..from.id.." protocol: "..algoId)
				log:print("[Coordinator.passive] - COORDINATOR PASSIVE THREAD at node: "..job.position.." received msg "..key.." from sender id: "..from.id.." protocol: "..algoId)
				algo:passive_thread(from, buffer)
			else
				log:print("[Coordinator.passive] - COORDINATOR PASSIVE THREAD at node: "..job.position.." cannot run the passive thread of protocol: "..algoId.." for msg "..key)
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
			--log:print("[Coordinator.passive] - COORDINATOR PASSIVE THREAD at node: "..job.position.." received from sender id: "..from.id.." protocol: "..algoId)
			log:print("[Coordinator.passive] - COORDINATOR PASSIVE THREAD at node: "..job.position.." received from sender id: "..from.id.." protocol: "..algoId)
			algo:passive_thread(from, buffer)
		else
			log:print("[Coordinator.passive] - COORDINATOR PASSIVE THREAD at node: "..job.position.." cannot run the passive thread of protocol: "..algoId)
		end
	end
			

end

Coordinator.sender=function()
	-- This msg table will be like  this: sender_buffer={ {dest={peer1}, msgs={msg1, msg2}}  {dest={peer2}, msgs={msg3}}  ... }
	-- msg1 = {"Coordinator.passive_thread", algoId1, sender, buf, eventToFire, timeout, dst} 
	-- msg2 = {"Coordinator.passive_thread", algoId1, sender, buf, eventToFire, timeout, dst}
	-- msg3 = {"Coordinator.passive_thread", algoId2, sender, buf, eventToFire, timeout, dst}
	-- peer1={ip = "127.0.0.1", port = 200}
	-- peer2={ip = "127.0.0.1", port = 300}
	-- peer3={ip = "127.0.0.1", port = 400}
		log:print(" DEBUG - [Coordinator.sender] - at node: "..job.position.." RUNNING.")
	
		Coordinator.sender_msgs_lock:lock()
			if #Coordinator.senderBuffer > 0 then
				log:print(" DEBUG - [Coordinator.sender] - at node: "..job.position.." number of destinations in the senders buffer: "..#Coordinator.senderBuffer)
				for k,v in pairs(Coordinator.senderBuffer) do 
					log:print("destination: "..tostring(v.dest[1].id).." "..tostring(v.dest[1].peer.ip).."/"..tostring(v.dest[1].peer.port)..": has ".. tostring(#v.msgs).." messages ")
					allEventsToFire = {}

					for g,h in pairs(v.msgs) do 
						log:print(" DEBUG - [Coordinator.sender] - destination: "..tostring(v.dest[1].id).." "..tostring(v.dest[1].peer.ip).."/"..tostring(v.dest[1].peer.port)..": has ".. tostring(#v.msgs))
						log:print(" DEBUG - [Coordinator.sender] - destination: "..tostring(v.dest[1].id).." messages: "..tostring(h[1]).." algoId: "..tostring(h[2]) )

						log:print(" DEBUG - [Coordinator.sender] - filling events to fire with: "..h[5] )
						allEventsToFire[#allEventsToFire+1] = h[5]
						timeout = h[6]
						sender = h[3]
					end
					events.thread(function() Coordinator.ship(sender, v, timeout, allEventsToFire) end)
				end 
				log:print(" DEBUG - [Coordinator.sender] - all msgs handled, cleaning Coordinator.senderBuffer ")
				Coordinator.senderBuffer={} 
			else
				log:print(" DEBUG - [Coordinator.sender]  at node: "..job.position.." #Coordinator.senderBuffer not > 0 : Nothing to send")
			end
		Coordinator.sender_msgs_lock:unlock()

		log:print(" DEBUG - [Coordinator.sender]  END")
end

Coordinator.ship=function(sender, v, timeout, allEventsToFire)

		log:print("[Coordinator.ship] - ship THREAD at node: "..job.position.." id: "..sender.id.." sending "..#v.msgs.." protocols")
		log:print(" DEBUG [Coordinator.ship] - testing variables at node: "..job.position.." received sender: "..tostring(sender))
		log:print(" DEBUG [Coordinator.ship] - testing variables at node: "..job.position.." received v: "..tostring(v))
		log:print(" DEBUG [Coordinator.ship] - testing variables at node: "..job.position.." received v.msgs: "..tostring(v.msgs))
		log:print(" DEBUG [Coordinator.ship] - testing variables at node: "..job.position.." received timeout: "..tostring(timeout))

		local ok = rpc.acall(v.dest[1].peer,{"Coordinator.passive_thread", "msgs",   sender, v.msgs}, timeOut)
	--local ok = rpc.acall(dst.peer      ,{"Coordinator.passive_thread", algoId, sender, buf}  , timeOut)
		if not ok then
			Coordinator.totalFailedMsgs=Coordinator.totalFailedMsgs+1
			log:print("[Coordinator.send] - COORDINATOR at node: "..job.position.." id: "..sender.id.." exchange with peer "..v.dest[1].id.." not completed, continuing.")
			log:print("[Coordinator.send] - COORDINATOR at node: "..job.position.." events to fire: "..#allEventsToFire)
			for k,ev in pairs(allEventsToFire) do
				log:print("[Coordinator.send] - COORDINATOR at node: "..job.position.." event: "..tostring(ev))
				events.fire(ev)
			end
		else
			Coordinator.totalOkMsgs=Coordinator.totalOkMsgs+1
			log:print("[Coordinator.ship] - ship THREAD received OK from RPC.ACALL() at node: "..job.position.." id: "..sender.id.." sending "..#v.msgs.." to "..v.dest[1].id)	
		end
		log:print("[Coordinator.send] - at node: "..job.position.." COORDINATOR at node: "..job.position.." id: "..sender.id.." TOTAL_OK_MSGS: "..Coordinator.totalOkMsgs.." TOTAL_FAILED_MSGS: "..Coordinator.totalFailedMsgs)
end

Coordinator.send=function(algoId, dst, buf, eventToFire, invokingProtocolID)
	-- This msg table will be like  this: sender_buffer={ {dest={peer1}, msgs={msg1, msg2}, type=1/2}  {dest={peer2}, msgs={msg3}, type=1/2 }  ... }
	-- msg1 = {"Coordinator.passive_thread", algoId1, sender, buf, eventToFire, timeout, dst} 
	-- msg2 = {"Coordinator.passive_thread", algoId1, sender, buf, eventToFire, timeout, dst}
	-- msg3 = {"Coordinator.passive_thread", algoId2, sender, buf, eventToFire, timeout, dst}
	-- peer1={ip = "127.0.0.1", port = 200}
	-- peer2={ip = "127.0.0.1", port = 300}
	-- peer3={ip = "127.0.0.1", port = 400}

		log:print(" DEBUG - [Coordinator.SEND] - at node: "..job.position.." - COORDINATOR SEND method invoked at node: "..job.position.." by protocol: "..invokingProtocolID)

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
				log:print(" DEBUG - [Coordinator.SEND] -  at node: "..job.position.." COORDINATOR SEND - Coordinator.piggybackMsg active")
				-- orginal msg: {"Coordinator.passive_thread", algoId, sender, buf} 
				-- added: {"Coordinator.passive_thread", algoId, sender, buf , eventToFire, timeout}
				log:print(" DEBUG - [Coordinator.SEND] -  at node: "..job.position.." preparing new msg ")
				newMsg = {"Coordinator.passive_thread", algoId, sender, buf, eventToFire, timeOut, dst} 

				log:print(" DEBUG - [Coordinator.SEND] -  at node: "..job.position.." getting lock()")
				Coordinator.sender_msgs_lock:lock()

					if #Coordinator.senderBuffer == 0 then
						log:print(" DEBUG - [Coordinator.SEND] -  at node: "..job.position.." COORDINATOR SEND -  #Coordinator.senderBuffer == 0 ")
						Coordinator.senderBuffer[#Coordinator.senderBuffer+1] = { dest={dst}, msgs={newMsg} }
						log:print(" DEBUG - [Coordinator.SEND] - at node: "..job.position.." adding newMSG dest.id: "..tostring(dst.id).." newMSG dest.ip: "..tostring(dst.peer.ip).." newMSG dest.port: "..tostring(dst.peer.port))
					else
						log:print(" DEBUG - [Coordinator.SEND] - at node: "..job.position.." COORDINATOR SEND -  #Coordinator.senderBuffer not equal 0 ")
						found = false
						for k,v in pairs(Coordinator.senderBuffer) do 
							if (v.dest[1]==dst) then 
								v.msgs[#v.msgs+1] = newMsg
								found = true
							end 
						end
						if not found then
							Coordinator.senderBuffer[#Coordinator.senderBuffer+1] = { dest={dst}, msgs={newMsg} }
							log:print(" DEBUG - [Coordinator.SEND] - at node: "..job.position.." adding newMSG dest.id: "..tostring(dst.id).." newMSG dest.ip: "..tostring(dst.peer.ip).." newMSG dest.port: "..tostring(dst.peer.port))
						end
						
					end
					log:print(" DEBUG - [Coordinator.SEND] - at node: "..job.position.." - COORDINATOR SEND - print Coordinator.senderBuffer: ")
					Coordinator.printSenderBuffer()
				Coordinator.sender_msgs_lock:unlock()  -- note: it seems to be too long this lock(), change to work with a copy to improve performance?
				log:print(" DEBUG - [Coordinator.SEND] -  at node: "..job.position.." getting unlock()")
				
			else
				log:print(" DEBUG - [Coordinator.SEND] -  at node: "..job.position.." COORDINATOR SEND - Coordinator.piggybackMsg NOT active at node: "..job.position)
				-- keep exaclty as before
				--local timeOut = math.ceil(algo.cycle_period/2)
				--local sender = {ip=algo.me.peer.ip, port=algo.me.peer.port, id=algo.me.id}
				log:print("[Coordinator.send] - at node: "..job.position.." COORDINATOR SEND at node: "..job.position.." id: "..sender.id.." at protocol: "..algoId.." ")
				local ok = rpc.acall(dst.peer,{"Coordinator.passive_thread", algoId, sender, buf}, timeOut)
				if not ok then
					Coordinator.totalFailedMsgs=Coordinator.totalFailedMsgs+1
					log:print("[Coordinator.send] - at node: "..job.position.." COORDINATOR at node: "..job.position.." id: "..sender.id.." exchange with peer "..dst.id.." not completed, continuing.")
					events.fire(eventToFire)
				else
					Coordinator.totalOkMsgs=Coordinator.totalOkMsgs+1
				end
			end	
		else
			log:print("[Coordinator.send] - at node: "..job.position.." COORDINATOR at node: "..job.position.." id: "..sender.id.." protocol "..algoId.." is not in the catalog")
		end
		
		log:print("[Coordinator.send] - at node: "..job.position.." COORDINATOR at node: "..job.position.." id: "..sender.id.." TOTAL_OK_MSGS: "..Coordinator.totalOkMsgs.." TOTAL_FAILED_MSGS: "..Coordinator.totalFailedMsgs)
		
end

Coordinator.printSenderBuffer = function()
	log:print(" DEBUG - [Coordinator.PRINTSENDERBUFFER] - at node: "..job.position.." printing invoked ")
	if #Coordinator.senderBuffer > 0 then
		log:print(" DEBUG - [Coordinator.PRINTSENDERBUFFER] - at node: "..job.position.." #Coordinator.senderBuffer= "..tostring(#Coordinator.senderBuffer) )
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
	-- aqui , o tipo !!!!  o type da msg tem que ficar no nivel das msgs e nao dos destinos
	
	--if Coordinator.piggybackMsg then
  --
	--	--newMsg = {"Coordinator.passive_thread", algoId, sender, buf, eventToFire, timeout, dst} 
	--	newMsg = {"Coordinator.dispatch", algoId, method, payload, srcId}
  --
	--	
	--	Coordinator.sender_msgs_lock:lock()
	--	
	--		if #Coordinator.senderBuffer == 0 then
	--			Coordinator.senderBuffer[#Coordinator.senderBuffer] = { dest={dst}, msgs={newMsg} , type=2 }
	--		else
	--			found = false
	--			for k,v in pairs(Coordinator.senderBuffer) do 
	--				if (v.dest[1]==dst.peer) then 
	--					v.msgs[#v.msgs+1] = newMsg
	--					found = true
	--				end 
	--			end
	--			if not found then
	--				Coordinator.senderBuffer[#Coordinator.senderBuffer] = { dest={dst.peer}, msgs={newMsg} , type=2 }
	--			end
	--		end
	--	
	--	Coordinator.sender_msgs_lock:unlock()  -- note: it seems to be too long this lock(), change to work with a copy to improve performance?
	--	
	--	
	--	
	--	
	--else
		-- keep as before
		log:print("[Coordinator.CALLALGOMETHOD] - COORDINATOR at node: "..job.position.." callAlgoMethod invoked from node: "..srcId.." for method: "..method.." of protocol: "..algoId.." at node: "..dst.id)
	  local ok = rpc.acall(dst, {"Coordinator.dispatch", algoId, method, payload, srcId}, 3)
	  if not ok then 
			log:print("[Coordinator.CALLALGOMETHOD] - COORDINATOR at node: "..job.position.." exchange with node "..dst.id.." did not complete, continuing") 
		end
		-- end
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
