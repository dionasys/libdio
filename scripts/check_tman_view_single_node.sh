#!/bin/bash 
# returns the views by cycle of a single node. note that the max number of cycles checked here is 300. 
INPUT_DATA_DIR="raw_outputs"
OUTPUT_DATA_DIR="output_data_logs"
OUTPUT_PLOT_DIR="output_plots"

JOB=$1
NODEID=$2
CYCLES=$3

if [ $# -eq 0 ]; then
    echo "No arguments: inform job-number node-id cycles"
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

OUTPUT_BASE_FILE="tman_view_job_"$JOB"_node_"$node".dat"

if [ ! -d "$OUTPUT_DATA_DIR/$JOB" ]; then
   echo $OUTPUT_DATA_DIR/$JOB" : out put data directory does not exist, creating..."
   mkdir -p $OUTPUT_DATA_DIR/$JOB
fi

> $OUTPUT_DATA_DIR/$JOB/$OUTPUT_BASE_FILE
  echo "collecting data.."
  for cycle in `seq 1 1 $CYCLES`; do 
    echo "$1 $2 $cycle"
    ##cat $INPUT_DATA_DIR/$JOB  | grep "node: $NODE " | grep "cycle: $cycle " | grep "CURRENT TMAN" | tail -1 | awk '{$1=$3=$4=$5=$6=$7=$10=$11=$12=""; print $0 }'  >  $OUTPUT_DATA_DIR/$JOB/$OUTPUT_BASE_FILE; 
    cat $INPUT_DATA_DIR/$JOB | grep "CURRENT TMAN_VIEW" |  grep "node: $NODEID " | grep "cycle: $cycle " |  tail -1 | awk '{$1=$3=$4=$5=$6=$7=$10=$11=$12=""; print $0 }' >>  $OUTPUT_DATA_DIR/$JOB/$OUTPUT_BASE_FILE 
  done
echo "end."
