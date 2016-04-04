#!/bin/bash
INPUT_DATA_DIR="raw_outputs"
OUTPUT_DATA_DIR="output_data_logs"
OUTPUT_PLOT_DIR="output_plots"

JOB=$1
NODES=$2
CYCLES=$3

if [ $# -eq 0 ]; then
    echo "No arguments: inform job-number numb-nodes and cycles"
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


for node in `seq 1 1 $NODES`; do
 > $OUTPUT_DATA_DIR/$JOB/pss_view_job_"$JOB"_node_"$node".dat
 for cycle in `seq 1 1 $CYCLES`; do 
   echo "cat $INPUT_DATA_DIR/$JOB | grep \"CURRENT PSS_VIEW:  at node: $node \" | grep -v pss_SELECT | grep \" cycle: $cycle \" | tail -1  >> $OUTPUT_DATA_DIR/$JOB/pss_view_job_\"$JOB\"_node_\"$node\".dat" 
   cat $INPUT_DATA_DIR/$JOB | grep "CURRENT PSS_VIEW:  at node: $node " | grep -v pss_SELECT | grep " cycle: $cycle " | tail -1  >> $OUTPUT_DATA_DIR/$JOB/pss_view_job_"$JOB"_node_"$node".dat
 done
done
