set terminal png medium size 640,480 background '#ffffff'
set output "output.png"
set tics nomirror scale 0.5
plot [-5:6.5] sin(x) with impulse ls -1
quit
