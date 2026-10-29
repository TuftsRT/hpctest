# Changelog

## Unreleased

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
