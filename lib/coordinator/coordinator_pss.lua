require"splay.base"
rpc = require"splay.rpc"
misc = require "splay.misc"
crypto = require "crypto"
rpc.server(job.me.port)
ongoing_rpc = "0"
is_init = "0"

Coordinator={}
Coordinator.algos={}
--Coordinator.initAlgos=function(confObj)
-- For each algoId in confObj
--end

Coordinator.launch=function(algo, running_time)
	log:print("begin")
	if algo == nil then
	  log:print("PSS is nil")
	end
	-- set termination thread
	events.thread(function() events.sleep(running_time) os.exit() end)
	log:print("begin 2")
			-- init random number generator
	math.randomseed(job.position*os.time())
	log:print("begin 3")
			-- wait for other nodes to start 
	--events.sleep(3)
	log:print("begin 4 "..algo.cycle_period)
	-- desynchronize starting time nodes
	local desync_wait = (algo.cycle_period * math.random())
	log:print("begin 5")
			--log:print("waiting "..desync_wait.." seconds to desynchronize")
	events.sleep(desync_wait)
	log:print("begin 6")
			-- initialize pss
	--TODO ForEach algo in Coordinator.algos Do algo.Init() END
	algo:pss_init()
	log:print("begin 7")
	events.sleep(5)
	--END TODO
	-- periodic thread
	--local pss_thread_ = events.periodic(pss.cycle_period, function() pss.active_thread() end)
	--local pss_thread_ = events.periodic(algo.cycle_period, Coordinator.doActive)
	events.periodic(algo.cycle_period, Coordinator.doActive)
	log:print("begin 8")
end

Coordinator.doActive=function()
  local algo=nil
  for key in pairs(Coordinator.algos) do
    algo=Coordinator.algos[key]
    if algo~=nil then
    	log:print("Doing active thread of algo: "..key)
    	algo:active_thread()
    else
    	log:print("Algo: "..key.." is not instantiated")
    end
  end
end

Coordinator.send=function(algoId, dst, buf)
		local algo=Coordinator.algos[algoId]
	  --log:print("Cycle / 2 "..algo.cycle_period)
		local ok, r = rpc.acall(dst,{"Coordinator.passive_thread", algoId, job.position, buf}, algo.cycle_period/2)
		return ok, r
end

