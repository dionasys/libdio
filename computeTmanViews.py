import sys, os, string, datetime, time, statistics
# note: statistics only exists on python > v.3 
'''
Script to evaluate the convergence of a Structure
usage:  python <script_name> <number_of_job>
'''

def listDir(currdir):
	fileList=[]
	for file in os.listdir(currdir):
		if(file.endswith(".dat")):
			fileList.append(file)
	return(fileList)

def getViewFromStringWithAge(viewString):
	auxView = []
	aux1 = viewString.replace('(', ' ')
	aux2 = aux1.replace(')', ' ')
	viewStringSplit = aux2.split()
	index = 1
	while index < len(viewStringSplit)-1:
		item = []
		item.append(viewStringSplit[index])
		item.append(viewStringSplit[index+1])
		index = index + 2
		auxView.append(item)
	return auxView

def getViewFromStringWithOutAge(viewString):
	auxView = []
	aux1 = viewString.replace('(', ' ')
	aux2 = aux1.replace(')', ' ')
	viewStringSplit = aux2.split()
	index = 1
	while index < len(viewStringSplit)-1:
		peerId = int(viewStringSplit[index])
		auxView.append(peerId)
		index = index + 2
	return auxView

def getViewAtLine(lineAux):
	viewIndex1 = lineAux.find('[ ')
	viewIndex2 = lineAux.find(' ]')
	viewString = lineAux[viewIndex1:viewIndex2+2]
	currentViewAtLine = getViewFromStringWithOutAge(viewString)
	return currentViewAtLine
	
def getListOfNodes(listofFiles, filenameIdentifier):

	expListOfNodes = []
	for fileName in listofFiles:
		if fileName.startswith(filenameIdentifier):
			nodeName = fileName.split('.')[0].split('_')
			nodeId = int(nodeName[len(nodeName)-1]) 
			expListOfNodes.append(nodeId)
	expListOfNodes.sort()
	print('List of nodes in this experiment: ' + str((expListOfNodes)) )
	return(expListOfNodes)

def getTimeInSeconds(timeString):
	x = time.strptime(timeString.split('.')[0],'%H:%M:%S')
	seconds = datetime.timedelta(hours=x.tm_hour,minutes=x.tm_min,seconds=x.tm_sec).total_seconds()
	return seconds

def getFixedDataFromFile(fileName, gossipCycle):
	'''in this case there is a fixing in the time to syncronize the events based on the cycle period
		returns a list such : [['nodeid', 'cycle', currentTime, [view List]]
	'''
	allFileData = []
	currentFile = open(source_dir + fileName, 'r')
	currentLine = 0
	startTime = 0
	
	lastTime = 0
	lastCycle = 0 

	try:
		for line in currentFile:			
			currentLine=currentLine+1
			viewAtLine = getViewAtLine(line)
			lineSplit = line.split() 
			nodeId =  lineSplit[8]
			cycle = lineSplit[10] 
			#print(str(isinstance(lineSplit[0], basestring)))
			lineTime = getTimeInSeconds(lineSplit[0])
			#print(lineTime)
			if currentLine == 1:
				startTime = lineTime
				currentTime = 0
				lastTime = currentTime
			else: 
				#currentTime = lineTime - startTime
				auxtime = lineTime - startTime
				if auxtime % gossipCycle == 0:
					#if current time happens at exact gossip cycles, nothing to fix
					#print('auxtime %  gossipCycle: ' + str(auxtime%gossipCycle))
					currentTime = auxtime
				else:
					#if current time happens at out of phase with gossip cycles, must be fixed
					#print('auxtime %  gossipCycle: ' + str(auxtime%gossipCycle))
					currentTime = auxtime + (gossipCycle - (auxtime%gossipCycle))
				#print('cycle: ' + str(cycle) + ' lastCycle: ' + str(lastCycle))
				#print('currentTime: ' + str(currentTime) + ' lastTime: ' + str(lastTime))
				
				jumpedCycles = (currentTime - lastTime)/gossipCycle
				#print('calc jumped: ' + str(jumpedCycles))
				if jumpedCycles>1:
					#print('jumped: ' + str(jumpedCycles-1))
					for i in range(1,int(jumpedCycles)):
						#print(i)
						# add the number of lines missing according to the number of jumps
						linesData = []
						linesData.append(nodeId) 
						linesData.append(int(lastCycle) + i)
						linesData.append(int(lastTime) + (i*gossipCycle))
						linesData.append([]) 
						#print('fixing data: ') 
						#print(linesData) 
						#print(linesData) 
						allFileData.append(linesData)
					lastCycle = int(lastCycle) + int(jumpedCycles)-1
					lastTime = int(lastTime) + ((int(jumpedCycles)-1)*gossipCycle)
			#print('current cycle: ' + str(cycle) + ' last cycle: ' + str(lastCycle))
			#print('current time: ' + str(currentTime) + ' last time: ' + str(lastTime))

			linesData = []
			linesData.append(nodeId) 
			linesData.append(cycle) 
			linesData.append(currentTime)
			linesData.append(viewAtLine) 
			#print(linesData) 
			allFileData.append(linesData)
		
			lastTime = currentTime
			lastCycle = cycle
	finally:
		currentFile.close
	return allFileData

