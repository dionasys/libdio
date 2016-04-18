import sys, os, string

def listDir(currdir):
    fileList=[]
    #print('current dir: [' + currdir + ']')
    for file in os.listdir(currdir):
        if(file.endswith(".dat")):
            fileList.append(file)
    return(fileList)
        
def getViewFromString(viewString):
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
    print(listofFiles)
    fileName='tman_view_job_95_node_1.dat' 
    print(fileName)
    for fileName in listofFiles:
        if fileName.startswith('tman'):
            print('open file to read: ' + fileName)
            
            name = fileName.split('.')[0].split('_')
            nodeId = int(name[len(name)-1]) 
            currentFile = open(source_dir + fileName, 'r')
            
            try:
                for line in currentFile:
            
                    viewIndex1 = line.find('[ ')
                    viewIndex2 = line.find(' ]')
                    viewString = line[viewIndex1:viewIndex2+2]
                    lineSplit = line.split() 
                    nodeId =  lineSplit[4]
                    cycle = lineSplit[6] 
                    currentView = getViewFromString(viewString)
                    idealView = calcIdealView(nodeId,idealViewSize)

                    ratio = calcRatioIdealCurrent(currentView, idealView)
                    print(str(cycle) + ' ' + str(ratio) )
                    if partials.get(cycle) == None:
                        rat = [ratio]
                        partials[cycle] = rat
                    else:
                        partials[cycle].append(ratio)
                    
            finally:
                currentFile.close
    
    
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