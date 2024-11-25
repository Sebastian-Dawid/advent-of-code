#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

typedef enum __attribute__((__packed__))
{
    UP,
    RIGHT,
    DOWN,
    LEFT
} dir_t;

typedef struct
{
    dir_t dir;
    uint64_t count;
} instruction_t;

typedef struct
{
    instruction_t* values;
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
    vec->values = malloc(sizeof(instruction_t));
    return vec;
}

void push(vec_t* v, instruction_t inst)
{
    if (v->length == v->capacity)
    {
        v->capacity *= 2;
        v->values = realloc(v->values, sizeof(instruction_t) * v->capacity);
    }
    v->values[v->length++] = inst;
}

typedef struct
{
    int64_t x;
    int64_t y;
} point_t;

typedef struct
{
    point_t* points;
    size_t length;
    size_t capacity;
} loop_t;

loop_t* create_loop(loop_t* l)
{
    loop_t* loop = l;
    if (loop == NULL)
    {
        loop = malloc(sizeof(loop_t));
    }
    loop->length = 0;
    loop->capacity = 1;
    loop->points = malloc(sizeof(point_t));
    return loop;
}

void add_point(loop_t* l, point_t p)
{
    if (l->length == l->capacity)
    {
        l->capacity *= 2;
        l->points = realloc(l->points, sizeof(point_t) * l->capacity);
    }
    l->points[l->length++] = p;
}

vec_t instructions = {0};

void instructions_from_file_pt1(FILE* fd)
{
    char* lineptr = NULL;
    size_t length, n;
    create_vec(&instructions);
    while ((length = getline(&lineptr, &n, fd)) != -1) // loop over all lines
    {
        instruction_t inst;

        switch (lineptr[0])
        {
            case 'U':
                inst.dir = UP;
                break;
            case 'R':
                inst.dir = RIGHT;
                break;
            case 'D':
                inst.dir = DOWN;
                break;
            case 'L':
                inst.dir = LEFT;
                break;
        }

        inst.count = atol(lineptr + 2);

        push(&instructions, inst);
    }
    free(lineptr);
}

void instructions_from_file_pt2(FILE* fd)
{
    char* lineptr = NULL;
    size_t length, n;
    if (instructions.values != NULL) free(instructions.values);
    create_vec(&instructions);
    while ((length = getline(&lineptr, &n, fd)) != -1) // loop over all lines
    {
        instruction_t inst;

        switch (lineptr[length - 3])
        {
            case '3':
                inst.dir = UP;
                break;
            case '0':
                inst.dir = RIGHT;
                break;
            case '1':
                inst.dir = DOWN;
                break;
            case '2':
                inst.dir = LEFT;
                break;
        }
        lineptr[length - 3] = 0;
        inst.count = strtol(lineptr + length - 8, NULL, 16);

        push(&instructions, inst);
    }
    free(lineptr);
}

size_t find_volume()
{
    // add all trench points to loop
    loop_t loop;
    create_loop(&loop);
    point_t point = { 0, 0 };
    add_point(&loop, point);
    size_t sum = 0;

    for (size_t i = 0; i < instructions.length; ++i)
    {
        size_t len = instructions.values[i].count;
        switch (instructions.values[i].dir)
        {
            case UP:
                point.y += len;
                break;
            case RIGHT:
                point.x += len;
                break;
            case DOWN:
                point.y -= len;
                break;
            case LEFT:
                point.x -= len;
                break;
        }
        add_point(&loop, point);
        sum += len;
    }

    // shoelace formula
    int64_t area = 0;
    area += loop.points[loop.length - 1].x * (loop.points[0].y - loop.points[loop.length - 2].y);
    area += loop.points[0].x * (loop.points[1].y - loop.points[loop.length - 1].y);
    for (int64_t i = 1; i < (int64_t)loop.length - 1; ++i)
    {
        area += loop.points[i % loop.length].x * (loop.points[(i + 1) % loop.length].y - loop.points[i - 1 % loop.length].y);
    }

    // pick's theorem
    sum = labs(area/2) + 1 - (sum/2) + sum;

    free(loop.points);
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
    instructions_from_file_pt1(fd);
    fclose(fd);
    printf("Part 1: %lu\n", find_volume());

    fd = fopen(filename, "r");
    instructions_from_file_pt2(fd);
    fclose(fd);
    printf("Part 2: %lu\n", find_volume());

    free(instructions.values);

    return EXIT_SUCCESS;
}
