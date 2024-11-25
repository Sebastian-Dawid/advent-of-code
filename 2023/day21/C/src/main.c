#include <stdio.h>
#include <stdlib.h>
#include "mat.h"
#include "vec.h"

#define true  1
#define false 0

typedef enum __attribute__((__packed__))
{
    ROCK,
    PLOT
} tile_type_t;

typedef struct
{
    int64_t x;
    int64_t y;
} point_t;

typedef struct
{
    _Bool visited;
    point_t position;
} state_t;

typedef struct
{
    tile_type_t type;
    vec_t visited;
    size_t shortest_distance;
} tile_t;

const point_t NORTH = { 0, 1 };
const point_t EAST = { 1, 0 };
const point_t SOUTH = { 0, -1 };
const point_t WEST = { -1, 0 };

const point_t DIRS[4] = { { 0, 1 }, { 1, 0 }, { 0, -1 }, { -1, 0 } };

point_t start = {0};

mat_t map = {0};

void read_map_from_file(FILE* fd)
{
    char* lineptr = NULL;
    size_t length, n;
    size_t rows = 0;
    while ((length = getline(&lineptr, &n, fd)) != -1)
    {
        if (map.values == NULL)
        {
            create_mat(&map, length - 1, 0, sizeof(tile_t));
        }
        tile_t tiles[length - 1];

        for (size_t i = 0; i < length - 1; ++i)
        {
            create_vec(&tiles[i].visited, sizeof(state_t));
            state_t s = {false, {0,0}};
            vec_push(&tiles[i].visited, &s);
            if (lineptr[i] == '#')
            {
                tiles[i].type = ROCK;
            }
            else
            {
                tiles[i].type = PLOT;
                if (lineptr[i] == 'S')
                {
                    start.x = i;
                    start.y = rows;
                }
            }
        }

        mat_add_row(&map, tiles);
        rows++;
    }
    free(lineptr);
}

state_t* find_state(vec_t* v, point_t p)
{
    for (size_t i = 0; i < v->length; ++i)
    {
        state_t* state = v->elems + v->elem_size * i;
        if (state->position.x == p.x && state->position.y == p.y) return state;
    }
    return NULL;
}

size_t walk_paths(point_t point, size_t remaining_distance, size_t total_distance, _Bool wrapping, point_t board)
{
    tile_t* tile = mat_value(&map, point.x, point.y);
    tile->shortest_distance = remaining_distance;
    size_t sum = 0;
    state_t* state = find_state(&tile->visited, board);
    if (state == NULL)
    {
        state_t st = { false, board };
        vec_push(&tile->visited, &st);
        state = find_state(&tile->visited, board);
    }
    if (remaining_distance % 2 == 0 && state->visited == false)
    {
        sum++;
    }
    state->visited = true;

    if (remaining_distance == 0)
    {
        return 1;
    }

    for (size_t i = 0; i < 4; ++i)
    {
        point_t pt = point;
        pt.x += DIRS[i].x;
        pt.y += DIRS[i].y;
        if (0 <= pt.x && pt.x < map.cols && 0 <= pt.y && pt.y < map.rows)
        {
            tile_t* target = (tile_t*)mat_value(&map, pt.x, pt.y);
            state_t* target_state = find_state(&target->visited, board);
            if (target_state == NULL)
            {
                state_t st = { false, board };
                vec_push(&tile->visited, &st);
                target_state = find_state(&tile->visited, board);
            }
            if (target->type == PLOT && (target_state->visited == false || remaining_distance - 1 > target->shortest_distance))
            {
                sum += walk_paths(pt, remaining_distance - 1, total_distance, wrapping, board);
            }
        }
    }
    return sum;
}

_Bool find_point(vec_t* v, point_t p)
{
    for (size_t i = 0; i < v->length; ++i)
    {
        point_t* pt = v->elems + v->elem_size * i;
        if (pt->x == p.x && pt->y == p.y) return true;
    }
    return false;
}