#def getExactDataFromFile(fileName):
#	'''this method gets the time as it happens in the log. 
#		by counting the difference between the start time and the time that events happened. 
#		no fixing is made. the drawback of this method is some delays can happen and the data 
#		is logged few seconds later or before.
#		returns a list such : [['nodeid', 'cycle', currentTime, [view List]]
#	''' 
#	allFileData = []
#	currentFile = open(source_dir + fileName, 'r')
#	currentLine = 0
#	startTime = 0

#	try:
#		for line in currentFile:			
#			currentLine=currentLine+1
#			viewAtLine = getViewAtLine(line)
#			lineSplit = line.split() 
#			nodeId =  lineSplit[8]
#			cycle = lineSplit[10] 
#			lineTime = getTimeInSeconds(lineSplit[0])
#			if currentLine == 1:
#				startTime = lineTime
#				currentTime = 0
#			else: 
#				currentTime = lineTime - startTime

#			linesData = []
#			linesData.append(nodeId) 
#			#linesData.append(cycle) # it turns out that the cycle information is not that important if time is handled.
#			linesData.append(currentTime)
#			linesData.append(viewAtLine)  
#			allFileData.append(linesData)
#	finally:
#		currentFile.close
#	return allFileData

def getDataFromAllLogFiles(listofFiles, filenameIdentifier, gossipPeriod):
	dataFromAllFiles = []
	for fileName in listofFiles:
		if fileName.startswith(filenameIdentifier):
			#name = fileName.split('.')[0].split('_')  # this two lines would useful only if we need to id of the nodes before parsing the content of the file
			#nodeId = int(name[len(name)-1]) 
			
			# parsedDataFromFile = getExactDataFromFile(fileName)
			parsedDataFromFile = getFixedDataFromFile(fileName, gossipPeriod)
			dataFromAllFiles.append(parsedDataFromFile)
			
	return(dataFromAllFiles)
	
def saveCumulatedScoresToFile(myScoreDic, outDir, fileName): 

	filename = outDir + fileName
	os.makedirs(os.path.dirname(filename), exist_ok=True)
	with open(filename, "w") as myOutputFile:
		myOutputFile.write('time - cumul- total_nodes - mean - pvariance - pstdev - mode \n')
		for k,v in sorted(cumulatedScores.items()):	
			#if v['nodes'] > 2 and v['cumul'] > 0:
			myOutputFile.write(str(k) + ' ' + str(v['cumul']) + ' ' + str(v['nodes']) + ' ' + str(statistics.mean(v['values'])) + ' ' + str(statistics.variance(v['values'])) + ' ' + str(statistics.stdev(v['values'])) + '\n' )
	
	
	myOutputFile.close()



#############################################################################	
def computeIdealView(listOfAllNodes, distFunction, viewSize, mbitSpace):
	eachRankedNodes = []
	allRankedNodes = []
	for node in listOfAllNodes:
		toRank = list(listOfAllNodes)
		toRank.remove(node)
		rankedNodes = rankNode(node, toRank, distFunction, viewSize, mbitSpace)
		allRankedNodes.append([node, rankedNodes])
		
	return(allRankedNodes)

