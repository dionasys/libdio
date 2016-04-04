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
  self.logDebug = true
 
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

function PSS.getNodeID(self) return self.me:getID() end

----------------------------------------------------

function PSS.pss_selectPartner(self)

		if self.logDebug then 
			local currentMethod = "[PSS.pss_SELECTPARTNER() ] - "
			log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." PSS.pss_SELECTPARTNER() - STARTED. method: "..self.SEL)
		end
		
		if #self.view > 0 then
			
			if self.SEL == "rand" then 
				local selected = math.random(#self.view) 
			
				return selected 
			end
			
			if self.SEL == "tail" then
				local tail_ind = -1
				local biggerAge = -1
				
				for i,p in pairs(self.view) do
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
         for i, p in pairs(self.view) do
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
--function PSS.same_peer_but_different_ages(self, a, b)	  
--  return a.peer.ip == b.peer.ip and a.peer.port == b.peer.port
--end

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
 
-- if #self.all_known_nodes == 0 then 
--		self.all_known_nodes[1] = node.id
--		return
-- end

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

----------------------------------------------------
function PSS.pss_selectToSend(self, t_type)		
  
	   
		local currentMethod = "[("..t_type..") - PSS.pss_SELECTTOSEND() ] - "
		if self.logDebug then 
	  	log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." PSS.pss_SELECTTOSEND() - STARTED.")
	 		self.utils:print_this_view(currentMethod.."CURRENT PSS_VIEW: ", self.view, self.cycle_numb, self.algoId)
		end
		
		local toSend = {}
		-- insert own descriptor to "toSend" buffer =>  buffer = ((MyAddress,0)) from original algo.
		--self.me:setAge(0)
		table.insert(toSend, self.me) 

		--log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." ANTES " ) 
		if self.logDebug then
			self.utils:print_this_view(currentMethod.." add own descriptor to toSend buffer: ", toSend, self.cycle_numb, self.algoId)
		end
		--log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." DEPOIS " ) 
		
		if #self.view > 0 then 
			-- shuffle (permute) the view => view.permute() from original algo  
			self.view = misc.shuffle(self.view)
			if self.logDebug then
				self.utils:print_this_view(currentMethod.." SHUFFLE PSS_VIEW: ", self.view, self.cycle_numb, self.algoId)
			end
			
			-- make a copy 
			local tmp_view = misc.dup(self.view)
			
			if self.logDebug then
				self.utils:print_this_view(currentMethod.." COPIED PSS_VIEW to TEMP_VIEW: ", tmp_view, self.cycle_numb, self.algoId)
			end
			
			-- sort the tmp_view by age => move oldest H items to end of view 
			table.sort(tmp_view,function(a,b) return a.age < b.age end)
			if self.logDebug then
				self.utils:print_this_view(currentMethod.." TEMP_VIEW SORTED BY AGE: ", tmp_view, self.cycle_numb, self.algoId)
			end
			
			if #tmp_view-self.H+1 > 0 then 
				--TODO: check this step again. for big valeus of H may fail
				for i=(#tmp_view-self.H+1),#tmp_view do
					local ind = -1
					for j=1,#self.view do
						if self.same_peer(self, tmp_view[i],self.view[j]) then 
							ind=j; 
							break 
						end
					end
					assert (not (ind == -1))
					elem = table.remove(self.view,ind)  
					self.view[#self.view+1] = elem
				end	
			end
			
			for i=1,(self.exch-1) do
				toSend[#toSend+1]=self.view[i]
			end
		end
		
		if self.logDebug then
    	self.utils:print_this_view(currentMethod.." VIEW (buffer) SELECTED to be SENT:", toSend, self.cycle_numb, self.algoId)
    	self.utils:print_this_view(currentMethod.." PSS_VIEW after all SELECTTOSEND ", self.view, self.cycle_numb, self.algoId)	
    	log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." PSS.pss_SELECTTOSEND() - END.")
    end
		return toSend
	end
----------------------------------------------------
	function PSS.pss_selectToKeep(self, received, t_type)
		
		-- logs	
	  local currentMethod = "[("..t_type..") -  PSS.pss_SELECTTOKEEP() ] - "
	  
	  if self.logDebug then
	  	log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." PSS.pss_SELECTTOKEEP() - STARTED.")
	  	self.utils:print_this_view(currentMethod.."CURRENT PSS_VIEW: ", self.view, self.cycle_numb, self.algoId)
 	  	self.utils:print_this_view(currentMethod.."PSS: [received VIEW - buffer] at SELECTTOKEEP ", received, self.cycle_numb, self.algoId)
 	  end
 	  
		--merge received and local view
		for j=1,#received do
			self.view[#self.view+1] = received[j] 
		end
		
		if self.logDebug then
			-- only for debugging
			self.utils:print_this_view(currentMethod.."PSS: after [merge VIEW + received VIEW] at SELECTTOKEEP ", self.view, self.cycle_numb, self.algoId)
		end
 	  
 	  -- ensures that the local node is not in the merged view.
		self.remove_all_instances_of_me(self.view, self.me.id)
		
		if self.logDebug then
			-- only for debugging
    	self.utils:print_this_view(currentMethod.."PSS: merged VIEW after [removed instances of me] at SELECTTOKEEP ", self.view, self.cycle_numb, self.algoId)
		end
		
		-- remove duplicates: let only the newest node if there are duplicates. Remove older ones.
		local i = 1
		local condition=false
		while i < #self.view do  
			for j=i+1,#self.view do
			  --log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." view size: "..#self.view.." i: "..i.." j: "..j)
					condition=self.view[i].peer.ip == self.view[j].peer.ip and self.view[i].peer.port == self.view[j].peer.port
				--if self.same_peer_but_different_ages(self.view[i], self.view[j]) then
				if condition then
				
					if self.logDebug then
						log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." EQUAL nodes found in the view, view#: "..#self.view.." i: "..i.." j: "..j)
     	  	  --log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." self.view[i].id="..self.view[i].id)
     			  --log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." self.view[i].peer.ip="..self.view[i].peer.ip)
 	      	  --log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." self.view[i].peer.port="..self.view[i].peer.port)
   	    	  --log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." self.view[i].age="..self.view[i].age)
    	  	  --log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." self.view[j].id="..self.view[j].id)
    	  	  --log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." self.view[j].peer.ip="..self.view[j].peer.ip)
    	  	  --log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." self.view[j].peer.port="..self.view[j].peer.port)
     	  	  --log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." self.view[j].age="..self.view[j].age)
     			  --log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." COMPARING AGES")
					end
				
					if self.view[i].age < self.view[j].age then 
						log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." self.view[i].age < self.view[j].age ")
						table.remove(self.view,j) -- delete the oldest
				  else
				  	--log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." self.view[i].age > or = self.view[j].age ")
						table.remove(self.view,i)
				  end
					i = i - 1 
					break
				end
			end
			i = i + 1
		end
		
		if self.logDebug then
			-- only for debugging
			self.utils:print_this_view(currentMethod.."[PSS: VIEW merged after [DUPLICATES - OLDER AGE] at SELECTTOKEEP:", self.view, self.cycle_numb, self.algoId)
		end

		-- remove old items from the view: the number of the nodes to remove is defined by min(H,#view-c) 
		local o = math.min(self.H,#self.view-self.c)
		if self.logDebug then
			-- only for debugging
   		log:print(currentMethod.."[SELECTTOKEEP] : will remove the min (H="..self.H..",#view-c="..#self.view-self.c..")= "..o.." OLDEST ITEMS")
		end
		
		local diff = false
		if #self.view>1 then
			-- first checks if elements have different ages
			for i=1,#self.view-1 do
				if self.view[i].age ~= self.view[i+1].age then
		   		diff = true
				end
			end
			-- if so proceeds with the removal
			if diff then
					while o > 0 do
						local oldest_index = -1
						local oldest_age = 0  -- oldest age starts at 0 instead of -1
						for i=1,#self.view do 
							if oldest_age < self.view[i].age then
								oldest_age = self.view[i].age
								oldest_index = i
							end
						end
						if  oldest_index > -1 then 
							if self.logDebug then
								log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." removing oldest node: "..self.view[oldest_index].id.."("..self.view[oldest_index].age..")")
							end
							table.remove(self.view,oldest_index)
						end
						o = o - 1
					end
			else
			    if self.logDebug then
			   	  log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." NO NODES WITH DIFFERENT AGES WERE FOUND to remove the oldest nodes")
			   	end
			end
			
		end

		if self.logDebug then
			-- only for debugging
   		self.utils:print_this_view(currentMethod.."[PSS: VIEW merged after [remove the min(H,#view-c) OLDEST ITEMS] at SELECTTOKEEP:", self.view, self.cycle_numb, self.algoId)
		end
		
		-- remove the head items from view: min(S,#view-c)
		o = math.min(self.S,#self.view-self.c)
		while o > 0 do
		  if self.logDebug then
		  	log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." REMOVING HEAD node: "..self.view[1].id.."("..self.view[1].age..")")
 			end
			table.remove(self.view,1) -- not optimal
			o = o - 1
		end
		
		-- remove items at random: in the case there still are too many peers in the view 
		while #self.view > self.c do 
		  if self.logDebug then 
		  	log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." PSS_VIEW size: "..#self.view)
		  end
		  local randnode_index = math.random(#self.view)
		  if self.logDebug then
		  	log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." removing random node: "..self.view[randnode_index].id.."("..self.view[randnode_index].age..")")
		  end
			table.remove(self.view,randnode_index) 
		end

		assert (#self.view <= self.c, currentMethod.." [WARNING] at node: "..job.position.." id: "..self.me.id.." #self.view <= self.c")
		
		if self.logDebug then
			self.utils:print_this_view(currentMethod.."PSS_VIEW after all SELECTTOKEEP:", self.view, self.cycle_numb, self.algoId)	
			log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." PSS.pss_SELECTTOKEEP() - END.")
		end
	end

----------------------------------------------------
	function PSS.pss_send_at_rpc(self,peer,pos,buf)
	  log:print("Cycle / 2 "..self.cycle_period)
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
	 			--print("value found at: "..index)	 		
				--print("current table size: "..#view) 	
				table.remove(view, index)
		 		--print("index removed")
		 		--print("table size now: "..#view)	
				--print_view(view)
			end
	end
end
----------------------------------------------------
	-- PSS PASSIVE THREAD
----------------------------------------------------

	function PSS.passive_thread(self, from, buffer)
	-- TODO maybe consider a queue for passive threads ? to received the requests. 
	--test with locks
		--self.view_lock:lock()
		
		local currentMethod = "[PSS.PASSIVE_THREAD] - "
		if self.logDebug then
		  log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." invoked from: "..from.." [PSS.PASSIVE_THREAD] - STARTED")
		  self.utils:print_this_view(currentMethod.." CURRENT PSS_VIEW: ", self.view, self.cycle_numb, self.algoId)
		end	
		
		if not self.is_init then
			log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." pss.is_init is false: ignoring request invoked from: "..from.." [PSS.PASSIVE_THREAD] - END")
			return false
		end
		
		if self.ongoing_rpc then
					log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." self.ongoing_rpc is true: ignoring request invoked from: "..from.." [PSS.PASSIVE_THREAD] - END")
					return false
	  end
	  
	  if self.logDebug then
			log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." - size of received VIEW (buffer): "..#buffer.." from "..from)
			self.utils:print_this_view(currentMethod.." received VIEW (buffer) from "..from, buffer, self.cycle_numb, self.algoId)
		end
		
		-- select to send		
		local ret = self.pss_selectToSend(self, "PASSIVE_THREAD")
		if self.logDebug then
			self.utils:print_this_view(currentMethod.." VIEW SELECTED TO RETURN (buffer): ", ret, self.cycle_numb, self.algoId)
		end
		
	  -- select to keep
		self.pss_selectToKeep(self,buffer, "PASSIVE_THREAD")
		

		-- increase the age of all nodes in the view
		--for _,v in ipairs(self.view) do
		--		v.age = v.age+1
		--end
		
		self.utils:print_this_view(currentMethod.." CURRENT PSS_VIEW after ALL PSS PASSIVE THREAD: ", self.view, self.cycle_numb, self.algoId)
		if self.logDebug then
			log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." [PSS.PASSIVE_THREAD] - END")
		end
		
		-- self.view_lock:unlock()
		return ret
	end
