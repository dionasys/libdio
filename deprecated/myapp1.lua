require"splay.base"
rpc = require"splay.rpc"
misc = require "splay.misc"
crypto = require "crypto"
rpc.server(job.me.port)

--#################### CLASS NODE ###################################
local Node = {}
Node.__index = Node 
--TODO: ASAP:  set type for id , either hashed or job.position based. change set_IDSpace , compute_ID set_hashed accordingly 

function Node.new(me)

local self = setmetatable({}, Node)
	
	self.peer=me
	self.id=job.position
	self.age=0
	self.payload={}  
	
	self.hashedID = false
	self.idbase = 2
	self.idexpo = 1
	
	self.computeID_func=nil
	self.computeID_func_params={}
	
  return self
end


--function Node.compute_hash(self, o, bits) 	
--	return string.sub(crypto.evp.new("sha1"):digest(o), 1, bits/4)  
--end

----------------------------------------------------
	function Node.set_computeID_function(self, f)
		self.computeID_func = f
	end
----------------------------------------------------
	function Node.get_computeID_function(self)
		return self.computeID_func
	end
----------------------------------------------------
	function Node.set_computeID_function(self, f, args)
		self.computeID_func = f
		self.computeID_func_params = args
	end

	----------------------------------------------------
	function Node.computeID_function(self, ip , port)
	
	  if self==nil then
	    log:print("at node: "..job.position.." id: "..self.id.." self at computeID_function is nil: ")
	  end
		
		if ip==nil then
			log:print("ip nill")
		end
		
		if port==nil then
			log:print("port nill")
		end
		
		if self.computeID_func_params==nil then
			log:print("self.computeID_func_params nil")
		end
		
		if self.computeID_func==nil then
			log:warning("self.computeID_func_params nil")
		end
		
		
		local computedID = self.computeID_func(self, ip, port, self.computeID_func_params)
		return computedID
		
	end
	----------------------------------------------------

function Node.set_hashedID(self, digits)
		self.id = string.sub(crypto.evp.new("sha1"):digest(tostring(job.me.ip)..":"..tostring(job.me.port)), 1, digits)
end

function Node.set_hashedID(self)
		self.id = crypto.evp.new("sha1"):digest(tostring(job.me.ip)..":"..tostring(job.me.port))
end

function Node.toBits(num, bits)
-- only used for checking the selected values.
  local i = 2
  bits = bits or select(i, math.frexp(num))
  local t = {}
  for b = bits, 1, -1 do
       t[b] = math.fmod(num, i)
       num = (num - t[b]) / i
  end
 return t
end


function Node.set_IDSpace(self, bits)

			
			self.idexpo = bits
					
      local r = 0
      if bits%4 == 0 then
         r = bits/4
      else
         r= bits/4 + 1
      end
      
		 	log:print("[set_IDSpace] IDSPACE - At node: "..job.position.." id: "..self.id.." setting ID,  selected number of bits: "..bits.." hexa need to represent it: "..r)
      local resultHexa = string.sub(crypto.evp.new("sha1"):digest(tostring(job.me.ip)..":"..tostring(job.me.port)), 1, r)
 	 		log:print("[set_IDSpace] IDSPACE - At node: "..job.position.." id: "..self.id.." setting ID,  hashed(ip port) resultHexa: "..resultHexa)
      local resultNumb = tonumber(resultHexa,16)
      --local x = self.toBits(result3)
      --ret = ""
      --for j = 1, #x do
      --  ret = ret..x[j]
      --end
		 	log:print("[set_IDSpace] IDSPACE - At node: "..job.position.." id: "..self.id.." setting ID,  resultHexa to number: "..resultNumb)
      self.id = resultNumb
		
end


