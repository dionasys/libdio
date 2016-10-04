'''Global functions: These are the pre-defined distance functions and the functions used to set the correct payload (the data structure used by the selected distance function), according to the select distance func.'''

----------------------------------------------------

function id_based_ring_distance(self, a, b)
	local aux_parameters = self:get_distFunc_extraParams()
	if a[1]==nil or b[1]==nil then
		log:warning("DIST at node: "..job.position.." id_based_ring_distance: self either a[1]==nil or b[1]==nil")
		return 2^aux_parameters[1]-1
	end
	local k1 = a[1]
	local k2 = b[1]
			
	local distance = 0

	if k1 < k2 then 
		distance =  k2 - k1 
	else 
		distance =  2^aux_parameters[1] - k1 + k2 
	end
	return distance
end

----------------------------------------------------
function jaccard_distance(self, a, b)

	if self==nil then
		log:print("at node: "..job.position.." jaccard self dist_function nill: ")
	else
		log:print("at node: "..job.position.." jaccard self dist_function not nill: "..tostring(self))
	end

	if #a==0 and #b==0 then
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
