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