function Node.compute_ID(self, bits, ip , port)
	
			log:print("[compute_ID] IDSPACE - At node: "..job.position.." id: "..self.id.." computing hash id to IP: "..ip.." PORT: "..port)
      local r = 0
      if bits%4 == 0 then
         r = bits/4
      else
         r= bits/4 + 1
      end
 			
      local resultHexa = string.sub(crypto.evp.new("sha1"):digest(tostring(ip)..":"..tostring(port)), 1, r)
      log:print("[compute_ID] IDSPACE - At node: "..job.position.." id: "..self.id.." setting ID,  hashed(ip port) resultHexa: "..resultHexa)
      local resultNumb = tonumber(resultHexa,16)
      log:print("[compute_ID] IDSPACE - At node: "..job.position.." id: "..self.id.." setting ID,  resultHexa to number: - returning: "..resultNumb)
      return resultNumb
		
end

function Node.getIDExpo(self)
	return self.idexpo
end

function Node.setIDExpo(self, bits)
	self.idexpo = bits
end


function Node.setPeer(self, peer)
	self.peer = peer
end

function Node.getPeer(self)
	return self.peer
end

function Node.getIP(self)
	return self.peer.ip
end

function Node.getPort(self)
	return self.peer.port
end

function Node.setID(self, id)
	self.id = id
end

function Node.getID(self)
	return self.id
end

function Node.setAge(self, age)
	self.age = id
end

function Node.getAge(self)
	return self.age
end

function Node.setPayload(self, payload)
  
 	 --for k,v in pairs(payload) do
		--	self.payload[k] = v 
 	 --end
  
  	self.payload= payload
  	
	  local pl_string = ""
	
		for i=1, #self.payload do
			 pl_string = pl_string.." "..self.payload[i]
	 	end
	 	if self.logDebug then
	 		log:print("NODE - At node: "..job.position.." id: "..self.id.." setting node representation (payload): [ "..pl_string.." ]")
	 	end
  

end

function Node.getPayload(self)
	return self.payload
end

function Node.getPayloadSize(self)
	return #self.payload
end



------------------------ END OF CLASS NODES --------------------------

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
--#################### CLASS UTILITIES ###################################
--TODO organize utilities , some duplicate methods.

local Utilities={}
Utilities.__index=Utilities

function Utilities.new()
  local self=setmetatable({}, Utilities)
  return self
end


function Utilities.new(node)
  local self=setmetatable({}, Utilities)
  self.node = node 
  return self
end

function set_of_peers_to_string(v)

	  -- table.sort(v, function(a,b) return a.id < b.id end)
		local ret = ""
		if #v > 0 then
			for i=1,#v do
				if v[i] == nil then
					ret = ret.."NIL".." "	
				else
					-- different options to print, used to debug
					-- view only with ids
					--ret = ret..v[i].id.." "
					-- view with id + age
					ret = ret..v[i].id.."("..v[i].age..") "	
					-- view with id + payload
					-- ret = ret..v[i].id.." "..get_payload_as_string(v[i])
					-- view with id + age + payload
					-- ret = ret..v[i].id.."("..v[i].age..") "..get_payload_as_string(v[i])
				end
				--ret = ret..v[i].id.." " --"#payload: "..#v[i].payload   --aqui
			end
		end
		--log:print("VALUE: "..ret)
		return ret
end

