-- #################### CLASS TMAN ###################################

local TMAN ={}
TMAN.__index = TMAN


--function TMAN.new(me, size, cycle_period, base_procotols, active_b_proto, algoId)
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
	self.rank_extra_params={}
	
  self.me=me	
	self.s = size
	self.cycle_period = cycle_period
	self.algos={}
	self.b_protocol = {}
	self.b_active = active_b_proto
 
  for i,v in pairs(base_procotols) do
		self.b_protocol[i] = v   
  end
  self.logDebug = false
  self.protoName="TMAN"
	--self.algoId = algoId
	self.algoId = nil
  return self
end
----------------------------------------------------
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
			
		--local ranked_view = self.rank_view(self, self.me, self.t_view)
		local ranked_view = self.rank_view(self, viewCopy)
		
		if (ranked_view and #ranked_view >0) then
		  if self.logDebug then
				log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." node selected: "..ranked_view[1].id)  	
		  end
			return ranked_view[1]
		else
			return false
		end
	end
----------------------------------------------------	
	

	function TMAN.init(self, bootstrapNode)

		local currentMethod = "[TMAN.INIT] - "
		-- look for active algo 
		local active_algo_base = nil
		for k,v in pairs(self.b_protocol) do
				if v:getAlgoID()==self.b_active then
				   active_algo_base = v
				end
		end

		local peer = nil
		local bootView = {}
		
		--while #bootView < 2 do
		while #bootView < self.s do
			
			--log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." bootView size : "..#bootView )
			peer = active_algo_base:getPeer()
			if peer ~= nil then
			--	if self.logDebug then
				log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." getPeer() returned node: "..peer.id)
			--	end
				
				if #bootView  == 0 then
					--log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." view_contains found view.size == 0 adding node: "..peer.id)
					bootView[#bootView+1] = peer
					self.is_init = true
				else
					--log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." view_contains found view.size != 0  ")
					local found = false
					for k,v in ipairs(bootView) do
						if v.peer.ip == peer.peer.ip  and v.peer.port == peer.peer.port then
							found = true
						end
					end
				  
					if not found then
						bootView[#bootView+1] = peer
						--self.is_init = true
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

			--log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." END")
		-- start periodic thread
		events.periodic(self.cycle_period, function() self.active_thread(self) end)
	end

	
----------------------------------------------------
	function TMAN.select_view_to_send(self, selected_peer, viewCopy)
		
		local currentMethod = "[TMAN.SELECT_VIEW_TO_SEND] - "
		
		--if self.logDebug then
		--	log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." STARTED")
		--end
		
	  -- look for active algo 
		local active_algo = nil
		for k,v in pairs(self.b_protocol) do
				if v:getAlgoID()==self.b_active then
				   active_algo = v
				end
		end
		--if self.logDebug then
		--	log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." active base protocol id: "..self.b_active.." is : "..tostring(active_algo))
		--end

	  
		-- make a copy of the PSS
		local bufferPSS = active_algo:getViewCopy()
		
		self.utils:print_this_view(currentMethod.." TMAN_VIEW_GOT_FROM_PSS: ", bufferPSS, self.cycle_numb, self.algoId)
		
		-- self.removeDead(buffer)
		
		-- merges tman and pss view
		local merged =  misc.merge(viewCopy, bufferPSS)
		--if self.logDebug then
		--	self.utils:print_this_view(currentMethod.."CURRENT TMAN_VIEW:", viewCopy, self.cycle_numb, self.algoId)
		--	self.utils:print_this_view(currentMethod.." TMAN_PSS_MERGED_BUFFER_VIEW: ", merged, self.cycle_numb, self.algoId)
		--end
		
		-- add myself to the merged buffer
		merged[#merged+1] = self.me
		--if self.logDebug then
		--	self.utils:print_this_view(currentMethod.." TMAN_PSS_MERGED_BUFFER_VIEW: ", merged, self.cycle_numb, self.algoId)
		--end
		
		-- remove duplicates and the destination from the buffer
		self.remove_dup(self,merged)
		--if self.logDebug then
		--	self.utils:print_this_view(currentMethod.." TMAN_PSS_MERGED_BUFFER_VIEW_REMOVED_DUP: ", merged, self.cycle_numb, self.algoId)
		--end
		
		-- remove destination from merged view
		self.remove_node(self,merged, selected_peer)
		--if self.logDebug then
		--	self.utils:print_this_view(currentMethod.." TMAN_PSS_MERGED_BUFFER_VIEW_REMOVED_DEST: ", merged, self.cycle_numb, self.algoId)
		--end
		
		--if self.logDebug then
		--	log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." ENDED")
		--end
		return merged	
	end
	
