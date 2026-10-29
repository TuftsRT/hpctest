! Solve a 3x3 linear system (dgesv) and find the eigenvalues of a
! symmetric matrix (dsyev); both have exact answers.
program lapack_test
  implicit none
  double precision :: a(3,3), b(3), s(3,3), w(3), work(64)
  integer :: ipiv(3), info

  a = reshape([2d0, 1d0, 1d0,  1d0, 3d0, 2d0,  1d0, 0d0, 0d0], [3,3])
  b = [4d0, 5d0, 6d0]
  call dgesv(3, 1, a, 3, ipiv, b, 3, info)
  print '(a,i0)', 'dgesv info = ', info
  print '(a,3f10.5)', 'x =', b

  ! tridiagonal [2 -1; -1 2 -1; -1 2]: eigenvalues 2-sqrt(2), 2, 2+sqrt(2)
  s = reshape([2d0, -1d0, 0d0,  -1d0, 2d0, -1d0,  0d0, -1d0, 2d0], [3,3])
  call dsyev('N', 'U', 3, s, 3, w, work, size(work), info)
  print '(a,i0)', 'dsyev info = ', info
  print '(a,3f10.5)', 'eigenvalues =', w
end program lapack_test
