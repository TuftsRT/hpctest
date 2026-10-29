#!/bin/bash
#@ description: fio file-system throughput: sequential write/read (MB/s), 4k random read (IOPS)
#@ param io_dir =
#@ param fio = fio
#@ param fio_jobs = 4
#@ param fio_size = 1G
#@ exclusive: yes
#@ time: 15
#@ baseline-by: none
#@ tags: benchmark io

# io_dir picks the file system to test (default: the job directory). Direct I/O
# bypasses the page cache so the numbers reflect the file system, not memory.
dir=${io_dir:-$PWD}/fio.$$
mkdir -p "$dir"
common="--directory=$dir --numjobs=$fio_jobs --size=$fio_size --direct=1 --ioengine=psync
        --group_reporting --output-format=json"
$fio --name=seqwrite --rw=write --bs=1M $common > seqwrite.json
$fio --name=seqread  --rw=read  --bs=1M $common > seqread.json
$fio --name=randread --rw=randread --bs=4k --time_based --runtime=20 $common > randread.json
rm -rf "$dir"
python3 - <<'PY'
import json
def job(f):
    return json.load(open(f))["jobs"][0]
print("seq_write_MBps %d" % (job("seqwrite.json")["write"]["bw"] / 1024))
print("seq_read_MBps %d" % (job("seqread.json")["read"]["bw"] / 1024))
print("rand_read_IOPS %d" % job("randread.json")["read"]["iops"])
PY