----------------------------------------------------
	function TMAN.update_view_to_keep(self, received)
		
		local currentMethod = "[TMAN.UPDATE_VIEW_TO_KEEP] - "
		
		--if self.logDebug then
		--	log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." STARTED")
		--	self.utils:print_this_view(currentMethod.." - received view: ", received, self.cycle_numb, self.algoId)
		--end
		
		local viewCopy = self.getTViewCopy(self)
		
		viewCopy = misc.merge(received, viewCopy)
		
		--if self.logDebug then
		--	self.utils:print_this_view(currentMethod.." - MERGED received and local view: ", viewCopy , self.cycle_numb, self.algoId)
		--end

		self.remove_dup(self, viewCopy)
		viewCopy = self.rank_view(self, viewCopy)
		
		self.keep_first_n(self, self.s, viewCopy)
		-- keep view sorted by id after rank - useful for later checks
		table.sort(viewCopy, function(a,b) return a.id < b.id end)
		
		--self.check_view_stability(self)
		
		self.t_view_lock:lock()
			self.t_view = viewCopy
		self.t_view_lock:unlock()
		
		--if self.logDebug then
		--	log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." ENDED")
		--end
		
	end
----------------------------------------------------
	function TMAN.check_view_stability(self)
	
		local tmp_t_view = {}
		
		log:print("TMAN stable check")

		if #self.t_last_view == 0 then
			 log:print("TEST : last view is empty, #TMAN.t_last_view: "..#self.t_last_view)
			 self.t_last_view = self.t_view
			 
			 log:print("TEST : last view is empty, #TMAN.t_last_view: "..job.position.." : "..self.me.id.." #TMAN.t_last_view == 0 ")
		else

			if self.same_view(self, self.t_last_view, self.t_view)==true then
				 self.view_stable_counter = self.view_stable_counter +1
				 log:print("TEST :TMAN at ("..job.position..") "..self.me.id.." equal views")
				
				   
			else
				 log:print("TEST :TMAN at ("..job.position..") "..self.me.id.." NOT equal views ")
				
				 self.t_last_view = self.t_view
				 self.view_stable_counter = 0
				 self.view_stable_info=false
								 
			end
			log:print("TMAN TEST : counter at ("..job.position..") "..self.me.id.." is: "..self.view_stable_counter.." total cycles: "..self.cycle_numb)
		end
		--TODO change the stable condition here.
		if self.view_stable_counter>10 and self.view_stable_info==false then
			log:print("TEST VIEW stable true (>10 cycles) at node: "..job.position.." id: "..self.me.id.." after "..self.cycle_numb.." cycles")
			self.view_stable_info=true


		end	 
	end
----------------------------------------------------
	function TMAN.same_view(self, v1,v2)
		-- in this case v1 and v2 must be previously ordered by id
		--TODO refactoring: send it to Utilities
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
		--TODO refactoring: send it to Utilities
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
			--TODO refactoring: send it to Utilities
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
	--TODO refactoring: send it to Utilities
		for i = #set, n+1, -1 do
			table.remove(set,i)
		end
	end
----------------------------------------------------
	function TMAN.set_distance_function(self, f)
		self.rank_func = f
	end
----------------------------------------------------
	function TMAN.set_distance_function(self, f, args)
	 	self.rank_extra_params = args
		self.rank_func = f
	end
	
----------------------------------------------------
	function TMAN.set_distFunc_extraParams(self, args)
	
	  if self==nil then
	    log:warning("at node: "..job.position.." id: "..self.me.id.." self nil")
			--else
	   --log:print("at node: "..job.position.." id: "..self.me.id.." self not nil")
	    --log:print("at node: "..job.position.." id: "..self.me.id.." self "..tostring(self))
	  end
	  
	 	self.rank_extra_params = args
	  --log:print("aux setting rank extra param: "..self.rank_extra_params[1])
	end
----------------------------------------------------
	function TMAN.get_distFunc_extraParams(self)
	
	  if self==nil then
	    log:warning("at node: "..job.position.." id: "..self.me.id.." self nil")
			--else
	    --log:print("at node: "..job.position.." id: "..self.me.id.." self notl nil:  "..tostring(self))

	  end
	 
	 
	  
	  if self.rank_extra_params==nil then
	    log:warning("at node: "..job.position.." id: "..self.me.id.." self .rank_extra_params nil")
			--else
	   -- log:print("at node: "..job.position.." id: "..self.me.id.." self .rank_extra_params not nil self: "..tostring(self))
	  end
	   

	   --for k,v in pairs(self.rank_extra_params) do
	   --    log:print("at node: "..job.position.." id: "..self.me.id.." self  k,v : "..k..", "..v)
	   --end
	   
	   
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
	  --if self.logDebug then
		--log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." STARTED")
		--end
		
		local distances = {}
		local ranked = {}
		
		local mypayload = self.get_payload(self, self.me)
		local res =""
		for i=1, #mypayload do
		     res = res..mypayload[i]..", " 
		end
		
		--if self.logDebug then
    --log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." local payload ["..res.."]")
		--end
		
		for i,v in ipairs(viewCopy) do
			
			local nb_payload =  self.get_payload(self, v)
			res = ""
			for i=1, #nb_payload do
					 res = res..nb_payload[i]..", "
			end
			
			--if self.logDebug then
			--	log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." - neighbour "..v.id.." neighbour_payload ["..res.."]")
			--end

			 -- if self==nil then
	     -- 	log:print("at node: "..job.position.." id: "..self.me.id.." self dist_function nil: ")
	     -- end
	    
			local dist = self.dist_function(self, mypayload, nb_payload)
			
			--if self.logDebug then
			--	log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." TMAN distance ("..self.me.id..","..v.id..") : "..dist)
			--end
			distances[#distances+1] = {distance= dist, node=v}
			
		end
	
		table.sort(distances, function(a,b) return a.distance < b.distance end)

		local	ret=""
		local cumul_distance=0
		
		for i,v in ipairs(distances) do
			--sif self.logDebug then
		  --s	log:print(currentMethod.."at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." ranking["..i.."]: distance to "..v.node.id.." is "..v.distance)
			--send
			ret = ret.." "..v.node.id.." : ["..v.distance.."] "	
			cumul_distance = cumul_distance+v.distance
		end
		
		--if self.logDebug then
			--log:print(currentMethod.." "..l_thread.." TMAN_VIEW ranking at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." avg dist: "..cumul_distance/#distances.." view - "..ret)
		--end
	
		for i,v in ipairs(distances) do
			ranked[#ranked+1] = v.node
		end
		
		--if self.logDebug then
		--	log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." END")
		--end
		return ranked

	end

----------------------------------------------------
	function TMAN.get_payload(self, node)
	--TODO refactoring: send it to Utilities maybe
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
   	--log:print("remove node : "..node)
 
 		
			--TODO refactoring: send it to Utilities maybe	
		local j = 1
		for i = 1, #t do
		  
		  --log:print("t[j] node : "..t[j].id)
			--if self.same_node(self, t[j], node) then
			if  t[j].id==node then  
			  --log:print("same node")
				table.remove(t, j)
			else j = j+1 
			end
		end
		
	end

----------------------------------------------------
	function TMAN.same_node(self, n1,n2)
		--TODO refactoring: send it to Utilities maybe
		--log:print("n1. id: "..n1.id)
		--log:print("n2. peer: "..n2.id)
		
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
		--TODO refactoring: send it to Utilities maybe	
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
	
	local currentMethod = "[TMAN.getTViewCopy] - "

	self.t_view_lock:lock()
		local copy = misc.dup(self.t_view)
	self.t_view_lock:unlock()
  --if self.logDebug then
  --	self.utils:print_this_view(currentMethod.."TMAN_VIEWCOPY: ", copy, self.cycle_numb, self.algoId)	
	--end
	return copy

end

---------------------------------------------------- 
function TMAN.activeTMANThreadSuccess(self, received)
	
		local currentMethod = "[TMAN.ACTIVETMANTHREADSUCCESS] - "
	
	--if self.logDebug then
		--	log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." [TMAN.ACTIVETHREADSUCCESS] - STARTED")
		--end
	
		if self.logDebug then
			log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." - received buffer invoking TMAN.UPDATE_VIEW_TO_KEEP().")
		end
	
		-- self.removeDead(received)
		self.update_view_to_keep(self, received) 
	
		--if self.logDebug then
			--	log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." [TMAN.ACTIVETHREADSUCCESS] - fire CompleteTMANActive and end")
			--end
	
			events.fire('CompleteTMANActive')
