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
			lineTime = getTimeInSeconds(lineSplit[0])
			
			if currentLine == 1:
				startTime = lineTime
				currentTime = 0
				lastTime = currentTime
				linesData = []
				linesData.append(nodeId) 
				linesData.append(cycle) 
				linesData.append(currentTime)
				linesData.append(viewAtLine) 
				allFileData.append(linesData)
				lastTime = currentTime
				lastCycle = cycle
				
			else: 
				auxtime = lineTime - startTime
				if auxtime % gossipCycle == 0:
					currentTime = auxtime
					linesData = []
					linesData.append(nodeId) 
					linesData.append(cycle) 
					linesData.append(currentTime)
					linesData.append(viewAtLine) 
					allFileData.append(linesData)
					lastTime = currentTime
					lastCycle = cycle
					
					
				else:
					if int(cycle) < int(lastCycle): 
						currentTime = auxtime + (gossipCycle - (auxtime%gossipCycle))
						jumpedIntervals = (currentTime - lastTime)/gossipCycle
						for i in range(1,int(jumpedIntervals)):
							linesData = []
							linesData.append(nodeId) 
							linesData.append(int(lastCycle) + i)
							linesData.append(int(lastTime) + (i*gossipCycle))
							linesData.append([]) 
							allFileData.append(linesData)
						lastCycle = cycle
						lastTime = int(lastTime) + ((int(jumpedIntervals)-1)*gossipCycle)
					else:
						currentTime = auxtime - (auxtime%gossipCycle)
						linesData = []
						linesData.append(nodeId) 
						linesData.append(cycle) 
						linesData.append(currentTime)
						linesData.append(viewAtLine) 
						allFileData.append(linesData)
						lastTime = currentTime
						lastCycle = cycle

	finally:
		currentFile.close
	return allFileData

def getDataFromAllLogFiles(listofFiles, filenameIdentifier, gossipPeriod):
	dataFromAllFiles = []
	for fileName in listofFiles:
		if fileName.startswith(filenameIdentifier):
			parsedDataFromFile = getFixedDataFromFile(fileName, gossipPeriod)
			dataFromAllFiles.append(parsedDataFromFile)
	return(dataFromAllFiles)
	
def saveCumulatedScoresToFile(myScoreDic, outDir, fileName): 

	filename = outDir + fileName
	os.makedirs(os.path.dirname(filename), exist_ok=True)
	with open(filename, "w") as myOutputFile:
		myOutputFile.write('time - cumul- total_nodes - mean - pvariance - pstdev - mode \n')
		for k,v in sorted(cumulatedScores.items()):	
			myOutputFile.write(str(k) + ' ' + str(v['cumul']) + ' ' + str(v['nodes']) + ' ' + str(statistics.mean(v['values'])) + ' ' + str(statistics.variance(v['values'])) + ' ' + str(statistics.stdev(v['values'])) + '\n' )
	myOutputFile.close()

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
	return item[1]

def clockwise_id_distance(node1, node2, mbitSpace):
	if node1 < node2: 
		dist=node2-node1 
	else:
		dist=(2**mbitSpace)-node1+node2 
	return dist 

def counter_clockwise_id_distance(node1, node2, mbitSpace):
	if node1 > node2: 
		dist=node1-node2
	else:
		dist=(2**mbitSpace)-node2-node1 
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

	for eachValue in idealView: 
		idealViewValuesOnly.append(eachValue[0])

	for eachTime in behavior:
		eachTime[1].sort()	
		rate = rateView(idealViewValuesOnly, eachTime[1])
		nodeBehaviorRated.append([eachTime[0], eachTime[1], rate])
	
	return(nodeBehaviorRated)

def rateView(ideal, currentView):
	if len(ideal)==0:
		print('error: found ideal view size zero, while calculating the view rate at function rateView')
		sys.exit()
	found=0	
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
		ideal = getIdealViewOfNode(node, idealviews)
		behavior = getBehaviorOfNodePerTime(node, parseddata)
		ratedBehaviorOfNode = rateNodeBehaviorByTime(ideal, behavior)
		auxListOfBehaviors.append(ratedBehaviorOfNode)
	return(auxListOfBehaviors)
	
	
