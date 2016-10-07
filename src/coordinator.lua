-- #################### COORDINATOR ###################################
Coordinator={}
Coordinator.algos={}
Coordinator.senderBuffer={} 
Coordinator.piggybackMsg=false
Coordinator.senderPeriod=7
Coordinator.sender_msgs_lock = events.lock()
Coordinator.disseminationTTL = 5 

-- for evaluation only
Coordinator.totalOkMsgs=0
Coordinator.totalFailedMsgs=0

Coordinator.setPiggyBackMsgs = function(value)
	Coordinator.piggybackMsg=value
end

Coordinator.setDisseminationTTL = function(value)
	Coordinator.disseminationTTL = value
end


Coordinator.addProtocol=function(algo_id, algo_obj)
	local algo_seq = #Coordinator.algos+1
	algo_obj:setAlgoID(algo_id)   -- note: this method must be implemented by all 
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

Coordinator.launch = function(node, running_time, delay)

 	events.thread(function() events.sleep(running_time) os.exit() end)
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

Coordinator.passive_thread = function(algoId, from, buffer)

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
				algo:passive_thread(from, buffer)
			else
				log:print("[Coordinator.passive] - COORDINATOR PASSIVE THREAD at node: "..job.position.." cannot run the passive thread of protocol: "..algoId)
			end
		end
	else
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

Coordinator.sender = function()
	
		Coordinator.sender_msgs_lock:lock()
			if #Coordinator.senderBuffer > 0 then
				for k,v in pairs(Coordinator.senderBuffer) do 
					log:print("destination: "..tostring(v.dest[1].id).." "..tostring(v.dest[1].peer.ip).."/"..tostring(v.dest[1].peer.port)..": has ".. tostring(#v.msgs).." messages ")
					allEventsToFire = {}
					for g,h in pairs(v.msgs) do 
						allEventsToFire[#allEventsToFire+1] = h[5]
						timeout = h[6]
						sender = h[3]
					end
					events.thread(function() Coordinator.ship(sender, v, timeout, allEventsToFire) end)
				end 
				Coordinator.senderBuffer={} 
			else
			end
		Coordinator.sender_msgs_lock:unlock()
		
end

Coordinator.ship = function(sender, v, timeout, allEventsToFire)

		local ok = rpc.acall(v.dest[1].peer,{"Coordinator.passive_thread", "msgs",   sender, v.msgs}, timeOut)
		if not ok then
			Coordinator.totalFailedMsgs=Coordinator.totalFailedMsgs+1
			for k,ev in pairs(allEventsToFire) do
				events.fire(ev)
			end
		else
			Coordinator.totalOkMsgs=Coordinator.totalOkMsgs+1
		end
		
end

Coordinator.send = function(algoId, dst, buf, eventToFire, invokingProtocolID)

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
				newMsg = {"Coordinator.passive_thread", algoId, sender, buf, eventToFire, timeOut, dst} 

				Coordinator.sender_msgs_lock:lock()
					if #Coordinator.senderBuffer == 0 then
						Coordinator.senderBuffer[#Coordinator.senderBuffer+1] = { dest={dst}, msgs={newMsg} }
					else
						found = false
						for k,v in pairs(Coordinator.senderBuffer) do 
							if (v.dest[1]==dst) then 
								v.msgs[#v.msgs+1] = newMsg
								found = true
							end 
						end
						if not found then
							Coordinator.senderBuffer[#Coordinator.senderBuffer+1] = { dest={dst}, msgs={newMsg} }
						end
					end
					Coordinator.printSenderBuffer()
				Coordinator.sender_msgs_lock:unlock()  
			else
				log:print("[Coordinator.send] - at node: "..job.position.." COORDINATOR SEND at node: "..job.position.." id: "..sender.id.." at protocol: "..algoId.."  sending msg to "..dst.id)
				local ok = rpc.acall(dst.peer,{"Coordinator.passive_thread", algoId, sender, buf}, timeOut)
				if not ok then
					Coordinator.totalFailedMsgs=Coordinator.totalFailedMsgs+1
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

Coordinator.replaceDistFunctionAtLayer = function(algoId, newDistFunction, newExtraParameters)

	log:print("DEBUG : COORDINATOR at node: "..job.position.." [Coordinator.REPLACEDISTFUNCTIONATLAYER] - started for protocol: "..algoId)
	
	local algo = nil
	for k,v in pairs(Coordinator.algos) do 
		if v.id==algoId then
			algo = v.obj
		end
  end
	
	if algo then 
		log:print("DEBUG : [Coordinator.REPLACEDISTFUNCTIONATLAYER] at node: "..job.position.." protocol: "..algoId.." not nil:  invoking set_distance_function , set_distFunc_extraParams and floodDistFunc ")
		algo['set_distance_function'](algo, newDistFunction)
		algo['set_distFunc_extraParams'](algo, newExtraParameters)
		algo['floodDistFunc'](algo, newDistFunction, newExtraParameters, Coordinator.disseminationTTL)
	else 
		log:warning("DEBUG : [Coordinator.REPLACEDISTFUNCTIONATLAYER] - COORDINATOR at node: "..job.position.." No instance of algorithm "..algoId.." found") 
	end

end


Coordinator.setProtoDistFunction = function(algoId, newDistFunction, newExtraParameters)
	
	log:print("DEBUG : COORDINATOR at node: "..job.position.." [Coordinator.SETPROTODISTFUNCTION] - started for protocol: "..algoId)
	local algo = nil
	for k,v in pairs(Coordinator.algos) do 
		if v.id==algoId then
			algo = v.obj
		end
	end
	if algo then 
		log:print("DEBUG : [Coordinator.SETPROTODISTFUNCTION] at node: "..job.position.." protocol: "..algoId.." not nil:  invoking set_distance_function and set_distFunc_extraParams.")
		algo['set_distance_function'](algo, newDistFunction)
		algo['set_distFunc_extraParams'](algo, newExtraParameters)
	else 
		log:warning("DEBUG : [Coordinator.SETPROTODISTFUNCTION] - COORDINATOR at node: "..job.position.." No instance of algorithm "..algoId.." found") 
	end
	
end


Coordinator.bootstrap = function(node)
	
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
	
end
------------------------ END OF CLASS COORDINATOR --------------------------
