--#################### CLASS PSS  ###################################


local PSS = {}
PSS.__index = PSS 

--function PSS.new(c, h, s, fanout,cyclePeriod, selection, me)
function PSS.new(c, h, s, fanout,cyclePeriod, selection, me)
  local self = setmetatable({}, PSS)
  self.cycle_numb=0
  self.view={}
  self.view_copy={}
  self.c=c
  self.H=h
  --self.S=s
  self.S=math.floor(self.c/2+0.5)-1
  self.exch=fanout
  --self.exch=math.floor(c/2+0.5)
  self.view_copy_lock=events.lock()
	self.view_lock=events.lock()
  self.cycle_period=cyclePeriod
  self.SEL=selection
  self.me=me
  self.utils=Utilities.new(me)
  self.ongoing_rpc= false
  self.is_init = false
  self.totalknown = 0
  --self.algoId = algoId
  self.algoId=nil
  self.logDebug = false
  
  self.coordinator = coord
 
  self.protoName="PSS"
  
   -- auxiliary view , only for testing/debugging pss
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
	-- returns true and the key(position in the table) if id exists
	for k,v in pairs(t) do
		if v.id == id then 
			return true, k
		end 
	end
end


---------------------------------------------------i
function PSS.add_to_known_ids_set(self, node)
	-- this function is used only for testing the convergence

		for k,v in pairs(self.all_known_nodes) do
			if v == node.id then 
				return
			end 
		end
  
		self.all_known_nodes[#self.all_known_nodes+1] = node.id
 
	end


------------------------------------------
function PSS.get_logged_known_ids(self)
	--print("received set size: "..#set)
	res = ""
	for k, v in ipairs(self.all_known_nodes) do
		res = res..tostring(v).." "
	 end
   return "[ "..res.." ]"
end

---- ----------------------------------------------------
function PSS.pss_selectToSend(self, t_type, viewCopy)		
    
local currentMethod = "[("..t_type..") - PSS.pss_SELECTTOSEND() ] - "
--  		if self.logDebug then 
	--  	  	log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." PSS.pss_SELECTTOSEND() - STARTED.")
	--  	 		self.utils:print_this_view(currentMethod.."CURRENT PSS_VIEW: ", viewCopy, self.cycle_numb, self.algoId)
	--  		end
  		
	local toSend = {}
	-- insert own descriptor to "toSend" buffer =>  buffer = ((MyAddress,0)) from original algo.
	table.insert(toSend, self.me) 
  
	if #viewCopy > 0 then 
		-- shuffle (permute) the view => view.permute() from original algo  
		viewCopy = misc.shuffle(viewCopy)
		--			self.utils:print_this_view(currentMethod.." SHUFFLE PSS_VIEW: ", viewCopy, self.cycle_numb, self.algoId)

		-- make a copy 
		local tmp_view = misc.dup(viewCopy)
		--		self.utils:print_this_view(currentMethod.." COPIED PSS_VIEW to TEMP_VIEW: ", tmp_view, self.cycle_numb, self.algoId)
  			
		-- sort the tmp_view by age => move oldest H items to end of view 
		table.sort(tmp_view,function(a,b) return a.age < b.age end)
		--	self.utils:print_this_view(currentMethod.." TEMP_VIEW SORTED BY AGE: ", tmp_view, self.cycle_numb, self.algoId)

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
  		
	--if self.logDebug then
		--	self.utils:print_this_view(currentMethod.." VIEW (buffer) SELECTED to be SENT:", toSend, self.cycle_numb, self.algoId)
		--	self.utils:print_this_view(currentMethod.." PSS_VIEW after all SELECTTOSEND ", viewCopy, self.cycle_numb, self.algoId)	
		--	log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." PSS.pss_SELECTTOSEND() - END.")
		--end
		return toSend
	end
  ----------------------------------------------------
  function PSS.pss_selectToKeep(self, received, t_type)
  		
  		-- logs	
  	  local currentMethod = "[("..t_type..") -  PSS.pss_SELECTTOKEEP() ] - "
  	  
  	  --if self.logDebug then
  	  --	log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." PSS.pss_SELECTTOKEEP() - STARTED.")
  	  	--self.utils:print_this_view(currentMethod.."CURRENT PSS_VIEW: ", self.view, self.cycle_numb, self.algoId)
   	  	--self.utils:print_this_view(currentMethod.."PSS: [received VIEW - buffer] at SELECTTOKEEP ", received , self.cycle_numb, self.algoId)
				--end
   	  
  		--make a copy
  		local viewCopy = self.getViewCopy(self)
  		
  		--merge received and copy view
  		for j=1,#received do
  			viewCopy[#viewCopy+1] = received[j] 
  		end
  		
 -- 		if self.logDebug then
 -- 			self.utils:print_this_view(currentMethod.."PSS: after [merge VIEW + received VIEW] at SELECTTOKEEP ", viewCopy, self.cycle_numb, self.algoId)
 -- 		end
  	  
   	  -- ensures that the local node is not in the merged view.
  		self.remove_all_instances_of_me(viewCopy, self.me.id)
  		
  --	if self.logDebug then
  --		-- only for debugging
  --   	self.utils:print_this_view(currentMethod.."PSS: merged VIEW after [removed instances of me] at SELECTTOKEEP ", viewCopy , self.cycle_numb, self.algoId)
  --	end
  	
  		-- remove duplicates: let only the newest node if there are duplicates. Remove older ones.
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
  		
  		--	self.utils:print_this_view(currentMethod.."[PSS: VIEW merged after [DUPLICATES - OLDER AGE] at SELECTTOKEEP:", viewCopy, self.cycle_numb, self.algoId)
  
			-- the next 3 steps are well defined in the paper and used to guarantee the size of the view at most C
			if #viewCopy > self.c then
 			-- 1) remove old items from the view: the number of the nodes to remove is defined by min(H,#view-c) 
				local numberToRemove = math.min(self.H,#viewCopy-self.c)  
    	 	--	log:print(currentMethod.."[SELECTTOKEEP] : #viewCopy > self.c : it will remove the min (H="..self.H..",#viewCopy-c="..#viewCopy-self.c..")= "..numberToRemove.." OLDEST ITEMS from viewCopy")
  			viewCopy = self.remove_old_entries(self, numberToRemove, viewCopy)
    	 	--	self.utils:print_this_view(currentMethod.."[PSS: VIEW merged after [remove the min(H,#view-c) OLDEST ITEMS] at SELECTTOKEEP:", viewCopy,self.cycle_numb, self.algoId)
			end
			
  		if #viewCopy > self.c then 
  			--2)  remove the S first items from view: min(S,#view-c)
  			o = math.min(self.S,#viewCopy-self.c)
  			while o > 0 do
--  			  if self.logDebug then
--  			  	log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." REMOVING HEAD node: "..viewCopy[1].id.."("..viewCopy[1].age..")")
--   				end
  				table.remove(viewCopy,1)
  				o = o - 1
  			end
			end
  		
			-- 3) remove items at random: in the case there still are too many peers in the view 
  		if #viewCopy > self.c then 
				while #viewCopy > self.c do 
				local randnode_index = math.random(#viewCopy)
--  		log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." removing random node: "..viewCopy[randnode_index].id.."("..viewCopy[randnode_index].age..")")
  				table.remove(viewCopy,randnode_index) 
  			end
			end
  		
			assert (#viewCopy <= self.c, currentMethod.." [WARNING] at node: "..job.position.." id: "..self.me.id.." #viewCopy <= self.c")
  		
  		self.view_lock:lock()
  			self.view = viewCopy
  		self.view_lock:unlock()
  		
  		--if self.logDebug then
  		--	self.utils:print_this_view(currentMethod.."PSS_VIEW after all SELECTTOKEEP:", self.view, self.cycle_numb, self.algoId)	
  		--	log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." PSS.pss_SELECTTOKEEP() - END.")
  		--end
  end
---------------------------------------------------
function PSS.remove_old_entries(self, toRemove, viewCopy)
		-- toRemove is the number of nodes to be removed
		local currentMethod = "[PSS.REMOVE_OLD_ENTRIES] - "
		
		
		local diff = false

		-- first: checks if the view has elements in it, no operation is done if view is empty
		if #viewCopy>1 then 
			-- then: checks if elements in the view have different ages: if all have the same age, no 'old' node to be removed
			for i=1,#viewCopy-1 do
				if viewCopy[i].age ~= viewCopy[i+1].age then
		   		diff = true
				end
			end
			
			if diff then
				-- if there is an age difference: proceeds with the removal
					while toRemove > 0 do
						local oldest_index = -1
						local oldest_age = 0  -- oldest age should starts at 0 instead of -1
						for i=1,#viewCopy do -- traverses the view to find the index of the oldest node.
							if oldest_age < viewCopy[i].age then
								oldest_age = viewCopy[i].age
								oldest_index = i
							end
						end
						if  oldest_index > -1 then 
							if self.logDebug then
								log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." removing oldest node: "..viewCopy[oldest_index].id.."("..viewCopy[oldest_index].age..")")
							end
							table.remove(viewCopy,oldest_index)
						end
						toRemove = toRemove - 1
					end
			else
				-- if all nodes have the same age, just informe
				if self.logDebug then
					log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." NO NODES WITH DIFFERENT AGES WERE FOUND to remove the oldest nodes")
				end
			end
		else
			if self.logDebug then
				log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." RECEIVED  VIEW COPY SIZE IS ZERO - Nothing to remove")
			end
		end
		return viewCopy
		
