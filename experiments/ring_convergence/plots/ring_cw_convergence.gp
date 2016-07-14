set term postscript color eps enhanced 22
set output "cw_ring_convergence_churn_nochurn_jobs_130-132.eps"
load "styles.inc"

set style line 1 lt 1 lc rgb "#FF0000" lw 4 # red
set style line 2 lt 1 lc rgb "#00FF00" lw 4 # green
set style line 3 lt 1 lc rgb "#0000FF" lw 4 # blue

set size 1,0.65
set bmargin 3
set tmargin 3
set lmargin 8
set rmargin 5



set title "ring created with the lib - cw function used" offset 0,-0.8

set xlabel "Time (s)" offset 0,0.3
set ylabel "Converged Links (%)" offset 1.9,0

set grid y front
set grid x front
set yrange [1:]
set xrange [1:]



set key left bottom


plot '../data/130/tman_view_convergence_job_130.dat' using 1:4 with lines linestyle 1 t 'job 130 - no churn' , '../data/132/tman_view_convergence_job_132.dat' u 1:4 with lines linestyle 2 t 'job 132 - churn from 60 to 240'

