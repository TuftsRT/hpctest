#include <stdlib.h>
#include <string.h>

/* Two deliberate bugs: a 1-byte heap overflow and a 40-byte leak. */
int main(void)
{
    char *leak = malloc(40);
    memset(leak, 0, 40);
    char *buf = malloc(16);
    buf[16] = 'x';
    free(buf);
    return leak[0];
}
