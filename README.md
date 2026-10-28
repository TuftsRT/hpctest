# hpctest

**Portable health checks for HPC clusters: software modules, MPI, GPUs, the scheduler,
and node performance.**

`hpctest` submits small known-answer jobs through Slurm, checks their output, and
reports exactly what is broken and why: a module that no longer loads, a library that
won't link, an MPI stack that can't span nodes, a cgroup limit that isn't enforced, a
GPU that runs slow, a node whose hardware doesn't match its Slurm definition.

- **One file, no dependencies.** `bin/hpctest` is Python 3.6+ standard library.
- **Portable by design.** Tests are site-neutral; everything cluster-specific
  (partitions, module names, paths, policies, performance baselines) lives in one
  `sites/<name>/` directory that `hpctest site init` drafts for you.
- **Clear failures.** Every result is classified (MODULE, BUILD, FAIL, PERF, JOB, …) and
  shown with the evidence: the first mismatching line, the build log, the module error.
- **50 tests** covering compilers, MPI, numerical/I-O libraries, languages, applications,
  GPUs, Slurm/cgroups, and CPU/GPU/network/file-system benchmarks.

Version 1.0.0 · MIT license

---

## Contents

- [Requirements](#requirements)
- [Install](#install)
- [Quick start](#quick-start)
- [What a run looks like](#what-a-run-looks-like)
- [Concepts](#concepts)
- [Commands](#commands)
- [Tests](#tests)
- [Profiles](#profiles)
- [Benchmarks and baselines](#benchmarks-and-baselines)
- [Adopting hpctest at your site](#adopting-hpctest-at-your-site)
- [Writing tests](#writing-tests)
- [Repository layout](#repository-layout)
- [Contributing](#contributing)
- [License](#license)

## Requirements

- Slurm (`sbatch`, `squeue`, `sacct`, `scontrol`)
- Lmod, or Environment Modules 4+
- bash and Python 3.6 or newer
- A file system shared by the submit host and the compute nodes (for run directories)

Individual tests need the software they test (`gcc`, `openmpi`, `fio`, …). Tests whose
software a site doesn't have are disabled in that site's config and reported as SKIP.

## Install

```bash
git clone https://github.com/<owner>/hpctest.git
export PATH=$PWD/hpctest/bin:$PATH
hpctest --version
```

There is nothing to build. `hpctest` finds its tests, profiles and site configs
relative to its own location, so the directory can live anywhere, including a shared
software tree.

## Quick start

At a site that already has a config (or after [adopting it](#adopting-hpctest-at-your-site)):

```bash
hpctest check            # ~30 s, no jobs: can every test's modules be loaded here?
hpctest run -p quick     # ~5 min smoke test: compiler, OpenMP, MPI, Python, R, cgroups
hpctest run -p default   # main health check
hpctest run -p full      # everything, incl. GPU tests and benchmarks
```

The site is chosen by hostname (`[site] match` in each `site.conf`), by
`$HPCTEST_SITE`, or with `--site NAME`.

> Some sites forbid work on login nodes. Set `require_allocation = yes` in `site.conf`
> and `check`, `modules` and `run --local` will refuse to run outside a Slurm allocation.

## What a run looks like

An illustrative, abridged run:

```
$ hpctest run -p mpi
hpctest 1.0.0  site: example  tests: 6  jobs: 6
run directory: /scratch/alice/hpctest/20261028-152455-uhkw
submitted 6 job(s)
  PASS     mpi_hello
  PASS     mpi_hello:gcc+mvapich2
  MODULE   mpi_hello:oneapi+openmpi (cannot load: openmpi)
  PASS     mpi_hello:intelmpi
  BUILD    pnetcdf (build.sh exit 1)
  PASS     mpi_hello:oneapi+mvapich2

STATUS   TEST                       PASS  DETAIL
-------  -------------------------  -----  ----------------------------------------
PASS     mpi_hello                    1/1
PASS     mpi_hello:gcc+mvapich2       1/1
MODULE   mpi_hello:oneapi+openmpi     0/1  cannot load: openmpi
...
Summary: 4 PASS, 1 MODULE, 1 BUILD

Failure details:

[BUILD] pnetcdf  node c041
    build.sh exit 1
    build log (last lines):
        /usr/bin/ld: pnetcdf-write-standard.o: undefined reference to symbol 'ompi_mpi_info_null'
    modules: gcc/12.3.0 openmpi/4.1.5 parallel-netcdf/1.12.3
    files:   /scratch/alice/hpctest/20261028-152455-uhkw/pnetcdf
```

| Status | Meaning |
|--------|---------|
| PASS | output, exit code and benchmark numbers as expected |
| FAIL | output or exit code differs from what the test expects |
| PERF | output correct, but a benchmark number is outside its baseline range |
| MODULE | a module failed to load |
| BUILD | the test's compile step failed |
| JOB | the job died: timeout, OOM, node failure, cancelled |
| SUBMIT | `sbatch` rejected the job |
| PENDING | still queued when `--timeout` expired (the Slurm reason is shown) |
| SKIP | not applicable here: disabled for the site, missing site parameter, `--local` limits |

`hpctest` exits 0 only when nothing failed, so it works in cron and CI. Each run
directory holds `results.tsv`, `results.json`, `manifest.json`, and, for every
failed job (all jobs with `--keep`), the generated `job.sh`, its output, and logs.

## Concepts

**Test**: a directory with `test.sh` (job body plus `#@` metadata), `expected.out`,
optional `expected.err`, optional `build.sh`, and any input files.

```bash
#!/bin/bash
#@ description: MPI hello + allreduce, 4 ranks across 2 nodes
#@ param compiler = gcc
#@ param mpi = openmpi
#@ param mpirun = mpirun
#@ modules: ${compiler} ${mpi}
#@ nodes: 2
#@ tasks-per-node: 2
#@ time: 10
#@ tags: mpi quick

out=$($mpirun -n 4 ./mpi_hello)
...
```

Tests name modules with portable, Spack-style names and describe resources abstractly.
They never contain partitions, accounts, paths or module versions.

**Parameters** make one test cover many combinations. Override them in a profile,
in the site config, or on the command line:

```bash
hpctest run mpi_hello --set mpi=mvapich2
hpctest run c_hello --set compiler=intel-oneapi-compilers --set cc=icx
```

**Profile**: a named list of tests, with optional parameters, repeat counts and includes:

```
mpi_hello compiler=intel-oneapi-compilers mpi=intel-oneapi-mpi mpicc=mpiicx as=mpi_hello:intelmpi
slurm_cpuset x10 need=9          # 10 runs, pass if 9 pass (spreads over nodes)
stream serial                    # one at a time
@scheduler                       # include another profile
```

**Site**: `sites/<name>/` maps the portable layer onto one cluster:

| File | Purpose |
|------|---------|
| `site.conf` | module init, `[aliases]` (portable → local module names), GPU partition and request syntax, account/QOS, `max_exclusive_nodes`, CPU/GPU architecture features, `[params]`, `[disabled]` |
| `baselines.conf` | benchmark baselines, per CPU architecture or GPU model |
| `smoke.conf` | optional commands for the module catalog sweep |
| `profiles/`, `tests/` | site-only additions; same name overrides the core one |

`sites/template/site.conf` documents every key. `sites/tufts/` is a complete
real-world example.

## Commands

| Command | What it does |
|---------|--------------|
| `hpctest list [-p PROFILE] [-t TAG]` | tests with resources, the modules they load here, description |
| `hpctest profiles` | profiles and their sizes |
| `hpctest show TEST` | parameters, modules and exact `sbatch` options this site will use |
| `hpctest check [TESTS / -p PROFILE]` | load each test's modules on this node; no jobs |
| `hpctest run TESTS / -p PROFILE / tag:TAG / --all` | submit, wait, report |
| `hpctest report RUNDIR [--recheck]` | (re)evaluate a run, e.g. after `--no-wait` or new baselines |
| `hpctest modules [GLOBS] [--with MODS]` | load every module in the catalog, report broken ones |
| `hpctest calibrate ... / --from RUNDIR...` | measure benchmark baselines into `baselines.conf` |
| `hpctest site list / show / init NAME` | inspect sites, or probe this cluster and draft a new one |
| `hpctest new NAME -m MODULE -c CMD` | create a test skeleton |
| `hpctest bless RUNDIR/TEST` | copy a kept run's real output into the test's expected files |

Useful `run` options:

| Option | |
|--------|--|
| `-r N --need M` | run each test N times; pass if M succeed |
| `--set PARAM=VALUE` | override a test parameter (repeatable) |
| `--local` | run inside your current allocation instead of submitting |
| `--no-wait` | submit and exit; check later with `hpctest report` |
| `-k`, `--keep` | keep directories of passing jobs too |
| `-n`, `--nodes` | list nodes that had failures |
| `--timeout MIN`, `--cancel-on-timeout` | how long to wait for the queue |
| `--syslog` | log one line per test with `logger -t hpctest` |
| `-- SBATCH_OPTS` | passed to every `sbatch`, e.g. `-- --constraint=a100 --exclude=n12` |

## Tests

| Area | Tests |
|------|-------|
| Compilers | `c_hello`, `fortran_hello`, `openmp_hello`, `cuda_vector_add` |
| MPI | `mpi_hello` (any MPI × compiler via params), `pnetcdf` |
| Libraries | `fftw`, `gsl`, `hdf5`, `netcdf_c`, `netcdf_fortran`, `openblas`, `boost` |
| Languages | `python_hello`, `python_numpy`, `r_hello`, `julia_hello`, `octave_hello`, `matlab_hello`, `mathematica_hello`, `sqlite` |
| Applications | `blast`, `hmmer`, `quantum_espresso`, `gromacs`, `gnuplot`, `pytorch_cpu`, `pytorch_gpu`, `tensorflow_cpu`, `tensorflow_gpu` |
| Scheduler and nodes | `slurm_cpuset`, `slurm_memory`, `slurm_oom`, `slurm_exclusive`, `slurm_multinode`, `slurm_node_config` |
| Benchmarks | `stream`, `linpack_mkl`, `hpcg_mkl`, `db12`, `r_benchmark`, `io_fio`, `gpu_bench`, `osu_latency`, `osu_bw`, `osu_bibw`, `osu_allreduce`, `osu_alltoall`, `osu_bcast`, `osu_scatter` |

`hpctest list` shows them all with descriptions; `hpctest show TEST` shows one in full.

## Profiles

| Profile | Contents |
|---------|----------|
| `quick` | C, OpenMP, MPI, Python, R, SQLite, cgroup CPU and memory limits |
| `scheduler` | cgroups, OOM kill, exclusive allocation, multi-node `srun`, node hardware vs. Slurm config |
| `compilers` | GCC and Intel oneAPI (C, Fortran, OpenMP), CUDA |
| `mpi` | OpenMPI and MVAPICH2 with GCC and oneAPI, Intel MPI, PnetCDF |
| `libs` | FFTW, GSL, HDF5, netCDF-C/Fortran, OpenBLAS, Boost |
| `lang` | Python, NumPy, R, Julia, Octave, MATLAB, Mathematica, SQLite |
| `apps` | BLAST+, HMMER, Quantum ESPRESSO, gnuplot, PyTorch and TensorFlow (CPU) |
| `gpu` | CUDA, GROMACS, PyTorch, TensorFlow, GPU benchmark |
| `benchmarks` | STREAM, LINPACK, HPCG, DB12, R-benchmark-25, fio |
| `network` | OSU latency, bandwidth, bi-bandwidth, allreduce, alltoall, bcast, scatter |
| `default` | scheduler + compilers + mpi + libs + lang + apps |
| `full` | default + gpu + benchmarks + network |

Sites add their own; for example, `sites/tufts/profiles/gpu-types.list` runs the GPU
tests once on every GPU model in the cluster.

## Benchmarks and baselines

| Test | Measures |
|------|----------|
| `stream` | memory bandwidth; arrays sized to 4× the node's L3, one pinned thread per core |
| `linpack_mkl` | dense FP64 GFlops (Intel MKL LINPACK, N=40000 by default) |
| `hpcg_mkl` | sparse/memory-bound GFLOP/s (Intel MKL HPCG) |
| `db12` | per-core CPU score (DIRAC DB12) |
| `r_benchmark` | R + BLAS runtime (R-benchmark-25) |
| `io_fio` | file system: sequential write/read MB/s, 4k random-read IOPS (direct I/O) |
| `gpu_bench` | GPU memory bandwidth, host↔device GB/s, FP32 and FP16 tensor-core GEMM TFLOPS |
| `osu_*` | MPI point-to-point and collective latency/bandwidth |

Numbers are captured from the output and compared with the site's `baselines.conf`:

```ini
[stream@sapphirerapids]          # [test@<cpu arch>], from the node's Slurm features
copy = 407600 -25 50 1           # expected, allowed -25%..+50%, weight
[gpu_bench@h200]                 # [test@<gpu model>]
fp16_gemm_TFLOPS = 872.4 -25 50 1
[osu_latency]
SIZE16384 = 44 -90 60 -1         # negative weight: lower is better
```

Without a baseline a benchmark passes and prints its numbers. Record baselines with:

```bash
hpctest calibrate -p benchmarks -r 3 -- --constraint=icelake
hpctest calibrate --from RUNDIR [RUNDIR ...]     # from runs you already have
```

## Adopting hpctest at your site

```bash
hpctest site init mysite            # probes Slurm and the module system
$EDITOR sites/mysite/site.conf      # fix [aliases] marked NOT FOUND, GPU settings, ...
export HPCTEST_SITE=mysite
hpctest check                       # until clean (map or [disabled] what's missing)
hpctest run -p quick
hpctest calibrate -p benchmarks -r 3
```

`site init` writes the GPU partition, CPU architecture and GPU model features from
`sinfo`, the module init file, and an `[aliases]` section listing every module name
the tests use that `module avail` can't find, with candidate matches.
**[docs/PORTING.md](docs/PORTING.md)** walks through it, including EasyBuild naming,
MPI launchers, per-user limits and cron setup.

## Writing tests

```bash
hpctest new samtools -m samtools -c 'samtools --version | head -1'
hpctest run samtools --keep
hpctest bless RUNDIR/samtools       # take the real output as the expected output
```

Expected-output patterns: `${*}` matches any text, `${NAME}` captures a number for
baselines, and a leading `${?}` makes a line optional. See
**[docs/WRITING_TESTS.md](docs/WRITING_TESTS.md)** for all `#@` keys and conventions.

## Repository layout

```
bin/hpctest              the tool
tests/<name>/            portable tests
profiles/<name>.list     portable profiles
sites/template/          annotated site.conf
sites/tufts/             example: Tufts University HPC
docs/PORTING.md          adopting hpctest at a new site
docs/WRITING_TESTS.md    test format reference
third_party/             licenses of bundled third-party code
CHANGELOG.md
```

## Contributing

Issues and pull requests are welcome, especially new tests, scheduler or
module-system support, and site configs that others can learn from.

- Keep `bin/`, `tests/` and `profiles/` site-neutral. Anything specific to one
  cluster belongs in `sites/<name>/`.
- A new test should declare site-dependent inputs as `#@ param` (plus
  `#@ requires-param` when there is no sensible default) and use portable module names.
- Run `hpctest run <your test>` at least once on a real cluster before submitting.

## License

MIT; see [LICENSE](LICENSE). Some test inputs are third-party code under their own
licenses (OSU Micro-Benchmarks, STREAM, R-benchmark-25, DIRAC DB12, and others); see
[third_party/README.md](third_party/README.md).

## Acknowledgments

Developed at Tufts University Research Technology. Several test cases descend from an
earlier site-internal regression suite.
