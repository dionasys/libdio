#!/bin/bash 
# returns the views by cycle of a single node. note that the max number of cycles checked here is 300. 
INPUT_DATA_DIR="raw_outputs"
OUTPUT_DATA_DIR="output_data_logs"
OUTPUT_PLOT_DIR="output_plots"

JOB=$1
NODES=$2

if [ $# -ne 2 ]; then
    echo "No arguments: inform job-number number-of-nodes"
    exit 1
fi

if [ ! -f "$INPUT_DATA_DIR/$JOB" ]; then
   echo $INPUT_DATA_DIR/$JOB" : directory does not exits"
   exit 1
fi

if [ ! -d "$OUTPUT_DATA_DIR/$JOB" ]; then
  echo $OUTPUT_DATA_DIR/$JOB" : out put data directory does not exist, creating..."
  mkdir -p "$OUTPUT_DATA_DIR/$JOB"
fi

# captures how many instances of TMAN ran in this job
ALGOS=`cat $INPUT_DATA_DIR/$JOB | grep "CURRENT\ TMAN_VIEW" | grep cycle:\ 0\ |  grep "node: 1 " |  awk '{print $4 }' | cut -d "[" -f 2 | cut -d "]" -f 1 ` 

# grabs in different files the behavior of nodes by protocol.
for ALGO_ID in $ALGOS; do 
	for NODE in `seq 1 1 $NODES`; do 

		OUTPUT_BASE_FILE=$ALGO_ID"_view_job_"$JOB"_node_"$NODE".dat"
		> $OUTPUT_DATA_DIR/$JOB/$OUTPUT_BASE_FILE
		echo "collecting data for node $NODE...algo $ALGO_ID"
		cat $INPUT_DATA_DIR/$JOB | grep "CURRENT\ TMAN_VIEW" | grep $ALGO_ID | grep "id: $NODE " | awk '{$1=$3=$4=$5=$7=""; print $0 }' | sort >>  $OUTPUT_DATA_DIR/$JOB/$OUTPUT_BASE_FILE

	done
done

echo "END!"
