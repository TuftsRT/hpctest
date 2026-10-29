# Changelog

## Unreleased

- Compiler/MPI detection: `hpctest site init` and the new `hpctest check --fix` find, for
  each test whose modules fail to load or load with a version swap, an installed
  `compiler`/`mpi` version that loads cleanly. They write it to `[params:<test>]`, and
  write tests whose modules aren't available under `[disabled]`. On the Tufts module tree
  this reproduces the hand-written netCDF/NWChem settings with no manual edits.
- `hpctest check` reports SWAPPED when a later module silently replaces an earlier one
  (e.g. `nwchem` swapping `openmpi/5.0.7` for `openmpi/4.1.7`). With no
  selection it also checks the compiler/MPI variants from the profiles.
- `[params:<test>:<variant>]` sets parameters for one profile variant and beats the
  profile's own values.
- Removed the CPU `quantum_espresso` test (`quantum_espresso_gpu` remains).
- `blast` loads the module `blast` by default (was `blast-plus`).
- `site init` writes NOT FOUND aliases as comments; an empty alias loaded nothing and
  hid the problem.

- Multi-node MPI: `mpi_collectives` (16 ranks on 4 nodes; sendrecv to 32 MB, isend,
  bcast, allreduce, alltoall, every element verified; Open MPI, Intel MPI and MVAPICH2
  variants), `mpi_io` (collective MPI-IO to one shared file from 2 nodes, read back
  cross-node), `mpi_openmp` (hybrid MPI+OpenMP: no two threads share a CPU).
- Scheduler: `slurm_cpu_bind` (`srun -c N --cpu-bind=cores` gives tasks disjoint CPUs).
- Multi-GPU and multi-node GPU: `cuda_p2p` (GPU-to-GPU copies and peer reads, data
  checked), `cuda_mpi` (CUDA-aware MPI with device buffers across 2 nodes), `pytorch_ddp`
  (DDP on 2 GPUs) and `pytorch_ddp_multinode` (DDP on 2 nodes; reports the NCCL transport),
  `lammps_gpu`, `quantum_espresso_gpu`. All report bandwidths for GPU baselines.
- Applications and libraries: `star`, `hisat2`, `salmon`, `kallisto`, `featurecounts`,
  `gatk4`, `picard`, `fastp`, `cutadapt`, `trimmomatic`, `seqtk`, `vcftools`, `plink2`,
  `megahit`, `spades`, `diamond`, `mmseqs2`, `fasttree`, `iqtree`, `raxml_ng` (MPI, 2 nodes),
  `prodigal`, `multiqc`, `r_bioconductor`, `nwchem` (MPI, 2 nodes), `arpack`, `suite_sparse`;
  earlier in this cycle `samtools`, `bcftools`, `bedtools`, `minimap2`, `bowtie2`, `fastqc`,
  `lammps`, `eigen`, `lapack`, `scalapack`, `nco`, `cdo`, `gdal`, `cmake_build`,
  `java_hello`, `perl_hello`, `jupyter`, and the `tools` profile.
- Profiles: `mpi`, `gpu`, `scheduler`, `apps`, `libs` extended; Tufts `gpu-types` runs
  `cuda_p2p` and `pytorch_ddp` on every GPU model.

- 13 new tests:
  - Node health: `node_health` (clock sync, user/group lookup, DNS, `/tmp` space,
    file systems mounted, responsive and writable), `node_rdma` (InfiniBand/RoCE
    ports active at the expected rate).
  - GPU: `gpu_isolation` (a 1-GPU job can open only its own GPU), `gpu_health`
    (uncorrectable ECC errors, pending page retirement, PCIe link width),
    `nccl_allreduce` (correct sum + bus bandwidth across 2 GPUs).
  - Containers: `apptainer` (pull, run, same user, bind mounts, exit code),
    `apptainer_gpu` (`--nv`), `apptainer_mpi` (`srun` + MPI inside a container).
  - Scheduler: `slurm_timeout`, `slurm_array`, `slurm_dependency`,
    `slurm_accounting` (sacct state, exit code, MaxRSS), `slurm_srun_mpi`
    (`srun --mpi=pmix`, no mpirun).
- New profiles `node` and `containers`; `default` now includes both, `scheduler` and
  `gpu` include the new tests, `quick` includes `node_health`.
- `bin/hpctest`: test jobs no longer inherit the `SLURM_*` variables of the
  allocation `hpctest` runs in; before, every `srun` in a test failed with
  "SLURM_MEM_PER_CPU, SLURM_MEM_PER_GPU, and SLURM_MEM_PER_NODE are mutually exclusive"
  when `hpctest run` was started inside a job (required at sites with
  `require_allocation = yes`).
- `bin/hpctest`: job wait loop has a deadline and tolerates shared-file-system lag;
  `--local` kills a timed-out test's whole process group and runs serial/exclusive
  tests one at a time; `calibrate --tolerance` is validated.
- `selftest/`: offline tests for the driver (`python3 -m unittest discover -s selftest`).

## 1.0.0 (2026-10-28)

First public release.

- `bin/hpctest`: single-file driver (Python 3.6+, standard library only) for Slurm and
  Lmod / Environment Modules 4+.
- Site layer: `sites/<name>/site.conf` (module aliases, GPU partition and request
  syntax, account/QOS, exclusive-node limit, CPU/GPU architecture features, parameters,
  disabled tests), `baselines.conf`, `smoke.conf`, site profiles and tests.
- Commands: `list`, `profiles`, `show`, `check`, `run`, `report`, `modules`,
  `calibrate` (including `--from` existing runs), `site list|show|init`, `new`, `bless`.
- Result classes: PASS, FAIL, PERF, MODULE, BUILD, JOB, SUBMIT, PENDING, SKIP.
- 50 portable tests: compilers, MPI, libraries, languages, applications, GPU,
  Slurm/cgroup/node configuration, and CPU, GPU, network and file-system benchmarks.
- Portable profiles: quick, default, full, scheduler, compilers, mpi, libs, lang,
  apps, gpu, benchmarks, network.
- Example site: `sites/tufts`. Annotated template: `sites/template`.
