# Hyperthreading configuration drift on pax compute nodes

*Tufts Research Technology · hpctest node sweep · 2026-10-28*

## Summary

18 compute nodes have hyperthreading (SMT) **enabled in the BIOS**, while Slurm defines
them with `ThreadsPerCore=1`. The other 139 nodes checked have hyperthreading **off**,
which is clearly the cluster standard; each affected CPU model also has correctly
configured nodes.

**Impact in brief:**

| Area | Affected? | Detail |
|------|-----------|--------|
| Job submission and scheduling | **No** | Slurm offers the same CPUs and memory as on same-model nodes; nothing is rejected or held back. |
| CPU performance of jobs | **No** | Slurm hands out only the first thread of each core, so jobs never share a physical core (measured: no slowdown). |
| Programs that size themselves from the machine's CPU count | **Yes** | They see 2x the CPUs (128 instead of 64), so they start 2x as many workers as on an identical node, using more memory and risking out-of-memory kills. |
| Consistency between nodes | **Yes** | The same job behaves differently depending on which node of a model it lands on. |
| Monitoring and benchmarks | Minor | Tools reading `/proc/cpuinfo` or `lscpu` report a different topology. |

**Recommendation:** disable hyperthreading in the BIOS on the 18 nodes so they match
the rest of the cluster (rolling drain + reboot). Do **not** "fix" it by setting
`ThreadsPerCore=2` in `slurm.conf` (see [Recommendations](#recommendations)).

## Affected nodes

| CPU model | Affected | Same model, configured correctly | OS sees / Slurm uses |
|-----------|----------|----------------------------------|----------------------|
| Intel Xeon Gold 6438M | **14**: pax006, pax012, pax035, pax036, pax037, pax038, pax039, pax040, pax041, pax043, pax044, pax045, pax046, pax056 | 32 | 128 / 64 CPUs |
| Intel Xeon E5-2695 v4 | **3**: pax070, pax073, pax108 | 25 | 72 / 36 CPUs |
| Intel Xeon Gold 6248 | **1**: pax001 | 24 | 80 / 40 CPUs |

All other CPU models (Gold 6448Y, 6226R, 6240R, Platinum 8358, 8568Y+, 8570, 8480+,
Xeon 6767P/6747P, and others) are consistent. **No node** had a memory, socket or
cores-per-socket mismatch.

**Not checked (40 nodes):** 30 down, 3 in state UNKNOWN, 6 fully allocated during the
sweep (pax024, pax050, pax104, pax178, pax179, pax180), and pax079 (partition not open
to the account used). These should be checked when they are back or idle.

## How it was found

`hpctest`'s `slurm_node_config` test flagged pax045 and pax046. To check the whole
cluster, one small job (1 CPU, 100 MB, 2 min, mostly in `preempt`) ran on each of 157
reachable nodes and compared what the OS reports (`/proc/cpuinfo`, `lscpu`,
`/proc/meminfo`) with Slurm's node definition (`scontrol show node`).

## Effects

### 1. Job submission and scheduling: not affected

Slurm schedules from its own configuration, not from the hardware. An affected Gold 6438M
node is offered as 64 CPUs, exactly like the 32 correctly configured 6438M nodes, with
`SelectTypeParameters=CR_CPU_MEMORY` and `DefMemPerCPU=2000`. Users can request up to
64 CPUs on it, as on any other node of that model; no job is rejected, queued longer, or
billed differently. Slurm does not drain a node when the hardware has *more* CPUs than
configured (only fewer), which is why this went unnoticed.

### 2. CPU performance of jobs: not affected

Slurm hands out only the **first hardware thread of each physical core**; the second
threads (e.g. CPUs 64–127 on a 6438M node) are never given to any job, including
`--exclusive` jobs. Jobs therefore never share a core with another job or with
themselves, and the second threads stay idle, the same as on a node with hyperthreading
off.

Measured with 8 CPU-bound processes, each pinned to one of the job's CPUs, timed against
a single process running alone:

| Node | Job CPUs | Physical cores behind them | Slowdown, 8 in parallel |
|------|----------|----------------------------|-------------------------|
| pax004 (6438M, normal) | 8 | 8 | 1.00x |
| pax006 (6438M, affected) | 8 | 8 | 1.00x |
| pax035 (6438M, affected) | 8 | 8 | 1.00x |
| pax056 (6438M, affected) | 8 | 8 | 1.01x |
| pax070 (E5-2695 v4, affected) | 8 | 8 | 1.02x |
| pax108 (E5-2695 v4, affected), `--exclusive` | 36 (whole node) | 36 | n/a: the job could use only 36 of the 72 hardware threads |

An earlier note attributed a halved DB12 per-core score on pax045, and low STREAM/HPCG
results on pax108, to hyperthreading. Since jobs cannot use the second threads, that
explanation does not hold. The pax108 memory-bandwidth deficit (STREAM −40%, HPCG −42%)
needs a separate investigation (for example a missing or failed DIMM, or a
memory-channel imbalance).

### 3. Programs that size themselves from the machine: affected

Many programs pick their number of workers from the **total** CPU count of the machine
rather than from the CPUs the job was given. On an affected node that number doubles:

| Call | Normal 6438M node | Affected 6438M node |
|------|-------------------|---------------------|
| Python `os.cpu_count()` | 64 | 128 |
| Python `multiprocessing.Pool()` (default size) | 64 workers | 128 workers |
| R `parallel::detectCores()` | 64 | 128 |
| `nproc`, OpenMP, MKL/OpenBLAS (use the job's CPU mask) | 8 | 8 (unaffected) |

Measured in an 8-CPU job running 64 tasks that each hold 50 MB:

| Node | `Pool()` default | `Pool(8)` |
|------|------------------|-----------|
| pax004 (normal) | 64 workers, 1.6 s | 8 workers, 1.5 s |
| pax035 / pax056 (affected) | **128 workers**, 1.5 s | 8 workers, 1.4 s |

Running time barely changes, because the extra workers just take turns on the job's 8
cores. **Memory is the real cost:** every worker is a full process with its own copy of
the interpreter and of any data it loads. Estimated from the task size, peak memory was
about 7.7 GB with 128 workers against 3.8 GB with 64, versus 0.5 GB with the correct 8.
A job that fits its `--mem` on a normal node can therefore be **OOM-killed on an affected
node of the same model**, an intermittent failure that depends on node placement and is
hard for users to diagnose.

Typical patterns that are affected: `multiprocessing.Pool()`,
`concurrent.futures.ProcessPoolExecutor()`, R `mclapply(mc.cores = detectCores())`,
`make -j$(getconf _NPROCESSORS_ONLN)`, and pipelines that read `/proc/cpuinfo`.

This oversubscription already exists on every node (64 workers for an 8-CPU job); the
affected nodes double it. The user-side fix is the same everywhere: size pools from
`len(os.sched_getaffinity(0))`, `nproc`, or `$SLURM_CPUS_PER_TASK`.

### 4. Monitoring and benchmarks: minor

`lscpu`, `/proc/cpuinfo`, `hwloc` and tools built on them report 2 threads per core on
these nodes and 1 on their peers, which confuses node comparisons, hardware inventories
and per-core benchmark normalisation. Some applications (e.g. GROMACS) print hardware
warnings when the detected thread count does not match what they can use.

### 5. Other

- **No lost capacity:** the idle second threads are equivalent to hyperthreading off.
- **Security:** SMT side channels (MDS/L1TF class) need two workloads on sibling threads
  of one core. Jobs never get sibling threads, so the extra exposure is limited to
  system processes that may run on the idle threads.

## Recommendations

1. **Disable hyperthreading in the BIOS on the 18 nodes**, matching the cluster
   standard: drain each node, reboot into the BIOS change, then confirm `lscpu` shows
   `Thread(s) per core: 1`. No `slurm.conf` change is needed.
2. **Do not set `ThreadsPerCore=2`** for these nodes instead. With `CR_CPU_MEMORY`,
   Slurm would then hand out individual hardware threads, so two jobs could share a
   physical core, and a 1-CPU request would get half a core. That would cause exactly
   the performance problems the current setup avoids, on only some nodes of each model.
3. **Check the 40 unchecked nodes** once they are up or idle.
4. **Keep monitoring:** run hpctest's `node` profile after hardware work and BIOS
   updates (`slurm_node_config` detects this drift), for example per node with
   `hpctest run -p node -- -w <node>`.
5. **User guidance (cluster-wide, independent of this issue):** document that worker
   counts should come from `$SLURM_CPUS_PER_TASK` or `nproc`, not
   `os.cpu_count()`/`detectCores()`.

## Data and reproduction

Raw data is in `runs/ht-sweep/` in the hpctest repository (git-ignored):

| File | Contents |
|------|----------|
| `slurm.txt` | Slurm's node definitions (`scontrol show node`) |
| `out/<node>.txt` | what each node's OS reports |
| `compare.py` | compares the two (`python3 compare.py`) |
| `impact*.sh`, `impact*.<node>.txt` | the core-mapping, `--exclusive` and `Pool()` measurements above |

To re-check a single node:

```bash
srun -p preempt -w <node> -n1 -c1 -t 2 bash -c \
  'echo "$(hostname -s) OS: $(nproc --all) CPUs, $(lscpu | grep "per core")"; \
   scontrol show node $(hostname -s) | grep -o "CPUTot=[0-9]*\|ThreadsPerCore=[0-9]*"'
```
