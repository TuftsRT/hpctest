! ARPACK dsaupd/dseupd: 4 largest eigenvalues of the 1-D Laplacian tridiag(-1, 2, -1), n = 100.
! Exact: lambda_k = 2 - 2 cos(k pi / (n + 1)), k = n-3 .. n.
program laplace_eig
  implicit none
  integer, parameter :: n = 100, nev = 4, ncv = 20, lworkl = ncv * (ncv + 8)
  double precision :: v(n, ncv), workd(3 * n), workl(lworkl), resid(n), d(nev), z(n, nev)
  double precision :: tol, sigma, exact, maxerr, pi
  integer :: iparam(11), ipntr(11), ido, info, ierr, k
  logical :: sel(ncv)
  character(len=1) :: bmat = 'I'
  character(len=2) :: which = 'LA'

  tol = 0d0; ido = 0; info = 0
  iparam = 0; iparam(1) = 1; iparam(3) = 300; iparam(7) = 1
  do
    call dsaupd(ido, bmat, n, which, nev, tol, resid, ncv, v, n, iparam, ipntr, workd, workl, lworkl, info)
    if (ido /= -1 .and. ido /= 1) exit
    call lap(workd(ipntr(1)), workd(ipntr(2)))
  end do
  if (info < 0) then
    print *, 'dsaupd error', info; stop 1
  end if
  call dseupd(.true., 'A', sel, d, z, n, sigma, bmat, n, which, nev, tol, resid, ncv, v, n, &
              iparam, ipntr, workd, workl, lworkl, ierr)
  if (ierr /= 0) then
    print *, 'dseupd error', ierr; stop 1
  end if
  pi = acos(-1d0); maxerr = 0d0
  print '(a, i0)', 'converged Ritz values: ', iparam(5)
  do k = 1, nev
    exact = 2d0 - 2d0 * cos(dble(n - nev + k) * pi / dble(n + 1))
    maxerr = max(maxerr, abs(d(k) - exact))
    print '(a, i0, a, f12.8)', 'lambda(', n - nev + k, ') = ', d(k)
  end do
  if (maxerr < 1d-10) then
    print '(a)', 'max error vs analytic < 1e-10'
  else
    print '(a, es10.2)', 'max error vs analytic: ', maxerr
  end if
contains
  subroutine lap(x, y)
    double precision, intent(in) :: x(n)
    double precision, intent(out) :: y(n)
    integer :: i
    do i = 1, n
      y(i) = 2d0 * x(i)
      if (i > 1) y(i) = y(i) - x(i - 1)
      if (i < n) y(i) = y(i) - x(i + 1)
    end do
  end subroutine lap
end program laplace_eig
