-- myPSSExample: simple example of PSS deployment

 
function main()		
		
		
		local node = Node.new(job.me) 
		log:print("APP START - node: "..job.position.." id: "..node:getID().." ip/port: ["..node:getIP()..":"..node:getPort().."]")

	-- setting PSS 
	-- parameters: c (view size) , h (healing), s (swappig), fanout, cyclePeriod, peer_selection_policy , me
		local pss = PSS.new(5, 1, 1, 4, 5, "tail", node)
		
		
		Coordinator.addProtocol("pss1", pss)

	--launching the protocol
		Coordinator.showProtocols()
		Coordinator.launch(node, 300, 0)  --parameters: local node ref, running time in seconds, delay to start the protocol
		

end

events.thread(main)
events.loop()
