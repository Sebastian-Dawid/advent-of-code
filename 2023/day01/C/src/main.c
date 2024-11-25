#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

uint32_t part_1(FILE* fd)
{
    char* lineptr = NULL;
    size_t length, n;
    uint32_t sum = 0;
    while ((length = getline(&lineptr, &n, fd)) != -1) // loop over all lines
    {
        char first, last;
        int first_found = 0;
        for (uint32_t i = 0; i < length; ++i) // loop over all chars in a line
        {
            if (*(lineptr + i) < 0x30 || *(lineptr + i) > 0x39) // check if the current char is a number in ASCII
            {
                continue; // if not go to the next char
            }
            if (first_found == 0)
            {
                first = *(lineptr + i);
                first_found = 1;
            }
            last = *(lineptr + i);
        }
        // add the number to the sum
        sum += (first - 0x30) * 10;
        sum += last - 0x30;
    }
    free(lineptr);
    return sum;
}

char check_written_digit(char* word, uint32_t remaining_length)
{
    // length 3
    if (remaining_length < 3) return 0;
    if (strncmp(word, "one", 3) == 0) return 0x31;
    if (strncmp(word, "two", 3) == 0) return 0x32;
    if (strncmp(word, "six", 3) == 0) return 0x36;
    
    // length 4
    if (remaining_length < 4) return 0;
    if (strncmp(word, "four", 4) == 0) return 0x34;
    if (strncmp(word, "five", 4) == 0) return 0x35;
    if (strncmp(word, "nine", 4) == 0) return 0x39;
    
    // length 5
    if (remaining_length < 5) return 0;
    if (strncmp(word, "three", 5) == 0) return 0x33;
    if (strncmp(word, "seven", 5) == 0) return 0x37;
    if (strncmp(word, "eight", 5) == 0) return 0x38;
    
    return 0;
}

uint32_t part_2(FILE* fd)
{
    char* lineptr = NULL;
    size_t length, n;
    uint32_t sum = 0;
    while ((length = getline(&lineptr, &n, fd)) != -1) // loop over all lines
    {
        char first, last;
        int first_found = 0;
        char current_char;
        for (uint32_t i = 0; i < length; ++i) // loop over all chars in a line
        {
            if (*(lineptr + i) < 0x30 || *(lineptr + i) > 0x39) // check if the current char is a number in ASCII
            {
                if ((current_char = check_written_digit(lineptr + i, length - i)) == 0)
                {
                    continue; // if not go to the next char
                }
            }
            else
            {
                current_char = *(lineptr + i);
            }
            if (first_found == 0)
            {
                first = current_char;
                first_found = 1;
            }
            last = current_char;
        }
        // add the number to the sum
        sum += (first - 0x30) * 10;
        sum += last - 0x30;
    }
    free(lineptr);
    return sum;
}

int main(int argc, char** argv)
{
    if (argc != 2)
    {
        fprintf(stderr, "Usage: <prog> <filename>");
        return EXIT_FAILURE;
    }

    const char* filename = argv[1]; // grab filename
    FILE* fd = fopen(filename, "r");
    printf("Part 1: %d\n", part_1(fd));
    fclose(fd);

    fd = fopen(filename, "r"); // reopen stream
    printf("Part 2: %d\n", part_2(fd));
    fclose(fd);

    return EXIT_SUCCESS;
}
