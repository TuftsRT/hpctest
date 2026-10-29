#include <stdio.h>
#include <stdlib.h>

long square(long x);

int main(int argc, char **argv)
{
    long x = argc > 1 ? atol(argv[1]) : 2;
    printf("square(%ld) = %ld\n", x, square(x));
    return 0;
}
