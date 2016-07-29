require"splay.base"
rpc = require"splay.rpc"
rpc.server(job.me.port)
crypto = require "crypto"

-- testing function serialization in LUA 
function myFunc1(self, a, b)
	log:print("DEBUG: at position "..job.position.." func1 invoked")
	local c = a + b 
	return c
end 

function myFunc2(self, a, b)
	log:print("DEBUG: at position "..job.position.." func2 invoked")
	local c = a - b 
	return c
end 


function compute_hash(o)
	return string.sub(crypto.evp.new("sha1"):digest(o), 1, 32)
	--return tonumber(crypto.evp.new("sha1"):digest(o), 16)
end

function receive(sender, receivedFunc)
        log:print("DEBUG: at position "..job.position.." received an RPC from node "..sender)

        	if receivedFunc == nil then
       		log:print("DEBUG: at position "..job.position.." receivedFunc is nil")
        	else
	        	log:print("DEBUG: at position "..job.position.." receivedFunc is NOT nil")
				log:print("DEBUG: at position "..job.position.." receivedFunc is: "..receivedFunc.." receivedFunc hash: "..tostring(compute_hash(receivedFunc)))
				
				--log:print("DEBUG: at position "..job.position.." eval at destination: "..loadstring(receivedFunc)(self, 5,3))
				local newFunction = assert(loadstring(receivedFunc))
				log:print("DEBUG: at position "..job.position.." eval at destination: "..tostring(newFunction(self,5,3)))
				log:print("DEBUG: at position "..job.position.." newFunction hashed: " ..tostring(compute_hash(string.dump(newFunction))))
        	end

end

function main()

        local nodes = job.get_live_nodes() 
        log:print("DEBUG: I'm "..job.me.ip..":"..job.me.port.." my position is: "..job.position)
        local destinationPosition =  math.random(1,#nodes)
        	local func1String = string.dump(myFunc1)
        	local func2String = string.dump(myFunc2)
        	log:print("DEBUG: at position "..job.position.." function 1 string: " ..tostring(func1String))
        	log:print("DEBUG: at position "..job.position.." function 1 hashed: " ..tostring(compute_hash(func1String)))
        	log:print("DEBUG: at position "..job.position.." function 2 string: " ..tostring(func2String))
			log:print("DEBUG: at position "..job.position.." function 2 hashed: " ..tostring(compute_hash(func2String)))
			
			local funcToSend = string.dump(myFunc2)
			
			log:print("DEBUG: at position "..job.position.." dumped function: " ..funcToSend.." hash: "..tostring(compute_hash(funcToSend) ) )
			log:print("DEBUG: at position "..job.position.." eval at origin: "..loadstring(funcToSend)(self, 6,3))
			

        events.sleep(5)
        --log:print("DEBUG: at position "..job.position.." sending msg to "..nodes[1].ip..":"..nodes[1].port.." msg: "..tostring(funcToSend))
        log:print("DEBUG: at position "..job.position.." sending msg to "..destinationPosition.." msg: "..tostring(funcToSend))
        rpc.call(nodes[destinationPosition], {"receive", job.position, funcToSend})

        events.thread(function() log:print("End") end)
        events.sleep(5)
        os.exit()
end
events.thread(main)
events.loop()

