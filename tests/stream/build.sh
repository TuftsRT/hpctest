# Build step: runs inside the job after modules load (bash -e).
# STREAM rule: each array must be >= 4x the total last-level cache. Size N from this node.
l3=$(lscpu -B 2>/dev/null | awk -F: '/^L3 cache/ {gsub(/[^0-9]/, "", $2); print $2}')
n=$(( ${l3:-0} * 4 / 8 ))
[ "$n" -lt 80000000 ] && n=80000000
echo "$n" > stream_n
$cc -O3 -fopenmp -mcmodel=medium -DN=$n -DNTIMES=20 -o stream stream.c
