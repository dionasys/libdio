set term postscript color eps enhanced 22
load "styles.inc"

set style line 1 lt 1 lc rgb "#FF0000" lw 4 # red
set style line 2 lt 1 lc rgb "#00FF00" lw 4 # green
set style line 3 lt 1 lc rgb "#0000FF" lw 4 # blue
set style line 4 lt 1 lc rgb "#00FFFF" lw 4 # dont know
set size 1,0.65
set bmargin 3
set tmargin 3
set lmargin 8
set rmargin 5

set xlabel "Time (s)" offset 0,0.3
set ylabel "Converged Links (%)" offset 1.9,0

set grid y front
set grid x front
set yrange [1:]
set xrange [1:]
set key left bottom




set title "No piggyback ring 2tman - no churn and churn from 90 to 210" offset 0,-0.8


#set output "test_NON_piggybacked_job_253_nodes_128_nochurn.eps"
#set output "test_NON_piggybacked_job_254_nodes_128_nochurn.eps"
#set output "test_NON_piggybacked_job_256_nodes_128_churn_5min_15percent.eps"
set output "test_NON_piggyback_job256_nodes128_churn_and_no_churn_5min.eps"


#plot '../data/242/tman_view_convergence_job_242.dat' using 1:4 with lines linestyle 1 t 'job 242 - no churn'


#plot '../data/253/tman1_view_convergence_job_253.dat' using 1:4 with lines linestyle 1 t 'tman1 cw job 253 - no churn' , '../data/253/tman2_view_convergence_job_253.dat' u 1:4 with lines linestyle 2 t 'tman2 ccw job 253- no churn'

# 128 nodes no churn, job 254 is similar to 253, just made to verify the bahavior after some log/comment removal at the code and certify that everything was ok.
#plot '../data/254/tman1_view_convergence_job_254.dat' using 1:4 with lines linestyle 1 t 'tman1 cw job 254 - no churn' , '../data/254/tman2_view_convergence_job_254.dat' u 1:4 with lines linestyle 2 t 'tman2 ccw job 254- no churn'

# 128 nodes churn: 128 nodes 15% 5min. 
#plot '../data/256/tman1_view_convergence_job_256.dat' using 1:4 with lines linestyle 1 t 'tman1 cw job 256 - churn 15% 5min 128nodes' , '../data/256/tman2_view_convergence_job_256.dat' u 1:4 with lines linestyle 2 t 'tman2 ccw job 256- churn 15% 5min 128nodes'


plot '../data/254/tman1_view_convergence_job_254.dat' using 1:4 with lines linestyle 1 t 'tman1 cw job 254 - no churn' , '../data/254/tman2_view_convergence_job_254.dat' u 1:4 with lines linestyle 2 t 'tman2 ccw job 254- no churn', '../data/256/tman1_view_convergence_job_256.dat' using 1:4 with lines linestyle 3 t 'tman1 cw job 256 - churn 15% 5min 128nodes' , '../data/256/tman2_view_convergence_job_256.dat' u 1:4 with lines linestyle 4 t 'tman2 ccw job 256- churn 15% 5min 128nodes'