def getRatedBehaviorsPerNode(listofnodes, idealviews, parseddata): 

	auxListOfBehaviors = []
	for node in listofnodes:
		ideal = getIdealViewOfNode(node, idealviews)
		print('ideal view: ' + str(ideal)) 
		behavior = getBehaviorOfNode(node, parseddata)   
		idealViewValuesOnly = []
		for eachValue in ideal: 
			idealViewValuesOnly.append(eachValue[0])
		nodeBehaviorRated = []
		for each in behavior:
			rate = rateView(idealViewValuesOnly, each[3])
			print('at node ' + each[0] + ' at time: ' + str(each[2]) + ' the view was: ' + str(each[3]) + ' ideal view: ' + str(idealViewValuesOnly) + ' rate: ' + str(rate) )
			nodeBehaviorRated.append([each[2], each[3], idealViewValuesOnly, rate])
		auxListOfBehaviors.append([node, nodeBehaviorRated])
	# commenting the return below and keeping the printing above. change if needed. 
	#return(auxListOfBehaviors)

#########################################################################################

if __name__ == '__main__':

	if len(sys.argv) != 3:
		print('missing parameter: job number , protocolID')
		sys.exit()
	else:
		JOB = sys.argv[1]
		print('Evaluating job: '+ JOB)

	#parameters related to the experiments
	vSize = 4
	mbit = 8
	gossipPeriod = 5 
	protocolID = sys.argv[2] # ex:  'tman1' 'tman2'

	source_dir='./output_data_logs/'+JOB+'/'
	listofFiles = listDir(source_dir)
	
	listOfNodes = getListOfNodes(listofFiles, protocolID)
	
	filesParsedData = getDataFromAllLogFiles(listofFiles, protocolID , gossipPeriod)
	
	#------------------------------------------------------------	
	''' Experience 1: the following  evaluation is based on 2 different protocols is running at the same time with different functions: uncomment the lines to use it '''
	#if protocolID=='tman1':
	#	idealViews = computeIdealView(listOfNodes, clockwise_id_distance, vSize, mbit)
	#elif protocolID=='tman2':
	#	idealViews = computeIdealView(listOfNodes, counter_clockwise_id_distance, vSize, mbit)
	#else:
	#	print('protocolID: '+ protocolID+ ' was not recognized')
	#	sys.exit()	
		
	#listOfBehaviors = getAllRetedBehaviorsByTime(listOfNodes, idealViews, filesParsedData)
	#cumulatedScores = getCumulatedScoresByTime(listOfBehaviors)
	
	#saveCumulatedScoresToFile(cumulatedScores, './experiments/ring_convergence/data/'+JOB+'/', protocolID+'_view_convergence_job_'+JOB+'.dat')
	#------------------------------------------------------------	
	
	#------------------------------------------------------------	
	''' Experience 2: the following  evaluation is based on only one protocol runnning but in experiences where the function changes on the fly: I use it to check the adaptation of the system.  different protocols is running at the same time with different functions: uncomment the lines to use one of the functions, choose an 'function identifier" for the output files
	''' 
	
	#functionToTest = clockwise_id_distance
	#funcIdentifier = "cw"
	functionToTest = counter_clockwise_id_distance
	funcIdentifier = "ccw"
	
	idealViews = computeIdealView(listOfNodes, functionToTest, vSize, mbit)
	
	listOfBehaviors = getAllRetedBehaviorsByTime(listOfNodes, idealViews, filesParsedData)
	cumulatedScores = getCumulatedScoresByTime(listOfBehaviors)
	
	saveCumulatedScoresToFile(cumulatedScores, './experiments/ring_convergence/data/'+JOB+'/', protocolID+'_view_convergence_job_'+JOB+'_'+funcIdentifier+'.dat')
	
	#------------------------------------------------------------
