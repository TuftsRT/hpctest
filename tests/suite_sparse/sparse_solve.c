/* SuiteSparse: solve a 5x5 sparse system (UMFPACK user guide example, exact solution
 * x = 1..5) with UMFPACK (LU) and KLU, and a 100x100 SPD 1-D Laplacian with CHOLMOD. */
#include <stdio.h>
#include <math.h>
#include <umfpack.h>
#include <klu.h>
#include <cholmod.h>

static int n = 5;
static int Ap[] = {0, 2, 5, 9, 10, 12};
static int Ai[] = {0, 1, 0, 2, 4, 1, 2, 3, 4, 2, 1, 4};
static double Ax[] = {2., 3., 3., -1., 4., 4., -3., 1., 2., 2., 6., 1.};
static double b[] = {8., 45., -3., 3., 19.};

static void show(const char *who, const double *x, int m)
{
    printf("%s:", who);
    for (int i = 0; i < m; i++) printf(" %.6f", x[i]);
    printf("\n");
}

int main(void)
{
    double x[5];
    void *Symbolic, *Numeric;
    int s = umfpack_di_symbolic(n, n, Ap, Ai, Ax, &Symbolic, NULL, NULL);
    s |= umfpack_di_numeric(Ap, Ai, Ax, Symbolic, &Numeric, NULL, NULL);
    s |= umfpack_di_solve(UMFPACK_A, Ap, Ai, Ax, x, b, Numeric, NULL, NULL);
    umfpack_di_free_symbolic(&Symbolic);
    umfpack_di_free_numeric(&Numeric);
    if (s != UMFPACK_OK) { printf("UMFPACK error %d\n", s); return 1; }
    show("UMFPACK x", x, n);

    klu_common kc;
    klu_defaults(&kc);
    klu_symbolic *ks = klu_analyze(n, Ap, Ai, &kc);
    klu_numeric *kn = ks ? klu_factor(Ap, Ai, Ax, ks, &kc) : NULL;
    double y[5];
    for (int i = 0; i < n; i++) y[i] = b[i];
    if (!kn || !klu_solve(ks, kn, n, 1, y, &kc)) { printf("KLU error %d\n", kc.status); return 1; }
    show("KLU x", y, n);
    klu_free_symbolic(&ks, &kc);
    klu_free_numeric(&kn, &kc);

    /* CHOLMOD: 1-D Laplacian (SPD, n = 100) times ones = (1, 0, ..., 0, 1); solve back */
    cholmod_common c;
    cholmod_start(&c);
    int m = 100;
    cholmod_triplet *T = cholmod_allocate_triplet(m, m, 2 * m, 1, CHOLMOD_REAL, &c);  /* stype 1: upper */
    int *Ti = T->i, *Tj = T->j;
    double *Tx = T->x;
    for (int i = 0; i < m; i++) {
        Ti[T->nnz] = i; Tj[T->nnz] = i; Tx[T->nnz++] = 2.;
        if (i + 1 < m) { Ti[T->nnz] = i; Tj[T->nnz] = i + 1; Tx[T->nnz++] = -1.; }
    }
    cholmod_sparse *A = cholmod_triplet_to_sparse(T, 0, &c);
    cholmod_dense *B = cholmod_zeros(m, 1, CHOLMOD_REAL, &c);
    ((double *)B->x)[0] = ((double *)B->x)[m - 1] = 1.;
    cholmod_factor *L = cholmod_analyze(A, &c);
    cholmod_factorize(A, L, &c);
    cholmod_dense *X = cholmod_solve(CHOLMOD_A, L, B, &c);
    if (!X || c.status != CHOLMOD_OK) { printf("CHOLMOD error %d\n", c.status); return 1; }
    double err = 0.;
    for (int i = 0; i < m; i++) err = fmax(err, fabs(((double *)X->x)[i] - 1.));
    printf("CHOLMOD n=%d nnz(L)=%.0f, max |x - 1| %s\n", m, c.lnz, err < 1e-12 ? "< 1e-12" : "too large");
    cholmod_free_dense(&X, &c); cholmod_free_dense(&B, &c); cholmod_free_factor(&L, &c);
    cholmod_free_sparse(&A, &c); cholmod_free_triplet(&T, &c);
    cholmod_finish(&c);
    return 0;
}
