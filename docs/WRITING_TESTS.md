# Writing tests

A test is a directory under `tests/` (portable) or `sites/<site>/tests/` (site-only):

```
tests/fftw/
  test.sh         the job body, with "#@" metadata lines   (required)
  expected.out    expected stdout                          (required, may be empty)
  expected.err    expected stderr                          (optional: absent = must be empty)
  build.sh        compile step, run with bash -e           (optional)
  ...             input files; the directory is copied for each run
```

Quick start:

```bash
hpctest new samtools -m samtools -c 'samtools --version | head -1'
hpctest run samtools --keep                 # or: --local inside an allocation
hpctest bless <run-dir>/samtools            # copy the real output into expected.out/.err
$EDITOR tests/samtools/expected.out         # replace volatile parts with ${*}
```

## Metadata (`#@ key: value` lines in test.sh)

| Key | Meaning |
|-----|---------|
| `description` | one line, shown by `hpctest list` |
| `modules` | portable module names, may use params: `${compiler} ${mpi}` |
| `param NAME = default` | a parameter; exported to the job as `$NAME` (repeatable) |
| `requires-param` | params that must be non-empty (else SKIP); for site data paths |
| `nodes`, `ntasks`, `tasks-per-node`, `cpus-per-task`, `mem` | resources |
| `gpus` | GPUs per node; uses the site's `gpu_partition` / `gpu_request` |
| `exclusive` | `yes` = whole node(s); capped by the site's `max_exclusive_nodes` |
| `time` | limit, minutes or Slurm syntax (default: site `default_time`) |
| `constraint` | Slurm `--constraint` |
| `stderr` | `ignore` = do not compare stderr |
| `exit-code` | expected exit status of test.sh: `0` (default), a number, or `any` |
| `local` | `no` = never run with `--local` (e.g. tests that inspect the job's cgroup) |
| `tags` | words for `hpctest run tag:<tag>` and `hpctest list -t <tag>` |
| `sbatch` | raw extra sbatch options; avoid, it ties the test to one site |

Never put partitions, accounts, paths or module versions in a core test: use params and
let sites set them.

## What the job does

1. `module purge` (site `[modules] purge`), then loads each module, checking it really
   loaded. Any failure: status MODULE, nothing else runs.
2. `bash -e build.sh` if present. Non-zero exit: status BUILD (log in `.hpctest/build.log`).
3. `bash test.sh`; stdout and stderr are compared with the expected files, and the exit
   status with `exit-code`.

The job runs in a copy of the test directory (`$HPCTEST_DIR`); params are environment
variables. Write build lines that work at any site: rely on CPATH/LIBRARY_PATH from the
module or on `*-config` tools (`nc-config --cflags --libs`, `gsl-config`), not `$XYZ_HOME`.

## Expected output patterns

Each expected line must match one output line exactly (trailing spaces ignored):

| Pattern | Matches |
|---------|---------|
| `${*}` | any text, including none |
| `${NAME}` | a number, captured as NAME |
| `${?}` at line start | the line may be missing |

Trailing blank lines are ignored on both sides. Keep expected output small and stable:
filter the program's output in test.sh (`grep`, `awk`) to the lines that prove it worked,
and sort anything whose order varies (MPI ranks).

## Benchmarks

Capture the numbers that matter with `${NAME}` and let each site record baselines:

```
Copy ${copy}
Triad ${triad}
```

```bash
hpctest calibrate stream -r 3        # writes [stream@<arch>] into sites/<site>/baselines.conf
```

A baseline line is `NAME = expected low% high% [weight]`; a negative weight marks "lower is
better" (only affects the weighted summary). Without a baseline the test passes and shows
the measured values.

## Variants

One test can cover many module combinations through params. In a profile:

```
mpi_hello                                               # defaults (gcc + openmpi)
mpi_hello compiler=intel-oneapi-compilers mpi=intel-oneapi-mpi mpicc=mpiicx as=mpi_hello:intelmpi
```

On the command line: `hpctest run mpi_hello --set mpi=mvapich2`.
