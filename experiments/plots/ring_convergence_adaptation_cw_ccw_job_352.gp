set term postscript color eps enhanced 22 
load "styles.inc"  
set output "function_adaptation_cw_to_ccw_nochurn_job_352.eps" 
set style line 1 lt 1 lc rgb "#FF0000" lw 5 # red 
set style line 2 lt 2 lc rgb "#00FF00" lw 5 # green 
set style line 3 lt 3 lc rgb "#0000FF" lw 5 # blue 
set size 1,0.65 
set bmargin 3 
set tmargin 3 
set lmargin 8 
set rmargin 5 
set xlabel "Time (s)" offset 0,0.3 
set ylabel "Converged Links (%)" offset 1.9,0 
set y2label "Function \n Dissemination(%)" offset 0,0 
set title "256 nodes" offset 0,-0.8
set grid y front 
set grid x front 
set yrange [0:] 
set xrange [0:420] 
set key samplen 2 font ",12" right bottom  
set arrow from 120,0 to 120,100 nohead ls 304 
set arrow from 100,50 to 120,50 head ls 101 
set label "function \n replaced" left at 72,54 front font ",16"  
plot '../data/352/tman1_view_convergence_job_352_cw.dat' using 1:4 with lines linestyle 1 t 'initial function cw', '../data/352/tman1_view_convergence_job_352_ccw.dat' u 1:4 with lines linestyle 2 t 'replacing function ccw', '../data/352/computed_function_propagation_352.dat' u 2:6 with lines linestyle 3 t 'function dissemination (ttl 8)'  
