# hpctest expansion: multi-node MPI, multi-GPU and application tests on pax

*Tufts Research Technology · hpctest extension · 2026-10-29*

## Summary

hpctest grew from 63 to **124 tests**. This round added 37:

- **11 infrastructure tests** for what the suite did not cover before: MPI data correctness
  across several nodes, parallel I/O, hybrid MPI+OpenMP, CPU binding, multi-GPU within a
  node, GPU-to-GPU across nodes, and the GPU builds of LAMMPS and Quantum ESPRESSO.
- **26 application and library tests** with known answers (bioinformatics, chemistry,
  sparse/eigen solvers), 24 of which pass.

Running them on pax found **9 problems**, 4 of which directly affect GPU and hybrid users
today.

| # | Problem | Who is affected | Severity |
|---|---------|-----------------|----------|
| 1 | GPU traffic between nodes runs over TCP (~3.3 GB/s) although GPU nodes have 100 Gb/s RoCE | Multi-node GPU training (PyTorch DDP/FSDP), CUDA-aware MPI codes | **High** |
| 2 | `lammps/20240829.2-cuda` has no GPU support (CPU-only Kokkos) | LAMMPS GPU users | **High** |
| 3 | `quantum-espresso/7.4.1-cuda` aborts at start (`libgomp: TODO`) | QE GPU users | **High** |
| 4 | `srun` does not bind tasks to CPUs (no `task/affinity`) | Hybrid MPI+OpenMP and multi-task jobs launched with srun | Medium |
| 5 | Open MPI 5 refuses hybrid jobs when Slurm splits a rank's cores across sockets | Hybrid jobs on shared nodes (failed 2 of 6 runs) | Medium |
| 6 | NGC container `lammps/15Jun2023` crashes on L40S and newer GPUs | LAMMPS GPU users trying the container | Medium |
| 7 | MVAPICH2 2.3.7 reports 1 rank per node for shared-memory communicators | MPI-3 shared-memory / node-aware codes using MVAPICH2 | Low |
| 8 | `hisat2/2.2.1` module has no `hisat2` or `hisat2-build` command | HISAT2 users (module unusable) | **High** |
| 9 | `raxml-ng-mpi/1.2.2` aborts or hangs when ranks span 2 nodes | Multi-node RAxML-NG runs | Medium |

Working correctly: MPI data correctness on 16 ranks / 4 nodes (Open MPI 5, Intel MPI),
MPI-IO to `/cluster/tufts` from 2 nodes, CUDA peer copies between 2 GPUs, single-node
PyTorch DDP on 2 GPUs, and CUDA-aware MPI *correctness* (only its speed is affected).

## New tests