function Utilities.print_this_view(self, message, view, cycle, algoId)
	
  if message then 
    --log:print(message.." at node: ("..job.position..") id: "..me.id.." mypayload: "..get_payload_as_string(me).." cycle: "
    --  ..cycle.." view: "..set_of_peers_to_string(view))
    log:print("ALGO_ID:["..algoId.."] - "..message.." at node: "..job.position.." id: "..self.node:getID().." cycle: "..cycle.." view(#"..#view.."): [ "..set_of_peers_to_string(view).."]")
  else
    log:print("ALGO_ID:["..algoId.."] VIEW at node: "..job.position.." id: "..self.node:getID().." cycle: "..cycle.." view(# "..#view.." ): [ "..set_of_peers_to_string(view).."]")
  end
end

function Utilities.remove_dup(self, set)
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

function get_payload_as_string(peer)
    
    local mypayload = get_payload(peer)
		local res =""
		for i=1, #mypayload do
		     res = res..mypayload[i].." " 
		end
    return "["..res.."] "
end


function get_payload(peer)

		local payl = {}
		if type(peer) == "table" then 
			payl = peer.payload 
		else 
			payl = peer 
		end
		return payl
	end



------------------------ END OF CLASS UTILITIES --------------------------
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

-- Global functions
-- These are the pre-defined distance functions and 
-- the functions used to set the correct payload (the data structure used by the selected distance function), 
-- according to the select distance func.

----------------------------------------------------

function id_based_ring_distance(self, a, b)
	 -- a and b correspond to the data payload of each node 
   -- get extra parameters provides extra parameters need to calculate the dist function, these paremeters must be initialized with TMAN.set_distFunc_extraParams() method. 
 	 -- in this case the extra parameter will contain the auxiliar 'm' value used to calculate the distance in the ring, e.g., 2^m nodes 
 	 
-- 	 		if self==nil then
--	     	log:print("DIST at node: "..job.position.." id_based_ring_distance self dist_function nill: ")
--	     else
--	     	log:print("DIST at node: "..job.position.." id_based_ring_distance self dist_function not nill: "..tostring(self))
--	     end
	     
	     local aux_parameters = self:get_distFunc_extraParams()
 	 
 	    -- NOTE: what to do in this case, it happens in the beggining as views are spread by pss without the knowledge of payload which is a TMAN feature. 
 	    if a[1]==nil or b[1]==nil then
 	      log:warning("DIST at node: "..job.position.." id_based_ring_distance: self either a[1]==nil or b[1]==nil")
 	      -- if one of them is nill (ghost from pss) return a high distance in order to avoid them to be kept in the view.
 	      return 2^aux_parameters[1]-1
 	    end
			-- debug
	    --for k,v in pairs(a) do
	    --   log:print("DIST at node: "..job.position.." self a k,v : "..k..", "..v)
	   	--end
	   	--log:print("DIST at node: "..job.position.." self a[1]: "..a[1])
	   	
      --for k,v in pairs(b) do
	    --   log:print("DIST at node: "..job.position.." self b k,v : "..k..", "..v)
	   	--end
	  	--log:print("DIST at node: "..job.position.." self b[1]: "..b[1])
	    
			
			local k1 = a[1]
			local k2 = b[1]
			
			local distance = 0

			if k1 < k2 then 
					distance =  k2 - k1 
			else 
					distance =  2^aux_parameters[1] - k1 + k2 
			end
   		
   		--log:print("DIST at node: "..job.position.." self a[1]: "..a[1].." b[1]: "..b[1].." with aux_parameters[1]"..aux_parameters[1].." distance is: "..distance)
   		
   		return distance
end

----------------------------------------------------
function jaccard_distance(self, a, b)
      
      if self==nil then
	     	log:print("at node: "..job.position.." jaccard self dist_function nill: ")
	     else
	     	log:print("at node: "..job.position.." jaccard self dist_function not nill: "..tostring(self))
	     end
	     
	     
-- a and b correspond to the data payload of each node 
	--log:print("jaccard distance invoked")
	--if type(a) == "table" and  type(v2) == "table" then
		--log:print("a and b are tables ")
		if #a==0 and #b==0 then  -- if sets are empty similarity is considered 1.
			return 1
		end
		
		local intersec = get_intersection(a,b)
		--log:print("jaccard interesection: "..intersec)
		local union = misc.merge(a,b)
		--log:print("jaccard union: "..union)
		return 1-(#intersec/#union)
		--else
		--log:print("a and b are not tables ")
		--return 0
		--end
	 
end

----------------------------------------------------
function get_intersection(set_a, set_b)
	local result = {}
	  	for i = 1,#set_a do
	    	if contains(set_b, set_a[i]) then 
			result[#result+1]=set_a[i] 
		end
	  	end	
	return result	
end

----------------------------------------------------
function contains(set, elem)
  for i = 1,#set do
    if set[i] == elem then 
			return true 
		end
  end
  return false
end

----------------------------------------------------
function select_topics_according_to_id()
	-- returns specific topics according to the id of the node. 
	-- this function is used to test the clustering
	local topics = {"Agriculture", "Health","Aid","Infrastructure","Climate",
		"Poverty","Economy","Education","Energy","Mining","Science","Technology",
		"Environment","Development","Debt" ,"Protection","Labor","Finances",
		"Trade","Gender"}
	local selected = {}
	local myposition = job.position
  --log:print("node ID: (payload selection) : "..myposition)
	local interval = myposition % 4
	
	if interval == 0 then
		for i=1, 5 do
		  --log:print("Setting payload at node: "..myposition.." payload selected: "..topics[i])
		  selected[#selected+1] = topics[i]
		end
	end
	if interval == 1 then
		for i=6, 10 do
		  --log:print("Setting payload at node: "..myposition.." payload selected: "..topics[i])
		  selected[#selected+1] = topics[i]
		end
	end
	if interval == 2 then
		for i=11, 15 do
		  --log:print("Setting payload at node: "..myposition.." payload selected: "..topics[i])
		  selected[#selected+1] = topics[i]
		end
	end
	if interval == 3 then
		for i=16, 20 do
		  --log:print("Setting payload at node: "..myposition.." payload selected: "..topics[i])
		  selected[#selected+1] = topics[i]
		end
	end
 	return selected
end

----------------------------------------------------
----------------------------------------------------
function jaccard_distance(self, a, b)

		if #a==0 and #b==0 then  -- if sets are empty similarity is considered 1.
			return 1
		end
		
		local intersec = get_intersection(a,b)
		local union = misc.merge(a,b)
		return 1-(#intersec/#union)

end

----------------------------------------------------
function get_intersection(set_a, set_b)
	local result = {}
	  	for i = 1,#set_a do
	    	if contains(set_b, set_a[i]) then 
			result[#result+1]=set_a[i] 
		end
	  	end	
	return result	
end

----------------------------------------------------
function contains(set, elem)
  for i = 1,#set do
    if set[i] == elem then 
			return true 
		end
  end
  return false
end

----------------------------------------------------
function select_topics_according_to_id()
-- TEST: this function is used to test the clustering
-- returns specific topics according to the id of the node. used to select topics to nodes

	local topics = {"Agriculture", "Health","Aid","Infrastructure","Climate",
		"Poverty","Economy","Education","Energy","Mining","Science","Technology",
		"Environment","Development","Debt" ,"Protection","Labor","Finances",
		"Trade","Gender"}
	local selected = {}
	local myposition = job.position
	local interval = myposition % 4
	
	if interval == 0 then
		for i=1, 5 do
		  selected[#selected+1] = topics[i]
		end
	end
	if interval == 1 then
		for i=6, 10 do
		  selected[#selected+1] = topics[i]
		end
	end
	if interval == 2 then
		for i=11, 15 do
		  selected[#selected+1] = topics[i]
		end
	end
	if interval == 3 then
		for i=16, 20 do
		  selected[#selected+1] = topics[i]
		end
	end
 	return selected
end

----------------------------------------------------
function main()
	-- TODO: re-test this example after new updates regarding callback communication
	
	local node = Node.new(job.me) 

  log:print("APP START - node: "..job.position.." id: "..node:getID().." ip/port: ["..node:getIP()..":"..node:getPort().."]")
	
-- setting PSS 
-- parameters: c (view size) , h (healing), s (swappig), fanout, cyclePeriod, peer_selection_policy , me
	local pss = PSS.new(8, 1, 1, 4, 5, "tail", node)  
	Coordinator.addProtocol("pss1", pss)

-- setting TMAN 
-- parameters: me, view size, cycle_period, base_procotols, active_b_proto, algoId
	local tman_base_protocols={pss}
	local tman = TMAN.new(node, 4, 5, tman_base_protocols, "pss1")   

	Coordinator.addProtocol("tman1", tman)
	Test: jaccard based distance function
	tman:set_distance_function(tman, jaccard_distance)
	tman:set_node_representation(select_topics_according_to_id())
	tman:set_node_representation(rep)  -- it might change to --		node:setPayload(rep) 
	
-- launching protocols
	Coordinator.showProtocols()
	Coordinator.launch(node, 660, 0)  -- parameters: local node ref, running time in seconds, delay to start each protocol

end

events.thread(main)
events.loop()
