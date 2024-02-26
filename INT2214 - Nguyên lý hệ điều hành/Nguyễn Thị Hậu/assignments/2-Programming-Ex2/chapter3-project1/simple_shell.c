#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>
#include <string.h>

#define MAX_LINE 80 /* The maximum length command */
#define HISTORY_SIZE 10 /* Maximum number of commands to store in history */

char *history[HISTORY_SIZE]; /* History buffer */
int history_count = 0; /* Number of commands in history */

void add_to_history(const char *command) {
    if (history_count == HISTORY_SIZE) {
        history_count--;
        // Shift existing history to make room for the new command
        for (int i = 0; i < HISTORY_SIZE - 1; i++) {
            history[i] = history[i + 1];
        }
        free(history[HISTORY_SIZE - 1]);
    }
    // Allocate memory for the new command
    history[history_count] = strdup(command);
    if (history_count < HISTORY_SIZE) {
        history_count++;
    }
}

void print_history() {
    for (int i = history_count - 1; i >= 0; i--) {
        printf("%d %s\n", i + 1, history[i]);
    }
}

int main(void) {
    char *args[MAX_LINE/2 + 1]; /* command line arguments */
    int should_run = 1; /* flag to determine when to exit program */

    while (should_run) {
        printf("osh>");
        fflush(stdout);

        char input[MAX_LINE];
        fgets(input, MAX_LINE, stdin);
        
        // Create a copy of the input for tokenization
        char input_copy[MAX_LINE];
        strcpy(input_copy, input);

        // Tokenize the input copy
        char *token = strtok(input_copy, " \n");
        int i = 0;
        while (token != NULL) {
            args[i] = token;
            token = strtok(NULL, " \n");
            i++;
        }
        args[i] = NULL; // Null-terminate the argument list

        // Check if the user wants to exit
        if (strcmp(args[0], "exit") == 0) {
            should_run = 0;
            continue;
        }

        // Handle history command
        if (strcmp(args[0], "history") == 0) {
            print_history();
            continue;
        }

        // Check if the command is accessing history
        if (args[0][0] == '!') {
            int index;
            if (args[0][1] == '!') {
                index = history_count - 1; // !! means the most recent command
            } else {
                index = atoi(args[1]) - 1; // Extract the index after '!'
            }

            if (index < 0 || index >= history_count) {
                printf("No such command in history.\n");
                continue;
            }

            // Copy the command from history
            strcpy(input, history[index]);

            // Tokenize the command
            token = strtok(input, " \n");
            i = 0;
            while (token != NULL) {
                args[i] = token;
                token = strtok(NULL, " \n");
                i++;
            }
            args[i] = NULL; // Null-terminate the argument list
        }

        // If the command is "exit", "history", or from history ("!!" or "!n"), don't save it to history
        if (strcmp(args[0], "exit") != 0 && strcmp(args[0], "history") != 0 && args[0][0] != '!') {
            // Add the command to history
            add_to_history(input);
        }

        // Check if the command should run in the background
        int background = 0;
        if (strcmp(args[i - 1], "&") == 0) {
            args[i - 1] = NULL; // Remove the '&' from the argument list
            background = 1;
        }

        pid_t pid = fork();
        if (pid < 0) {
            fprintf(stderr, "Fork failed\n");
            return 1;
        } else if (pid == 0) { // Child process
            if (execvp(args[0], args) == -1) {
                fprintf(stderr, "Command execution failed\n");
                return 1;
            }
        } else { // Parent process
            if (!background) {
                wait(NULL); // Wait for the child process to finish unless running in background
            }
        }
    }

    // Free memory allocated for history
    for (int i = 0; i < history_count; i++) {
        free(history[i]);
    }

    return 0;
}
