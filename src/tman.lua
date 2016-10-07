-- #################### CLASS TMAN ###################################
local TMAN ={}
TMAN.__index = TMAN

function TMAN.new(me, size, cycle_period, base_procotols, active_b_proto)
	
	local self = setmetatable({}, TMAN)
	self.utils=Utilities.new(me)
	self.t_view = {}  
	self.t_last_view = {}
	self.t_last_view_as_string = ""
	self.view_stable_info = false
	self.view_stable_counter = 0
	self.t_view_lock = events.lock()
	self.ongoing_rpc = false
	self.is_init = false
	self.cycle_numb = 0
	self.rank_func = nil
	self.rank_extra_params=nil
	self.rank_func_hash = nil
	self.last1_rank_func_hash = nil
	self.last2_rank_func_hash = nil
	self.last1_rank_extra_params = nil
	self.last2_rank_extra_params = nil
	self.rank_func_lock = events.lock()
	self.rank_extra_params_lock = events.lock()
	self.me=me	
	self.s = size
	self.cycle_period = cycle_period
	self.algos={}
	self.b_protocol = {}
	self.b_active = active_b_proto
	self.coordinator=coord

	for i,v in pairs(base_procotols) do
		self.b_protocol[i] = v   
	end
	
	self.logDebug = false
	self.protoName="TMAN"
	self.algoId = nil
	return self

