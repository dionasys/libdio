set term postscript color eps enhanced 22
set output "func_adaptation_cw_to_ccw_ring_convergence_nochurn_jobs_331.eps"
load "styles.inc"

set style line 1 lt 1 lc rgb "#FF0000" lw 4 # red
set style line 2 lt 1 lc rgb "#00FF00" lw 4 # green
set style line 3 lt 1 lc rgb "#0000FF" lw 4 # blue

set size 1,0.65
set bmargin 3
set tmargin 3
set lmargin 8
set rmargin 5



set title "ring convergence - function adaptation cw to cww - churn - no piggyback" offset 0,-0.8

set xlabel "Time (s)" offset 0,0.3
set ylabel "Converged Links (%)" offset 1.9,0

set grid y front
set grid x front
set yrange [1:]
set xrange [1:]



set key left bottom


plot '../data/331/tman1_view_convergence_job_331_cw.dat' using 1:4 with lines linestyle 1 t 'job 331 - function cw' , '../data/331/tman1_view_convergence_job_331_ccw.dat' u 1:4 with lines linestyle 2 t 'job 331 - function ccw'

