#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

typedef struct
{
    size_t* values;
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
    vec->values = malloc(sizeof(size_t));
    return vec;
}

void push(vec_t* v, size_t value)
{
    if (v->length == v->capacity)
    {
        v->values = realloc(v->values, sizeof(size_t) * v->capacity * 2);
        v->capacity *= 2;
    }
    v->values[v->length] = value;
    v->length++;
}

typedef enum __attribute__((__packed__))
{
    EMPTY  = 0,
    ROUND  = 1,
    SQUARE = 2
} tile_t;

typedef struct
{
    tile_t* values;
    size_t rows;
    size_t cols;
} matrix_t;

matrix_t* create_matrix(matrix_t* m, size_t rows, size_t cols)
{
    matrix_t* matrix = m;
    if (matrix == NULL)
    {
        matrix = malloc(sizeof(matrix_t));
    }
    matrix->rows = rows;
    matrix->cols = cols;
    matrix->values = malloc(sizeof(tile_t) * rows * cols);
    return matrix;
}

void add_row(matrix_t* m)
{
    m->rows++;
    m->values = realloc(m->values, sizeof(tile_t) * m->rows * m->cols);
}

tile_t* value(matrix_t* m, size_t i, size_t j)
{
    return &m->values[i + j * m->cols];
}

void tilt_north(matrix_t* m, size_t i, size_t j)
{
    int64_t _j = j;
    for (_j = j; _j >= 0; --_j)
    {
        if (*value(m, i, _j) != EMPTY)
        {
            break;
        }
    }
    *value(m, i, _j + 1) = ROUND;
}

void tilt_west(matrix_t* m, size_t i, size_t j)
{
    int64_t _i = i;
    for (_i = i; _i >= 0; --_i)
    {
        if (*value(m, _i, j) != EMPTY)
        {
            break;
        }
    }
    *value(m, _i + 1, j) = ROUND;
}

void tilt_south(matrix_t* m, size_t i, size_t j)
{
    int64_t _j = j;
    for (_j = j; _j < m->rows; ++_j)
    {
        if (*value(m, i, _j) != EMPTY)
        {
            break;
        }
    }
    *value(m, i, _j - 1) = ROUND;
}

void tilt_east(matrix_t* m, size_t i, size_t j)
{
    int64_t _i = i;
    for (_i = i; _i < m->cols; ++_i)
    {
        if (*value(m, _i, j) != EMPTY)
        {
            break;
        }
    }
    *value(m, _i - 1, j) = ROUND;
}

void print_matrix(matrix_t* m);
void spin(matrix_t* m)
{
    for (size_t j = 0; j < m->rows; ++j)
    {
        for (size_t i = 0; i < m->cols; ++i)
        {
            if (*value(m, i, j) == ROUND)
            {
                *value(m, i, j) = EMPTY;
                tilt_north(m, i, j);
            }
        }
    }
    for (size_t j = 0; j < m->rows; ++j)
    {
        for (size_t i = 0; i < m->cols; ++i)
        {
            if (*value(m, i, j) == ROUND)
            {
                *value(m, i, j) = EMPTY;
                tilt_west(m, i, j);
            }
        }
    }
    for (int64_t j = m->rows - 1; j >= 0; --j)
    {
        for (int64_t i = m->cols - 1; i >= 0; --i)
        {
            if (*value(m, i, j) == ROUND)
            {
                *value(m, i, j) = EMPTY;
                tilt_south(m, i, j);
            }
        }
    }
    for (int64_t j = m->rows - 1; j >= 0; --j)
    {
        for (int64_t i = m->cols - 1; i >= 0; --i)
        {
            if (*value(m, i, j) == ROUND)
            {
                *value(m, i, j) = EMPTY;
                tilt_east(m, i, j);
            }
        }
    }
}

size_t hash(matrix_t* m)
{
    size_t hash = m->values[0];
    for (size_t i = 1; i < m->rows * m->cols; ++i)
    {
        hash += m->values[i] * i;
    }
    return hash;
}

void print_matrix(matrix_t* m)
{
    for (size_t j = 0; j < m->rows; ++j)
    {
        for (size_t i = 0; i < m->cols; ++i)
        {
            switch (*value(m, i, j)) {
                case EMPTY:
                    printf(".");
                    break;
                case ROUND:
                    printf("\033[1;32mO");
                    break;
                case SQUARE:
                    printf("\033[0;31m#");
                    break;
            }
            printf("\033[0m");
        }
        printf("\n");
    }
    printf("\n");
}

matrix_t input_pt1;
matrix_t input_pt2;

void matrix_from_file(FILE* fd, matrix_t* m)
{
    char* lineptr = NULL;
    size_t length, n;
    size_t idx = 0;
    while ((length = getline(&lineptr, &n, fd)) != -1) // loop over all lines
    {
        if (idx == 0)
        {
            create_matrix(m, 0, length - 1);
        }
        add_row(m);
        for (size_t i = 0; i < length - 1; ++i)
        {
            tile_t v;
            switch (lineptr[i]) {
                case '.':
                    v = EMPTY;
                    break;
                case 'O':
                    v = ROUND;
                    break;
                case '#':
                    v = SQUARE;
                    break;
            }
            *value(m, i, idx) = v;
        }
        idx++;
    }
    free(lineptr);
}

uint32_t part_1()
{
    uint32_t sum = 0;

    // tilt north
    for (size_t j = 0; j < input_pt1.rows; ++j)
    {
        for (size_t i = 0; i < input_pt1.cols; ++i)
        {
            if (*value(&input_pt1, i, j) == ROUND)
            {
                *value(&input_pt1, i, j) = EMPTY;
                tilt_north(&input_pt1, i, j);
            }
        }
    }

    // calc load
    for (size_t j = 0; j < input_pt1.rows; ++j)
    {
        for (size_t i = 0; i < input_pt1.cols; ++i)
        {
            if (*value(&input_pt1, i, j) == ROUND) sum += input_pt1.rows - j;
        }
    }

    return sum;
}

uint32_t part_2()
{
    uint32_t sum = 0;
    vec_t hashes;
    create_vec(&hashes);
    for (size_t i = 0; i < 1000000000; ++i)
    {
        spin(&input_pt2);
        size_t h = hash(&input_pt2);
        
        size_t cycle_length = 0;
        size_t to_first_cycle = 0;
        for (size_t i = 0; i < hashes.length; ++i)
        {
            if (h == hashes.values[i])
            {
                to_first_cycle = i + 1;
                cycle_length = hashes.length - i;
                break;
            }
        }

        if (cycle_length)
        {
            for (size_t j = 0; j < ((1000000000 - to_first_cycle) % cycle_length); ++j)
            {
                spin(&input_pt2);
            }
            break;
        }
        push(&hashes, h);
    }
    free(hashes.values);

    // calc load
    for (size_t j = 0; j < input_pt2.rows; ++j)
    {
        for (size_t i = 0; i < input_pt2.cols; ++i)
        {
            if (*value(&input_pt2, i, j) == ROUND) sum += input_pt2.rows - j;
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
    matrix_from_file(fd, &input_pt1);
    fclose(fd);
    printf("Part 1: %d\n", part_1());
    
    fd = fopen(filename, "r");
    matrix_from_file(fd, &input_pt2);
    fclose(fd);
    printf("Part 2: %d\n", part_2());

    free(input_pt1.values);
    free(input_pt2.values);

    return EXIT_SUCCESS;
}