end
----------------------------------------------------

function PSS.pss_send_at_rpc(self,peer,pos,buf)
		local ok, r = rpc.acall(peer,{"pss_passive_thread",pos, buf, self}, self.cycle_period/2)
		return ok, r
end
-----------------------------------------------------
function PSS.remove_all_instances_of_me(view, id)
	-- removes all instances of an id from the view without calling other functions.
	-- everything is done in this function. 
  local found = true
  local index, value = 0
  
	 
	while(found) do
			found = false
	   	local index = 0
			for key,value in pairs(view) do
			 	--print("key: "..key.." id value: "..value.id)
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
	-- PSS PASSIVE THREAD
----------------------------------------------------

function PSS.passive_thread(self, from, buffer)
	
	 local currentMethod = "[PSS.PASSIVE_THREAD] - "

		events.thread(function()
		
		local currentMethod = "[PSS.PASSIVE_THREAD] - "
		
		-- make a copy
		local viewCopy = self.getViewCopy(self)
		
		--if self.logDebug then
		  --log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." [PSS.PASSIVE_THREAD] - STARTED")
		  --self.utils:print_this_view("[PSS.PASSIVE_THREAD_START] - CURRENT PSS_VIEW: ", viewCopy, self.cycle_numb, self.algoId)
			--log:print("[PSS.PASSIVE_THREAD_RECEIVED] -  at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." - size of received VIEW (buffer): "..#buffer.." from "..from.id)
			self.utils:print_this_view("[PSS.PASSIVE_THREAD_RECEIVED] received VIEW (buffer) from "..from.id, buffer, self.cycle_numb, self.algoId)
			--end	
		
		-- select to send		
		local retView = self.pss_selectToSend(self, "PASSIVE_THREAD", viewCopy)
		--if self.logDebug then
		--	self.utils:print_this_view(currentMethod.." VIEW SELECTED TO RETURN (buffer): ", retView, self.cycle_numb, self.algoId)
		--end
		-- send a callback to the sender to invoke the method activeThreadSuccess() with the selected view 'retView' 
		Coordinator.callAlgoMethod(self.algoId, 'activeThreadSuccess', retView, from, self.me.id)
		-- for OO implementation:  self.coordinator:callAlgoMethod(self.algoId, 'activeThreadSuccess', retView, from, self.me.id)
		
		
		end)
		
	  -- select view to keep
		self.pss_selectToKeep(self,buffer, "PASSIVE_THREAD")
		
		-- increase the age of all nodes in the view and cycle number, NOTE: there are 2 versions of algorithms (one that increaments the age at passive threads and another that does not) in practice it seems to be a very bad idea since the age of nodes increase much faster. not doing it
		--self.view_lock:lock()
		--	for _,v in ipairs(self.view) do
		--		v.age = v.age+1
		--	end
		--self.view_lock:unlock()

		--self.utils:print_this_view("[PSS.PASSIVE_THREAD_END] - CURRENT PSS_VIEW after ALL PSS PASSIVE THREAD: ", self.view, self.cycle_numb, self.algoId)
		--if self.logDebug then
		--	log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." [PSS.PASSIVE_THREAD] - END")
		--end
		
