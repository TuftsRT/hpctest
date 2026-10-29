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
- **122 tests** covering compilers, MPI (multi-node correctness, MPI-IO, hybrid), numerical/I-O
  libraries, languages, applications, GPUs (single, multi-GPU, multi-node), containers,
  Slurm/cgroups, node health, and CPU/GPU/network/file-system benchmarks.

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
- Optional, for the tests that use them: Apptainer/Singularity, NVIDIA GPUs (CUDA, NCCL),
  `ibstat` (infiniband-diags) for `node_rdma`

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

You can also deploy it as a module. To load the module:
```
module load hpctest
hpctest --version
```
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
| `hpctest check [TESTS / -p PROFILE] [--fix]` | load each test's modules on this node; no jobs. Flags modules a later load silently swapped. `--fix` writes working compiler/MPI versions and `[disabled]` entries to `site.conf` |
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
| Compilers | `c_hello`, `fortran_hello`, `openmp_hello` (GCC, oneAPI, LLVM, NVHPC via params), `cmake_build` |
| MPI | `mpi_hello` (any MPI × compiler via params), `mpi_collectives` (16 ranks on 4 nodes, every message verified), `mpi_io` (MPI-IO to one shared file from 2 nodes), `mpi_openmp` (hybrid, thread placement), `pnetcdf`, `scalapack` |
| Libraries | `fftw`, `gsl`, `hdf5`, `netcdf_c`, `netcdf_fortran`, `openblas`, `boost`, `eigen`, `lapack` (netlib, OpenBLAS, MKL), `arpack`, `suite_sparse`, `nco`, `cdo`, `gdal` |
| Languages | `python_hello`, `python_numpy`, `r_hello`, `r_bioconductor`, `julia_hello`, `octave_hello`, `matlab_hello`, `mathematica_hello`, `sqlite`, `java_hello`, `perl_hello`, `jupyter` |
| Applications | `blast`, `hmmer`, `lammps`, `nwchem` (2 nodes), `gnuplot`, `pytorch_cpu`, `tensorflow_cpu` |
| Bioinformatics | alignment: `samtools`, `bcftools`, `bedtools`, `minimap2`, `bowtie2`, `star`, `hisat2`; RNA-seq: `salmon`, `kallisto`, `featurecounts`; variants: `gatk4`, `picard`, `vcftools`, `plink2`; reads: `fastqc`, `fastp`, `cutadapt`, `trimmomatic`, `seqtk`, `multiqc`; assembly: `megahit`, `spades`; search: `diamond`, `mmseqs2`; phylogeny: `fasttree`, `iqtree`, `raxml_ng` (MPI, 2 nodes); genes: `prodigal` |
| Tools | `valgrind`, `gdb`, `hwloc`, `gnu_parallel`, `nextflow`, `ffmpeg`, `imagemagick` |
| Scheduler | `slurm_cpuset`, `slurm_memory`, `slurm_oom`, `slurm_exclusive`, `slurm_multinode`, `slurm_timeout`, `slurm_array`, `slurm_dependency`, `slurm_accounting`, `slurm_srun_mpi`, `slurm_cpu_bind` |
| GPU, multi-GPU, multi-node GPU | `cuda_vector_add`, `cuda_p2p` (2 GPUs: peer copies, data checked), `cuda_mpi` (CUDA-aware MPI between GPUs on 2 nodes), `pytorch_ddp` (DDP on 2 GPUs), `pytorch_ddp_multinode` (DDP on 2 nodes, reports the NCCL transport), `nccl_allreduce`, `lammps_gpu`, `quantum_espresso_gpu`, `gromacs`, `pytorch_gpu`, `tensorflow_gpu` |
| Node health | `node_health`, `node_rdma`, `slurm_node_config`, `gpu_health`, `gpu_isolation` |
| Containers | `apptainer`, `apptainer_gpu`, `apptainer_mpi` |
| Benchmarks | `stream`, `linpack_mkl`, `hpcg_mkl`, `db12`, `r_benchmark`, `io_fio`, `gpu_bench`, `nccl_allreduce`, `osu_latency`, `osu_bw`, `osu_bibw`, `osu_allreduce`, `osu_alltoall`, `osu_bcast`, `osu_scatter` |

`hpctest list` shows them all with descriptions; `hpctest show TEST` shows one in full.

## Profiles

