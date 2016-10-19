set term postscript color eps enhanced 22
#set output "ring_convergence_2_instances_cw_ccw_churn_nochurn_256_nodes_jobs_254-256.eps"
set output "behavior_under_churn.eps"
load "styles.inc"

set style line 1 lt 1 lc rgb "#FF0000" lw 4 # red
set style line 2 lt 1 lc rgb "#00FF00" lw 4 # green
set style line 3 lt 1 lc rgb "#0000FF" lw 4 # bl
set style line 4 lt 1 lc rgb "#F0F00F" lw 4 # ?

set size 1,0.65
set bmargin 3
set tmargin 3
set lmargin 8
set rmargin 5

# note: ring convergence 2 instances cw ccw churn nochurn 256 nodes jobs 254 256 15% no piggyback

#set title "cw ccw churn 60-180 nochurn 256 nodes 60-180 15%" offset 0,-0.8

set xlabel "Time (s)" offset 0,0.3
set ylabel "Converged Links (%)" offset 1.9,0

set grid y front
set grid x front
set yrange [0:]
set xrange [0:250]

set arrow from 60,80 to 180,80 linestyle 304 back heads
set label "churn period" left at 102,85 front font ",16" 


#set key right bottom
set key samplen 2 font ",16" right bottom  


plot '../data/256/tman1_view_convergence_job_256.dat' using 1:4 with lines linestyle 4 t 'function cw - with churn' , '../data/256/tman2_view_convergence_job_256.dat' u 1:4 with lines linestyle 2 t 'function ccw - with churn' , '../data/254/tman1_view_convergence_job_254.dat' using 1:4 with lines linestyle 3 t 'function cw - without churn' , '../data/254/tman2_view_convergence_job_254.dat' u 1:4 with lines linestyle 1 t 'function ccw - without churn' 

