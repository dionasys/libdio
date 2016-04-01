#!/bin/bash 
# returns the views by cycle of a single node. note that the max number of cycles checked here is 300. 

INPUT_DATA_DIR="raw_outputs"
OUTPUT_DATA_DIR="output_data_logs"
OUTPUT_PLOT_DIR="output_plots"


if [ $# -eq 0 ]
  then
    echo "No arguments: inform job-number, numb-nodes and numb of cycles "
    exit 1
fi

JOB=$1
NODES=$2
CYCLES=$3

if [ ! -f "$INPUT_DATA_DIR/$JOB" ]; then
   echo $INPUT_DATA_DIR/$JOB" : directory does not exits"
   exit 1
fi

if [ ! -d "$OUTPUT_DATA_DIR/$JOB" ]; then
  echo $OUTPUT_DATA_DIR/$JOB" : out put data directory does not exist, creating..."
  mkdir -p "$OUTPUT_DATA_DIR/$JOB"
fi

OUTPUT_BASE_FILE="pss_view_2_job_"$JOB"_node_"$node".dat"

echo "collecting data..."
for node in `seq 1 1 $NODES`; do
 echo "node $node"
 OUTPUT_BASE_FILE="pss_view_job_"$JOB"_node_"$node".dat"
 touch $OUTPUT_DATA_DIR/$JOB/$OUTPUT_BASE_FILE
 for cycle in `seq 0 1 $CYCLES`; do 
  cat $INPUT_DATA_DIR/$JOB | grep "CURRENT PSS_VIEW:  at node: $node " | grep -v pss_SELECT | grep " cycle: $cycle " | tail -1  >> $OUTPUT_DATA_DIR/$JOB/$OUTPUT_BASE_FILE
 done
done
