#include <stdio.h>
#include <gsl/gsl_sf_bessel.h>

int main (int argc, char *argv[])
{
  double x = atof(argv[1]);
  double y = gsl_sf_bessel_J0(x);
  // Result is accurate to IEEE double precision (15-17 significant decimal
  // digits). Print it to 14 digits to be safe and avoid rounding side effects.
  printf ("J0(%g) = %.14f\n", x, y);
  return(0);
}