| Test | Resources | What it checks | Result on pax |
|------|-----------|----------------|---------------|
| `mpi_collectives` | 4 nodes × 4 ranks | Sendrecv up to 32 MB, Isend/Irecv, Bcast, Allreduce, Alltoall; every element verified; ranks per node | PASS (Open MPI 5, Intel MPI); FAIL MVAPICH2 (#7) |
| `mpi_io` | 2 nodes × 4 ranks | Collective MPI-IO write of one 128 MB file; each rank reads back blocks written from the other node | PASS |
| `mpi_openmp` | 2 nodes × 2 ranks × 4 threads | No two threads on a node share a CPU | PASS 4/6, FAIL 2/6 (#5) |
| `slurm_cpu_bind` | 1 node, 2 tasks × 4 CPUs | `srun -c 4 --cpu-bind=cores` gives each task its own 4 CPUs | FAIL (#4) |
| `cuda_p2p` | 1 node, 2 GPUs | GPU0↔GPU1 copies (256 MB) both ways, direct peer reads, data checked on GPU; GB/s | PASS (L40S: 22.7 GB/s, no peer access) |
| `cuda_mpi` | 2 nodes × 1 GPU | CUDA-aware MPI with device buffers: sendrecv, allreduce, bcast verified; GB/s | PASS, but 3.2 GB/s (#1) |
| `pytorch_ddp` | 1 node, 2 GPUs | torchrun + NCCL: exact all-reduce, loss decreases, identical weights on all ranks; bus GB/s and NCCL transport | PASS (L40S: 15.3 GB/s via SHM) |
| `pytorch_ddp_multinode` | 2 nodes × 1 GPU | Same, srun + torchrun across nodes | PASS, but 3.4 GB/s over `NET/Socket` (#1) |
| `lammps_gpu` | 1 GPU | LJ melt on the GPU; same step-0 thermo as the CPU test; energy conserved | FAIL (#2) |
| `quantum_espresso_gpu` | 1 GPU | pw.x CO relaxation; same final energy as the CPU test; "GPU acceleration is ACTIVE" | FAIL (#3) |

Profiles: `mpi` gains `mpi_collectives` (Open MPI, Intel MPI, MVAPICH2 variants), `mpi_io`
and `mpi_openmp`; `gpu` gains the six GPU tests; `scheduler` gains `slurm_cpu_bind`.
`sites/tufts/profiles/gpu-types.list` now also runs `cuda_p2p` and `pytorch_ddp` on each
GPU model (A100, H100, H200, L40S, RTX PRO 6000), since peer-to-peer behaviour depends on
each model's PCIe/NVLink topology (compare the earlier pax007 NCCL hang).

Run them with:

```bash
hpctest run -p mpi
hpctest run -p gpu
hpctest run -p gpu-types        # multi-GPU tests on every GPU model
hpctest run slurm_cpu_bind
```

## Findings in detail

### 1. Multi-node GPU traffic uses TCP instead of RoCE

GPU nodes have ConnectX-6 adapters (MT4123) with an active 100 Gb/s port, link layer
Ethernet (RoCE), on `ww1`. Two independent problems keep GPU jobs off it:

- **`ucx/1.18.0` is built `--without-verbs --without-rdmacm --without-cuda --without-gdrcopy`.**
  `ucx_info -d` lists only `tcp`, `posix`, `sysv`, `cma`, `self`. Every MPI built on it
  (including `openmpi/5.0.7-cuda`) therefore has no RDMA and no `cuda_copy`/`cuda_ipc`
  transports. `cuda_mpi` measured 3.2 GB/s GPU-to-GPU between two L40S nodes, the same
  with `UCX_NET_DEVICES=mlx5_0:1` or `mlx5_1:1`.
- **The PyTorch container image has no `libibverbs`.** NCCL logs
  `Failed to open libibverbs.so[.1]` and `Using network Socket`; all-reduce bus bandwidth
  across 2 nodes is 3.4 GB/s.

A 100 Gb/s link should give roughly 10–12 GB/s, so multi-node training and GPU MPI codes
are about 3–4× slower than the hardware allows.

**Fix:** rebuild UCX with `+verbs +rdmacm +cuda` (and `+gdrcopy` if the gdrdrv module is
installed), then rebuild the `-cuda` Open MPI on it; add `rdma-core` (libibverbs,
librdmacm) to the `tuftsttsrt/pytorch` (and `python-gpu`) images. Re-run `cuda_mpi` and
`pytorch_ddp_multinode`: the reported transport should be `NET/IB` and bandwidth should
rise several-fold, after which the measured values can be stored as baselines.

### 2. `lammps/20240829.2-cuda` is CPU-only

- Its Kokkos module is configured `-DKokkos_ENABLE_CUDA=OFF`;
  `lmp -h` reports `KOKKOS package API: Serial`, and the GPU package is not installed.
- `lmp -k on g 1 -sf kk` fails with *"GPUs are requested but Kokkos has not been compiled
  using a GPU-enabled backend"*; `-sf gpu` fails with *"Package gpu command without GPU
  package installed"*.
- The module also does not load the MPI it is linked to (`openmpi/4.1.8-cuda`), so a plain
  `lmp` in a batch job dies in `MPI_Init` (*"OMPI was not built with SLURM's PMI support"*).

**Fix:** rebuild with `kokkos +cuda +wrapper cuda_arch=80,89,90,120` (or the GPU package),
and add `depends_on("openmpi/4.1.8-cuda")` to the modulefile.

### 3. `quantum-espresso/7.4.1-cuda` aborts at start-up

`pw.x` stops immediately with `libgomp: TODO`, before writing any output (also with
`OMP_TARGET_OFFLOAD=DISABLED`). `ldd pw.x` shows both NVHPC's `libnvomp.so` and
gcc-15.1.0's `libgomp.so.1`: a gcc-built OpenMP dependency is mixed into the NVHPC build.

**Fix:** build QE's dependencies (FFTW, OpenBLAS or use NVHPC's BLAS) with NVHPC, or
without OpenMP, so only one OpenMP runtime is linked.

### 4. srun does not bind tasks to CPUs

`TaskPlugin = task/cgroup` without `task/affinity`. With `srun -n 2 -c 4 --cpu-bind=cores`
both tasks get the job's whole CPU set (`0,2,4,6,8,10,12,14` each): 8 CPUs shared, and in
a hybrid job 8 of 16 threads double up on cores.

**Fix:** `TaskPlugin=task/affinity,task/cgroup` in `slurm.conf`. `slurm_cpu_bind` and the
srun form of `mpi_openmp` should then pass.

### 5. Hybrid MPI+OpenMP jobs are refused on some allocations

Open MPI 5 `mpirun --map-by ppr:2:node:pe=4 --bind-to core` binds correctly, but with
`SelectTypeParameters=CR_CPU_MEMORY` a non-exclusive job can receive a rank's CPUs on both
sockets (e.g. pax072: `8,10-11,14-15,17-19`). Open MPI then refuses to start (*"bound to
CPUs in more than one package"*). `mpi_openmp` failed 2 of 6 runs, both on pax[072-073].
No mpirun option tried (`--bind-to core:overload-allowed`, `hwthread`, `--map-by node`,
`slot`) avoids it; `--ntasks-per-socket=1` was not tested because those nodes stayed busy.

**Fix:** with #4 fixed, document `srun --cpu-bind=cores -c N` as the supported launch for
hybrid jobs; consider `CR_Core_Memory`.

### 6. NGC LAMMPS container fails on newer GPUs

`lammps/15Jun2023` contains builds for sm60–sm80 only. On L40S (sm89) it warns
*"Host GPU architecture(sm89) not available in container, using sm60"* and aborts in
`Kokkos::Cuda` initialization. A plain `lmp` fails in `MPI_Init`; it starts only with
`srun --mpi=pmi2`. It may work on the A100 nodes (sm80), but that was not tested.
Together with #2, there is no working GPU LAMMPS on L40S, H100, H200 or RTX PRO 6000.

### 7. MVAPICH2 shared-memory communicator

With `gcc` + `mvapich2/2.3.7-1`, `MPI_Comm_split_type(MPI_COMM_TYPE_SHARED)` returns one
rank per node instead of four (Open MPI and Intel MPI: four). All message data was
correct. Codes that use MPI-3 shared-memory windows or detect node-local ranks this way
(e.g. some hybrid solvers, GPU-per-rank selection) behave wrongly under MVAPICH2.

## Measured values (no baselines yet)

| Test | GPU / nodes | Value |
|------|-------------|-------|
| `cuda_p2p` | 2 × L40S, one node | 22.7 GB/s each direction (no peer access, staged) |
| `pytorch_ddp` | 2 × L40S, one node | 15.3 GB/s bus bandwidth, NCCL `SHM/direct` |
| `pytorch_ddp_multinode` | L40S, 2 nodes | 3.4 GB/s bus bandwidth, NCCL `NET/Socket` |
| `cuda_mpi` | L40S, 2 nodes | 3.2 GB/s device-to-device |

Store baselines only after finding #1 is fixed, otherwise the TCP numbers become the
expected values: `hpctest calibrate cuda_p2p pytorch_ddp -r 2 -- --constraint=<model>`.

## Site configuration changes (`sites/tufts/`)

- `site.conf`: `[params:cuda_mpi] mpi = openmpi/5.0.7-cuda`;
  `[params:lammps_gpu] mpi = openmpi/4.1.8-cuda, lammps = lammps/20240829.2-cuda`;
  `[params:quantum_espresso_gpu] mpi = openmpi/4.1.8-cuda, espresso = quantum-espresso/7.4.1-cuda`.
- `profiles/gpu-types.list`: `cuda_p2p` and `pytorch_ddp` on every GPU model.
- `FINDINGS.local.md`: the findings above, with evidence.

## Application and library tests (26)

Every test runs the software on tiny deterministic inputs (generated in `test.sh` or
bundled, ≤ 40 KB) and checks real answers, not version strings.

| Area | Tests and what is checked | Result |
|------|---------------------------|--------|
| RNA-seq alignment | `star`: 100 reads map uniquely, 20 split over a known GT/AG intron, junction file correct; `hisat2`: same reads and intron | STAR PASS; HISAT2 **FAIL** (#8) |
| Quantification | `salmon`, `kallisto`: 60/40/0 reads over 3 transcripts, exact TPM; `featurecounts`: gene counts 60/40/0 and stranded counts | PASS |
| Variants | `gatk4`: sequence dictionary, SortSam, CountReads = 151, HaplotypeCaller calls a planted hom and het SNP; `picard`: MarkDuplicates flags the 8 planted duplicates, ValidateSamFile clean; `vcftools`, `plink2`: allele frequencies, filters, missingness, HWE | PASS |
| Read processing | `fastp`, `cutadapt`, `trimmomatic`: exact counts of adapter-trimmed, quality-trimmed and dropped reads; `seqtk`: format conversion, revcomp, trimming, masking; `multiqc`: aggregates samtools and cutadapt logs | PASS |
| Assembly | `megahit`, `spades`: a 5 kb genome assembles into 1 contig that is an exact substring of the reference, ≥ 98% coverage | PASS |
| Sequence search | `diamond`, `mmseqs2`: mutated proteins (90% identity) find their source; a random query finds nothing | PASS |
| Phylogeny | `fasttree`, `iqtree`: recover the true topology of a simulated 6-taxon tree, tree length near the true 0.75; `raxml_ng`: same with MPI on 2 nodes | FastTree, IQ-TREE PASS; RAxML-NG **FAIL** (#9) |
| Gene finding | `prodigal`: 4 planted genes on both strands at exact coordinates | PASS |
| R / Bioconductor | `r_bioconductor`: Biostrings, GenomicRanges, edgeR, DESeq2 find the 5 planted DE genes at log2FC ±3 | PASS |
| Chemistry (MPI) | `nwchem`: H2O SCF −76.010482 and MP2 −76.199029 (6-31G*), 4 ranks on 2 nodes | PASS |
| Solvers | `suite_sparse`: UMFPACK, KLU and CHOLMOD solve to the known x; `arpack`: 4 largest Laplacian eigenvalues vs analytic, error < 1e-10 | PASS |

All are in the `apps` profile, except `arpack` and `suite_sparse`, which are in `libs`.
Site settings were added for `arpack` and `nwchem` (gcc/12.4.0 + openmpi/4.1.7 module tree)
and for `raxml_ng` (`srun_mpi = pmi2` for the container's Open MPI).

### 8. `hisat2/2.2.1` has no usable commands

The wrapper directory `/cluster/tufts/apps/container/biocontainers/tools/hisat2/2.2.1/bin/`
contains only `extract_exons.py` and `extract_splice_sites.py`, so `hisat2-build` and
`hisat2` are "command not found". The container image
(`quay.io_biocontainers_hisat2:2.2.1--h1b792b2_3.sif`) works: run directly, it gives the
expected alignments. **Fix:** generate the missing wrapper scripts.

### 9. `raxml-ng-mpi/1.2.2` fails across nodes

With 4 ranks on 2 nodes, ranks on the second node abort with
`load_start_trees: Assertion 'i == instance.opts.num_searches' failed` or the run hangs.
It fails the same way with `--workers 1` and with a user-supplied start tree.
The same run with 4 ranks on 1 node finishes correctly in ~1.5 s. MPI in the image works
across nodes: an allreduce and an 800 KB send/receive succeed with `srun --mpi=pmi2`.
Likely cause: ranks on the other node read `<prefix>.raxml.startTree`, which rank 0 has just
written, through NFS before it is complete. It reproduces on both `/cluster/tufts` and
`/cluster/scratch`. Evidence: `runs/rxdbg/`. Workaround for users: run on one node.

Minor: the `subread` module wraps only featureCounts, exactSNP, detectionCall and
flattenGTF (no `subread-align`, `subjunc` or `subread-buildindex`).

## Previously known failures still present

`java_hello` (the JVM ignores the job's memory limit and sizes its heap to the node) and
`snakemake` (module missing `snakemake_interface_common`), from the run of 2026-10-28.

## Run directories

Evidence for the results above (under `runs/`):

| Run | Contents |
|-----|----------|
| `20261029-080002-ddck` | first `mpi_collectives`, `mpi_io`, `mpi_openmp` |
| `20261029-081507-plys` | `mpi_openmp` ×6 (2 failures on pax[072-073]) |
| `20261029-081901-craz` | full `mpi` profile (11 PASS, MVAPICH2 failure) |
| `20261029-081351-nfok` | `cuda_p2p`, `cuda_mpi` PASS |
| `20261029-081448-qiqo` | `pytorch_ddp`, `pytorch_ddp_multinode` PASS (with NCCL logs) |
| `20261029-081656-bubx` | `lammps_gpu` with the NGC container |
| `20261029-082040-uvdq` | `slurm_cpu_bind` FAIL |
| `20261029-082139-rxlr` | `lammps_gpu`, `quantum_espresso_gpu` FAIL with final error messages |
| `20261029-084105-xbrz` | application tests: 22 PASS, `hisat2` FAIL |
| `20261029-084105-thnb` | `arpack` PASS |
| `20261029-084105-hvvx`, `rxdbg/` | `raxml_ng` FAIL, plus debugging logs |
| `20261029-083354-usuh` | `nwchem` PASS (2 nodes) |
