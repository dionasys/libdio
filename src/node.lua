--#################### CLASS NODE ###################################
local Node = {}
Node.__index = Node 

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
		local resultHexa = string.sub(crypto.evp.new("sha1"):digest(tostring(job.me.ip)..":"..tostring(job.me.port)), 1, r)
		local resultNumb = tonumber(resultHexa,16)
		self.id = resultNumb
end


function Node.compute_ID(self, bits, ip , port)
			local r = 0
			if bits%4 == 0 then
				r = bits/4
			else
				r= bits/4 + 1
			end
			local resultHexa = string.sub(crypto.evp.new("sha1"):digest(tostring(ip)..":"..tostring(port)), 1, r)
			local resultNumb = tonumber(resultHexa,16)
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
	self.payload= payload
	local pl_string = ""
	for i=1, #self.payload do
		pl_string = pl_string.." "..self.payload[i]
	end
end

function Node.getPayload(self)
	return self.payload
end

function Node.getPayloadSize(self)
	return #self.payload
end

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
------------------------ END OF CLASS NODES --------------------------