end
----------------------------------------------------
	-- PSS ACTIVE THREAD
----------------------------------------------------
	
function PSS.active_thread(self)	


  	local currentMethod = "[PSS.ACTIVE_THREAD] - "
		self.view_lock:lock()
			self.cycle_numb = self.cycle_numb+1
		self.view_lock:unlock()
		
  	
  	--if self.logDebug then
 	  --	log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." [PSS.ACTIVE_THREAD] - STARTED")
			--self.utils:print_this_view("[PSS.ACTIVE_THREAD_START] - CURRENT PSS_VIEW: ", self.view, self.cycle_numb, self.algoId)
			--end
		
		local viewCopy = self.getViewCopy(self)

		local retry = true
		local exchange_retry=3

		-- select a neighbour to send (part of) its view : view.selectPeer() method from original algo
		local partner_ind = self.pss_selectPartner(self, viewCopy)
		if not partner_ind then
				log:warning(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." : no partner selected (PSS_VIEW is empty?)")
			--	if self.logDebug then
			--		log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." [PSS.ACTIVE_THREAD] - END")
			--	end
				return
		end	
		local partner = viewCopy[partner_ind]
		--if self.logDebug then
		--	log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." selected node to exchange: "..partner.id)
		--end
		--table.remove(viewCopy, partner_ind)
		
	  -- select buffer to send: select view elements to send	
		local buffer = self.pss_selectToSend(self, "ACTIVE_THREAD", viewCopy)

		--if self.logDebug then
		--	log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." sending buffer to node: "..partner.id)
		--end
		
		Coordinator.send(self.algoId, partner, buffer, 'CompleteActive')
		-- for OO Implementation:  self.coordinator:send(self.algoId, partner, buffer, 'CompleteActive')
		
		events.wait('CompleteActive')
		
		-- waits for a CompleteActive event to be fired from activeThreadSuccess() method which is invoked when whe response from the passive thread arrives at the coordinator. 
		
		-- make a copy of the current view: this copy is used by method getPeer() offered by the PSS API to other protocols
		self.view_copy = self.getViewCopy(self)

	  --if self.logDebug then
    --	self.utils:print_this_view(currentMethod.."SELF.VIEW_COPY_PSS: ", self.view_copy, self.cycle_numb, self.algoId)	
		--end

			-- increase the age of all nodes in the view and cycle number
		self.view_lock:lock()
			for _,v in ipairs(self.view) do
				v.age = v.age+1
			end
			-- print view	
			--self.cycle_numb = self.cycle_numb+1
			self.utils:print_this_view("[PSS.ACTIVE_THREAD_END] - CURRENT PSS_VIEW: ", self.view, self.cycle_numb, self.algoId)	
		self.view_lock:unlock()

		
		--if self.logDebug then
		--	log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." [PSS.ACTIVE_THREAD] - END")
		--end

