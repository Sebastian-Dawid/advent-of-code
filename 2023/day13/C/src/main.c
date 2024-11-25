#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

typedef enum __attribute__((__packed__)) // lets make sure this is only one byte
{
    ASH  = 0,
    ROCK = 1
} tile_t;

typedef struct
{
    size_t rows;
    size_t cols;
    tile_t* values;
} pattern_t;

pattern_t create_pattern(size_t rows, size_t cols)
{
    pattern_t p;
    p.cols = cols;
    p.rows = rows;
    p.values = malloc(sizeof(tile_t) * rows * cols);
    return p;
}

void add_row(pattern_t* p, char* str)
{
    p->rows++;
    p->values = realloc(p->values, sizeof(tile_t) * p->rows * p->cols);
    size_t idx = 0;
    while (str[idx] != '\n')
    {
        p->values[(p->rows - 1) * p->cols + idx] = (str[idx] == '#') ? ROCK : ASH;
        idx++;
    }
}

int32_t cmp_rows(pattern_t* p, size_t i, size_t j)
{
    int32_t diffs = 0;
    for (size_t k = 0; k < p->cols; ++k)
    {
        if (p->values[k + p->cols * i] != p->values[k + p->cols * j]) diffs += 1;
    }
    return diffs;
}

int32_t cmp_cols(pattern_t* p, size_t i, size_t j)
{
    int32_t diffs = 0;
    for (size_t k = 0; k < p->rows; ++k)
    {
        if (p->values[k * p->cols + i] != p->values[k * p->cols + j]) diffs += 1;
    }
    return diffs;
}

void destroy_pattern(pattern_t* p)
{
    free(p->values);
}

typedef struct
{
    pattern_t* values;
    size_t length;
    size_t capacity;
} vec_t;

vec_t* create_vec(vec_t* v)
{
    vec_t* vec = v;
    if (vec == NULL)
    {
        vec = malloc(sizeof(vec_t));
    }
    vec->length = 0;
    vec->capacity = 1;
    vec->values = malloc(sizeof(pattern_t));
    return vec;
}

void push(vec_t* v, pattern_t p)
{
    if (v->length == v->capacity)
    {
        v->values = realloc(v->values, sizeof(pattern_t) * v->capacity * 2);
        v->capacity *= 2;
    }
    v->values[v->length] = p;
    v->length++;
}

vec_t patterns;

void read_patterns(FILE* fd)
{
    char* lineptr = NULL;
    size_t length, n;
    uint32_t sum = 0;
    create_vec(&patterns);
    _Bool new_pattern = 1;
    pattern_t pattern;
    while ((length = getline(&lineptr, &n, fd)) != -1) // loop over all lines
    {
        if (lineptr[0] == '\n')
        {
            push(&patterns, pattern);
            new_pattern = 1;
            continue;
        }

        if (new_pattern)
        {
            new_pattern = 0;
            pattern = create_pattern(0, length - 1);
        }

        add_row(&pattern, lineptr);
    }
    push(&patterns, pattern);
    free(lineptr);
}

size_t part_1()
{
    size_t sum = 0;
    for (size_t i = 0; i < patterns.length; ++i)
    {
        for (size_t j = 1; j < patterns.values[i].rows; ++j)
        {
            if (cmp_rows(&patterns.values[i], j - 1, j) == 0)
            {
                _Bool match = 1;
                for (size_t k = 0; k < j; ++k)
                {
                    if (j + k >= patterns.values[i].rows) break;
                    if (cmp_rows(&patterns.values[i], j - 1 - k, j + k) != 0)
                    {
                        match = 0;
                        break;
                    }
                }
                if (match)
                {
                    sum += 100 * j;
                    break;
                }
            }
        }
        
        for (size_t j = 1; j < patterns.values[i].cols; ++j)
        {
            if (cmp_cols(&patterns.values[i], j - 1, j) == 0)
            {
                _Bool match = 1;
                for (size_t k = 0; k < j; ++k)
                {
                    if (j + k >= patterns.values[i].cols) break;
                    if (cmp_cols(&patterns.values[i], j - 1 - k, j + k) != 0)
                    {
                        match = 0;
                        break;
                    }
                }
                if (match)
                {
                    sum += j;
                    break;
                }
            }
        }
    }
    return sum;
}

uint32_t part_2()
{
    size_t sum = 0;
    for (size_t i = 0; i < patterns.length; ++i)
    {
        _Bool found = 0;
        for (size_t j = 1; j < patterns.values[i].rows; ++j)
        {
            if (abs(cmp_rows(&patterns.values[i], j - 1, j)) < 2)
            {
                _Bool match = 1;
                size_t errors = 0;
                for (size_t k = 0; k < j; ++k)
                {
                    if (j + k >= patterns.values[i].rows) break;
                    int32_t cmp = cmp_rows(&patterns.values[i], j - 1 - k, j + k);
                    if (cmp != 0)
                    {
                        if (abs(cmp) == 1 && errors == 0)
                        {
                            errors++;
                        }
                        else
                        {
                            match = 0;
                            break;
                        }
                    }
                }
                if (match && errors == 1)
                {
                    sum += 100 * j;
                    found = 1;
                    break;
                }
            }
        }
        
        if (found) continue;

        for (size_t j = 1; j < patterns.values[i].cols; ++j)
        {
            if (abs(cmp_cols(&patterns.values[i], j - 1, j)) < 2)
            {
                _Bool match = 1;
                size_t errors = 0;
                for (size_t k = 0; k < j; ++k)
                {
                    if (j + k >= patterns.values[i].cols) break;
                    int32_t cmp = cmp_cols(&patterns.values[i], j - 1 - k, j + k);
                    if (cmp != 0)
                    {
                        if (abs(cmp) == 1 && errors == 0)
                        {
                            errors++;
                        }
                        else
                        {
                            match = 0;
                            break;
                        }
                    }
                }
                if (match && errors == 1)
                {
                    sum += j;
                    break;
                }
            }
        }
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
    read_patterns(fd);
    fclose(fd);

    printf("%lu\n", patterns.capacity);
    printf("Part 1: %lu\n", part_1());
    printf("Part 2: %d\n", part_2());

    for (size_t i = 0; i < patterns.length; ++i)
    {
        destroy_pattern(&patterns.values[i]);
    }
    free(patterns.values);

    return EXIT_SUCCESS;
}