end
----------------------------------------------------
function TMAN.compute_hash(o) return string.sub(crypto.evp.new("sha1"):digest(o), 1, 32) end
function TMAN.getView(self) return self.t_view end
function TMAN.getViewSize(self) return self.s end
function TMAN.getCyclePeriod(self) return self.cycle_period end
function TMAN.getProtocolClassName(self) return self.protoName end
function TMAN.setLog(self, flag)  self.logDebug = flag  end
function TMAN.setAlgoID(self, algoId) self.algoId = algoId end
function TMAN.getAlgoID(self) return self.algoId end
function TMAN.getNodeID(self) return self.me:getID() end
function TMAN.getNode(self) return self.me end
----------------------------------------------------
function TMAN.select_peer(self, viewCopy) 
		
		local currentMethod = "[TMAN.SELECT_PEER] - "
		local ranked_view = self.rank_view(self, viewCopy)
		if (ranked_view and #ranked_view >0) then
			return ranked_view[1]
		else
			return false
		end
end
----------------------------------------------------	
function TMAN.init(self, bootstrapNode
	
		local currentMethod = "[TMAN.INIT] - "
		local active_algo_base = nil
		for k,v in pairs(self.b_protocol) do
			if v:getAlgoID()==self.b_active then
				active_algo_base = v
			end
		end
		local peer = nil
		local bootView = {}
		while #bootView < self.s do
			peer = active_algo_base:getPeer()
			if peer ~= nil then
				if #bootView  == 0 then
					bootView[#bootView+1] = peer
					self.is_init = true
				else
					local found = false
					for k,v in ipairs(bootView) do
						if v.peer.ip == peer.peer.ip  and v.peer.port == peer.peer.port then
							found = true
						end
					end
					if not found then
						bootView[#bootView+1] = peer
					end
				end
			else
				if self.logDebug then
					log:warning(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." getPeer() returned node IS NULL, will try again.")
				end
			end
			events.sleep(3)
		end
		self.t_view_lock:lock()
			self.t_view = bootView
			self.utils:print_this_view("[TMAN.INIT_INI_FROM_PSS] - CURRENT TMAN_VIEW:", self.t_view, self.cycle_numb, self.algoId)
		self.t_view_lock:unlock()
		events.periodic(self.cycle_period, function() self.active_thread(self) end)

end

	
----------------------------------------------------
function TMAN.select_view_to_send(self, selected_peer, viewCopy)
		
		local currentMethod = "[TMAN.SELECT_VIEW_TO_SEND] - "
		local active_algo = nil
		for k,v in pairs(self.b_protocol) do
			if v:getAlgoID()==self.b_active then
				active_algo = v
			end
		end
		local bufferPSS = active_algo:getViewCopy()
		
		self.utils:print_this_view(currentMethod.." TMAN_VIEW_GOT_FROM_PSS: ", bufferPSS, self.cycle_numb, self.algoId)
		local merged =  misc.merge(viewCopy, bufferPSS)
		merged[#merged+1] = self.me
		self.remove_dup(self,merged)
		self.remove_node(self,merged, selected_peer)
		return merged	
		
end
	
----------------------------------------------------
function TMAN.update_view_to_keep(self, received)
		
		local currentMethod = "[TMAN.UPDATE_VIEW_TO_KEEP] - "
		local viewCopy = self.getTViewCopy(self)
		viewCopy = misc.merge(received, viewCopy)
		self.remove_dup(self, viewCopy)
		viewCopy = self.rank_view(self, viewCopy)
		self.keep_first_n(self, self.s, viewCopy)
		table.sort(viewCopy, function(a,b) return a.id < b.id end)
		self.t_view_lock:lock()
			self.t_view = viewCopy
		self.t_view_lock:unlock()
		
end
----------------------------------------------------
function TMAN.same_view(self, v1,v2)
	
		if type(v1) == "table" and  type(v2) == "table" then
			if #v1 == #v2 then
				for i=1,#v1 do
					if v1[i].id ~= v2[i].id then
						return false
					end
				end
				return true
			else
				return false
			end
		end	
		
end
	
----------------------------------------------------
function TMAN.same_ids_view(self, v1,v2)

		if type(v1) ~= "table" then
			return e1 == e2
		elseif type(v2) == "table" then
				for i=1,#v1 do
					local found = false
						for y=1,#v2 do
							if v1[i].id == v2[y].id then
								found = true
							end
						end
						if found==false then
							return "false"
						end	
				end
			return "true"
		end	
		
end
----------------------------------------------------
function TMAN.same_id(self, n1,n2)
	
		local peer_first
		if n1.peer then 
			peer_first = n1.peer 
		else 
			peer_first = n1 
		end
		local peer_second
		if n2.peer then 
			peer_second = n2.peer 
		else 
			peer_second = n2 
		end
		return peer_first.id == peer_second.id 

end
	
----------------------------------------------------
function TMAN.keep_first_n(self, n, set)
		for i = #set, n+1, -1 do
			table.remove(set,i)
		end
end
----------------------------------------------------
function TMAN.set_distance_function(self, f)
	-- Note: the rationale of using a last1 and last2 is to control the dissemination of distance functions avoiding unwanted replacements 
		self.rank_func_lock:lock()
			if self.rank_func_hash == nil and self.last1_rank_func_hash == nil  and self.last2_rank_func_hash == nil then 
				local initialHash = self.compute_hash(string.dump(f))
				self.rank_func = f
				self.rank_func_hash = initialHash
				self.last1_rank_func_hash = initialHash
				self.last2_rank_func_hash = initialHash
			else
				local receivedFuncHash = self.compute_hash(string.dump(f))
				if receivedFuncHash ~= self.rank_func_hash and receivedFuncHash ~= self.last1_rank_func_hash and receivedFuncHash ~= self.last2_rank_func_hash then
					self.last2_rank_func_hash = self.last1_rank_func_hash
					self.last2_rank_func_hash = self.rank_func_hash 
					self.rank_func_hash = receivedFuncHash
					self.rank_func = f 
				end
			end
		self.rank_func_lock:unlock()

end
----------------------------------------------------
function TMAN.get_distance_function(self)
		return self.rank_func
end
----------------------------------------------------
function TMAN.set_distFunc_extraParams(self, args)
		
		self.rank_extra_params_lock:lock()
			if self.rank_extra_params == nil and self.last1_rank_extra_params == nil  and self.last2_rank_extra_params == nil then 
				self.rank_extra_params = args
			else
				if not misc.equal(args, self.rank_extra_params) and not misc.equal(args, self.last1_rank_extra_params) and not misc.equal(args, self.last2_rank_extra_params) then
					self.last2_rank_extra_params = self.last1_rank_extra_params
					self.last1_rank_extra_params= self.rank_extra_params 
					self.rank_func_hash = receivedFuncHash
					self.rank_extra_params = args 
				end
			end
		self.rank_extra_params_lock:unlock()
end
----------------------------------------------------
function TMAN.get_distFunc_extraParams(self)
		return self.rank_extra_params 
end
----------------------------------------------------
function TMAN.dist_function(self, p1, p2)
	
	  if self==nil then
	    log:warning("at node: "..job.position.." id: "..self.me.id.." self dist_function nil: ")
	  end
		
		dist = self.rank_func(self, p1, p2)
		return dist
		
end
----------------------------------------------------
function TMAN.rank_view(self, viewCopy)
	
		local currentMethod = "[TMAN.RANK_VIEW] - "
		local distances = {}
		local ranked = {}
		local mypayload = self.get_payload(self, self.me)
		local res =""
		for i=1, #mypayload do
			res = res..mypayload[i]..", " 
		end
		for i,v in ipairs(viewCopy) do
			local nb_payload =  self.get_payload(self, v)
			res = ""
			for i=1, #nb_payload do
				res = res..nb_payload[i]..", "
			end
			local dist = self.dist_function(self, mypayload, nb_payload)
			distances[#distances+1] = {distance= dist, node=v}
		end
		table.sort(distances, function(a,b) return a.distance < b.distance end)
		local	ret=""
		local cumul_distance=0
		for i,v in ipairs(distances) do
			ret = ret.." "..v.node.id.." : ["..v.distance.."] "	
			cumul_distance = cumul_distance+v.distance
		end
		for i,v in ipairs(distances) do
			ranked[#ranked+1] = v.node
		end
		return ranked
end
----------------------------------------------------
function TMAN.get_payload(self, node)

		local payl = {}
		if type(node) == "table" then 
			payl = node.payload 
		else 
			payl = node 
		end
		return payl
end
----------------------------------------------------
function TMAN.remove_failed_node(self, node)
		self.t_view_lock:lock()
		self.remove_node(self, self.t_view, node)
		self.t_view_lock:unlock()
end
----------------------------------------------------
function TMAN.remove_node(self, t, node)
		local j = 1
		for i = 1, #t do
			if  t[j].id==node then
				table.remove(t, j)
			else j = j+1 
			end
		end
end
----------------------------------------------------
function TMAN.same_node(self, n1,n2)
		local peer_first
		if n1.peer then 
			peer_first = n1.peer 
		else 
			peer_first = n1 
		end
		local peer_second
		if n2.peer then 
			peer_second = n2.peer 
			else 
			peer_second = n2 
		end
		return peer_first.port == peer_second.port and peer_first.ip == peer_second.ip
end
----------------------------------------------------
function TMAN.remove_dup(self, set)
	
		for i,v in ipairs(set) do
			local j = i+1
			while(j <= #set and #set > 0) do
				if v.id == set[j].id then
					table.remove(set,j)
				else j = j + 1
				end
			end
		end
end
----------------------------------------------------
function TMAN.getTViewCopy(self)

	self.t_view_lock:lock()
		local copy = misc.dup(self.t_view)
	self.t_view_lock:unlock()
	return copy
end
---------------------------------------------------- 
function TMAN.activeTMANThreadSuccess(self, received)

		if received[2] ~= nil then
			local curFunction = assert(loadstring(received[2]))
			self.set_distance_function(self, curFunction)
		end
		if received[3] ~= nil then
			self.set_distFunc_extraParams(self, received[3])
		end
		self.update_view_to_keep(self, received[1])  
			events.fire('CompleteTMANActive')
end
	
---------------------------------------------------- 
function TMAN.active_thread(self)
	
		local currentMethod = "[TMAN.ACTIVE_THREAD] - "
		self.t_view_lock:lock()
			self.cycle_numb = self.cycle_numb+1
		self.t_view_lock:unlock()
		local viewCopy = self.getTViewCopy(self)
		local selected_peer = self.select_peer(self, viewCopy) 
		if not selected_peer and self.logDebug then 
			log:warning(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." TMAN active_thread: no selected_peer chosen") 
			return 
		end
		local buffer = self.select_view_to_send(self, selected_peer.id, viewCopy)
		local funcToSend = string.dump(self.get_distance_function(self))		
		local funcPar =  self.get_distFunc_extraParams(self)
		if funcToSend ~= nil and funcPar ~= nil then
			buffer_function = {buffer, funcToSend , funcPar}
		end
		if buffer_function == nil  then
			log:print(currentMethod.." node: "..job.position.." active thread - buffer_function is nil")
		else 
			Coordinator.send(self.algoId, selected_peer, buffer_function,'CompleteTMANActive', self.algoId)
		end
		events.wait('CompleteTMANActive')
		self.t_view_lock:lock()
			self.utils:print_this_view("[TMAN.ACTIVE_THREAD_END] - CURRENT TMAN_VIEW: ", self.t_view, self.cycle_numb, self.algoId)
		self.t_view_lock:unlock()
end
----------------------------------------------------
function TMAN.passive_thread(self, sender, received)
	
	events.thread(function()
		local currentMethod = "[TMAN.PASSIVE_THREAD] - "
		local viewCopy = self.getTViewCopy(self)
		local buffer_to_send = self.select_view_to_send(self, sender, viewCopy)
		local adapt_buffer_function_to_send = {}
		if received[2] ~= nil then
			local curFunction = assert(loadstring(received[2]))
			self.set_distance_function(self, curFunction)
		end
		if received[3] ~= nil then
			self.set_distFunc_extraParams(self, received[3])
		end
		local funcToSend = string.dump(self.get_distance_function(self))
		local funcPar =  self.get_distFunc_extraParams(self)
		if funcToSend == nil or funcPar == nil then
			log:print(currentMethod.." node: "..job.position.." passive thread - funcToSend or funcPar are nil")
		else 
			adapt_buffer_function_to_send = {buffer_to_send, funcToSend , funcPar}
			Coordinator.callAlgoMethod(self.algoId, 'activeTMANThreadSuccess', adapt_buffer_function_to_send, sender, self.me.id)
		end
	end)

	self.update_view_to_keep(self, received[1])
end
----------------------------------------------------
function TMAN.set_node_representation(self, node_rep)
		self.me.payload= node_rep
		local pl_string = ""
		for i=1, #self.me.payload do
			pl_string = pl_string.." "..node_rep[i]
		end
end
----------------------------------------------------
function TMAN.removeDead(received)
			local ret = {}
			for k,v in ipairs(received) do
						local latency = rpc.ping(v.peer, 2)
						if latency then
							ret[#ret+1] = v
						else 
							table.remove(self.t_view, v)
					end
			end
			return ret
end
		----------------------------------------------------
function TMAN.floodForwardDistFunc(self, forwardingPayload)

			local dst = nil 
			disseminationPayload = { forwardingPayload[1], forwardingPayload[2] , (forwardingPayload[3])-1}
			local viewCopy = self.getTViewCopy(self)
			for k,v in ipairs(viewCopy) do
					dst = {ip=v.peer.ip, port=v.peer.port, id=v.id}
					Coordinator.callAlgoMethod(self.algoId, 'handleDistFuncFlood', disseminationPayload, dst , self.me.id)
			end
end
	
----------------------------------------------------
function TMAN.handleDistFuncFlood(self, receivedPayload)

		if receivedPayload[1] ~= nil then
			local receivedFunction = assert(loadstring(receivedPayload[1]))
			self.set_distance_function(self, receivedFunction)
		end
		if receivedPayload[2] ~= nil then
			self.set_distFunc_extraParams(self, receivedPayload[2])
		end
		if receivedPayload[3] ~= nil and receivedPayload[3] > 0 then
			self.floodForwardDistFunc(self, receivedPayload)
		end

end
	----------------------------------------------------
function TMAN.floodDistFunc(self, distFunc, extraParam, ttl)
	
		local currentMethod = "[TMAN.FLOODDISTFUNC] - "
		local dst = nil 
		local funcToDissem = string.dump(distFunc)
		local disseminationPayload = {}
		if distFunc == nil or extraParam == nil then
			log:print(currentMethod.." node: "..job.position.." floodDistFunc - currentFunc or funcExtraParameters are nil")
		else 
			disseminationPayload = {funcToDissem, extraParam , ttl}
			local viewCopy = self.getTViewCopy(self)
			for k,v in ipairs(viewCopy) do
				dst = {ip=v.peer.ip, port=v.peer.port, id=v.id}
				Coordinator.callAlgoMethod(self.algoId, 'handleDistFuncFlood', disseminationPayload, dst , self.me.id)
			end
		end
end
------------------------ END OF CLASS TMAN ----------------------------

