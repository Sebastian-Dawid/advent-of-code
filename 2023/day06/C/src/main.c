#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

size_t find_num_greater(size_t t, size_t d)
{
    size_t num = 0;
    for (size_t i = 1; i < t; ++i)
    {
        if (i * (t - i) > d) num++;
    }
    return num;
}

void remove_space(char* restrict trimmed, char* restrict untrimmed)
{
    while (*untrimmed != '\0')
    {
        if (!isspace(*untrimmed))
        {
            *trimmed = *untrimmed;
            trimmed++;
        }
        untrimmed++;
    }
    *trimmed = '\0';
}

size_t part_1(FILE* fd)
{
    char* lineptr1 = NULL;
    char* lineptr2 = NULL;
    size_t length, n;
    size_t prod = 1;

    size_t times[4];
    size_t dists[4];

    length = getline(&lineptr1, &n, fd);
    size_t offset = strcspn(lineptr1, ":") + 1;
    char* rem = lineptr1 + offset;
    size_t idx = 0;
    while (offset < length)
    {
        offset += strspn(lineptr1 + offset, " ");
        rem = lineptr1 + offset;
        times[idx] = atoi(rem);
        idx++;
        offset += strcspn(rem, " ");
    }

    length = getline(&lineptr2, &n, fd);
    offset = strcspn(lineptr2, ":") + 1;
    rem = lineptr2 + offset;
    idx = 0;
    while (offset < length)
    {
        offset += strspn(lineptr2 + offset, " ");
        rem = lineptr2 + offset;
        dists[idx] = atoi(rem);
        idx++;
        offset += strcspn(rem, " ");
    }

    for (size_t i = 0; i < idx; ++i)
    {
        prod *= find_num_greater(times[i], dists[i]);
    }

    free(lineptr1);
    free(lineptr2);
    return prod;
}

size_t part_2(FILE* fd)
{
    char* lineptr1 = NULL;
    char* lineptr2 = NULL;
    size_t length, n;

    length = getline(&lineptr1, &n, fd);
    char* rem = lineptr1 + strcspn(lineptr1, ":") + 1;
    char* time_str = malloc(strlen(rem));
    strncpy(time_str, rem, strlen(rem));
    remove_space(time_str, rem);
    size_t time = atoll(time_str);

    length = getline(&lineptr2, &n, fd);
    rem = lineptr2 + strcspn(lineptr2, ":") + 1;
    char* dist_str = malloc(strlen(rem));
    strncpy(dist_str, rem, strlen(rem));
    remove_space(dist_str, rem);
    size_t dist = atoll(dist_str);

    free(time_str);
    free(dist_str);
    free(lineptr1);
    free(lineptr2);
    return find_num_greater(time, dist);
}

int main(int argc, char** argv)
{
    if (argc != 2)
    {
        fprintf(stderr, "Usage: %s <filename>\n", argv[0]);
        return EXIT_FAILURE;
    }

    const char* filename = argv[1]; // grab filename
    FILE* fd = fopen(filename, "r");
    printf("Part 1: %ld\n", part_1(fd));
    fclose(fd);

    fd = fopen(filename, "r"); // reopen stream
    printf("Part 2: %ld\n", part_2(fd));
    fclose(fd);

    return EXIT_SUCCESS;
}
