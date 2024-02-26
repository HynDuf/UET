#include <stdio.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
int value = 5;
int main() {
    printf("\n Before fork()");
    fflush(stdout);
    pid_t pid;
    pid = fork();
    if (pid < 0) { /* error occurred */
        fprintf(stderr, "\n Fork Failed");
        return 1;
    } else if (pid == 0) { /* child process */
        value += 15;
        printf("\n CHILD: value = %d", value);
        /* LINE A */
        return 0;
    } else if (pid > 0) { /* parent process */
        wait(NULL);
        printf("\n PARENT: value = %d", value);
        /* LINE B */
        return 0;
    }
}
