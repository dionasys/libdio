INPUT_DATA_DIR="../raw_logs"
OUTPUT_DATA_DIR="../output_data_logs"
OUTPUT_PLOT_DIR="../output_plots"
OUTPUT_BASE_FILENAME="known_nodes" #changing this name, the input name in the corresponding plot script must be changed

JOB=$1
NODES=$2

if [ $# -eq 0 ]; then
    echo "No arguments: inform job-number and numb-nodes "
    exit 1
fi

if [ ! -f "$INPUT_DATA_DIR/$JOB" ]; then
   echo $INPUT_DATA_DIR/$JOB" : file does not exits"
   exit 1
fi

if [ ! -d "$OUTPUT_DATA_DIR/$JOB" ]; then
	echo $OUTPUT_DATA_DIR/$JOB" : out put data directory does not exist, creating..."
  mkdir -p "$OUTPUT_DATA_DIR/$JOB"
fi


if [ ! -d "$OUTPUT_PLOT_DIR/$JOB" ]; then
	echo $OUTPUT_PLOT_DIR/$JOB" : out put plots directory does not exist, creating..."
  mkdir -p "$OUTPUT_PLOT_DIR/$JOB"
fi


for node in `seq 1 1 $NODES`; do
  #cat $JOB | grep CONVERG | grep "node: $node " >> $OUTPUT_DATA_DIR/$JOB/convergence_job_"$1"_node_"$node".dat
	##echo "cat $JOB | grep CONVERG | grep \"node: $node \" >> $OUTPUT_DATA_DIR/$JOB/$OUTPUT_BASE_FILENAME"_job_"$1"_node_"$node".dat" "
	cat $INPUT_DATA_DIR/$JOB | grep CONVERG | grep "node: $node " >> $OUTPUT_DATA_DIR/$JOB/$OUTPUT_BASE_FILENAME"_job_"$1"_node_"$node".dat"
  
done
