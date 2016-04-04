#!/bin/bash


if [ $# -eq 0 ]
  then
    echo "No arguments: inform job-number and cycles to to evaluated. "
    exit 1
fi

JOB=$1
CYCLES=$2
CYCLES=$((CYCLES+1))

INPUT_LOG_DIR="output_data_logs"
INPUT_BASE_DATA_FILE="known_nodes"
OUTPUT_PLOT_DIR="output_plots"
OUTPUT_PS_FILE="pss_"$INPUT_BASE_DATA_FILE"_job_"$JOB".ps"
OUTPUT_GP_FILE="pss_"$INPUT_BASE_DATA_FILE"_job_"$JOB".gp"

if [ ! -d "$INPUT_LOG_DIR/$JOB" ]; then
   echo $INPUT_LOG_DIR/$JOB" : source directory does not exits"
   exit 1
fi

if [ ! -d "$OUTPUT_PLOT_DIR/$JOB" ]; then
   echo $OUTPUT_PLOT_DIR/$JOB" : out put plots directory does not exist, creating..."
   mkdir -p "$OUTPUT_PLOT_DIR/$JOB"
fi
LIST=`echo "$INPUT_LOG_DIR/$JOB/$INPUT_BASE_DATA_FILE"_job_"$JOB"_node_*.dat`
#echo $LIST

for files in `ls $LIST `; do
  #echo $files
  NODE=`echo $files | cut -d "_"  -f 8 | cut -d "." -f 1`
  #echo $NODE
  cat $files | head -$CYCLES | awk '{print $9,$10,$13,$14,$15,$17}'  > $OUTPUT_PLOT_DIR/$JOB/aux_job_"$JOB"_node_"$NODE".dat
done

echo "set grid " > $OUTPUT_PLOT_DIR/$JOB/$OUTPUT_GP_FILE
echo "set title \"PSS KNOWN NODES x Cycles\" " >> $OUTPUT_PLOT_DIR/$JOB/$OUTPUT_GP_FILE
echo "set ylabel \" # of Nodes \" " >> $OUTPUT_PLOT_DIR/$JOB/$OUTPUT_GP_FILE
echo "set xlabel \" # of Cycles \" " >> $OUTPUT_PLOT_DIR/$JOB/$OUTPUT_GP_FILE
echo "set term postscript color " >> $OUTPUT_PLOT_DIR/$JOB/$OUTPUT_GP_FILE
echo "set output \"$OUTPUT_PLOT_DIR"/"$JOB"/"$OUTPUT_PS_FILE\" " >> $OUTPUT_PLOT_DIR/$JOB/$OUTPUT_GP_FILE

PLOT_CMD=""
for aux_files in `ls $OUTPUT_PLOT_DIR"/"$JOB/aux_job_"$JOB"_node_*.dat`; do
  if [ "$PLOT_CMD" == "" ]; then
    PLOT_CMD="\"$aux_files\" u 4:6 w linespoints sm be t \"\"" 
  else
    PLOT_CMD=$PLOT_CMD", \"$aux_files\" u 4:6 w linespoints sm be t \"\"  " 
  fi
done
PLOT_CMD="plot $PLOT_CMD"
echo $PLOT_CMD >> $OUTPUT_PLOT_DIR/$JOB/$OUTPUT_GP_FILE

gnuplot $OUTPUT_PLOT_DIR/$JOB/$OUTPUT_GP_FILE