----------------------------------------------------
	-- PSS ACTIVE THREAD
----------------------------------------------------
	
	function PSS.active_thread(self)	
		-- test with lock	
	 -- self.view_lock:lock()
	 self.ongoing_rpc=true
  	local currentMethod = "[PSS.ACTIVE_THREAD] - "
  	
  	if self.logDebug then
 	  	log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." [PSS.ACTIVE_THREAD] - STARTED")
			self.utils:print_this_view(currentMethod.."CURRENT PSS_VIEW: ", self.view, self.cycle_numb, self.algoId)
		end
		

		if not self.is_init then
			log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." PSS.IS_INIT is false: [PSS.ACTIVE_THREAD] - END")
			--self.view_lock:unlock()
			return false
		end
		

		

		--local exchange_aborted=true
		local retry = true
		local exchange_retry=3
			
		-- select a neighbour to send (part of) its view : view.selectPeer() method from original algo
		local partner_ind = self.pss_selectPartner(self)
		
		if not partner_ind then
				log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." : no partner selected (PSS_VIEW is empty?)")
				if self.logDebug then
					log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." [PSS.ACTIVE_THREAD] - END")
				end
				return
		end	
		local partner = self.view[partner_ind]
		
		if self.logDebug then
			log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." selected node to exchange: "..partner.id)
		end
		
	  -- select buffer to send: select view elements to send	
		--local buffer = self.pss_selectToSend(self, "ACTIVE_THREAD")

			local buffer = self.pss_selectToSend(self, "ACTIVE_THREAD")

		-- try to exchange with selected
		for i=1,exchange_retry do
    	
			if self.logDebug then
				log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." sending buffer to node: "..partner.id.." at try#: "..i)
			end
			
			local ok, r = Coordinator.send(self.algoId, partner, buffer)
		
			if ok then
				if self.logDebug then
					log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." received - ok==true - from REMOTE node: "..partner.id)
				end
				local received = r[1]
				if received==false then
				  local w_delay = math.random(0.5, self.cycle_period * 0.5)
				  if self.logDebug then
  					log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." - received - false from REMOTE node: "..partner.id.." wating "..w_delay.." to retry again." )
  				end
					events.sleep(w_delay)	
					
				else
					retry=false
					if self.logDebug then
						log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." - received buffer from REMOTE node: "..partner.id.." invoking SELECTTOKEEP().")
					end
						self.pss_selectToKeep(self, received, "ACTIVE_THREAD")
				end
				
			else
				if i==3 then 
					log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." after "..exchange_retry.." failed retrials")
			  		--log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." after "..exchange_retry.." failed retrials, removing " ..partner.id.." from the view") 				
						--table.remove(self.view,partner_ind)
				else
				  local w_delay = math.random(0.5, self.cycle_period * 0.5)
				  if self.logDebug then
  					log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." - received [ok==false] , RPC error (".. r..") from REMOTE node: "..partner.id.." wating "..w_delay.." to retry again." )
  				end
					events.sleep(w_delay)
				end
			end		
			
			--if exchange_aborted==false then 
			if retry==false then
					if self.logDebug then
   				log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." - retry==false : breaking the loop at retry#: "..i)
   				end
					break 
			end
			
		end
		
		-- sort view by id
		-- table.sort(self.view,function(a,b) return a.id < b.id end)
		
		-- make a copy of the current view: this copy is used by method getPeer() which is the method offered by the PSS API to other protocols to access the view. 
		-- e.g., getPeer is the method used by TMAN to get PSS' view
		self.view_copy_lock:lock()
			self.view_copy = misc.dup(self.view)
		self.view_copy_lock:unlock()
	  if self.logDebug then
    	self.utils:print_this_view(currentMethod.."COPY_VIEW_PSS: ", self.view_copy, self.cycle_numb, self.algoId)	
		end

		
		if self.logDebug then
			log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." - increasing the age of all nodes in PSS_VIEW")
		end
		
		-- increase the age of all nodes in the view
		for _,v in ipairs(self.view) do
				v.age = v.age+1
		end
		

	  -- debug: 	
	  if self.logDebug then
    	self.utils:print_this_view(currentMethod.."CURRENT PSS_VIEW: ", self.view, self.cycle_numb, self.algoId)	
		end
		------------------------------------------------------------------------------------	
		-- TEST DEBUG: adds IDs of known nodes to a global set/table called all_known_nodes
		--for _,v in pairs(self.view) do
		--  self.add_to_known_ids_set(self, v)  
		--end
		
		--TODO: remove it later: this is for debugging only. 
		--if self.logDebug then
		--	log:print("[PSS.active_thread] - PSS_VIEW CONVERGENCE at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." all_known_nodes size: "..#self.all_known_nodes)
		--end
		------------------------------------------------------------------------------------
		
    -- print view	
    self.utils:print_this_view(currentMethod.."CURRENT PSS_VIEW: ", self.view, self.cycle_numb, self.algoId)	
	
		if self.logDebug then
			log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." [PSS.ACTIVE_THREAD] - END")
    end
    -- increase cycle number
		self.cycle_numb = self.cycle_numb+1
		-- allow incoming passive threads
		self.ongoing_rpc = false	
		
		--self.view_lock:unlock()
			
	end
	