size_t get_passed_tiles(point_t start, size_t steps)
{
    vec_t tiles;
    create_vec(&tiles, sizeof(point_t));
    vec_push(&tiles, &start);

    for (size_t i = 0; i < steps; ++i)
    {
        vec_t tiles_new;
        create_vec(&tiles_new, sizeof(point_t));
        for (size_t j = 0; j < tiles.length; ++j)
        {
            for (size_t k = 0; k < 4; ++k)
            {
                point_t pt = ((point_t*)tiles.elems)[j];
                pt.x += DIRS[k].x;
                pt.y += DIRS[k].y;
                if (0 <= pt.x && pt.x < map.cols && 0 <= pt.y && pt.y < map.rows)
                {
                    tile_t* target = (tile_t*)mat_value(&map, pt.x, pt.y);
                    if (target->type != ROCK && find_point(&tiles_new, pt) == false) vec_push(&tiles_new, &pt);
                }
            }
        }
        free(tiles.elems);
        tiles = tiles_new;
    }

    free(tiles.elems);
    return tiles.length;
}

size_t part_2(point_t start, size_t steps)
{
    // filled completely
    size_t tiles_odd = get_passed_tiles(start, 3 * map.cols);
    size_t tiles_even = get_passed_tiles(start, 2 * map.cols);

    // extremes
    size_t corners = 0;
    point_t pt;
    pt.x = 0;
    pt.y = start.y;
    corners += get_passed_tiles(pt, map.cols - 1);
    pt.x = map.cols - 1;
    pt.y = start.y;
    corners += get_passed_tiles(pt, map.cols - 1);
    pt.x = start.x;
    pt.y = 0;
    corners += get_passed_tiles(pt, map.cols - 1);
    pt.x = start.x;
    pt.y = map.rows - 1;
    corners += get_passed_tiles(pt, map.cols - 1);

    // laterals
    size_t small = 0, big = 0;
    pt.x = map.cols - 1;
    pt.y = 0;
    big   += get_passed_tiles(pt, map.cols + start.x - 1);
    small += get_passed_tiles(pt, start.x - 1);
    pt.x = 0;
    pt.y = 0;
    big   += get_passed_tiles(pt, map.cols + start.x - 1);
    small += get_passed_tiles(pt, start.x - 1);
    pt.x = map.cols - 1;
    pt.y = map.cols - 1;
    big   += get_passed_tiles(pt, map.cols + start.x - 1);
    small += get_passed_tiles(pt, start.x - 1);
    pt.x = 0;
    pt.y = map.cols - 1;
    big   += get_passed_tiles(pt, map.cols + start.x - 1);
    small += get_passed_tiles(pt, start.x - 1);

    size_t width_romboid = (steps - start.x)/map.cols;
    size_t full_odd  = (width_romboid/2 * 2 - 1) * (width_romboid/2 * 2 - 1);
    size_t full_even = (width_romboid/2 * 2) * (width_romboid/2 * 2);

    return tiles_odd*full_odd + tiles_even*full_even + width_romboid*small + (width_romboid-1)*big + corners;
}

int main(int argc, char** argv)
{
    if (argc != 4)
    {
        fprintf(stderr, "Usage: <prog> <filename> <no1> <no2>");
        return EXIT_FAILURE;
    }

    const char* filename = argv[1]; // grab filename
    FILE* fd = fopen(filename, "r");
    read_map_from_file(fd);
    fclose(fd);
    point_t starting_borad = {0,0};
    printf("Part 1: %lu\n", walk_paths(start, atol(argv[2]), atol(argv[2]), false, starting_borad));

    for (size_t i = 0; i < map.cols; ++i)
    {
        for (size_t j = 0; j < map.rows; ++j)
        {
            tile_t* tile = mat_value(&map, j, i);
            free(tile->visited.elems);
        }
    }
    free(map.values);

    fd = fopen(filename, "r");
    map.values = NULL;
    read_map_from_file(fd);
    fclose(fd);
    printf("Part 2: %lu\n", part_2(start, atol(argv[3])));
    
    for (size_t i = 0; i < map.cols; ++i)
    {
        for (size_t j = 0; j < map.rows; ++j)
        {
            tile_t* tile = mat_value(&map, j, i);
            free(tile->visited.elems);
        }
    }
    free(map.values);

    return EXIT_SUCCESS;
}