| Profile | Contents |
|---------|----------|
| `quick` | C, OpenMP, MPI, Python, R, SQLite, cgroup CPU and memory limits, node basics |
| `scheduler` | cgroups, OOM kill, exclusive allocation, multi-node `srun`, node hardware vs. Slurm config, step time limits, job arrays, dependencies, `sacct` accounting, `srun --mpi` launch, per-task CPU binding |
| `node` | clock sync, user/group lookup, DNS, `/tmp` space, file systems, RDMA ports, hardware vs. Slurm config |
| `containers` | Apptainer: image pull, user, bind mounts, exit codes; MPI inside a container |
| `compilers` | GCC, Intel oneAPI, LLVM and NVHPC (C, Fortran, OpenMP), CUDA, CMake build |
| `mpi` | OpenMPI and MVAPICH2 with GCC and oneAPI, Intel MPI; multi-node data correctness (Open MPI, Intel MPI, MVAPICH2), MPI-IO, hybrid MPI+OpenMP, PnetCDF, ScaLAPACK |
| `libs` | FFTW, GSL, HDF5, netCDF-C/Fortran, OpenBLAS, Boost, Eigen, LAPACK (3 providers), ARPACK, SuiteSparse, NCO, CDO, GDAL |
| `lang` | Python, NumPy, R, Julia, Octave, MATLAB, Mathematica, SQLite, Java, Perl, Jupyter |
| `apps` | BLAST+, HMMER, LAMMPS, NWChem, gnuplot, PyTorch and TensorFlow (CPU), 28 bioinformatics tools |
| `tools` | Valgrind, GDB, hwloc, GNU parallel, Snakemake, Nextflow, FFmpeg, ImageMagick |
| `gpu` | CUDA, GROMACS, PyTorch, TensorFlow, LAMMPS and Quantum ESPRESSO GPU builds, GPU benchmark, GPU isolation and health, multi-GPU (P2P, NCCL, PyTorch DDP), multi-node GPU (CUDA-aware MPI, DDP), Apptainer `--nv` |
| `benchmarks` | STREAM, LINPACK, HPCG, DB12, R-benchmark-25, fio |
| `network` | OSU latency, bandwidth, bi-bandwidth, allreduce, alltoall, bcast, scatter |
| `default` | scheduler + node + compilers + mpi + libs + lang + apps + containers + tools |
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
| `nccl_allreduce` | NCCL all-reduce bus bandwidth across 2 GPUs of one node (GB/s) |
| `cuda_p2p` | GPU0↔GPU1 copy bandwidth within a node (GB/s) |
| `pytorch_ddp`, `pytorch_ddp_multinode` | NCCL all-reduce bus bandwidth through PyTorch, in one node and across 2 nodes (GB/s) |
| `cuda_mpi` | MPI device-to-device bandwidth between GPUs on 2 nodes (GB/s) |
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
hpctest site init mysite            # probes Slurm and modules, finds working compiler/MPI
$EDITOR sites/mysite/site.conf      # review: [disabled], aliases marked NOT FOUND, GPU settings
export HPCTEST_SITE=mysite
hpctest check                       # should be clean; after module changes: hpctest check --fix
hpctest run -p quick
hpctest calibrate -p benchmarks -r 3
```

`site init` writes the GPU partition, CPU architecture and GPU model features from
`sinfo`, the module init file, and an `[aliases]` section listing every module name
the tests use that `module avail` can't find, with candidate matches. It then loads
every test's modules, including the compiler and MPI variants in the profiles, and fixes
what it can:

- **Compiler/MPI detection.** If a test's modules fail to load, or a later module
  silently swaps the MPI version (Lmod keeps `is-loaded openmpi` true), it tries other
  installed versions of the test's `compiler`/`mpi` parameters. It starts with the
  versions the test's other modules load by themselves (`netcdf-c` →
  `openmpi/4.1.7`) and writes the first clean combination as
  `[params:<test>]  compiler = gcc/12.4.0    # detected by hpctest`.
- **Not available.** Tests whose modules don't exist, or exist only behind an unrelated
  module level, go under `[disabled]` with the reason, e.g. `lammps_gpu = not available:
  lammps+cuda`. Map the name under `[aliases]` and delete the line to enable the test.

Detection loads modules only; a `hpctest run` confirms the result. Lines a person writes are
never replaced, and `hpctest check --fix` redoes detection after module changes.

`site init` is for a new site. It won't touch an existing `site.conf`:

| Command | Effect on `sites/<name>/` |
|---------|---------------------------|
| `hpctest site init <name>` | writes `site.conf` and runs detection; stops if `site.conf` already exists |
| `hpctest site init <name> --force` | rewrites `site.conf` from scratch (**hand edits are lost**); keeps `baselines.conf`, `smoke.conf`, `profiles/`, `tests/` |
| `hpctest site init <name> --no-probe` | writes `site.conf` without loading modules (no detection) |
| `hpctest check --fix` | for an existing site: edits `site.conf` in place, adding or updating only `# detected by hpctest` lines; comments and your own lines are kept |
**[docs/PORTING.md](docs/PORTING.md)** walks through it, including EasyBuild naming,
MPI launchers, per-user limits and cron setup.

A few tests need site values in `[params]` (`hpctest show <test>` lists a test's params):

| Param | Test | Example |
|-------|------|---------|
| `fs_paths`, `fs_write` | `node_health` | shared file systems that must be mounted / writable |
| `rdma_rate`, `rdma_min_ports` | `node_rdma` | `100` (Gb/s), `1` |
| `image`, `bind_paths` | `apptainer`, `apptainer_gpu` | a local `.sif` if compute nodes can't reach Docker Hub |
| `mpi_image`, `srun_mpi` | `apptainer_mpi` | a `.sif` with an MPI built for PMIx or PMI-2 |

Node problems usually affect one node, not a whole partition, so run the `node` profile
on each node:

```bash
for n in $(sinfo -h -N -p batch -o %N | sort -u); do hpctest run -p node --no-wait -- -w $n; done
```

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
selftest/                offline tests of bin/hpctest (no Slurm needed)
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
- If you change `bin/hpctest`, run `python3 -m unittest discover -s selftest`.

## License

MIT; see [LICENSE](LICENSE). Some test inputs are third-party code under their own
licenses (OSU Micro-Benchmarks, STREAM, R-benchmark-25, DIRAC DB12, and others); see
[third_party/README.md](third_party/README.md).

## Acknowledgments

Developed at Tufts University Research Technology. Several test cases descend from an
earlier site-internal regression suite.
