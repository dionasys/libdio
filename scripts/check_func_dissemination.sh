#!/bin/bash 

JOB=$1


if [ $# -ne 1 ]; then
    echo "No arguments: inform job-number "
    exit 1
fi

OUTPUT_DATA_DIR="experiments/ring_convergence/data"
OUTPUT_FILE="function_propagation_"$JOB".dat"


if [ ! -d "$OUTPUT_DATA_DIR/$JOB" ]; then
  echo $OUTPUT_DATA_DIR/$JOB" : out put data directory does not exist, creating..."
  mkdir -p "$OUTPUT_DATA_DIR/$JOB"
fi

echo "saving grep to file: "$OUTPUT_DATA_DIR"/"$JOB"/"$OUTPUT_FILE

grep changing raw_outputs/$JOB | awk '{print $2 " " $7 " "  $8 " "  $11}'  > $OUTPUT_DATA_DIR/$JOB/$OUTPUT_FILE