def rankNode(me, listToRank, distFunction, viewSize, mbitSpace):
	rankedDistances = []
	for eachNode in listToRank:
		distance = distFunction(me, eachNode, mbitSpace)
		currentNode = [eachNode, distance]
		rankedDistances.append(currentNode)
		
	rankedDistances=list(sorted(rankedDistances, key=getKey))
	return(cropRankedListOfDistances(rankedDistances, viewSize))

def cropRankedListOfDistances(rankedDistances, viewSize):
	croplist = list(rankedDistances[:viewSize])
	return (croplist)

def getKey(item):
	#this function is used only to help to sort another list of lists, to sort all the sublists by the second value of the lists
	return item[1]

def clockwise_id_distance(node1, node2, mbitSpace):
	if node1 < node2: 
		dist=node2-node1 
	else:
		dist=(2**mbitSpace)-node1+node2 
	return dist 
#############################################################################

def getListOfTimesLogged(myParsedData):
	# returns a list with all seconds where there was some logs
	print(getTimeStats(myParsedData))

def getTimeStats(myParsedData):
	timeStats = {}
	fullTimeList = []
	for eachLine in myParsedData:
		for eachmoment in eachLine:
			fullTimeList.append(eachmoment[1])
	for i in fullTimeList:
		timeStats[i] = timeStats.get(i, 0)+1
	return timeStats
	
def printBehaviorPerNode(mylistOfNodes, myParsedData):
	#print behavior of all nodes, separated by nodes
	for eachnode in mylistOfNodes:
		for each in myParsedData:
			if each[0][0] == str(eachnode):
				print('Node: ' + str(eachnode))
				print(each)

def printBehaviorPerTime(mylistOfNodes, myParsedData):
	#print behavior of all nodes, separated by nodes
	#for eachnode in mylistOfNodes:
	for each in myParsedData:
	#	if each[0][0] == str(eachnode):
	#	print('Node: ' + str(eachnode))
		print(each)

def getBehaviorOfNode(node, myParsedData):
	'''  
		get the behavior of a single node, for all the times available
		ex: [ ['1', '0', 0, [2, 3, 4, 6]], ['1', '1', 5.0, [2, 3, 4, 5]], ['nodeid', 'cycle', time, [view]]...] 
	'''
	for each in myParsedData:
		if each[0][0] == str(node):
			return(each)

def getBehaviorOfNodePerTime(node, myParsedData):
	'''get the behavior of a single node, ordered per time logged 
		the returned value is a list of lists, and each element corresponds to a time where there was something logged and the view at this moment
		ex: [ [0, [2, 3, 4, 6]],  [5.0, [2, 3, 4, 5]],  [10.0, [2, 3, 4, 5]], [15.0, [2, 3, 4, 5]]....]
	'''
	listToRet = []
	for eachNode in myParsedData:
		#print('node: ' + str(eachNode))
		#print(eachNode[0][0])
		if eachNode[0][0] == str(node):
			for eachTime in eachNode:
				listLine = [eachTime[2], eachTime[3]]
				listToRet.append(listLine)
	#print(listToRet)
	return(listToRet)

def getIdealViewOfNode(node, allIdealViews):
	for eachnode in allIdealViews:
	# eachnode in idealviews is [nodeID, [[closest_neighbor , distance], [next_closest_neighbor, distance]]]
		if eachnode[0] == node:
			return(eachnode[1])

	return None 
#########################################################################################
def rateNodeBehaviorByTime(idealView, behavior):
	
	idealViewValuesOnly = []
	nodeBehaviorRated = []
	
	# first gets only the values of an idealView (which consists of multiples [neighbor, distance] pairs)
	for eachValue in idealView: 
		idealViewValuesOnly.append(eachValue[0])

	# for each time rates the view 	
	for eachTime in behavior:
		eachTime[1].sort()	
		rate = rateView(idealViewValuesOnly, eachTime[1])
		#print('at time: ' + str(eachTime[0]) + ' the view was: ' + str(eachTime[1]) + ' ideal view: ' + str(idealViewValuesOnly) + ' rate: ' + str(rate) )
		nodeBehaviorRated.append([eachTime[0], eachTime[1], rate])
	
	return(nodeBehaviorRated)

