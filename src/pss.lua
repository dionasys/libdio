--#################### CLASS PSS  ###################################

local PSS = {}
PSS.__index = PSS 


function PSS.new(c, h, s, fanout,cyclePeriod, selection, me)
  local self = setmetatable({}, PSS)
  self.cycle_numb=0
  self.view={}
  self.view_copy={}
  self.c=c
  self.H=h
  self.S=math.floor(self.c/2+0.5)-1
  self.exch=fanout
  self.view_copy_lock=events.lock()
	self.view_lock=events.lock()
  self.cycle_period=cyclePeriod
  self.SEL=selection
  self.me=me
  self.utils=Utilities.new(me)
  self.ongoing_rpc= false
  self.is_init = false
  self.totalknown = 0
  self.algoId=nil
  self.logDebug = false
  self.coordinator = coord
  self.protoName="PSS"
  self.all_known_nodes={}
  return self
end

----------------------------------------------------
function PSS.getViewSize(self) return self.c end
function PSS.getCyclePeriod(self)  return self.cycle_period end
function PSS.getProtocolClassName(self) return self.protoName end
function PSS.setLog(self, flag) self.logDebug = flag end
function PSS.setAlgoID(self, algoId) self.algoId = algoId end
function PSS.getAlgoID(self) return self.algoId end
function PSS.getNode(self) return self.me end
function PSS.getNodeID(self) return self.me:getID() end
function PSS.get_id(self) return self.me.id end
----------------------------------------------------

