#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

typedef struct
{
    int64_t values[32]; // fixed length to prevent constant reallocs
    size_t length;
} sequence_t;

sequence_t sequences[200]; // 52.8 kB
size_t sequence_count = 0;

void get_sequences(FILE* fd)
{
    char* lineptr = NULL;
    size_t length, n;

    size_t idx = 0;
    while ((length = getline(&lineptr, &n, fd)) != -1)
    {
        size_t offset = 0;
        sequences[idx].length = 0;
        while (offset < length)
        {
            sequences[idx].values[sequences[idx].length] = atol(lineptr + offset);
            offset += strcspn(lineptr + offset, " ") + 1;
            sequences[idx].length++;
        }

        idx++;
    }
    sequence_count = idx;

    free(lineptr);
}

sequence_t get_subsequence(const sequence_t* s)
{
    sequence_t sequence;
    sequence.length = 0;

    for (size_t i = 1; i < s->length; ++i)
    {
        sequence.values[sequence.length] = s->values[i] - s->values[i - 1];
        sequence.length++;
    }

    return sequence;
}

_Bool is_zero(const sequence_t* s)
{
    for (size_t i = 0; i < s->length; ++i)
    {
        if (s->values[i] != 0) return 0;
    }
    return 1;
}

int64_t part_1()
{
    size_t sum = 0;
    for (size_t i = 0; i < sequence_count; ++i)
    {
        size_t idx = 0;
        sequence_t sub[20];
        sub[0] = sequences[i];
        do {
            idx++;
            sub[idx] = get_subsequence(&sub[idx - 1]);
        } while (is_zero(&sub[idx]) == 0);

        // extrapolate
        int64_t val = 0;
        for (int64_t j = idx - 1; j >= 0; --j)
        {
            val += sub[j].values[sub[j].length - 1];
        }
        sum += val;
    }
    return sum;
}

int64_t part_2()
{
    size_t sum = 0;
    for (size_t i = 0; i < sequence_count; ++i)
    {
        size_t idx = 0;
        sequence_t sub[20];
        sub[0] = sequences[i];
        do {
            idx++;
            sub[idx] = get_subsequence(&sub[idx - 1]);
        } while (is_zero(&sub[idx]) == 0);

        // extrapolate
        int64_t val = 0;
        for (int64_t j = idx - 1; j >= 0; --j)
        {
            val = sub[j].values[0] - val;
        }
        sum += val;
    }
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
    get_sequences(fd);
    fclose(fd);

    printf("Part 1: %ld\n", part_1());
    printf("Part 2: %ld\n", part_2());

    return EXIT_SUCCESS;
}
