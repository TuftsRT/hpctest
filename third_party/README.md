# Third-party code and data

Licenses below come from file headers or the upstream projects; confirm them before
relying on this table. hpctest itself is MIT licensed (see `LICENSE`). Some test inputs are third-party
works, redistributed unmodified or lightly modified for testing, under their own terms:

| Path | Origin | License |
|------|--------|---------|
| `tests/osu_*/osu_*.c`, `osu_coll.h` | OSU Micro-Benchmarks, The Ohio State University | BSD-style; see `OSU-MICRO-BENCHMARKS-COPYRIGHT` |
| `tests/stream/stream.c` | STREAM 5.9, John D. McCalpin | STREAM license (in the file header): published results must follow the STREAM run rules and be labelled as such when modified |
| `tests/r_benchmark/R-25` | R Benchmark 2.5, Simon Urbanek | GPL-2.0-or-later (file header) |
| `tests/db12/DIRACbenchmark.py` | DIRAC Benchmark 2012 (R. Graciani, A. McNab, B. Bockelman); ported to Python 3 | No license stated in the file; DIRAC is GPL-3.0. **Verify before redistributing.** |
| `tests/netcdf_c/simple_xy_wr.c`, `tests/netcdf_fortran/simple_xy_wr.f90` | Unidata netCDF examples | Unidata netCDF license (BSD-style) |
| `tests/pnetcdf/pnetcdf-write-standard.c` | PnetCDF examples | PnetCDF license (BSD-style) |
| `tests/hmmer/globins4.*` | HMMER tutorial data | BSD-3-Clause (HMMER) |
| `tests/quantum_espresso_gpu/*.UPF` | Quantum ESPRESSO pseudopotentials | as distributed with Quantum ESPRESSO (GPL) |

Other test sources (`hello.c`, `mpi_hello.c`, `gpu_bench.cu`, the Boost, GSL, FFTW,
HDF5, OpenBLAS and Python examples, ...) are part of hpctest under the MIT license
unless their header says otherwise.
