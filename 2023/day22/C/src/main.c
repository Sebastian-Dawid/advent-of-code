#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "vec.h"
#include "mat.h"

#define true  1
#define false 0

typedef struct
{
    int64_t x, y, z;
} point_t;

typedef struct
{
    point_t start;
    point_t end;
} brick_t;

int cmp(const void* _a, const void* _b)
{
    const brick_t* a = _a;
    const brick_t* b = _b;
    int64_t min_a = (a->start.z < a->end.z) ? a->start.z : a->end.z;
    int64_t min_b = (b->start.z < b->end.z) ? b->start.z : b->end.z;
    return min_a > min_b;
}

typedef struct
{
    int64_t height;
    size_t idx;
} height_t;

vec_t bricks = {0};
size_t width = 0, depth = 0;

void read_bricks_from_file(FILE* fd)
{
    char* lineptr = NULL;
    size_t length, n;
    create_vec(&bricks, sizeof(brick_t));
    while ((length = getline(&lineptr, &n, fd)) != -1)
    {
        brick_t brick = {0};
        char* line = lineptr;

        brick.start.x = atol(line);
        line += strcspn(line, ",") + 1;
        brick.start.y = atol(line);
        line += strcspn(line, ",") + 1;
        brick.start.z = atol(line);
        line += strcspn(line, "~") + 1;
        brick.end.x = atol(line);
        line += strcspn(line, ",") + 1;
        brick.end.y = atol(line);
        line += strcspn(line, ",") + 1;
        brick.end.z = atol(line);

        width = (width < brick.start.x) ? brick.start.x : width;
        width = (width < brick.end.x) ? brick.end.x : width;
        depth = (depth < brick.start.y) ? brick.start.y : depth;
        depth = (depth < brick.end.y) ? brick.end.y : depth;

        vec_push(&bricks, &brick);
    }
    free(lineptr);
    qsort(bricks.elems, bricks.length, sizeof(brick_t), cmp);
}

size_t drop_bricks(size_t exclude, _Bool propagate)
{
    size_t total_dropped = 0;
    mat_t height_map = {0};
    create_mat(&height_map, width + 1, depth + 1, sizeof(height_t));

    for (size_t i = 0; i < bricks.length; ++i)
    {
        if (exclude == i) continue;
        _Bool should_drop = true;
        brick_t* brick = bricks.elems + i * sizeof(brick_t);
        int64_t height = (brick->start.z < brick->end.z) ? brick->start.z : brick->end.z;
        int64_t top_height = (brick->start.z > brick->end.z) ? brick->start.z : brick->end.z;
        int64_t max_height = 0;
        for (size_t x = brick->start.x; x <= brick->end.x; ++x)
        {
            for (size_t y = brick->start.y; y <= brick->end.y; ++y)
            {
                height_t* current_height = mat_value(&height_map, x, y);
                max_height = (max_height < current_height->height) ? current_height->height : max_height;
                if (height - current_height->height == 1)
                {
                    should_drop = false;
                }
            }
        }
        int64_t new_height = height;
        int64_t new_top_height = top_height;
        if (should_drop)
        {
            total_dropped++;
            max_height++;
            new_height = max_height;
            new_top_height = max_height + (top_height - height);
        }
        for (size_t x = brick->start.x; x <= brick->end.x; ++x)
        {
            for (size_t y = brick->start.y; y <= brick->end.y; ++y)
            {
                height_t* current_height = mat_value(&height_map, x, y);
                current_height->height = new_top_height;
                current_height->idx = i;
                if (propagate == false) continue;
                brick->start.z = new_height;
                brick->end.z = new_top_height;
            }
        }
    }

    free(height_map.values);
    return total_dropped;
}

_Bool stable_without(size_t exclude)
{
    mat_t height_map = {0};
    create_mat(&height_map, width + 1, depth + 1, sizeof(height_t));

    for (size_t i = 0; i < bricks.length; ++i)
    {
        if (exclude == i) continue;
        _Bool should_drop = true;
        brick_t* brick = bricks.elems + i * sizeof(brick_t);
        int64_t height = (brick->start.z < brick->end.z) ? brick->start.z : brick->end.z;
        int64_t top_height = (brick->start.z > brick->end.z) ? brick->start.z : brick->end.z;
        for (size_t x = brick->start.x; x <= brick->end.x; ++x)
        {
            for (size_t y = brick->start.y; y <= brick->end.y; ++y)
            {
                height_t* current_height = mat_value(&height_map, x, y);
                if (height - current_height->height == 1)
                {
                    should_drop = false;
                }
            }
        }
        if (should_drop) return true;
        for (size_t x = brick->start.x; x <= brick->end.x; ++x)
        {
            for (size_t y = brick->start.y; y <= brick->end.y; ++y)
            {
                height_t* current_height = mat_value(&height_map, x, y);
                current_height->height = top_height;
                current_height->idx = i;
            }
        }
    }
    free(height_map.values);
    return false;
}

vec_t relevant_bricks = {0};

size_t part_1()
{
    create_vec(&relevant_bricks, sizeof(size_t));
    drop_bricks(~0, true);
    size_t sum = 0;
    for (size_t i = 0; i < bricks.length; ++i)
    {
        if (stable_without(i) == false)
        {
            sum += 1;
        }
        else
        {
            vec_push(&relevant_bricks, &i);
        }
    }
    return sum;
}

size_t part_2()
{
    size_t sum = 0;
    for (size_t i = 0; i < relevant_bricks.length; ++i)
    {
        size_t* exclude = relevant_bricks.elems + i * sizeof(size_t);
        sum += drop_bricks(*exclude, false);
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
    read_bricks_from_file(fd);
    fclose(fd);

    printf("Part 1: %lu\n", part_1());
    printf("Part 2: %lu\n", part_2());
    
    free(relevant_bricks.elems);
    free(bricks.elems);
    return EXIT_SUCCESS;
}
