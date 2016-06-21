import sys, os, string, datetime, time

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
    
    
    
def calcIdealView(id, idealViewSize):
    ideal = []
    i = 0
    for i in range(idealViewSize):
        #print(i)
        #print(i+int(id)+1)
        ideal.append(i+int(id)+1)
    return ideal
    
def calcRatioIdealCurrent(current, ideal):
    
    found = 0
    idealSize = len(ideal)
    for eachElement in ideal:
        for each in current:
            #print(eachElement)
            #print(each[0])
            if int(each[0]) == int(eachElement):
                found = found + 1
    return(100/float(idealSize)*float(found))
    
def getTimeInSeconds(timeString):
    x = time.strptime(timeString.split('.')[0],'%H:%M:%S')
    seconds = datetime.timedelta(hours=x.tm_hour,minutes=x.tm_min,seconds=x.tm_sec).total_seconds()
    return seconds
    
def getDataFromFile(fileName):
    retDic = {}
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
            
            lineData = lineData.append([currentTime, cycle, viewAtLine])
            
            #print(str(currentTime)+' '+nodeId+' '+cycle+' '+str(viewAtLine))
            
    finally:
      currentFile.close
     
     retDic{'node': nodeId, 'viewsList': lineData }
     return retDic
    

if __name__ == '__main__':
    idealViewSize = 6
    partials = {}
    
    if len(sys.argv) != 2:
        print('missing parameter: job number')
        sys.exit()
    else:
        JOB = sys.argv[1]
  
    source_dir='./output_data_logs/'+JOB+'/'
    listofFiles = listDir(source_dir)

    for fileName in listofFiles:
        if fileName.startswith('tman'):
            print('open file to read: ' + fileName)
            #name = fileName.split('.')[0].split('_')
            #nodeId = int(name[len(name)-1]) 
            ret = getDataFromFile(fileName)
            partials{ret['node'], ret['viewsList']}
            
    
    
    #print(partials)
    #for key, value in sorted(partials.iteritems()): 
    #    print(str(key) + ' ' + str(value))
    #for k in partials.keys():
    #    print(k)
    #    size = len(partials[cycle])
    #    subtotal = 0
    #    for i in range(size):
    #        subtotal = subtotal + int(partials[cycle][i])
    #    localAvg = float(subtotal)/float(size)
    #    print (cycle + ' '+ localAvg)