----------------------------------------------------

	function PSS.getPeer(self)
		
		local currentMethod = "[PSS.GETPEER] - "
		
		self.view_copy_lock:lock()
		local peer=nil
		if #self.view_copy ~= 0 then 
			if self.logDebug then
			log:print("[PSS.getPeer] - VIEW COPY SIZE: "..#self.view_copy)
			end
			peer = self.view_copy[math.random(#self.view_copy)] 
			if self.logDebug then
			log:print("[PSS.GETPEER] - GOT PEER: "..peer.id)
			end
		else
			 if self.logDebug then
			 	log:print("[PSS.GETPEER] - VIEW COPY size = ZERO: ")
			 end
		   peer = nil
		end
		
	  if self.logDebug then
    	self.utils:print_this_view(currentMethod.."VIEW_COPY_PSS: ", self.view_copy, self.cycle_numb, self.algoId)	
		end
	
		self.view_copy_lock:unlock()
		
	  
		
		return peer
		
	end
----------------------------------------------------
	
	function PSS.getViewSnapshot(self)
		
		local currentMethod = "[PSS.GETVIEWSNAPSHOT] - "
	  if self.logDebug then
    	self.utils:print_this_view(currentMethod.."VIEW_COPY_PSS: ", self.view_copy, self.cycle_numb, self.algoId)	
		end
		return self.view_copy
		
	end
----------------------------------------------------

	function PSS.init(self, selected_indexes)
	
	local currentMethod = "[PSS.INIT]"
	
		--for i=1,#selected_indexes do
		--	log:print("PSS INIT: at ("..job.position..") selected index: "..selected_indexes[i])
		--end	
		
		if #selected_indexes < self.c then
	   log:warning(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." - ERROR: number of available/selected nodes is lower than the size of the selected PSS view - Stopping")
	  
			
			os.exit()
		end
		for i,v in pairs(selected_indexes) do
			  log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." - setting selected index "..v.." to PSS_VIEW")
				local a_peer = job.get_live_nodes()[v]
				local index = v
				log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." INIT-PSS index: "..index.." ip: "..a_peer.ip.." port: "..a_peer.port)
		 		-- now setting node objects to the view
		 		local newnode = Node.new(a_peer)

		 		--local computedID = self.me:compute_ID(self.me:getIDExpo(), newnode:getPeer().ip , newnode:getPeer().port)
		 		local computedID = nil
				if self.me:get_computeID_function() == nil then 
					log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." self.me:get_computeID_function == nil using index") 
					computedID = index
				else
					--log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." self.me:get_computeID_function not nil calling func") 
					log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." newnode:getPeer().ip "..newnode:getPeer().ip.." newnode:getPeer().port"..newnode:getPeer().port) 
					computedID = self.me:computeID_function(newnode:getPeer().ip , newnode:getPeer().port)
					log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." computed id: "..computedID) 
				end
				
				
				newnode:setID(computedID)
	
				log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." - adding new node "..newnode:getID().." ip=("..newnode:getPeer().ip..") port=("..newnode:getPeer().port..")")
		 		self.view[#self.view+1] = newnode 
		 		
		end
		
		
		-- sort view by id
		--table.sort(self.view,function(a,b) return a.id < b.id end)
		self.view_copy_lock:lock()
			self.view_copy = misc.dup(self.view)
		  if self.logDebug then
	    	self.utils:print_this_view(currentMethod.."COPY_VIEW_PSS: ", self.view_copy, self.cycle_numb, self.algoId)	
			end
		self.view_copy_lock:unlock()
	 
		
		assert (#self.view == math.min(self.c,#selected_indexes))
		
		self.utils:print_this_view("[PSS.INIT] - VIEW_INITIALIZED:", self.view, self.cycle_numb, self.algoId)
		self.is_init=true
		

	end
------------------------------------------------------------------------
function PSS.getRemotePayload(self, dst)

	 
    local currentMethod = "[PSS.INIT.GETREMOTEPAYLOAD] - "
    local received_payload = {}
    
    if(dst==nil) then
    else
         log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." DST NOT NILL" )
    end
    log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." trying to update data from node id: "..tostring(dst.ip)) 
                 
		local ok, r = rpc.acall(dst,{tostring(self.algoId..".getLocalPayload"), me})
		if ok then
				log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." received - ok==true - from REMOTE node: "..tostring(dst.ip))
			
				local received_pl = r[1]
				if received_pl==false then
  				log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." - received_pl [false] from REMOTE node: "..tostring(dst.ip))
				else
					log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." - received_pl [payload buffer] from REMOTE node: "..tostring(dst.ip))
					received_payload = received_pl
				end
		else
			  log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." received [ok==false] from REMOTE node: "..tostring(dst.ip))	 
		end
		return received_payload
end	
------------------------------------------------------------------------
function PSS.getLocalPayload(self, from)
 	  -- this method may be useless - check used to test the bootstrap but may be remove later. 
    local currentMethod = "[PSS.GETPAYLOAD] - "
    log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." invoked from: "..tostring(from.id))
		return self.me.payload
end
------------------------------------------------------------------------
function PSS.get_id(self)
  return self.me.id
end




------------------------ END OF CLASS PSS ----------------------------
