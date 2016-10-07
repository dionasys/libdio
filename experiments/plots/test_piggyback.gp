set term postscript color eps enhanced 22
#set output "cw_ring_convergence_churn_nochurn_jobs_239-132.eps"
set output "test_piggyback_job_252_nodes_128_nochurn.eps"
load "styles.inc"

set style line 1 lt 1 lc rgb "#FF0000" lw 4 # red
set style line 2 lt 1 lc rgb "#00FF00" lw 4 # green
set style line 3 lt 1 lc rgb "#0000FF" lw 4 # blue

set size 1,0.65
set bmargin 3
set tmargin 3
set lmargin 8
set rmargin 5



set title "piggybacked msgs ring with 2 tman protocols - cw and ccw" offset 0,-0.8

set xlabel "Time (s)" offset 0,0.3
set ylabel "Converged Links (%)" offset 1.9,0

set grid y front
set grid x front
set yrange [1:]
set xrange [1:]



set key left bottom


#plot '../data/242/tman_view_convergence_job_242.dat' using 1:4 with lines linestyle 1 t 'job 242 - no churn'


plot '../data/252/tman1_view_convergence_job_252.dat' using 1:4 with lines linestyle 1 t 'tman1 cw job 252 - no churn' , '../data/252/tman2_view_convergence_job_252.dat' u 1:4 with lines linestyle 2 t 'tman2 ccw job 252- no churn'



