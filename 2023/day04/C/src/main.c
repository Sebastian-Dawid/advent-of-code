#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

uint32_t uint_pow(uint32_t base, uint32_t exp)
{
    uint32_t res = 1;
    while (exp)
    {
        if (exp % 2)
        {
            res *= base;
        }
        exp /= 2;
        base *= base;
    }
    return res;
}

uint32_t part_1(FILE* fd)
{
    char* lineptr = NULL;
    size_t length, n;
    uint32_t sum = 0;
    uint32_t* winning_numbers = NULL;
    _Bool first_line = 1;
    while ((length = getline(&lineptr, &n, fd)) != -1) // loop over all lines
    {
        size_t offset = strcspn(lineptr, ":") + 2;
        char* c_winning_numbers = lineptr + offset;
        size_t bar_offset = strcspn(lineptr, "|") + 2;
        char* c_given_numbers = lineptr + bar_offset;
        size_t winning_numbers_length = (bar_offset - offset - 2)/3;
        uint32_t winners = 0;

        if (first_line)
        {
            winning_numbers = malloc(sizeof(uint32_t) * winning_numbers_length);
            first_line = 0;
        }

        for (size_t i = 0; i < winning_numbers_length; ++i)
        {
            winning_numbers[i] = atoi(c_winning_numbers + 3 * i);
        }
        for (size_t i = 0; i < (length - bar_offset)/3; ++i)
        {
            uint32_t num = atoi(c_given_numbers + 3 * i);
            for (size_t j = 0; j < winning_numbers_length; ++j)
            {
                if (num == winning_numbers[j])
                {
                    winners++;
                    break;
                }
            }
        }

        if (winners > 0)
        {
            sum += uint_pow(2, winners - 1);
        }
    }
    free(winning_numbers);
    free(lineptr);
    return sum;
}

typedef struct
{
    uint32_t* values;
    size_t length;
    size_t capacity;
} vec_t;

vec_t* create_vec()
{
    vec_t* vec = malloc(sizeof(vec_t));
    vec->length = 0;
    vec->capacity = 1;
    vec->values = malloc(sizeof(uint32_t));
    return vec;
}

void delete_vec(vec_t* vec)
{
    free(vec->values);
    free(vec);
}

uint32_t pop(vec_t* vec)
{
    uint32_t val = *vec->values;
    for (size_t i = 1; i < vec->length; ++i)
    {
        vec->values[i - 1] = vec->values[i];
    }
    return val;
}

void push(vec_t* vec, uint32_t value)
{
    if (vec->length == vec->capacity)
    {
        vec->values = realloc(vec->values, sizeof(uint32_t) * vec->capacity * 2);
        vec->capacity *= 2;
    }
    vec->values[vec->length] = value;
    vec->length++;
}

uint32_t sum_vec(vec_t* vec)
{
    uint32_t sum = 0;
    for (size_t i = 0; i < vec->length; ++i)
    {
        sum += vec->values[i];
    }
    return sum;
}

void print_vec(vec_t* vec)
{
    printf("[");
    for (size_t i = 0; i < vec->length; ++i)
        printf("%d, ", vec->values[i]);
    printf("]\n");
}

uint32_t part_2(FILE* fd)
{
    char* lineptr = NULL;
    size_t length, n;
    vec_t* repetitions = create_vec();
    uint32_t* winning_numbers = NULL;
    _Bool first_line = 1;
    uint32_t scratchcard = 0;
    while ((length = getline(&lineptr, &n, fd)) != -1) // loop over all lines
    {
        if (repetitions->length <= scratchcard)
        {
            push(repetitions, 1);
        }
        else
        {
            repetitions->values[scratchcard]++;
        }

        size_t offset = strcspn(lineptr, ":") + 2;
        char* c_winning_numbers = lineptr + offset;
        size_t bar_offset = strcspn(lineptr, "|") + 2;
        char* c_given_numbers = lineptr + bar_offset;
        size_t winning_numbers_length = (bar_offset - offset - 2)/3;
        uint32_t winners = 0;

        if (first_line)
        {
            winning_numbers = malloc(sizeof(uint32_t) * winning_numbers_length);
            first_line = 0;
        }

        for (size_t i = 0; i < winning_numbers_length; ++i)
        {
            winning_numbers[i] = atoi(c_winning_numbers + 3 * i);
        }
        for (size_t i = 0; i < (length - bar_offset)/3; ++i)
        {
            uint32_t num = atoi(c_given_numbers + 3 * i);
            for (size_t j = 0; j < winning_numbers_length; ++j)
            {
                if (num == winning_numbers[j])
                {
                    winners++;
                    break;
                }
            }
        }

        for (size_t i = 0; i < repetitions->values[scratchcard]; ++i)
        {
            for (size_t j = 1; j <= winners; ++j)
            {
                if (repetitions->length <= scratchcard + j)
                {
                    push(repetitions, 1);
                }
                else
                {
                    repetitions->values[scratchcard + j]++;
                }
            }
        }

        scratchcard++;
    }

    uint32_t sum = sum_vec(repetitions);

    delete_vec(repetitions);
    free(winning_numbers);
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
