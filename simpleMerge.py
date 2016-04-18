import os.path, sys
# this is a simple merge that is used avoid the problems with SPLAY's merger, mergers all files to a single one

if len(sys.argv) == 2:
    output_file = sys.argv[1]
    print('merged output: ' + output_file)
else:
    output_file = 'test_lib.lua'
    print('merged output: ' + output_file)



filesToMerge = ['requirements.lua', 'node.lua', 'coordinator.lua', 'utilities.lua', 'pss.lua', 'tman.lua', 'ranking.lua', 'myTest.lua' ]

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
