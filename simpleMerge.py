#!/usr/bin/python
import os.path, sys
# this is a simple merge that is used avoid the problems with SPLAY's merger, mergers all files to a single one
# 5 possible ways of using this script:
#	1) simpleMerge.py
#	2) simpleMerge.py out=xxx  -> uses the std input (myTest.lua)
#	3) simpleMerge.py in=xxx   -> uses the std output(libdio.lua)
#	4) simpleMerge.py out=xxx simpleMerge.py in=xxx
#	5) simpleMerge.py in=xxx simpleMerge.py out=xxx

print('Preparing files...')

filesToMerge = ['required.lua', 'node.lua', 'coordinator.lua', 'utilities.lua', 'pss.lua', 'tman.lua', 'ranking.lua' ]
stdOutput = 'libdio.lua' #std output name used if no out=yyy option is passed
stdInput  = 'myTest.lua' #this file is the file usually used for tests (it contains many diff. tests depending on the content of myTest.lua), for a user specific app the option in=xxx must be used to include the source for the specific app.

def filenameError(inorout): 
	print('[Wrong arguments: ' + inorout + ' filename has the same name as another file in the filesToMerge list]')
	print('[Wrong arguments: choose another ' + inorout + ' filename. Exiting.]')
	sys.exit()


if len(sys.argv) > 3:
	print('Wrong arguments: usage python simpleMerge.py [in=xxx.lua | out=yyy.lua | in=xxx.lua out=yyy.lua | out=yyy.lua in=xxx.lua]')

if len(sys.argv) == 1:
	#invoked as: simpleMerge.py
	print('[no arguments, using standard options]')
	output_file = stdOutput
	filesToMerge.append(stdInput)

if len(sys.argv) == 2:
 	#invoked as: simpleMerge.py out=xxx
 	if sys.argv[1].split('=')[0] == 'out':
 		print('[only out-file passed]')
 		output_file = sys.argv[1].split('=')[1]
 		filesToMerge.append(stdInput)
	#invoked as: simpleMerge.py in=xxx
	if sys.argv[1].split('=')[0] == 'in':
		print('[only in-file passed]')
		stdInput = sys.argv[1].split('=')[1]
		# check if selected input is part of default files
		if stdInput in filesToMerge: 
			filenameError('input')
		filesToMerge.append(stdInput)
		output_file = stdOutput

if len(sys.argv) == 3:
	#invoked as: simpleMerge.py out=xxx simpleMerge.py in=xxx
	if sys.argv[1].split('=')[0] == 'out' and sys.argv[2].split('=')[0] == 'in':
		print('[out and in-file passed]')
		output_file = sys.argv[1].split('=')[1]
		stdInput = sys.argv[2].split('=')[1]
		# check if selected input is part of default files
		if stdInput in filesToMerge: 
			filenameError('input')
		filesToMerge.append(stdInput)

	#invoked as: simpleMerge.py in=xxx simpleMerge.py out=xxx
	if sys.argv[1].split('=')[0] == 'in' and sys.argv[2].split('=')[0] == 'out': 
		print('[in and out-file passed]')
		stdInput = sys.argv[1].split('=')[1]
		# check if selected input is part of default files
		if stdInput in filesToMerge: 
			filenameError('input')
		filesToMerge.append(stdInput)  
		output_file = sys.argv[2].split('=')[1]

print('merging files  : '+ str(filesToMerge))
print('selected output: ' + output_file)

# check if selected output is part of default files
if output_file in filesToMerge: 
	filenameError('output')

# remove output file if exists
try:
	os.remove(output_file)
except OSError:
	pass
# 
#merge files in the list into a single output file 
#for eachFile in filesToMerge:
#	currentFile = open(eachFile, 'r')
#	outFile = open(output_file, 'a')
#	try:
#		for line in currentFile: 
#			outFile.write(line)
#	finally:
#		currentFile.close
#		outFile.close

try:
	outFile = open(output_file, 'a')
	outFile.write("-- File automatically merged by sympleMerge.py \n")
	print('created output: ' + output_file)
	for eachFile in filesToMerge:
		try:
			currentFile = open(eachFile, 'r')
			for line in currentFile: 
				outFile.write(line)
		except IOError:
			print('Error trying to open the file '+eachFile+' to read.')
		finally:
			currentFile.close
except IOError:
	print('Unable to open the file '+outFile+' to write.')
finally:
	outFile.close
print 'Finished.'

