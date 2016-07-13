import sys, os, string, datetime, time
'''
Script to evaluate the convergence of a Structure
usage:  python <script_name> <number_of_job>
'''

def listDir(currdir):
	fileList=[]
	#print('current dir: [' + currdir + ']')
	for file in os.listdir(currdir):
		if(file.endswith(".dat")):
			fileList.append(file)
	return(fileList)

def getViewFromStringWithAge(viewString):
	auxView = []
	aux1 = viewString.replace('(', ' ')
	aux2 = aux1.replace(')', ' ')
	##print(aux2)
	viewStringSplit = aux2.split()
	#print(len(viewStringSplit))
	index = 1
	while index < len(viewStringSplit)-1:
		item = []
		#print(viewStringSplit[index])
		item.append(viewStringSplit[index])
		item.append(viewStringSplit[index+1])
		index = index + 2
		auxView.append(item)
	return auxView

def getViewFromStringWithOutAge(viewString):
	auxView = []
	aux1 = viewString.replace('(', ' ')
	aux2 = aux1.replace(')', ' ')
	#print(aux2)
	viewStringSplit = aux2.split()
	#print(len(viewStringSplit))
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

#def calcRatioIdealCurrent(current, ideal):
#	found = 0
#	idealSize = len(ideal)
#	for eachElement in ideal:
#		for each in current:
#			#print(eachElement)
#			#print(each[0])
#			if int(each[0]) == int(eachElement):
#				found = found + 1
#	return(100/float(idealSize)*float(found))
	
def getListOfNodes(listofFiles, filenameIdentifier):

	expListOfNodes = []
	for fileName in listofFiles:
		if fileName.startswith(filenameIdentifier):
			nodeName = fileName.split('.')[0].split('_')
			nodeId = int(nodeName[len(nodeName)-1]) 
			expListOfNodes.append(nodeId)
	expListOfNodes.sort
	print('Number of nodes in this experiment: ' + str(len(expListOfNodes)) )
	return(expListOfNodes)

def getTimeInSeconds(timeString):
	x = time.strptime(timeString.split('.')[0],'%H:%M:%S')
	seconds = datetime.timedelta(hours=x.tm_hour,minutes=x.tm_min,seconds=x.tm_sec).total_seconds()
	return seconds

def getFixedDataFromFile(fileName, gossipCycle):
	''' in this case there is a fixing in the time to syncronize the events based on the cycle period
	'''
	#print('openning file: ' + fileName )
	# returns a list such : [['nodeid', 'cycle', currentTime, [view List]]
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

def getExactDataFromFile(fileName):
	'''this method gets the time as it happens in the log. 
		by counting the difference between the start time and the time that events happened. 
		no fixing is made. the drawback of this method is some delays can happen and the data 
		is logged few seconds later or before.
	''' 
	print('openning file: ' + fileName )
	# returns a list such : [['nodeid', 'cycle', currentTime, [view List]]
	allFileData = []
	currentFile = open(source_dir + fileName, 'r')
	currentLine = 0
	startTime = 0

	try:
		for line in currentFile:			
			currentLine=currentLine+1
			viewAtLine = getViewAtLine(line)
			lineSplit = line.split() 
			nodeId =  lineSplit[8]
			cycle = lineSplit[10] 
			#print(str(isinstance(lineSplit[0], basestring)))
			lineTime = getTimeInSeconds(lineSplit[0])
			if currentLine == 1:
				startTime = lineTime
				currentTime = 0
			else: 
				currentTime = lineTime - startTime

			linesData = []
			linesData.append(nodeId) 
			#linesData.append(cycle) 
			linesData.append(currentTime)
			linesData.append(viewAtLine)  
			allFileData.append(linesData)
	finally:
		currentFile.close
	return allFileData

def getDataFromAllLogFiles(listofFiles, filenameIdentifier, gossipPeriod):
	dataFromAllFiles = []
	for fileName in listofFiles:
		if fileName.startswith(filenameIdentifier):
			#name = fileName.split('.')[0].split('_')
			#nodeId = int(name[len(name)-1]) 
			# parsedDataFromFile = getExactDataFromFile(fileName)
			parsedDataFromFile = getFixedDataFromFile(fileName, gossipPeriod)
			dataFromAllFiles.append(parsedDataFromFile)
			
	return(dataFromAllFiles)
	