end
	
---------------------------------------------------- 
function TMAN.active_thread(self)
		
		local currentMethod = "[TMAN.ACTIVE_THREAD] - "
		self.t_view_lock:lock()
			self.cycle_numb = self.cycle_numb+1
		self.t_view_lock:unlock()
		
	--if self.logDebug then
		--	log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." [TMAN.ACTIVE_THREAD] - STARTED")
		--self.utils:print_this_view("[TMAN.ACTIVE_THREAD_START] - CURRENT TMAN_VIEW:", self.t_view, self.cycle_numb, self.algoId)
		--end
		
		local viewCopy = self.getTViewCopy(self)
		
		local selected_peer = self.select_peer(self, viewCopy) 
		if not selected_peer then 
			if self.logDebug then
				log:warning(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." TMAN active_thread: no selected_peer chosen") 
			end
			return 
		else
			--log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." TMAN selected_peer: "..selected_peer.id)
		end
		
		
		local buffer = self.select_view_to_send(self, selected_peer.id, viewCopy)
						
		if self.logDebug then
			log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." sending buffer to node: "..selected_peer.id)
		end
			
		Coordinator.send(self.algoId, selected_peer, buffer,'CompleteTMANActive')
		
		events.wait('CompleteTMANActive')

		
		self.t_view_lock:lock()
			--self.cycle_numb = self.cycle_numb+1
			self.utils:print_this_view("[TMAN.ACTIVE_THREAD_END] - CURRENT TMAN_VIEW: ", self.t_view, self.cycle_numb, self.algoId)
		self.t_view_lock:unlock()
		