end

----------------------------------------------------

function PSS.activeThreadSuccess(self, received)
	
	local currentMethod = "[PSS.ACTIVETHREADSUCCESS] - "
	
	--if self.logDebug then
  --	log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." [PSS.ACTIVETHREADSUCCESS] - STARTED")
	--end
	
	self.pss_selectToKeep(self, received, "ACTIVE_THREAD")
	--if self.logDebug then
  --	log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." [PSS.ACTIVETHREADSUCCESS] - fire CompleteActive and end")
	--end
  events.fire('CompleteActive')
end
	
----------------------------------------------------
function PSS.getViewCopy(self)
	
	local currentMethod = "[PSS.getViewCopy] - "

	self.view_lock:lock()
	local copy = misc.dup(self.view)
	self.view_lock:unlock()
 -- if self.logDebug then
 -- 	self.utils:print_this_view(currentMethod.."GET_VIEW_COPY_PSS: ", copy, self.cycle_numb, self.algoId)	
 --	end
	return copy

end
----------------------------------------------------
	
function PSS.getViewSnapshot(self)
		
		local currentMethod = "[PSS.GETVIEWSNAPSHOT] - "
	  --if self.logDebug then
    --	self.utils:print_this_view(currentMethod.."VIEW_COPY_PSS: ", self.view_copy, self.cycle_numb, self.algoId)	
		--end
		return self.view_copy
		
	end
----------------------------------------------------


