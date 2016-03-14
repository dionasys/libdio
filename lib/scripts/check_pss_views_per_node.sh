

if [ $# -eq 0 ]
  then
    echo "No arguments: inform job-number, numb-nodes and numb of cycles "
    exit 1
fi

JOB=$1
NODES=$2
CYCLES=$3

if [ ! -d "output_logs/$JOB" ]; then
   mkdir "output_logs/$JOB"
fi

for node in `seq 1 1 $NODES`; do
 > output_logs/$JOB/pss_view_job_"$JOB"_node_"$node".dat
 for cycle in `seq 1 1 $CYCLES`; do 
  cat $JOB | grep "CURRENT PSS_VIEW:  at node: $node " | grep -v pss_SELECT | grep " cycle: $cycle " | tail -1  >> output_logs/$JOB/pss_view_job_"$JOB"_node_"$node".dat
 done
done