def computeIdealView(listOfAllNodes, distFunction, viewSize, mbitSpace):
	eachRankedNodes = []
	allRankedNodes = []
	for node in listOfAllNodes:
		toRank = list(listOfAllNodes)
		toRank.remove(node)
		rankedNodes = rankNode(node, toRank, distFunction, viewSize, mbitSpace)
		allRankedNodes.append([node, rankedNodes])
		
	return(allRankedNodes)

def getKey(item):
	#this function is used only to help to sort another list of lists, to sort all the sublists by the second value of the lists
	return item[1]

def cropRankedListOfDistances(rankedDistances, viewSize):
	croplist = list(rankedDistances[:viewSize])
	return (croplist)


def rankNode(me, listToRank, distFunction, viewSize, mbitSpace):
	rankedDistances = []
	for eachNode in listToRank:
		distance = distFunction(me, eachNode, mbitSpace)
		currentNode = [eachNode, distance]
		rankedDistances.append(currentNode)
		
	rankedDistances=list(sorted(rankedDistances, key=getKey))
	return(cropRankedListOfDistances(rankedDistances, viewSize))

def clockwise_id_distance(node1, node2, mbitSpace):
	if node1 < node2: 
		dist=node2-node1 
	else:
		dist=(2**mbitSpace)-node1+node2 
	return dist 
	
def getTimeStats(myParsedData):
	timeStats = {}
	fullTimeList = []
	for eachLine in myParsedData:
		for eachmoment in eachLine:
			fullTimeList.append(eachmoment[1])
	for i in fullTimeList:
		timeStats[i] = timeStats.get(i, 0)+1
	return timeStats

def getListOfTimesLogged(myParsedData):
	# returns a list with all seconds where there was some logs
	print(getTimeStats(myParsedData))


	
	
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
	#get the behavior of a single node, for all the times available
	for each in myParsedData:
		if each[0][0] == str(node):
			return(each)

def getBehaviorOfNodePerTime(node, myParsedData):
	#get the behavior of a single node, order per time logged 
	listToRet = []
	for eachNode in myParsedData:
		#print(eachNode)
		if eachNode[0][0] == str(node):
			for eachTime in eachNode:
				listLine = [eachTime[2], eachTime[3]]
				listToRet.append(listLine)
	return(listToRet)

def getIdealViewOfNode(node, allIdealViews):
	for eachnode in allIdealViews:
	# eachnode in idealviews is [nodeID, [[closest_neighbor , distance], [next_closest_neighbor, distance]]]
		if eachnode[0] == node:
			return(eachnode[1])
	return None 

def rateNodeBehavior(idealView, behavior):
	
	idealViewValuesOnly = []
	nodeBehaviorRated = []
	
	# first gets only the values of an idealView (which consists of multiples [neighbor, distance] pairs)
	for eachValue in idealView: 
		idealViewValuesOnly.append(eachValue[0])
	print(idealViewValuesOnly)
	# for each time rates the view 	
	for eachTime in behavior:
		eachTime[1].sort()	
		rate = rateView(idealViewValuesOnly, eachTime[1])
		#print('at time: ' + str(eachTime[0]) + ' the view was: ' + str(eachTime[1]) + ' rate: ' + str(rate) )
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
	mbit = 10
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
	cumulatedScores = {}  # ex: {'5': [25, 25, 50, 75, 100 , 100 ] }
	for node in listOfNodes:
		
		ideal = getIdealViewOfNode(node, idealViews)
		behavior = getBehaviorOfNodePerTime(node, filesParsedData)
		print('node ' + str(node) + ' ideal view:')
		print(len(ideal))
		#print('node ' + str(node) + ' views by time:')
		#print(behavior)
		ratedBehaviorOfNode = rateNodeBehavior(ideal, behavior)
		
		for eachTime in ratedBehaviorOfNode: 
			if eachTime[0] not in cumulatedScores: 
				cumulatedScores[eachTime[0]] = eachTime[2]
			else:
				cumulatedScores[eachTime[0]] =+ eachTime[2]
	
	print(cumulatedScores)
		
	
	
		
	
