#include <stdio.h>

static int depth;

void crash_here(int *p)
{
    *p = 42;  /* p is NULL */
}

void recurse(int n)
{
    depth = n;
    if (n == 0)
        crash_here(NULL);
    else
        recurse(n - 1);
}

int main(void)
{
    recurse(2);
    printf("not reached\n");
    return 0;
}
