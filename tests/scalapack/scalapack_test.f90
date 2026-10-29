! Solve A x = b with ScaLAPACK pdgesv on a 2 x (nprocs/2) BLACS grid.
! A = ones + n*I and b = 2n, so the exact solution is x = 1 everywhere.
program scalapack_test
  use mpi
  implicit none
  integer, parameter :: n = 200, nb = 16
  integer :: ictxt, nprow, npcol, myrow, mycol, info, ginfo, ierr, rank, nprocs
  integer :: mloc, nloc, lld, i, j
  integer :: desca(9), descb(9)
  integer, allocatable :: ipiv(:)
  double precision, allocatable :: a(:,:), b(:)
  double precision :: err, gerr
  integer, external :: numroc, indxl2g

  call mpi_init(ierr)
  call mpi_comm_rank(mpi_comm_world, rank, ierr)
  call mpi_comm_size(mpi_comm_world, nprocs, ierr)
  nprow = 2
  npcol = nprocs / 2
  call blacs_get(-1, 0, ictxt)
  call blacs_gridinit(ictxt, 'R', nprow, npcol)
  call blacs_gridinfo(ictxt, nprow, npcol, myrow, mycol)

  mloc = numroc(n, nb, myrow, 0, nprow)
  nloc = numroc(n, nb, mycol, 0, npcol)
  lld = max(1, mloc)
  call descinit(desca, n, n, nb, nb, 0, 0, ictxt, lld, info)
  call descinit(descb, n, 1, nb, nb, 0, 0, ictxt, lld, info)
  allocate(a(lld, max(1, nloc)), b(lld), ipiv(mloc + nb))

  do j = 1, nloc
     do i = 1, mloc
        a(i, j) = 1d0
        if (indxl2g(i, nb, myrow, 0, nprow) == indxl2g(j, nb, mycol, 0, npcol)) &
             a(i, j) = 1d0 + n
     end do
  end do
  b = 2d0 * n

  call pdgesv(n, 1, a, 1, 1, desca, ipiv, b, 1, 1, descb, info)

  ! b is distributed over process column 0 only
  err = 0d0
  if (mycol == 0 .and. mloc > 0) err = maxval(abs(b(1:mloc) - 1d0))
  call mpi_allreduce(err, gerr, 1, mpi_double_precision, mpi_max, mpi_comm_world, ierr)
  call mpi_allreduce(abs(info), ginfo, 1, mpi_integer, mpi_max, mpi_comm_world, ierr)
  if (rank == 0) then
     print '(a,i0,a,i0,a,i0)', 'BLACS grid ', nprow, ' x ', npcol, ', n = ', n
     print '(a,i0)', 'pdgesv info = ', ginfo
     if (gerr < 1d-10) then
        print '(a)', 'solution correct'
     else
        print '(a,es10.2)', 'solution WRONG, max error ', gerr
     end if
  end if
  call blacs_gridexit(ictxt)
  call mpi_finalize(ierr)
end program scalapack_test