end
----------------------------------------------------
function TMAN.passive_thread(self, sender, received)
	
local currentMethod = "[TMAN.PASSIVE_THREAD] - "
	
	
events.thread(function()
	local currentMethod = "[TMAN.PASSIVE_THREAD] - "
	--log:print(currentMethod.." node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." sender: "..sender.id)
		
	local viewCopy = self.getTViewCopy(self)
		
	--if self.logDebug then
		--	log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." [TMAN.PASSIVE_THREAD] - STARTED")
		--self.utils:print_this_view("[TMAN.PASSIVE_THREAD_START] - CURRENT TMAN_VIEW:", viewCopy, self.cycle_numb, self.algoId)
		--end
		
		--	 select to send
		local buffer_to_send = self.select_view_to_send(self, sender, viewCopy)

		Coordinator.callAlgoMethod(self.algoId, 'activeTMANThreadSuccess', buffer_to_send, sender, self.me.id)
	
		end)
	
		-- select view to keep
		-- self.removeDead(received)
		self.update_view_to_keep(self, received)

		--self.utils:print_this_view("[TMAN.PASSIVE_THREAD_END] - CURRENT TMAN_VIEW:", self.t_view, self.cycle_numb, self.algoId)
		--if self.logDebug then
			--	log:print(currentMethod.." at node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." [TMAN.ACTIVE_THREAD] - END")
			--end


		end
----------------------------------------------------
	function TMAN.set_node_representation(self, node_rep)
	
	  self.me.payload= node_rep
	  local pl_string = ""
	
		for i=1, #self.me.payload do
  	 	 -- self.me.payload[#self.me.payload+1] = node_rep[i]
			 pl_string = pl_string.." "..node_rep[i]
	 	end
	 	if self.logDebug then
	 		log:print("TMAN - At node: node: "..job.position.." id: "..self.me.id.." cycle: "..self.cycle_numb.." setting node representation (payload): [ "..pl_string.." ]")
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
	

------------------------ END OF CLASS TMAN ----------------------------