def rateView(ideal, currentView):
	if len(ideal)==0:
		print('error: found ideal view size zero, while calculating the view rate at function rateView')
		sys.exit()
	found=0	
	#TODO: can be implemented by means of sets and seems to be more elegant and error prone too. improve it. 
	if len(currentView) > 0:
		for item in ideal:
			#print('checking item ' + str(item))
			if item in currentView:
				found = found + 1
	else:
		return(0)
	return(100/float(len(ideal))*float(found))

#########################################################################################
def getShortestRunningTime(listOfBehaviors, gossipPeriod):
	# get the time corresponding to the node that ran the shortest experiment
	shortest = 1000000
	for eachNodeLine in listOfBehaviors:
		if len(eachNodeLine) < shortest: 
			shortest = len(eachNodeLine)
	return((shortest*gossipPeriod)-gossipPeriod)

def getLongestRunningTime(listOfBehaviors, gossipPeriod):
	# get the time corresponding to the node that ran the longest experiment
	longest = 0
	for eachNodeLine in listOfBehaviors:
		if len(eachNodeLine) > longest: 
			longest = len(eachNodeLine)
	
	return((longest*gossipPeriod)-gossipPeriod)
###############################################################################	
def getCumulatedScoresByTime(listofallbehaviors):
	'''  listofallbehaviors argument is like this:  
	[	[   0, [2, 3, 4, 6], 100.0]
		[ 5.0, [2, 3, 4, 5], 100.0]
		[10.0, [2, 3, 4, 5], 100.0]
		[15.0, [2, 3, 4, 5], 100.0]...
	] 
	
		the returning value is a dictionary like this:
		cumulated =  { '0' : {'cumul': x , 'nodes': y, 'avg': 0}, '5' : {'cumul': w , 'nodes': z, 'avg': 0}, '10' : {'cumul': k , 'nodes': y, 'avg': 0 }
		''' 
		
	cumulated = {}  #   { '1' : {'cumul': 0.0 , 'nodes': 0, 'avg': 0 , 'values': [] } }
	for eachNodeLine in listofallbehaviors:
		for eachTime in eachNodeLine: 
			#print(eachTime)
			if eachTime[0] not in cumulated:
				cumulated[int(eachTime[0])] = {'cumul': eachTime[2] , 'nodes': 1, 'avg': 0, 'values': [] }
				cumulated[int(eachTime[0])]['values'].append(eachTime[2])
				
			else:
				cumulated[int(eachTime[0])]['cumul'] = cumulated[eachTime[0]]['cumul'] + eachTime[2]
				cumulated[int(eachTime[0])]['values'].append(eachTime[2])
				cumulated[int(eachTime[0])]['nodes'] = cumulated[eachTime[0]]['nodes'] + 1
				
			
			cumulated[int(eachTime[0])]['avg'] = float(cumulated[eachTime[0]]['cumul']) / float(cumulated[eachTime[0]]['nodes'])
			
	return cumulated

def getAllRetedBehaviorsByTime(listofnodes, idealviews, parseddata): 
	''' output will be a list of all behaviors by time for each node, like this:  
	[	[   0, [2, 3, 4, 6], 100.0]
		[ 5.0, [2, 3, 4, 5], 100.0]
		[10.0, [2, 3, 4, 5], 100.0]
		[15.0, [2, 3, 4, 5], 100.0]...
	] 
	'''
	auxListOfBehaviors = []

	for node in listofnodes:
		#print('node : ' + str(node))
		ideal = getIdealViewOfNode(node, idealviews)
		#print('ideal view: ' + str(ideal)) 
		behavior = getBehaviorOfNodePerTime(node, parseddata)
		#print(behavior)
		ratedBehaviorOfNode = rateNodeBehaviorByTime(ideal, behavior)
		#print(ratedBehaviorOfNode)
		auxListOfBehaviors.append(ratedBehaviorOfNode)
		
	return(auxListOfBehaviors)
	
	
