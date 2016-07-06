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
	expListOfNodes.sort()
	return(expListOfNodes)

def getTimeInSeconds(timeString):
	x = time.strptime(timeString.split('.')[0],'%H:%M:%S')
	seconds = datetime.timedelta(hours=x.tm_hour,minutes=x.tm_min,seconds=x.tm_sec).total_seconds()
	return seconds

def getFixedDataFromFile(fileName, gossipCycle):
	''' in this case there is a fixing in the time to syncronize the events based on the cycle period
	'''
	print('openning file: ' + fileName )
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
				currentTime = lineTime - startTime
			# fixing time 
			print('current cycle: ' + str(cycle) + ' last cycle: ' + str(lastCycle))
			print('current time: ' + str(currentTime) + ' last time: ' + str(lastTime))

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



if __name__ == '__main__':
	# check arguments
	if len(sys.argv) != 2:
		print('missing parameter: job number')
		sys.exit()
	else:
		JOB = sys.argv[1]
		print('parsing job: '+ JOB)

	#parameters related to the experiments
	vSize = 5
	mbit = 10
	gossipPeriod = 5 

	source_dir='./output_data_logs/'+JOB+'/'
	listofFiles = listDir(source_dir)
	listOfNodes = getListOfNodes(listofFiles, 'tman')
	
	filesParsedData = getDataFromAllLogFiles(listofFiles, 'tman', gossipPeriod)
	idealViews = computeIdealView(listOfNodes, clockwise_id_distance, vSize, mbit)
	
	#print(filesParsedData)
	#getListOfTimesLogged(filesParsedData)
	
	#print(len(idealViews))
	#print(len(filesParsedData))
	
	#printBehaviorPerNode(listOfNodes, filesParsedData)
	#print(getBehaviorOfNode(2, filesParsedData))
	
	#printBehaviorPerTime(listOfNodes, filesParsedData)
	
	#for eachnode in idealViews:
	#	print(eachnode[1])
	
	
	
		






