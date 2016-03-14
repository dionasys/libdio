require"splay.base"
rpc = require"splay.rpc"
misc = require "splay.misc"
crypto = require "crypto"
rpc.server(job.me.port)

-- ############################################################################
-- CURRENT NODE
-- ############################################################################
me = {}   -- me = {peer, age, id}
me.peer = job.me  -- job.me = peer = {ip = "127.0.0.1", port = 20000}
M = 32
function compute_hash(o)
	return tonumber(string.sub(crypto.evp.new("sha1"):digest(o), 1, M/4), 16)
end
me.age = 0
--me.id = compute_hash(table.concat({tostring(job.me.ip),":",tostring(job.me.port)}))
me.id = job.position
me.payload = {}

-- ############################################################################
-- 	PEER SAMPLING SERVICE
-- ############################################################################
-- PSS PARAMETERS (default parameters, can be changed with the method PSS.set_parameters)
-- ##################################################################
RUNNING_TIME = 120
PSS_VIEW_SIZE = 10
PSS_SHUFFLE_SIZE = math.floor(PSS_VIEW_SIZE / 2 + 0.5)
PSS_SHUFFLE_PERIOD =  5
TMAN_SHUFFLE_PERIOD = 5

PSS = {

	view = {},
	view_copy = {},
	c = PSS_VIEW_SIZE,
	exch = PSS_SHUFFLE_SIZE,
	H = 1,
	S = math.floor(PSS_VIEW_SIZE/ 2 + 0.5) - 1,
	SEL = "rand", -- Selection algorithm can be "tail" or "rand"
	view_copy_lock = events.lock(),
	running_time = 60,
	cycle_period = PSS_SHUFFLE_PERIOD,
	cycle_numb=0,
	
	total_known = {}
	

	
	-- ##################################################################
	print_table = function(t)
		print("[ (size "..#t..")")
		for i=1,#t do
			print("  "..i.." : ".."["..t[i].peer.ip..":"..t[i].peer.port.."] - age: "..t[i].age.." - id: "..t[i].id)
		end
		print("]")
	end,
	-- ##################################################################
	set_of_peers_to_string = function(v)
		ret = ""; 
		for i=1,#v do	
			ret = ret..v[i].id.." "	
		end
		return ret
	end,
	
	
	-- ##################################################################
--	print_set_of_peers = function(v,message)	
--		if message then 
--			log:print(message) 
--		end
--		log:print(PSS.set_of_peers_to_string(v))
--	end,
	-- ##################################################################
	print_view = function(message)
		if message then 
			log:print(message) 
		end
		log:print("PSS_VIEW ("..job.position..") : "..me.id.." : "..PSS.set_of_peers_to_string(PSS.view))
	end,
	-- ##################################################################
	print_this_pss_view = function(message, view)
		if message then 
			log:print(message.." at node: ("..job.position..") id: "..me.id.." cycle: "..PSS.cycle_numb.." view: "..PSS.set_of_peers_to_string(view))
		else
			log:print("PSS_VIEW at node: ("..job.position..") id: "..me.id.." cycle: "..PSS.cycle_numb.." view: "..PSS.set_of_peers_to_string(view))
		end
		--log:print(message.."("..job.position..") : "..me.id.." : "..TMAN.set_of_peers_to_string(view))
		
	end,
	
	-- ##############################################################
	-- ######## PSS FUNCTIONS ########
-- ##################################################################
	pss_selectPartner= function()
		if #PSS.view > 0 then
			if PSS.SEL == "rand" then 
				return math.random(#PSS.view) 
			end
			if PSS.SEL == "tail" then
				local ret_ind = -1 ; local ret_age = -1
				for i,p in pairs(PSS.view) do
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
	end,
	-- ##################################################################
	same_peer_but_different_ages = function(a,b)
		return a.peer.ip == b.peer.ip and a.peer.port == b.peer.port
	end,
	-- ##################################################################
	same_peer = function(a,b)
		return PSS.same_peer_but_different_ages(a,b) and a.age == b.age
	end,
	-- ##################################################################
	pss_selectToSend = function()
		
		--log:print("PSS selectToSend:  #me.payload: "..#me.payload)
		--for i=1, #me.payload do
		--	log:print("payload["..i.."]: "..me.payload[i])
		--end
		
		local toSend = {}
		-- insert own descriptor to "toSend" buffer
		table.insert(toSend,{peer={ip=job.me.ip,port=job.me.port},age=0,id=me.id,payload=me.payload})  --added payload
		
		if #PSS.view > 0 then 
			--shuffle and sort view by age
			PSS.view = misc.shuffle(PSS.view)
			local tmp_view = misc.dup(PSS.view)
			table.sort(tmp_view,function(a,b) return a.age < b.age end)
			
			for i=(#tmp_view-PSS.H+1),#tmp_view do
				local ind = -1
				for j=1,#PSS.view do
					if PSS.same_peer(tmp_view[i],PSS.view[j]) then 
						ind=j; 
						break 
					end
				end
				assert (not (ind == -1))
				elem = table.remove(PSS.view,ind)
				PSS.view[#PSS.view+1] = elem
			end
	
			for i=1,(PSS.exch-1) do
				toSend[#toSend+1]=PSS.view[i]
			end
		end
		return toSend
	end,
	-- ##################################################################
	pss_selectToKeep = function(received)
		
		
		--merge received and local view
		for j=1,#received do 
			PSS.view[#PSS.view+1] = received[j] 
		end
		-- add remove itself 
		table.remove(PSS.view,job.position)
		

		local i = 1	
		-- remove oldest age if the same node happens to be in the view twice
		while i < #PSS.view-1 do
			for j=i+1,#PSS.view do
				if PSS.same_peer_but_different_ages(PSS.view[i],PSS.view[j]) then
					if PSS.view[i].age < PSS.view[j].age then 
						table.remove(PSS.view,j) -- delete the oldest
					else
						table.remove(PSS.view,i)
					end
					i = i - 1 -- we need to retest for i in case there is one more duplicate
					break
				end
			end
			i = i + 1
		end
	
		-- remove the min(H,#view-c) oldest items from view
		local o = math.min(PSS.H,#PSS.view-PSS.c)
		while o > 0 do
			-- brute force -- remove the oldest
			local oldest_index = -1
			local oldest_age = -1
			for i=1,#PSS.view do 
				if oldest_age < PSS.view[i].age then
					oldest_age = PSS.view[i].age
					oldest_index = i
				end
			end
			assert (not (oldest_index == -1))
			table.remove(PSS.view,oldest_index)
			o = o - 1
		end
		
		-- remove the min(S,#view-c) head items from view
		o = math.min(PSS.S,#PSS.view-PSS.c)
		while o > 0 do
			table.remove(PSS.view,1) -- not optimal
			o = o - 1
		end
		--log:print("#pss.view= "..#PSS.view.." pss.c= "..PSS.c)
		-- in the case there still are too many peers in the view, remove at random
		while #PSS.view > PSS.c do 
			table.remove(PSS.view,math.random(#PSS.view)) 
		end
	--log:print("#pss.view= "..#PSS.view.." pss.c= "..PSS.c)
		assert (#PSS.view <= PSS.c)
		--log:print("PSS_SELECT_TO_KEEP ", ( misc.time() - selectToKeepStart ) )		
	end,
	
	ongoing_rpc=false,
	is_init = false,
	-- ##################################################################
	-- PSS PASSIVE THREAD
	pss_passive_thread = function(from,buffer)
		
		if PSS.ongoing_rpc or not PSS.is_init then
			return false
		end

		

		local ret = PSS.pss_selectToSend()
		PSS.pss_selectToKeep(buffer)
		--PSS.print_this_pss_view("passive_thread ("..job.position.."): after selectToKeep")
		--PSS.print_this_pss_view("PSS_VIEW", PSS.view)
		return ret
	end,
	-- #####################################################################
	pss_send_at_rpc = function(peer,pos,buf)
		local ok, r = rpc.acall(peer,{"PSS.pss_passive_thread", pos, buf},PSS.cycle_period/2)
		return ok,r
	end,
	-- ##################################################################
	-- PSS ACTIVE THREAD 
	pss_active_thread = function()
		
		PSS.ongoing_rpc=true
		local exchange_aborted=true
		local exchange_retry=2
		
		
		
		for i=1,exchange_retry do 
			partner_ind = PSS.pss_selectPartner()
			if not partner_ind then
				log:print("pss_active_thread: pss view is empty, no partner can be selected")
				return
			end
			partner = PSS.view[partner_ind]
			--log:print("TEST ()"..job.position..") removing destination node "..partner.id.." from the view")
			--PSS.print_this_pss_view("TEST PSS_before", PSS.view)
			table.remove(PSS.view,partner_ind)
			--PSS.print_this_pss_view("TEST PSS_VIEW after", PSS.view)
			
			buffer = PSS.pss_selectToSend()

			local rpcStart=misc.time()
			local ok, r = PSS.pss_send_at_rpc(partner.peer,job.position, buffer) 

			if ok then
				PSS.cycle_numb = PSS.cycle_numb+1
				
				local received = r[1]
				if received==false then
					
					events.sleep(math.random())	
					
				else
					exchange_aborted=false 
					PSS.pss_selectToKeep(received)
					--PSS.print_this_pss_view("PSS_VIEW",PSS.view)
					
				end
			else
				log:print("on peer ("..job.position..") peer "..partner.id.." did not respond -- removing it from the view")
				log:warning("PSS.pss_passive_thread RPC error:", r)
				table.remove(PSS.view,partner_ind)
			end		
			if exchange_aborted==false then break end
		end
	
		PSS.view_copy_lock:lock()
		local viewCopyLock = misc.time()
		PSS.view_copy = misc.dup(PSS.view)
		PSS.view_copy_lock:unlock()
		
		for _,v in ipairs(PSS.view) do
				v.age = v.age+1
		end
		
		-- sort view by id
		table.sort(PSS.view,function(a,b) return a.id < b.id end)
		
		PSS.print_this_pss_view("PSS_VIEW", PSS.view)
		
		-- now, allow to have an incoming passive thread request
		PSS.ongoing_rpc=false
	end,
	
	-- ###############################

	pss_getPeer = function()
		
		PSS.view_copy_lock:lock()
		local peer = PSS.view_copy[math.random(#PSS.view_copy)] 
		PSS.view_copy_lock:unlock()
		return peer
		
	end,
-- ##################################################################
	pss_init = function()
		
		
		local indexes = {}
		for i=1,#job.nodes do 
			indexes[#indexes+1]=i 
		end
		table.remove(indexes,job.position) --remove myself
		
		local selected_indexes = misc.random_pick(indexes,math.min(PSS.c,#indexes))	

		for i=1,#selected_indexes do
			log:print("PSS INIT: at ("..job.position..") selected index: "..selected_indexes[i])
		end	
		
		for i,v in pairs(selected_indexes) do
			   log:print("PSS INIT: node ("..job.position..") setting selected index: "..v.." to local pss view")
				local a_peer = job.nodes[v]
				--local hashed_index = compute_hash(tostring(a_peer.ip) ..":"..tostring(a_peer.port))
				local hashed_index = v
		 		--PSS.view[#PSS.view+1] = {peer=a_peer,age=math.random(PSS.c),id=hashed_index , payload={}}  -- aqui added payload
		 		PSS.view[#PSS.view+1] = {peer=a_peer,age=0,id=hashed_index , payload={}}  -- aqui added payload
		end
		-- sort view by id
		table.sort(PSS.view,function(a,b) return a.id < b.id end)
		
		PSS.view_copy = misc.dup(PSS.view)
		assert (#PSS.view == math.min(PSS.c,#indexes))
		
		PSS.print_this_pss_view("PSS_VIEW_INITIALIZED: ", PSS.view)
		PSS.is_init = true
		
		
	end,

	
	-- ##############################
	 set_parameters = function(run, view, cycle)

	PSS.running_time = run
	PSS.c = view
	PSS.exch = math.floor(view / 2 + 0.5)
	PSS.cycle_period = cycle
	log:print("RUNNING_TIME: "..PSS.running_time.."["..RUNNING_TIME.."]".." PSS_VIEW_SIZE: "..PSS.c.."["..PSS_VIEW_SIZE.."]".." PSS_SHUFFLE_SIZE: "..PSS.exch.."["..PSS_SHUFFLE_SIZE.."]".." PSS_SHUFFLE_PERIOD: "..PSS.cycle_period.."["..PSS_SHUFFLE_PERIOD.."]")
	
	end,
	
	
	 startPSS = function()
			-- set termination thread
			events.thread(function() events.sleep(PSS.running_time) log:print("TMAN TEST total cycles at ("..job.position..") "..me.id.." "..TMAN.t_cycle_numb) os.exit() end)
			-- init random number generator
			math.randomseed(job.position*os.time())
			-- wait for other nodes to start 
			events.sleep(3)
			-- desynchronize starting time nodes
			local desync_wait = (PSS.cycle_period * math.random())
			--log:print("waiting "..desync_wait.." seconds to desynchronize")
			events.sleep(desync_wait)
			-- initialize pss
			PSS.pss_init()
			events.sleep(5)
			-- periodic thread
			PSS_thread = events.periodic(PSS.cycle_period, PSS.pss_active_thread) 
	
	end,

}



-- ################################# END PSS #######################################
-- #################################################################################


-- ################################# TMAN #########################################
-- #################################################################################
TMAN = {
	
	t_view = {}, -- VIEW
	t_last_view = {}, -- LAST STATE/VIEW
	t_last_view_as_string = "", -- LAST STATE as string
	view_stable_info = false,
	view_stable_counter = 0,
	
	t_view_lock = events.lock(),
	ongoing_rpc = false,
	view_init = false,
	
	s = 5,   -- TMAN_VIEW_SIZE
	cycle_period = TMAN_SHUFFLE_PERIOD,
	t_cycle_numb = 0,
	rank_func,
	
	-- ##################################################################
	select_peer = function()
		-- the selection for TMAN has to order the nodes in the view and select the first node, according to the ranking function.
		--log:print("TMAN enter function select_peer")
			
		local ranked_view = TMAN.rank_view(me, TMAN.t_view)
		--log:print("TMAN passed TMAN.rank_view: "..#ranked_view)
		--if (ranked_view ) then
		--	log:print("TMAN ranked_view exists")
		--end
		
		if (ranked_view and #ranked_view >0) then
			--log:print("TMAN ranked_view and #ranked_view >0: "..ranked_view[1].id)
			return ranked_view[1]
		else
			--log:print("TMAN ranked_view and #ranked_view >0    == false")
			return false
		end
	end,
	-- ##################################################################
	init_t_view = function()
		-- maybe changed this to avoid duplicated choice from pss
		
		for i = 1, TMAN.s do 
			TMAN.t_view[i] = PSS.pss_getPeer()

		end
		TMAN.print_this_t_view("TMAN_VIEW_INIT_FROM_PSS", TMAN.t_view)
		--log:print("TMAN INIT END")
		TMAN.view_init = true	

		
	end,
	
	init_t_biased_view = function()
		
		log:print("TMAN INIT VIEW not from PSS")
		for i = 1, TMAN.s do 
			TMAN.t_view[i] = PSS.pss_getPeer()

		end
		--log:print("TMAN INIT END")
		TMAN.view_init = true	

		
	end,
	
	-- ##################################################################
	print_view = function(message)
		if message then 
			log:print(message) 
		end
		log:print("PSS_VIEW ("..job.position..") : "..me.id.." : "..PSS.set_of_peers_to_string(PSS.view))
	end,
	-- ##################################################################
	select_view_to_send = function(selected_peer)
		
		--log:print("TMAN select_view_to_send")
		-- make a copy of the PSS
		PSS.view_copy_lock:lock()		
		--log:print("TMAN select_view_to_send  dup")
		local pss_buffer = misc.dup(PSS.view_copy)
		PSS.view_copy_lock:unlock()
		--log:print("TMAN select_view_to_send end lock")
		-- merges tman and pss view
		--log:print("TMAN select_view_to_send merge ")
		local merged =  misc.merge(TMAN.t_view, pss_buffer)
		-- add myself to the merged buffer
		merged[#merged+1] = me
		-- remove duplicates and the destination from the buffer
		--log:print("TMAN select_view_to_send dup merged")
		TMAN.remove_dup(merged)
		--log:print("TMAN select_view_to_send remove node ")
		TMAN.remove_node(merged, selected_peer)
		
		--TMAN.print_this_t_view("TMAN merged view: ",merged)
		--log:print("TMAN END select_view_to_send")
		return merged	
	end,
	
	-- ##################################################################
	update_view_to_keep = function(received)
		log:print("TEST 1")
		TMAN.t_view_lock:lock()
		--log:print("TMAN_VIEW -  update to keep - before merge")
		--TMAN.print_this_t_view(TMAN.t_view)
		
		TMAN.t_view = misc.merge(received, TMAN.t_view)
		--log:print("TEST, is same view: "..TMAN.same_ids_view(received,TMAN.t_view))
		
		
		--log:print("TMAN_VIEW -  update to keep - after merge")
		--TMAN.print_this_t_view(TMAN.t_view)
		TMAN.remove_dup(TMAN.t_view)
		--log:print("TMAN_VIEW -  update to keep - after remove dup")
		--TMAN.print_this_t_view(TMAN.t_view)
		TMAN.t_view = TMAN.rank_view(me, TMAN.t_view)
		--TMAN.print_this_t_view("TMAN_VIEW -  update to keep - after rank ")
		
		TMAN.keep_first_n(TMAN.s,TMAN.t_view)
		
		--TMAN.print_this_t_view("TMAN_VIEW -  update to keep - after keep first ")
		
		-- keep view sorted by id after rank - useful for later checks
		table.sort(TMAN.t_view,function(a,b) return a.id < b.id end)
		
		TMAN.check_view_stability()
		
		TMAN.t_view_lock:unlock()
		
	
	end,
	-- ##################################################################
	check_view_stability = function()
	
		local tmp_t_view = {}
		-- problem:  last view is not ordered	
		log:print("TMAN stable check")
	
		--tmp_t_view = misc.dup(TMAN.t_view)
		--table.sort(tmp_t_view,function(a,b) return a.id < b.id end)
		
		--TMAN.print_this_t_view(TMAN.t_view)
		--TMAN.print_this_t_view("TEST :ordered copy TMAN_VIEW",tmp_t_view)
		
		if #TMAN.t_last_view == 0 then
			 log:print("TEST : last view is empty, #TMAN.t_last_view: "..#TMAN.t_last_view)
			 TMAN.t_last_view = TMAN.t_view
			 
			 log:print("TEST : last view is empty, #TMAN.t_last_view: "..job.position.." : "..me.id.." #TMAN.t_last_view == 0 ")
			 --TMAN.print_this_t_view("TEST TMAN last view now  ", tmp_t_view)

		else
			--TMAN.print_this_t_view("TEST : current TMAN_VIEW : ", TMAN.t_view)
			--TMAN.print_this_t_view("TEST : current LAST VIEW : ", TMAN.t_last_view)
			

			if TMAN.same_view(TMAN.t_last_view, TMAN.t_view)==true then
				 TMAN.view_stable_counter = TMAN.view_stable_counter +1
				 log:print("TEST :TMAN at ("..job.position..") "..me.id.." equal views")
				
				   
			else
				 log:print("TEST :TMAN at ("..job.position..") "..me.id.." NOT equal views ")
				
				 TMAN.t_last_view = TMAN.t_view
				 TMAN.view_stable_counter = 0
				 TMAN.view_stable_info=false
				 --TMAN.print_this_t_view("TEST : NOW current last view at ("..job.position..") "..me.id.." is: ", TMAN.t_last_view)
				 
			end
			log:print("TMAN TEST : counter at ("..job.position..") "..me.id.." is: "..TMAN.view_stable_counter.." total cycles: "..TMAN.t_cycle_numb)
		end
		
		if TMAN.view_stable_counter>10 and TMAN.view_stable_info==false then
			log:print("TEST VIEW stable true (>10 cycles) at node "..job.position.." "..me.id.." after "..TMAN.t_cycle_numb.." cycles")
			TMAN.view_stable_info=true


		end	 
	end,
	-- ##################################################################
	same_view = function(v1,v2)
		-- in this case v1 and v2 must be previously ordered by id
		log:print("TEST 2")
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
	end,
	
	-- ##################################################################
	same_ids_view = function(v1,v2)
		
		--log:print("TEST 2")
		if type(v1) ~= "table" then
			--log:print("TEST 3")
		    return e1 == e2
		elseif type(v2) == "table" then
			--log:print("TEST 4")
				for i=1,#v1 do
					local found = false
					--log:print("TEST 5 v1: "..v1[i].id)
						for y=1,#v2 do
							--log:print("TEST v1 and v2 are: "..v1[i].id..v2.id)
						  	--log:print("TEST 6 v2 : "..v2[y].id)
							if v1[i].id == v2[y].id then
							    found = true
						  		 -- log:print("TEST found ")

							end
						end
						if found==false then
							return "false"
						end	
				end
			return "true"
		end	
	end,
	-- ##################################################################
	same_id = function(n1,n2)
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
	end,
	
	-- ##################################################################
	keep_first_n = function(n, set)
		log:print("TMAN before reduce view size to "..n.." set size: "..#set)
		for i = #set, n+1, -1 do
			table.remove(set,i)
		end
		log:print("TMAN after reduce view size to "..n.." set size: "..#set)
	end,
	--###################################################################
	set_distance_function = function(f)
		TMAN.rank_func = f
	end,
	-- ##################################################################
	dist_function = function(p1, p2)
		
		dist = TMAN.rank_func(p1, p2)
		return dist
		
	end,
	-- ##################################################################
	rank_view = function(node, view)
		
		local distances = {}
		local ranked = {}
		--log:print("view #: "..#view)
		--TMAN.print_detailed_view()
		
		for i,v in ipairs(view) do
			local pl = TMAN.get_payload(v)
				
			local dist = TMAN.dist_function(TMAN.get_payload(node), TMAN.get_payload(v))
	
			log:print("TMAN distance ("..node.id..","..v.id..") is "..dist)
			distances[#distances+1] = {distance= dist, node=v}
			
		end
	
		table.sort(distances, function(a,b) return a.distance < b.distance end)
		

		local l_thread =""
		if TMAN.ongoing_rpc then
			l_thread = "ACTIVE THREAD"
		else
			l_thread = "PASSIVE THREAD"
		end

		ret=""
		local cumul_distance =0;
		
		for i,v in ipairs(distances) do
			log:print("TMAN_VIEW "..l_thread.." ranking["..i.."]: node ("..job.position..") "..node.id.." to "..v.node.id.." distance "..v.distance)
			ret = ret.." "..v.node.id.." : ["..v.distance.."] "	
			cumul_distance = cumul_distance+v.distance
		end
		
		log:print("bla TMAN_VIEW ranking cumul: "..cumul_distance)
		log:print("bla TMAN_VIEW ranking "..l_thread.." ranked at node: ("..job.position..") id: "..me.id.." cycle: "..TMAN.t_cycle_numb.." avg dist: "..cumul_distance/#distances.." view - "..ret)
	
		for i,v in ipairs(distances) do
			ranked[#ranked+1] = v.node
		end
		
		
	
		return ranked

	end,

	-- ##################################################################
	set_of_peers_to_string = function(v)
		ret = ""; 
		for i=1,#v do	
			ret = ret..v[i].id.." "	
			--ret = ret..v[i].id.." " --"#payload: "..#v[i].payload   --aqui
		end
		return ret
	end,
	

		
	-- ##################################################################
	print_view = function(message)
		if message then 
			log:print(message) 
		end
		log:print("TMAN_VIEW ("..job.position..") : "..me.id.." : "..TMAN.set_of_peers_to_string(TMAN.t_view))
	end,
	-- ##################################################################
	print_detailed_view = function(message)
		if message then 
			log:print(message) 
		end
		log:print("TMAN detailed VIEW ("..job.position..") : "..me.id.." : "..TMAN.set_of_detailed_peers_to_string(TMAN.t_view))
	end,
	-- ##################################################################
	set_of_detailed_peers_to_string = function(v)
		ret = "";
		local pl = "" 
		for i=1,#v do	
			ret = ret..v[i].id.." "..v[i].peer.ip.." "..v[i].peer.port.." "
			log:print("node: "..v[i].id.." #v[i].payload: "..#v[i].payload)
		
		end
		return ret
	end,
	
	-- ##################################################################
	print_this_t_view = function(message, view)
		--log:print(message.." at node: ("..job.position..") id: "..me.id.." cycle: "..TMAN.t_cycle_numb.." view: "..TMAN.set_of_peers_to_string(view))
		if message then 
			log:print(message.." at node: ("..job.position..") id: "..me.id.." cycle: "..TMAN.t_cycle_numb.." view: "..TMAN.set_of_peers_to_string(view))
		else
			log:print("TMAN_VIEW at node: ("..job.position..") id: "..me.id.." cycle: "..TMAN.t_cycle_numb.." view: "..TMAN.set_of_peers_to_string(view))
		end
			
	end,
	-- ##################################################################
	get_payload = function(node)
		local payl = {}
		if type(node) == "table" then 
			--log:print("TMAN get payload: node "..node.id.." is a table #node:"..#node.payload)
			payl = node.payload 
		else 
			--log:print("TMAN get payload: node is NOT a table")
			payl = node 
		end
		return payl
	end,

	-- ##################################################################
	remove_failed_node = function(node)
		
		TMAN.t_view_lock:lock()
		TMAN.remove_node(TMAN.t_man, node)
		TMAN.t_view_lock:unlock()
		
	end,
	-- ##################################################################
	remove_node  = function(t, node)
		
		local j = 1
		for i = 1, #t do
			if TMAN.same_node(t[j],node) then 
				table.remove(t, j)
			else j = j+1 
			end
		end
		
	end,
	-- ##################################################################
	remove_dup = function(set)
		
		for i,v in ipairs(set) do
			local j = i+1
			while(j <= #set and #set > 0) do
				if v.id == set[j].id then
					table.remove(set,j)
				else j = j + 1
				end
			end
		end
		
	end,
	-- ##################################################################
	same_node = function(n1,n2)
		
		local peer_first
		if n1.peer then 
			peer_first = n1.peer 
			else peer_first = n1 
		end
		local peer_second
		if n2.peer then 
			peer_second = n2.peer 
			else peer_second = n2 
		end
		return peer_first.port == peer_second.port and peer_first.ip == peer_second.ip
	end,
	
	-- ##################################################################
	contains = function (set, elem)
	  for i = 1,#set do
	    if set[i] == elem then 
			--log:print("element: "..set[i].." equals to "..elem)
			return true 
		end
	  end
	  return false
	end,
	
	-- ##################################################################
	get_intersection = function(set_a, set_b)
		local result = {}
		
		--log:print("#set_a #set_b: "..#set_a.." : "..#set_b)
		
  	  	for i = 1,#set_a do
			--log:print("checking element: "..set_a[i])
  	    	if TMAN.contains(set_b, set_a[i]) then 
				result[#result+1]=set_a[i] 
			end
  	  	end	

		return result	
	end,
	-- ##################################################################
	
	-- #################### ACTIVE/PASSIVE THREADS ########################## 
	t_active_thread = function()
		TMAN.ongoing_rpc=true
		
		--log:print("TMAN t_active_thread")
		--TMAN.print_this_t_view(TMAN.t_view)
		for i=1, #me.payload do
			log:print("TMAN my topics: "..me.payload[i])
	    end
		
		
		local selected_peer = TMAN.select_peer()  -- order and selects the first 
		
		--log:print("TMAN selected_peer: "..selected_peer.id)
		if not selected_peer then 
			log:print("TMAN active_thread: no selected_peer selected") 
			return 
			--else
		--	lo-g:print("TMAN selected: ")
		end
		
		local buffer = TMAN.select_view_to_send(selected_peer)	-- selects the view to send
	
		local try = 0
		local trials = 3 

		local status, reply = rpc.acall(selected_peer.peer, {'TMAN.t_passive_thread',buffer,me}) 
		
		while not status do
			try = try + 1
			if try <= trials then 
			    retry_time = math.random(try * 3, try * 6)
				log:print("TMAN.active_thread: got no response from:"..selected_peer.id.. ": "..tostring(reply).." => trying again in"..retry_time.." seconds")
				events.sleep(retry_time)
				status, reply = rpc.acall(selected_peer.peer,{'TMAN.t_passive_thread',buffer,me})
			else
				log:print("TMAN.active_thread: got no response from:"..destination.id.. ": "..tostring(reply).." => removing it from view")
				TMAN.remove_failed_node(selected_peer)
				break
			end
		end	
		
		
		if status then
			TMAN.t_cycle_numb = TMAN.t_cycle_numb+1
			
			local received = reply[1]
			--local received = reply
			if received==false then
					log:print("TMAN didnt receive a reply from remote node")
			else
				--log:print("TMAN received a reply from remote node")
				--TMAN.print_this_t_view(TMAN.t_view)
				--TMAN.print_this_t_view("TMAN received view: ",received)
				--merged = misc.merge(received, TMAN.t_view)
				--TMAN.print_this_t_view("TMAN merged view: ",buffer)
				TMAN.update_view_to_keep(received)  -- should probably include here the function to rank, variables to calculate this rank. etc.
				
		end
		end
	
	TMAN.print_this_t_view("TMAN_VIEW", TMAN.t_view)
	
	TMAN.ongoing_rpc=false
	end,
	-- ##################################################################
	t_passive_thread = function(received, sender)
		
		if TMAN.ongoing_rpc then
			--log:print("TMAN ongoing rpc true")
			return false
		end
		
		--TMAN.t_cycle_numb = TMAN.t_cycle_numb+1
		
		--TMAN.print_this_t_view("TMAN passive thread: received:  ",received)
		local buffer_to_send = TMAN.select_view_to_send(sender)
		--TMAN.print_this_t_view("TMAN passive thread: buffer_to_send:  ",buffer_to_send)
		--TMAN.print_this_t_view(TMAN.t_view);
		--local merged = misc.merge(received, TMAN.t_view)
		-- must rank after receiving !!! 
		TMAN.update_view_to_keep(received);  -- not yet implemented. 
		
		return buffer_to_send
	end,
	
	-- ##################################################################
	start_tman = function()
		
		--TMAN.set_topics(4,4, true, 10) -- used for testing	
		events.sleep(30)
		TMAN.init_t_view()

		local desync_wait = (TMAN.cycle_period * math.random())
		--log:print("waiting "..desync_wait.." seconds to desynchronize nodes")
		events.sleep(desync_wait)

		events.sleep(5)
		-- periodic thread of tman
		TMAN_thread = events.periodic(TMAN.cycle_period, TMAN.t_active_thread) 
	
	end,
	
	-- ##################################################################
	set_node_representation = function(node_rep)

		for i=1, #node_rep do
	    	 me.payload[#me.payload+1] = node_rep[i]
			 log:print("TMAN - node ("..job.position..") "..me.id.." setting node representation (payload): "..node_rep[i])
	 	end
	end,
	-- ##################################################################
	get_node_representation = function()
		
		 return me.payload  
	  
	end,
	-- ##################################################################
	get_node_representation_as_string = function()
	
	  payload_string =""
	  --log:print(" TEST #me.payload : "..#me.payload )
	  for i=1,#me.payload do
		  payload_string = payload_string..me.payload[i].." "
	  end
	  return payload_string
	 
		
	end,
	
	-- ##################################################################
	set_parameters = function(view_size, cycle_per)
		
		TMAN.s = view_size
		TMAN.cycle_period = cycle_per
		
	end,
		

}



-- ################################# END TMAN #######################################

-- #########################################################################################
-- #################################### APP #############################################
function select_topics()
	-- selects from 'lower' to 'upper' random values from the "topics" table for each node.
	-- returns a table with the selected topics
	
	local topics = {"Agriculture", "Health","Aid","Infrastructure","Climate","Poverty","Economy","Education","Energy","Mining","Science","Technology","Environment","Development","Debt" ,"Protection","Labor","Finances", "Trade","Gender", "Urban"}
	local selected = {}
	
	local lower = 4
	local upper = 4 
	
	local number = math.random(lower, upper)
	for i=1, number do
		local index = math.random(#topics)
		selected[#selected+1] = topics[index]
	end
		
 	return selected
	
end

function select_topics_according_to_id()
	-- returns specific topics according to the id of the node. 
	-- this function is used to test the clustering
	
	local topics = {"Agriculture", "Health","Aid","Infrastructure","Climate","Poverty","Economy","Education","Energy","Mining","Science","Technology","Environment","Development","Debt" ,"Protection","Labor","Finances", "Trade","Gender"}
	local selected = {}
	local myposition = job.position
	log:print("NODE ID: (payload selection) : "..myposition)
	
	--local T_nodes = job.nodes
	
	--local index = T_nodes % #topics
	
	local interval = myposition % 4
	if interval == 0 then
		for i=1, 5 do
		  log:print("(payload selected:"..topics[i])
		  selected[#selected+1] = topics[i]
		end
	end
	if interval == 1 then
		for i=6, 10 do
		  log:print("(payload selected:"..topics[i])
		  selected[#selected+1] = topics[i]
		end
	end
	if interval == 2 then
		for i=11, 15 do
		  log:print("(payload selected:"..topics[i])
		  selected[#selected+1] = topics[i]
		end
	end
	if interval == 3 then
		for i=16, 20 do
		  log:print("(payload selected:"..topics[i])
		  selected[#selected+1] = topics[i]
		end
	end
	
	
--	if myposition <=10 then 
--		log:print("myposition <=10 ")
--		for i=1, 5 do
--		  log:print("(payload selected:"..topics[i])
--		  selected[#selected+1] = topics[i]
--		end
--	end
--	if myposition > 10 and myposition < 20 then 
--		log:print("myposition > 10 and myposition < 20")
--		for i=5, 9 do
--			log:print("(payload selected:"..topics[i])
--			  selected[#selected+1] = topics[i]
--		end
--	end
--	if myposition > 20 and myposition <= 30 then 
--		log:print("myposition > 20 and myposition <= 30 ")
--		for i=9, 13 do
--			log:print("(payload selected:"..topics[i])
--		 	 selected[#selected+1] = topics[i]
--		end
--	end
--	if myposition> 30 and myposition <= 40 then 
--		log:print("myposition> 30 and myposition <= 40")
--		for i=13, 17 do
--			log:print("(payload selected:"..topics[i])
--		  	selected[#selected+1] = topics[i]
--		end
--	end
--	if myposition > 40 and myposition <= 50 then 
--		log:print("myposition > 40 and myposition <= 50")
--		for i=17, 20 do
--			log:print("(payload selected:"..topics[i])
--		  	selected[#selected+1] = topics[i]
--		end
--	end
 	return selected
	
end

function jaccard_distance(a, b)
	--log:print("jaccard distance invoked")
	--if type(a) == "table" and  type(v2) == "table" then
		--log:print("a and b are tables ")
		if #a==0 and #b==0 then  -- if sets are empty similarity is considered 1.
			return 0
		end
		
		local intersec = TMAN.get_intersection(a,b)
		--log:print("jaccard interesection: "..intersec)
		local union = misc.merge(a,b)
		--log:print("jaccard union: "..union)
		return 1-(#intersec/#union)
		--else
		--log:print("a and b are not tables ")
		--return 0
		--end
	 
end

-- ###############################
function main( )
	
		PSS.set_parameters(300, 6, 3)  -- running time, view_size , cycle period
		PSS.startPSS()
		events.sleep(10)
		TMAN.set_parameters(4, 5)  -- tman view size. cycle period
		
		TMAN.set_distance_function(jaccard_distance)
		--TMAN.set_node_representation(select_topics())
		TMAN.set_node_representation(select_topics_according_to_id())
		
		
		
		TMAN.start_tman()




end		
events.thread(main)  
events.loop()

-- ###############################
