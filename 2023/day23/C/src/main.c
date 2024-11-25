#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <search.h>
#include "vec.h"
#include "mat.h"

#define true  1
#define false 0

typedef struct
{
    int64_t x, y;
} point_t;

typedef enum
{
    NORTH,
    EAST,
    SOUTH,
    WEST,
    NONE
} dir_t;

point_t DIRS[4] = { { 0, 1 }, { 1, 0 }, { 0, -1 }, { -1, 0 } };

typedef enum __attribute__((__packed__))
{
    FOREST,
    PATH,
    SLOPE_NORTH,
    SLOPE_EAST,
    SLOPE_SOUTH,
    SLOPE_WEST
} tile_t;

typedef struct
{
    point_t id;
    vec_t visited;
} node_t;

typedef struct
{
    size_t first;
    size_t second;
} tuple_t;

mat_t map_1 = {0};
mat_t map_2 = {0};

void read_paths_from_file(FILE* fd)
{
    char* lineptr = NULL;
    size_t length, n;
    while ((length = getline(&lineptr, &n, fd)) != -1)
    {
        if (map_1.values == NULL) create_mat(&map_1, length - 1, 0, sizeof(tile_t));
        if (map_2.values == NULL) create_mat(&map_2, length - 1, 0, sizeof(tile_t));

        tile_t row_1[length - 1];
        tile_t row_2[length - 1];
        for (size_t i = 0; i < length - 1; ++i)
        {
            switch (lineptr[i])
            {
                case '.':
                    row_1[i] = PATH;
                    row_2[i] = PATH;
                    break;
                case '#':
                    row_1[i] = FOREST;
                    row_2[i] = FOREST;
                    break;
                case '>':
                    row_1[i] = SLOPE_EAST;
                    row_2[i] = PATH;
                    break;
                case '<':
                    row_1[i] = SLOPE_WEST;
                    row_2[i] = PATH;
                    break;
                case '^':
                    row_1[i] = SLOPE_NORTH;
                    row_2[i] = PATH;
                    break;
                case 'v':
                    row_1[i] = SLOPE_SOUTH;
                    row_2[i] = PATH;
                    break;
            }
        }
        mat_add_row(&map_1, row_1);
        mat_add_row(&map_2, row_2);
    }
    free(lineptr);
}

_Bool in_visited(point_t val, vec_t* visited)
{
    for (size_t i = 0; i < visited->length; ++i)
    {
        point_t v = *((point_t*)visited->elems + i);
        if (v.x == val.x && v.y == val.y) return true;
    }
    return false;
}

_Bool in_refs(void* val, void** refs, size_t len)
{
    for (size_t i = 0; i < len; ++i)
    {
        void* v = *(refs + i);
        if (val == v) return true;
    }
    return false;
}

tuple_t* in_dists(size_t pos, vec_t* dists)
{
    for (size_t i = 0; i < dists->length; ++i)
    {
        size_t p = ((tuple_t*)dists->elems + i)->first;
        if (pos == p) return (tuple_t*)dists->elems + i;
    }
    return NULL;
}

_Bool valid_combination(dir_t dir, tile_t tile)
{
    if (dir == NORTH && tile == SLOPE_NORTH) return true;
    if (dir == EAST && tile == SLOPE_EAST) return true;
    if (dir == SOUTH && tile == SLOPE_SOUTH) return true;
    if (dir == WEST && tile == SLOPE_WEST) return true;
    return false;
}

size_t part_1(mat_t map)
{
    point_t start = {1,0};
    point_t end   = {map.cols - 2, map.rows - 1};

    vec_t refs;
    create_vec(&refs, sizeof(void*));
    vec_t queue;
    create_vec(&queue, sizeof(node_t));
    vec_t res;
    create_vec(&res, sizeof(size_t));

    vec_t visited;
    create_vec(&visited, sizeof(point_t));
    node_t node = { start, visited };
    vec_push(&queue, &node);

    while (queue.length > 0)
    {
        node_t node;
        vec_pop(&queue, &node);
        if (in_visited(node.id, &node.visited)) continue;
        vec_t visited;
        vec_copy(&visited, &node.visited);
        if (in_visited(node.id, &visited) == false)
        {
            vec_push(&visited, &node.id);
        }
        if (in_refs(node.visited.elems, refs.elems, refs.length) == false)
        {
            vec_push(&refs, &node.visited.elems);
        }

        if (node.id.x == end.x && node.id.y == end.y)
        {
            size_t len = visited.length - 1;
            vec_push(&res, &len);
        }

        for (size_t i = 0; i < 4; ++i)
        {
            int64_t nx = node.id.x + DIRS[i].x;
            int64_t ny = node.id.y - DIRS[i].y;

            if (0 <= nx && nx < map.cols && 0 <= ny && ny < map.rows
                    && (*(tile_t*)mat_value(&map, nx, ny) == PATH
                        || valid_combination(i, *(tile_t*)mat_value(&map, nx, ny))))
            {
                point_t id = { nx, ny };
                if (in_visited(id, &visited) == false)
                {
                    node_t new = { id, visited };
                    vec_push(&queue, &new);
                }
            }
        }
        for (size_t i = 0; i < refs.length; ++i)
        {
            void* ref;
            vec_pop(&refs, &ref);
            _Bool to_be_freed = true;
            for (size_t j = 0; j < queue.length; ++j)
            {
                void* _ref = ((node_t*)queue.elems + j)->visited.elems;
                if (_ref == ref)
                {
                    to_be_freed = false;
                    break;
                }
            }
            if (to_be_freed) free(ref);
            else vec_push(&refs, &ref);
        }
    }

    for (size_t i = 0; i < refs.length; ++i)
    {
        void* ref = *((void**)refs.elems + i);
        free(ref);
    }

    size_t max = 0;
    for (size_t i = 0; i < res.length; ++i)
    {
        size_t val = ((size_t*)res.elems)[i];
        max = (max < val) ? val : max;
    }

    free(refs.elems);
    free(queue.elems);
    free(res.elems);
    
    return max;
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
    read_paths_from_file(fd);
    fclose(fd);

    printf("Part 1: %lu\n", part_1(map_1));
    free(map_1.values);
    free(map_2.values);
    
    
    return EXIT_SUCCESS;
}
