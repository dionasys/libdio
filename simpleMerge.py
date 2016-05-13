#!/usr/bin/python

import os.path, sys
# this is a simple merge that is used avoid the problems with SPLAY's merger, mergers all files to a single one
print('Preparing files...')

filesToMerge = ['required.lua', 'node.lua', 'coordinator.lua', 'utilities.lua', 'pss.lua', 'tman.lua', 'ranking.lua' ]
stdOutput = 'libdio.lua' #std output name used if no out=yyy option is passed
stdInput  = 'myTest.lua' #this file is the file usually used as test, many diff. tests depending on the content of myTest.lua, for user specific app the option in=xxx must be used

if len(sys.argv) > 3:
	print('Wrong arguments: usage python simpleMerge.py [in=xxx.lua | out=yyy.lua | in=xxx.lua out=yyy.lua | out=yyy.lua in=xxx.lua]')

if len(sys.argv) == 1:
	print('[no arguments, using standard options]')
	output_file = stdOutput
	filesToMerge.append(stdInput)

if len(sys.argv) == 2:
 	#simpleMerge.py out=xxx
 	if sys.argv[1].split('=')[0] == 'out':
 		print('[only out-file passed]')
 		output_file = sys.argv[1].split('=')[1]
 		filesToMerge.append(stdInput)
		#simpleMerge.py in=xxx
	if sys.argv[1].split('=')[0] == 'in':
		print('[only in-file passed]')
		stdInput = sys.argv[1].split('=')[1]
		# check if selected input is part of default files
		if stdInput in filesToMerge: 
			print('[Wrong arguments: input filename has the same name as another file in the filesToMerge list]')
			print('[Wrong arguments: choose another input filename. Exiting.]')
			sys.exit()
		filesToMerge.append(stdInput)
		output_file = stdOutput

if len(sys.argv) == 3:
	# simpleMerge.py out=xxx simpleMerge.py in=xxx
	if sys.argv[1].split('=')[0] == 'out' and sys.argv[2].split('=')[0] == 'in':
		print('[out and in-file passed]')
		output_file = sys.argv[1].split('=')[1]
		stdInput = sys.argv[2].split('=')[1]
		# check if selected input is part of default files
		if stdInput in filesToMerge: 
			print('[Wrong arguments: input filename has the same name as another file in the filesToMerge list]')
			print('[Wrong arguments: choose another input filename. Exiting.]')
			sys.exit()
		
		filesToMerge.append(stdInput)
	# simpleMerge.py in=xxx simpleMerge.py out=xxx
	if sys.argv[1].split('=')[0] == 'in' and sys.argv[2].split('=')[0] == 'out': 
		print('[in and out-file passed]')
		stdInput = sys.argv[1].split('=')[1]
		# check if selected input is part of default files
		if stdInput in filesToMerge: 
			print('[Wrong arguments: input filename has the same name as another file in the filesToMerge list]')
			print('[Wrong arguments: choose another input filename. Exiting.]')
			sys.exit()
		filesToMerge.append(stdInput)  
		output_file = sys.argv[2].split('=')[1]

print('merging files  : '+ str(filesToMerge))
print('selected output: ' + output_file)

# check if selected output is part of default files
if output_file in filesToMerge: 
	print('[Wrong arguments: output filename has the same name as another file in the filesToMerge list]')
	print('[Wrong arguments: choose another output filename. exiting.]')
	sys.exit()

# remove output file if exists
try:
	os.remove(output_file)
except OSError:
	pass

#merge files in the list into a single output file 
for eachFile in filesToMerge:
	currentFile = open(eachFile, 'r')
	outFile = open(output_file, 'a')
	try:
		for line in currentFile: 
			outFile.write(line)
	finally:
		currentFile.close
		outFile.close
print('created output: ' + output_file)
print 'Finished.'