def getRatedBehaviorsPerNode(listofnodes, idealviews, parseddata): 

	auxListOfBehaviors = []

	for node in listofnodes:
		#print('node : ' + str(node))
		ideal = getIdealViewOfNode(node, idealviews)
		print('ideal view: ' + str(ideal)) 
		behavior = getBehaviorOfNode(node, parseddata)   # ['nodeid', 'cycle', time, [view]]...] 

		# rate Behavior Of Node
		idealViewValuesOnly = []
		# first gets only the values of an idealView (which consists of multiples [neighbor, distance] pairs)
		for eachValue in ideal: 
			idealViewValuesOnly.append(eachValue[0])

		# for each node rates the view at each time	
		nodeBehaviorRated = []
		for each in behavior:
			#print(each)
			rate = rateView(idealViewValuesOnly, each[3])
			print('at node ' + each[0] + ' at time: ' + str(each[2]) + ' the view was: ' + str(each[3]) + ' ideal view: ' + str(idealViewValuesOnly) + ' rate: ' + str(rate) )
			nodeBehaviorRated.append([each[2], each[3], idealViewValuesOnly, rate])
		
		
		
		auxListOfBehaviors.append([node, nodeBehaviorRated])
	# this function is more useful for debugging strange values than for being used for other functions for the moment.
	# commenting the returns below and just keeping the printing above. change if needed. 
	#return(auxListOfBehaviors)

#########################################################################################

if __name__ == '__main__':
	# check arguments
	if len(sys.argv) != 2:
		print('missing parameter: job number')
		sys.exit()
	else:
		JOB = sys.argv[1]
		print('Evaluating job: '+ JOB)

	#parameters related to the experiments
	vSize = 4
	mbit = 8
	gossipPeriod = 5 

	source_dir='./output_data_logs/'+JOB+'/'
	listofFiles = listDir(source_dir)
	
	listOfNodes = getListOfNodes(listofFiles, 'tman')
	
	filesParsedData = getDataFromAllLogFiles(listofFiles, 'tman', gossipPeriod)
	idealViews = computeIdealView(listOfNodes, clockwise_id_distance, vSize, mbit)
	
	# finally create a function to calculate the ratio 'current view/ideal view' at each time, for all nodes that logged at this time.
	# the output would be something like [ at_segundo_x, total_logged_nodes , avg_of_all_ratios or comulated_ratios ] 
	# the function should looks like something like this: calculeViewsConvergenceByTine( listOfNodes, idealViews, filesParsedData )
	
	
	# print all parsed data, for all log files
	#print(filesParsedData)

	#getListOfTimesLogged(filesParsedData)
	
	#print the size of the ideal views
	#print(len(idealViews))
	#print(len(filesParsedData))
	
	#print the behavior of all nodes individually presented by node
	#printBehaviorPerNode(listOfNodes, filesParsedData)
	
	#print the behavior of a single nodes given by the first parameter
	#print(getBehaviorOfNode(1, filesParsedData))
	
	#print(idealViews)
	
	# this function is useful for debugging
	# listOfBehaviors = getRatedBehaviorsPerNode(listOfNodes, idealViews, filesParsedData)
	
	listOfBehaviors = getAllRetedBehaviorsByTime(listOfNodes, idealViews, filesParsedData)
	cumulatedScores = getCumulatedScoresByTime(listOfBehaviors)
	
	saveCumulatedScoresToFile(cumulatedScores, './plot_data/'+JOB+'/', 'tman_view_convergence_job_'+JOB+'.dat')
	
	#print(getShortestRunningTime(listOfBehaviors, gossipPeriod))
	#print(getLongestRunningTime(listOfBehaviors, gossipPeriod))
	
	print('time - cumul- total_nodes - mean - pvariance - pstdev - mode')
	for k,v in sorted(cumulatedScores.items()):
	#if v['nodes'] > 2 and v['cumul'] > 0:
		print(k,v['cumul'], v['nodes'], statistics.mean(v['values']), statistics.variance(v['values']) , statistics.stdev(v['values']) )
	


		
	
	
		
	