Coordinator.passive_thread=function(algoId, from, buffer)
		--log:print("Emitter: "..from.." Receiver: "..job.position)
		if ongoing_rpc=="1" or not is_init=="1" then
			return false
		end
		local algo=Coordinator.algos[algoId]
		local ret = algo:passive_thread(from, buffer)
		--log:print("buffer size: "..#buffer)
		return ret
end



local Utilities={}
Utilities.__index=Utilities

function Utilities.new()
  local self=setmetatable({}, Utilities)
  return self
end


function Utilities.print_this_pss_view(self, message, view, cycle)
  if message then 
    log:print(message.." at node: ("..job.position..") id: "..me.id.." cycle: "
      ..cycle.." view: "..self.set_of_peers_to_string(view))
  else
    log:print("PSS_VIEW at node: ("..job.position..") id: "..me.id.." cycle: "
      ..cycle.." view: "..set_of_peers_to_string(view))
  end
end

function Utilities.set_of_peers_to_string(v)
		ret = ""; 
		for i=1,#v do	
			ret = ret..v[i].id.." "	
			--ret = ret..v[i].id.." " --"#payload: "..#v[i].payload   --aqui
		end
		return ret
end



local PSS = {} -- the table representing the class, which will double as the metatable for the instances
PSS.__index = PSS -- failed table lookups on the instances should fallback to the class table, to get methods

function PSS.new(c, h, s, fanout,cyclePeriod, selection, me, algoId)
  local self = setmetatable({}, PSS)
  self.cycle_numb=0
  self.view={}
  self.view_copy={}
  self.c=c
  self.H=h
  self.S=s
  self.exch=fanout
  self.view_copy_lock=events.lock()
  self.cycle_period=cyclePeriod
  self.SEL=selection
  self.me=me
  self.utils=Utilities.new()
  self.algoId=algoId
  --self.ongoing_rpc = "0"
  --self.is_init = "0"
  return self
end

function PSS.pss_selectPartner(self)
		if #self.view > 0 then
			if self.SEL == "rand" then 
				return math.random(#self.view) 
			end
			if self.SEL == "tail" then
				local ret_ind = -1 ; local ret_age = -1
				for i,p in pairs(self.view) do
					if (p.age > ret_age) then 
						ret_ind = i;ret_age=p.age
					end
				end
				assert (not (ret_ind == -1))
				return ret_ind
			end
		else
			return false
		end
end

	-- ##################################################################
--function PSS.same_peer_but_different_ages(self, a, b)	  
--  return a.peer.ip == b.peer.ip and a.peer.port == b.peer.port
--end
	-- ##################################################################
function PSS.same_peer(self,a,b)
 	  local condition=a.peer.ip == b.peer.ip and a.peer.port == b.peer.port
  return condition and a.age == b.age
end
	-- ##################################################################
	function PSS.pss_selectToSend(self)
		
		--log:print("PSS selectToSend:  #me.payload: "..#me.payload)
		--for i=1, #me.payload do
		--	log:print("payload["..i.."]: "..me.payload[i])
		--end
		
		local toSend = {}
		-- insert own descriptor to "toSend" buffer
		table.insert(toSend,{peer={ip=job.me.ip,port=job.me.port},age=0,id=me.id,payload=me.payload})  --added payload
		
		if #self.view > 0 then 
			--shuffle and sort view by age
			self.view = misc.shuffle(self.view)
			local tmp_view = misc.dup(self.view)
			table.sort(tmp_view,function(a,b) return a.age < b.age end)
			
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
	
			for i=1,(self.exch-1) do
				toSend[#toSend+1]=self.view[i]
			end
		end
		return toSend
	end
	-- ##################################################################
	function PSS.pss_selectToKeep(self, received)

 	  
		--merge received and local view
		for j=1,#received do
			self.view[#self.view+1] = received[j] 
		end
		-- add remove itself 
		table.remove(self.view,job.position)
		local i = 1
		local condition=false
		-- remove oldest age if the same node happens to be in the view twice
		while i < #self.view-1 do
			for j=i+1,#self.view do
				condition=self.view[i].peer.ip == self.view[j].peer.ip and self.view[i].peer.port == self.view[j].peer.port
--				if self.same_peer_but_different_ages(self.view[i], self.view[j]) then
				if condition then
				if self.view[i].age < self.view[j].age then 
					table.remove(self.view,j) -- delete the oldest
				else
					table.remove(self.view,i)
				end
					i = i - 1 -- we need to retest for i in case there is one more duplicate
					break
				end
			end
			i = i + 1
		end
		-- remove the min(H,#view-c) oldest items from view
		local o = math.min(self.H,#self.view-self.c)
		while o > 0 do
			-- brute force -- remove the oldest
			local oldest_index = -1
			local oldest_age = -1
			for i=1,#self.view do 
				if oldest_age < self.view[i].age then
					oldest_age = self.view[i].age
					oldest_index = i
				end
			end
			assert (not (oldest_index == -1))
			table.remove(self.view,oldest_index)
			o = o - 1
		end
		
		-- remove the min(S,#view-c) head items from view
		o = math.min(self.S,#self.view-self.c)
		while o > 0 do
			table.remove(self.view,1) -- not optimal
			o = o - 1
		end
		--log:print("#self.view= "..#self.view.." self.c= "..self.c)
		-- in the case there still are too many peers in the view, remove at random
		while #self.view > self.c do 
			table.remove(self.view,math.random(#self.view)) 
		end
	--log:print("#self.view= "..#self.view.." self.c= "..self.c)
		assert (#self.view <= self.c)
		--log:print("PSS_SELECT_TO_KEEP ", ( misc.time() - selectToKeepStart ) )		
	end
	
	-- ##################################################################
	-- PSS PASSIVE THREAD
	function PSS.passive_thread(self, from, buffer)
		--log:print("Emitter: "..from.." Receiver: "..job.position)
		if ongoing_rpc=="1" or not is_init=="1" then
			return false
		end
		local ret = self.pss_selectToSend(self)
		--log:print("buffer size: "..#buffer)
		self.pss_selectToKeep(self,buffer)
		--self.print_this_pss_view("passive_thread ("..job.position.."): after selectToKeep")
		--self.print_this_pss_view("PSS_VIEW", self.view)
		return ret
	end
	-- #####################################################################
	function PSS.pss_send_at_rpc(self,peer,pos,buf)
	  log:print("Cycle / 2 "..self.cycle_period)
		local ok, r = rpc.acall(peer,{"pss_passive_thread",pos, buf, self}, self.cycle_period/2)
		return ok, r
	end
	-- ##################################################################
	-- PSS ACTIVE THREAD

	
	function PSS.active_thread(self)		
		ongoing_rpc="1"
		--self:setOngoingRpc(1)
		local exchange_aborted=true
		local exchange_retry=2
			
		
		for i=1,exchange_retry do
			local partner_ind = self.pss_selectPartner(self)
			if not partner_ind then
				log:print("pss_active_thread: pss view is empty, no partner can be selected")
				return
			end
			local partner = self.view[partner_ind]
			--log:print("TEST ()"..job.position..") removing destination node "..partner.id.." from the view")
			--self.print_this_pss_view("TEST PSS_before", self.view)
			table.remove(self.view,partner_ind)
			--self.print_this_pss_view("TEST PSS_VIEW after", self.view)
			
			buffer = self.pss_selectToSend(self)

			local ok, r = Coordinator.send(self.algoId, partner.peer, buffer)
			--local ok, r = self.pss_send_at_rpc(self,partner.peer,job.position, buffer) 

			if ok then
				self.cycle_numb = self.cycle_numb+1
				local received = r[1]
				if received==false then
					events.sleep(math.random())	
					
				else
					exchange_aborted=false 
					self.pss_selectToKeep(self, received)
					--self.print_this_pss_view("PSS_VIEW",self.view)
					
				end
			else
				log:print("on peer ("..job.position..") peer "..partner.id.." did not respond -- removing it from the view")
				log:warning("self.pss_passive_thread RPC error:", r)
				table.remove(self.view,partner_ind)
			end		
			if exchange_aborted==false then break end
		end
	
		self.view_copy_lock:lock()
		local viewCopyLock = misc.time()
		self.view_copy = misc.dup(self.view)
		self.view_copy_lock:unlock()
		
		for _,v in ipairs(self.view) do
				v.age = v.age+1
		end
		
		-- sort view by id
		table.sort(self.view,function(a,b) return a.id < b.id end)
		
		self.utils:print_this_pss_view("PSS_VIEW ", self.view, self.cycle_numb)
		
		-- now, allow to have an incoming passive thread request
		--self.setOngoingRpc(0)
		ongoing_rpc = "0"
	end
	
	-- ###############################

	function PSS.pss_getPeer(self)
		
		self.view_copy_lock:lock()
		local peer = self.view_copy[math.random(#self.view_copy)] 
		self.view_copy_lock:unlock()
		return peer
		
	end
-- ##################################################################
	function PSS.pss_init(self)
		
		
		local indexes = {}
		for i=1,#job.nodes do 
			indexes[#indexes+1]=i 
		end
		table.remove(indexes,job.position) --remove myself
		
		local selected_indexes = misc.random_pick(indexes,math.min(self.c,#indexes))	

		for i=1,#selected_indexes do
			log:print("PSS INIT: at ("..job.position..") selected index: "..selected_indexes[i])
		end	
		
		for i,v in pairs(selected_indexes) do
			   log:print("PSS INIT: node ("..job.position..") setting selected index: "..v.." to local pss view")
				local a_peer = job.nodes[v]
				--local hashed_index = compute_hash(tostring(a_peer.ip) ..":"..tostring(a_peer.port))
				local hashed_index = v
				--why not 0 at the age?
		 		--self.view[#self.view+1] = {peer=a_peer,age=math.random(self.c),id=hashed_index , payload={}}  -- aqui added payload
		 		self.view[#self.view+1] = {peer=a_peer,age=0,id=hashed_index , payload={}}  -- aqui added payload
		end
		-- sort view by id
		table.sort(self.view,function(a,b) return a.id < b.id end)
		
		self.view_copy = misc.dup(self.view)
		assert (#self.view == math.min(self.c,#indexes))
		
		self.utils:print_this_pss_view("PSS_VIEW_INITIALIZED: ", self.view, self.cycle_numb)
		is_init = "1"
		--self.setIsInit(1)

	end

function PSS.get_id(self)
  return self.me.id
end

--function compute_hash(o)
--	return tonumber(string.sub(crypto.evp.new("sha1"):digest(o), 1, 8), 16)
--end

function main()
  me={}
  me.peer=job.me
  me.id=job.position
  local algo=PSS.new(10, 1, 3, 5, 5, "rand", me, "pss1")
  Coordinator.algos.pss1=algo
  log:print("Current id: "..algo:get_id())
  Coordinator.launch(algo, 2000)
end

events.thread(main)  
events.loop()
