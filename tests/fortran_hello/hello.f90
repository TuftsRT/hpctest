program hello
  implicit none
  integer :: i
  real(8) :: s
  s = 0.0d0
  do i = 1, 100
    s = s + dble(i)
  end do
  print '(a)', 'Hello from Fortran'
  print '(a,f8.1)', 'sum 1..100 =', s
end program hello
