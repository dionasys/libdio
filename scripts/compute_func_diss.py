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




def getTimeInSeconds(timeString):
	x = time.strptime(timeString.split('.')[0],'%H:%M:%S')
	seconds = datetime.timedelta(hours=x.tm_hour,minutes=x.tm_min,seconds=x.tm_sec).total_seconds()
	return seconds



def getExactDataFromFile(fileName):
	
	allFileData = []
	currentFile = open(fileName, 'r')
	currentLine = 0
	startTime = 0

	try:
		for line in currentFile:			
			currentLine=currentLine+1

			lineSplit = line.split() 
			nodeId =  lineSplit[3]

			lineTime = getTimeInSeconds(lineSplit[0])
			if currentLine == 1:
				startTime = lineTime
				currentTime = 0
			else: 
				currentTime = lineTime - startTime

			linesData = []
			linesData.append(currentTime)
			linesData.append(nodeId) 

			allFileData.append(linesData)
	finally:
		currentFile.close
	return allFileData

def getDataFromAllLogFiles(fileName):
	dataFromAllFiles = []
	
	parsedDataFromFile = getExactDataFromFile(fileName)
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
	totalnodes =256
	
	listOfTimes = []
	listOfTimesIndex = []

	source_file='./experiments/ring_convergence/data/'+JOB+'/function_propagation_'+JOB+'.dat'
	out_file='./experiments/ring_convergence/data/'+JOB+'/computed_function_propagation_'+JOB+'.dat'
	temp_file='./experiments/ring_convergence/data/'+JOB+'/temp_computed_function_propagation_'+JOB+'.dat'

	
	filesParsedData = getExactDataFromFile(source_file )
	#print(filesParsedData)
	
	for each in filesParsedData:
		#print(str(each[0] )+ ' ' + str(each[1]))
		if each[0] != 0:
			listOfTimes.append(each[0])
			if each[0] not in listOfTimesIndex:
				listOfTimesIndex.append(each[0])
	
	#for each in listOfTimes:
		#print(each)
	cumul = 0	
	outfile = open(temp_file, 'a')
	line = ""
	
	for each in listOfTimesIndex: 
		numberOfTimes = listOfTimes.count(each)
		cumul = cumul + numberOfTimes
		line = "index: " + str(each) + " ocorreu: " + str( numberOfTimes) + " cumul: " + str( 100/float(totalnodes) * float(cumul) )  + '\n'
		print(line)
		outfile.write(line)
		
	outfile.close()
		
	os.system('sort < '+ temp_file + ' > '+ out_file)
	os.system('rm ' + temp_file)
	