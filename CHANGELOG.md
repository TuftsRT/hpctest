# Changelog

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
