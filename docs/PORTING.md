# Porting hpctest to another cluster

Everything specific to a cluster lives in `sites/<name>/`. The driver (`bin/hpctest`),
the tests (`tests/`) and the profiles (`profiles/`) are shared and should not need edits.

Requirements: Slurm, Lmod or Environment Modules 4+, bash, Python 3.6+ (standard library
only), and a file system that both the submit host and the compute nodes can see.

## 1. Generate a site directory

On a compute node (or wherever your policy allows module loads):

```bash
git clone <this repo> hpctest && cd hpctest
bin/hpctest site init mysite
```

This probes the cluster and writes `sites/mysite/`:

| File | Contents |
|------|----------|
| `site.conf` | GPU partition, CPU architecture features from `sinfo`, module init file, and an `[aliases]` section listing every module name the tests use, marking the ones `module avail` cannot find (with candidates) |
| `baselines.conf` | empty; filled by `hpctest calibrate` |
| `smoke.conf` | optional quick commands for the module catalog sweep |
| `profiles/`, `tests/` | empty; for site-only additions |

`sites/template/site.conf` documents every key.

## 2. Map module names

Tests use portable, Spack-style module names (`gcc`, `openmpi`, `intel-oneapi-mkl`,
`netcdf-c`, `blast-plus`, ...). Map any that differ:

```ini
[aliases]
gcc = GCC/12.3.0
openmpi = OpenMPI/4.1.5-GCC-12.3.0
blast-plus = BLAST+/2.14.1-gompi-2023a
```

A value may list several modules or be empty (load nothing). Then check:

```bash
export HPCTEST_SITE=mysite      # or set [site] match = <hostname regex>
bin/hpctest check               # loads each test's modules here; no jobs
```

Repeat until clean. Software you don't have goes under `[disabled]`:

```ini
[disabled]
mathematica_hello = no license
```

If one test needs a different toolchain, override its parameters (any parameter, and
module parameters can name several modules):

```ini
[params:netcdf_c]
compiler = gcc/12.3.0 openmpi/4.1.5
```

## 3. Scheduler settings

```ini
[slurm]
partition = compute
gpu_partition = gpu
gpu_request = --gpus-per-node={gpus}
account = hpc-staff
max_exclusive_nodes = 4      # if per-user limits stop larger --exclusive jobs
arch_features = icelake zen3
```

Tests describe their needs abstractly (`#@ nodes`, `ntasks`, `gpus`, `exclusive`, `mem`,
`time`); `hpctest show <test>` prints the exact sbatch options your settings produce.

MPI tests launch with `$mpirun` (default `mpirun`). If your MPI needs another launcher:

```ini
[params]
mpirun = srun --mpi=pmix
```

## 4. Run

```bash
bin/hpctest run -p quick
bin/hpctest run -p default
```

Read the failure details. Common first-run issues:

| Status | Usual cause |
|--------|-------------|
| MODULE | alias missing, or the module needs a compiler/MPI loaded first (set the test's params) |
| BUILD | library found by the module but not on CPATH/LIBRARY_PATH (check the modulefile) |
| SUBMIT | partition/account/QOS settings |
| SKIP   | test disabled, GPU test without `gpu_partition`, or a missing `requires-param` value |

## 5. Calibrate benchmarks

Benchmarks (`-p benchmarks`, `-p network`) compare numbers with `baselines.conf`. Until a
baseline exists they PASS and report the measured values. Record baselines with:

```bash
bin/hpctest calibrate -p benchmarks -r 3
bin/hpctest calibrate -p network -r 3
```

Each value becomes the median of the passing runs, per CPU architecture
(`[stream@icelake]`), with tolerance `-25..+50 %` (change with `--tolerance`). Existing
tolerances and weights are kept. To get every architecture, steer jobs with
`-- --constraint=<feature>`. Edit `baselines.conf` freely afterwards.

## 6. Site-only tests and profiles

`hpctest new mytest --site-only -m mymodule -c 'mytool --version'` creates
`sites/mysite/tests/mytest/`. A site test with the same name as a core test overrides it.
Site profiles in `sites/mysite/profiles/` override core profiles of the same name;
`@core/<name>` includes the core version.

## 7. Schedule it

```cron
# Nightly health check, results to syslog (tag hpctest)
30 2 * * * cd /path/hpctest && HPCTEST_SITE=mysite bin/hpctest run -p default -q --syslog --cancel-on-timeout >> /var/log/hpctest.log 2>&1
```

Exit status is 0 only when nothing failed. `results.json` in each run directory is easy to
feed into dashboards.

## 8. Module catalog sweep

```bash
bin/hpctest modules                     # every module visible after purge
bin/hpctest modules --with gcc openmpi  # modules behind a compiler/MPI hierarchy level
bin/hpctest modules 'py-*' -o py.tsv
```

Each module is loaded on its own; failures, modules that add nonexistent directories to
PATH/LD_LIBRARY_PATH, and failing `smoke.conf` commands are reported.

## Sharing back

Improvements to `bin/`, `tests/` and `profiles/` should stay site-neutral: no paths,
partitions or module versions. Put those in `sites/<name>/`. A new core test should
declare its site-dependent inputs as `#@ param` (and `#@ requires-param` when there is no
sensible default).