function PSS.getPeer(self)
		
		local currentMethod = "[PSS.GETPEER] - "
		local viewCopy = self.getViewCopy(self)
		
		self.utils:print_this_view("[PSS.GETPEER]] - CURRENT PSS_VIEW: ", self.view, self.cycle_numb, self.algoId)	
		
		local peer=nil
		
		if #viewCopy ~= 0 then 
			--if self.logDebug then
			--	log:print(currentMethod.."PSS - VIEW COPY SIZE: "..#viewCopy)
			--end
			peer = viewCopy[math.random(#viewCopy)] 
			--if self.logDebug then
			--	log:print(currentMethod.."PSS - GOT PEER: "..peer.id)
			--end
		else
			 --if self.logDebug then
			 --	log:print(currentMethod.."PSS - VIEW COPY size = ZERO: ")
			 --end
		   peer = nil
		end
		
	  if self.logDebug then
    	self.utils:print_this_view(currentMethod.."PSS - returning VIEW_COPY_PSS: ", viewCopy, self.cycle_numb, self.algoId)	
		end

		return peer
		
end

----------------------------------------------------

-- function PSS.init(self, selected_indexes)
-- 	
-- 	local currentMethod = "[PSS.INIT]"
-- 		
-- 		if #selected_indexes < self.c then
-- 	   log:warning(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." - ERROR: number of available/selected nodes is lower than the size of the selected PSS view - Stopping")
-- 			
-- 			os.exit()
-- 		end
-- 		for i,v in pairs(selected_indexes) do
-- 			  log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." - setting selected index "..v.." to PSS_VIEW")
-- 				local a_peer = job.get_live_nodes()[v]
-- 				local index = v
-- 				log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." INIT-PSS index: "..index.." ip: "..a_peer.ip.." port: "..a_peer.port)
-- 		 		-- now setting node objects to the view
-- 		 		local newnode = Node.new(a_peer)
-- 
-- 		 		--local computedID = self.me:compute_ID(self.me:getIDExpo(), newnode:getPeer().ip , newnode:getPeer().port)
-- 		 		local computedID = nil
-- 				if self.me:get_computeID_function() == nil then 
-- 					log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." self.me:get_computeID_function == nil using index") 
-- 					computedID = index
-- 				else
-- 					--log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." self.me:get_computeID_function not nil calling func") 
-- 					log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." newnode:getPeer().ip "..newnode:getPeer().ip.." newnode:getPeer().port"..newnode:getPeer().port) 
-- 					computedID = self.me:computeID_function(newnode:getPeer().ip , newnode:getPeer().port)
-- 					log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." computed id: "..computedID) 
-- 				end
-- 				newnode:setID(computedID)
-- 				log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." - adding new node "..newnode:getID().." ip=("..newnode:getPeer().ip..") port=("..newnode:getPeer().port..")")
-- 		 		self.view[#self.view+1] = newnode 
-- 		end
-- 		-- sort view by id
-- 		--table.sort(self.view,function(a,b) return a.id < b.id end)
-- 		self.view_copy_lock:lock()
-- 			self.view_copy = misc.dup(self.view)
-- 		  if self.logDebug then
-- 	    	self.utils:print_this_view(currentMethod.."COPY_VIEW_PSS: ", self.view_copy, self.cycle_numb, self.algoId)	
-- 			end
-- 		self.view_copy_lock:unlock()
-- 		assert (#self.view == math.min(self.c,#selected_indexes))
-- 		self.utils:print_this_view("[PSS.INIT] - VIEW_INITIALIZED:", self.view, self.cycle_numb, self.algoId)
-- 		self.is_init=true
-- 
-- end
function PSS.init(self, peerToBoot)
	
	local currentMethod = "[PSS.INIT] - "
	--log:print(currentMethod.." at node: "..job.position.." - START ")


  if not peerToBoot then return end
	
  self.view[#self.view + 1] = peerToBoot
	
  local try = 0
  while events.yield() do
    if rpc.ping(peerToBoot.peer, 3) then break end
    try = try + 1
		--log:print(currentMethod.." at node: "..job.position.." - node "..peerToBoot.id.." is not available to bootstrap, trying again. Try num: "..try)
    events.sleep(2)
  end
	self.utils:print_this_view(currentMethod.."CURRENT PSS_VIEW(INIT_VIEW): ", self.view, self.cycle_numb, self.algoId)	
	--log:print(currentMethod.." at node: "..job.position.." - INIT END")
  events.periodic(self.cycle_period, function() self.active_thread(self) end)
	
end

-- -----------------------------------------------------------------------


------------------------ END OF CLASS PSS ----------------------------