function PSS.pss_selectPartner(self, viewCopy)
	
	if #viewCopy > 0 then
		if self.SEL == "rand" then 
			local selected = math.random(#viewCopy) 
			return selected 
		end
		if self.SEL == "tail" then
			local tail_ind = -1
			local biggerAge = -1
			
			for i,p in pairs(viewCopy) do
				if (p.age > biggerAge) then 
					biggerAge=p.age
					tail_ind = i
				end
			end
			assert (not (tail_ind == -1))
			return tail_ind
		end
		if self.SEL == "head" then
			local smallAge = 999
			local head_ind = -1
			for i, p in pairs(viewCopy) do
				if p.age < smallAge then
					smallAge = p.age
					head_ind = i
				end
			end
			assert (not (head_ind == -1))
			return head_ind
		end
	else
		return false
	end
end

----------------------------------------------------
function PSS.same_peer(self,a,b)
	local condition=a.peer.ip == b.peer.ip and a.peer.port == b.peer.port
	return condition and a.age == b.age
end
----------------------------------------------------
function PSS.contains_id(t,id) 
	for k,v in pairs(t) do
		if v.id == id then 
			return true, k
		end 
	end
end
---------------------------------------------------i
function PSS.add_to_known_ids_set(self, node)
	
		for k,v in pairs(self.all_known_nodes) do
			if v == node.id then 
				return
			end 
		end
		self.all_known_nodes[#self.all_known_nodes+1] = node.id
end
------------------------------------------
function PSS.get_logged_known_ids(self)

	res = ""
	for k, v in ipairs(self.all_known_nodes) do
		res = res..tostring(v).." "
	 end
   return "[ "..res.." ]"
end

---- ----------------------------------------------------
function PSS.pss_selectToSend(self, t_type, viewCopy)		

	local currentMethod = "[("..t_type..") - PSS.pss_SELECTTOSEND() ] - "
	local toSend = {}
	table.insert(toSend, self.me) 
	if #viewCopy > 0 then 
		viewCopy = misc.shuffle(viewCopy)
		local tmp_view = misc.dup(viewCopy)
		table.sort(tmp_view,function(a,b) return a.age < b.age end)
		if #tmp_view-self.H+1 > 0 then 
			for i=(#tmp_view-self.H+1),#tmp_view do
				local ind = -1
				for j=1,#viewCopy do
					if self.same_peer(self, tmp_view[i],viewCopy[j]) then 
						ind=j; 
						break 
					end
				end
				assert (not (ind == -1))
				elem = table.remove(viewCopy,ind)  
				viewCopy[#viewCopy+1] = elem
			end	
		end
		for i=1,(self.exch-1) do
			toSend[#toSend+1]=viewCopy[i]
		end
	end
	return toSend
end
  ----------------------------------------------------
  function PSS.pss_selectToKeep(self, received, t_type)

		local currentMethod = "[("..t_type..") -  PSS.pss_SELECTTOKEEP() ] - "
		local viewCopy = self.getViewCopy(self)
		for j=1,#received do
			viewCopy[#viewCopy+1] = received[j] 
		end
		self.remove_all_instances_of_me(viewCopy, self.me.id)
		local i = 1
		local condition=false
		while i < #viewCopy do  
			for j=i+1,#viewCopy do
				condition=viewCopy[i].peer.ip == viewCopy[j].peer.ip and viewCopy[i].peer.port == viewCopy[j].peer.port
				if condition then	 -- same_peer_but_different_ages
					if viewCopy[i].age < viewCopy[j].age then 
						table.remove(viewCopy,j) -- delete the oldest
					else
						table.remove(viewCopy,i)
					end
					i = i - 1 
					break
				end
			end
			i = i + 1
		end
		if #viewCopy > self.c then
			local numberToRemove = math.min(self.H,#viewCopy-self.c)  
			viewCopy = self.remove_old_entries(self, numberToRemove, viewCopy)
		end

		if #viewCopy > self.c then 
			o = math.min(self.S,#viewCopy-self.c)
			while o > 0 do
				table.remove(viewCopy,1)
				o = o - 1
			end
		end
		if #viewCopy > self.c then 
			while #viewCopy > self.c do 
				local randnode_index = math.random(#viewCopy)
				table.remove(viewCopy,randnode_index) 
			end
		end

		assert (#viewCopy <= self.c, currentMethod.." [WARNING] at node: "..job.position.." id: "..self.me.id.." #viewCopy <= self.c")
		self.view_lock:lock()
			self.view = viewCopy
		self.view_lock:unlock()

	end
---------------------------------------------------
function PSS.remove_old_entries(self, toRemove, viewCopy)

		local diff = false
		if #viewCopy>1 then 
			for i=1,#viewCopy-1 do
				if viewCopy[i].age ~= viewCopy[i+1].age then
		   		diff = true
				end
			end
			if diff then
					while toRemove > 0 do
						local oldest_index = -1
						local oldest_age = 0 
						for i=1,#viewCopy do 
							if oldest_age < viewCopy[i].age then
								oldest_age = viewCopy[i].age
								oldest_index = i
							end
						end
						if  oldest_index > -1 then 
							table.remove(viewCopy,oldest_index)
						end
						toRemove = toRemove - 1
					end
			end
		end
		return viewCopy
		
end
----------------------------------------------------
function PSS.pss_send_at_rpc(self,peer,pos,buf)
		local ok, r = rpc.acall(peer,{"pss_passive_thread",pos, buf, self}, self.cycle_period/2)
		return ok, r
end
----------------------------------------------------
function PSS.remove_all_instances_of_me(view, id)
	
	local found = true
	local index, value = 0
	while(found) do
		found = false
		local index = 0
		for key,value in pairs(view) do
			if value.id == id then 
				found = true
				index = key
				break
			end 
		end
		if(index>0) then
			table.remove(view, index)
		end
	end
end
----------------------------------------------------
function PSS.passive_thread(self, from, buffer)

		events.thread(function()
			local viewCopy = self.getViewCopy(self)
			self.utils:print_this_view("[PSS.PASSIVE_THREAD_RECEIVED] received VIEW (buffer) from "..from.id, buffer, self.cycle_numb, self.algoId)
			local retView = self.pss_selectToSend(self, "PASSIVE_THREAD", viewCopy)
			Coordinator.callAlgoMethod(self.algoId, 'activeThreadSuccess', retView, from, self.me.id)
		end)
		self.pss_selectToKeep(self,buffer, "PASSIVE_THREAD")
end
----------------------------------------------------
function PSS.active_thread(self)	

	local currentMethod = "[PSS.ACTIVE_THREAD] - "
		self.view_lock:lock()
			self.cycle_numb = self.cycle_numb+1
		self.view_lock:unlock()
		local viewCopy = self.getViewCopy(self)
		local retry = true
		local exchange_retry=3
		local partner_ind = self.pss_selectPartner(self, viewCopy)
		if not partner_ind then
				log:warning(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." : no partner selected (PSS_VIEW is empty?)")
				return
		end	
		local partner = viewCopy[partner_ind]
		local buffer = self.pss_selectToSend(self, "ACTIVE_THREAD", viewCopy)
		Coordinator.send(self.algoId, partner, buffer, 'CompleteActive',  self.algoId)

		events.wait('CompleteActive')
		self.view_copy = self.getViewCopy(self)
		self.view_lock:lock()
			for _,v in ipairs(self.view) do
				v.age = v.age+1
			end
			self.utils:print_this_view("[PSS.ACTIVE_THREAD_END] - CURRENT PSS_VIEW: ", self.view, self.cycle_numb, self.algoId)	
		self.view_lock:unlock()

end
----------------------------------------------------
function PSS.activeThreadSuccess(self, received)

	self.pss_selectToKeep(self, received, "ACTIVE_THREAD")
	events.fire('CompleteActive')
end
----------------------------------------------------
function PSS.getViewCopy(self)

	self.view_lock:lock()
	local copy = misc.dup(self.view)
	self.view_lock:unlock()
	return copy

end
----------------------------------------------------
function PSS.getViewSnapshot(self)

		return self.view_copy
		
	end
----------------------------------------------------
function PSS.getPeer(self)
		
		local viewCopy = self.getViewCopy(self)
		self.utils:print_this_view("[PSS.GETPEER]] - CURRENT PSS_VIEW: ", self.view, self.cycle_numb, self.algoId)	
		local peer=nil
		if #viewCopy ~= 0 then 
			peer = viewCopy[math.random(#viewCopy)] 
		else
			peer = nil
		end
		return peer
end
----------------------------------------------------
function PSS.init(self, peerToBoot)
	
	local currentMethod = "[PSS.INIT] - "
	if not peerToBoot then 
		log:warning("Didnt received peerBoot")
		return 
	end
	self.view[#self.view + 1] = peerToBoot
	local try = 0
	while events.yield() do
		if rpc.ping(peerToBoot.peer, 3) then break end
		try = try + 1
		events.sleep(2)
	end
	self.utils:print_this_view(currentMethod.."CURRENT PSS_VIEW(INIT_VIEW): ", self.view, self.cycle_numb, self.algoId)	
	events.periodic(self.cycle_period, function() self.active_thread(self) end)
end
------------------------ END OF CLASS PSS ----------------------------
