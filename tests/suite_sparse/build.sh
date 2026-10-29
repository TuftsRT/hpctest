# Build step: runs inside the job after modules load (bash -e).
# Headers may sit in include/ or include/suitesparse/ depending on the install: add both.
inc=$(pkg-config --cflags UMFPACK KLU CHOLMOD 2>/dev/null || true)
$cc -O2 -o sparse_solve sparse_solve.c $inc -lumfpack -lklu -lcholmod -lamd -lcolamd -lsuitesparseconfig -lm
