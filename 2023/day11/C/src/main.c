#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

typedef struct
{
    int64_t x;
    int64_t y;
    int64_t initial_x;
} galaxy_t;

typedef struct
{
    galaxy_t* values;
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
    vec->capacity = 1;
    vec->length = 0;
    vec->values = malloc(sizeof(galaxy_t));
    return vec;
}

void push(vec_t* vec, galaxy_t value)
{
    if (vec->length == vec->capacity)
    {
        vec->values = realloc(vec->values, sizeof(galaxy_t) * vec->capacity * 2);
        vec->capacity *= 2;
    }
    vec->values[vec->length] = value;
    vec->length++;
}

vec_t galaxies_pt1;
vec_t galaxies_pt2;

void find_galaxies(FILE* fd)
{
    create_vec(&galaxies_pt1);
    create_vec(&galaxies_pt2);
    char* lineptr = NULL;
    size_t length, n;
    int64_t y_pt1 = 0;
    int64_t y_pt2 = 0;
    _Bool expanded[140] = {0};
    size_t cols;
    while ((length = getline(&lineptr, &n, fd)) != -1)
    {
        cols = length;
        _Bool empty = 1;
        for (int64_t x = 0; x < length - 1; ++x)
        {
            if (lineptr[x] == '#')
            {
                galaxy_t galaxy_pt1 = { x, y_pt1, x };
                galaxy_t galaxy_pt2 = { x, y_pt2, x };
                push(&galaxies_pt1, galaxy_pt1);
                push(&galaxies_pt2, galaxy_pt2);
                empty = 0;
                expanded[x] = 1;
            }
        }
        if (empty)
        {
            y_pt1++;
            y_pt2 += 999999;
        }
        y_pt1++;
        y_pt2++;
    }

    for (size_t i = 0; i < cols; ++i)
    {
        for (size_t j = 0; j < galaxies_pt1.length; ++j)
        {
            if (expanded[i] == 0 && galaxies_pt1.values[j].initial_x > i)
            {
                galaxies_pt1.values[j].x++;
                galaxies_pt2.values[j].x += 999999;
            }
        }
    }

    free(lineptr);
}

uint64_t find_distance(vec_t* galaxies)
{
    uint64_t sum = 0;
    for (size_t i = 0; i < galaxies->length; ++i)
    {
        for (size_t j = i + 1; j < galaxies->length; ++j)
        {
            int64_t diff_x = labs(galaxies->values[i].x - galaxies->values[j].x);
            int64_t diff_y = labs(galaxies->values[i].y - galaxies->values[j].y);
            sum += diff_x + diff_y;
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
    find_galaxies(fd);
    fclose(fd);

    printf("Part 1: %ld\n", find_distance(&galaxies_pt1));
    printf("Part 2: %ld\n", find_distance(&galaxies_pt2));

    return EXIT_SUCCESS;
}
