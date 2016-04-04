import os.path


output_file = 'test_tman.lua'
#test
#filesToMerge = ['1.txt', '2.txt', '3.txt']
filesToMerge = ['requirements.lua', 'coordinator.lua', 'node.lua', 'utilities.lua', 'pss.lua', 'tman.lua', 'ranking.lua', 'myTest.lua' ] 


# remove output file if exists
try:
	os.remove(output_file)
except OSError:
	pass

#merge files in the array into a single output files 
for eachFile in filesToMerge:	
	#print(eachFile)
	currentFile = open(eachFile, 'r')
	outFile = open(output_file, 'a')
	try:
		for line in currentFile: 
			#print (line)
			outFile.write(line)
	finally:
		currentFile.close
		outFile.close
print 'End.'		
