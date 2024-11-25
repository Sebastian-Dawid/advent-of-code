#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

typedef enum __attribute__((__packed__))
{
    EMPTY               = 0,    // '.'
    VERTICAL_SPLITTER   = 0x1,  // '|'
    HORIZONTAL_SPLITTER = 0x2,  // '-'
    UP_MIRROR           = 0x4,  // '/'
    DOWN_MIRROR         = 0x8   // '\'

} tile_type_t;

typedef enum __attribute__((__packed__))
{
    NONE  = 0,
    UP    = 0x1,
    RIGHT = 0x2,
    DOWN  = 0x4,
    LEFT  = 0x8
} dir_t;

typedef struct
{
    tile_type_t type;
    dir_t dirs;
} tile_t;

typedef struct
{
    tile_t* tiles;
    size_t cols;
    size_t rows;
} map_t;

map_t* create_map(map_t* m, size_t cols, size_t rows)
{
    map_t* map = m;
    if (map == NULL)
    {
        map = malloc(sizeof(map_t));
    }
    map->rows = rows;
    map->cols = cols;
    map->tiles = malloc(sizeof(tile_t) * rows * cols);
    return map;
}

void add_row(map_t* m)
{
    m->rows++;
    m->tiles = realloc(m->tiles, sizeof(tile_t) * m->rows * m->cols);
}

map_t copy(map_t* m)
{
    map_t map = *m;
    map.tiles = malloc(map.cols * map.rows * sizeof(tile_t));
    memcpy(map.tiles, m->tiles, map.cols * map.rows * sizeof(tile_t));
    return map;
}

map_t init_map = {0};

void map_from_file(FILE* fd)
{
    char* lineptr = NULL;
    size_t length, n;
    while ((length = getline(&lineptr, &n, fd)) != -1)
    {
        if (init_map.tiles == NULL)
        {
            create_map(&init_map, length - 1, 0);
        }
        add_row(&init_map);

        for (size_t i = 0; i < length - 1; ++i)
        {
            tile_t tile = { EMPTY, NONE };
            switch (lineptr[i])
            {
                case '-':
                    tile.type = HORIZONTAL_SPLITTER;
                    break;
                case '|':
                    tile.type = VERTICAL_SPLITTER;
                    break;
                case '/':
                    tile.type = UP_MIRROR;
                    break;
                case '\\':
                    tile.type = DOWN_MIRROR;
                    break;
            }
            init_map.tiles[init_map.cols * (init_map.rows - 1) + i] = tile;
        }
    }
    free(lineptr);
}

void follow_beam(map_t* m, int64_t x, int64_t y, dir_t dir)
{
    if (dir == NONE) { fprintf(stderr, "ERROR: Invalid direction!"); return; }
    if (x < 0 || m->cols <= x || y < 0 || m->rows <= y) return;

    tile_t* current_tile = &m->tiles[m->cols * y + x];
    while ((current_tile->dirs & dir) == 0)
    {
        current_tile->dirs |= dir;

        switch (current_tile->type)
        {
            case HORIZONTAL_SPLITTER:
                if (dir == UP || dir == DOWN)
                {
                    follow_beam(m, x - 1, y, LEFT);
                    follow_beam(m, x + 1, y, RIGHT);
                    return;
                }
                break;
            case VERTICAL_SPLITTER:
                if (dir == RIGHT || dir == LEFT)
                {
                    follow_beam(m, x, y - 1, UP);
                    follow_beam(m, x, y + 1, DOWN);
                    return;
                }
                break;
            case UP_MIRROR:
                switch (dir)
                {
                    case UP:
                        dir = RIGHT;
                        break;
                    case RIGHT:
                        dir = UP;
                        break;
                    case DOWN:
                        dir = LEFT;
                        break;
                    case LEFT:
                        dir = DOWN;
                        break;
                    default:
                        break;
                }
                break;
            case DOWN_MIRROR:
                switch (dir) {
                    case UP:
                        dir = LEFT;
                        break;
                    case RIGHT:
                        dir = DOWN;
                        break;
                    case DOWN:
                        dir = RIGHT;
                        break;
                    case LEFT:
                        dir = UP;
                        break;
                    default:
                        break;
                }
                break;
            default:
                break;
        }

        switch (dir)
        {
            case UP:
                y -= 1;
                break;
            case RIGHT:
                x += 1;
                break;
            case DOWN:
                y += 1;
                break;
            case LEFT:
                x -= 1;
                break;
            default:
                break;
        }

        if (x < 0 || m->cols <= x || y < 0 || m->rows <= y) return;
        current_tile = &m->tiles[m->cols * y + x];
    }
}

void print_map(map_t map)
{
    for (size_t i = 0; i < map.rows; ++i)
    {
        for (size_t j = 0; j < map.cols; ++j)
        {
            if (map.tiles[i * map.cols + j].dirs != 0)
            {
                printf("\033[1;32m#");
            }
            else
            {
                printf("\033[0;31m.");
            }
            printf("\033[0m");
        }
        printf("\n");
    }
    printf("\n");
}

size_t energized_tiles(map_t map)
{
    size_t sum = 0;
    for (size_t i = 0; i < map.rows; ++i)
    {
        for (size_t j = 0; j < map.cols; ++j)
        {
            if (map.tiles[i * map.cols + j].dirs != 0)
            {
                sum += 1;
            }
        }
    }
    return sum;
}

size_t part_1()
{
    map_t map = copy(&init_map);
    follow_beam(&map, 0, 0, RIGHT);
#ifdef PRINT
    print_map(map);
#endif
    size_t sum = energized_tiles(map);
    free(map.tiles);
    return sum;
}

uint32_t part_2(size_t pt_1)
{
    uint32_t max = pt_1;

    for (size_t x = 0; x < init_map.cols; x += init_map.cols-1)
    {
        for (size_t y = 0; y < init_map.rows; ++y)
        {
            map_t map = copy(&init_map);
            follow_beam(&map, x, y, (x == 0) ? RIGHT : LEFT);
#ifdef PRINT
            print_map(map);
#endif
            size_t m = energized_tiles(map);
            max = (m > max) ? m : max;
            free(map.tiles);
        }
    }

    for (size_t y = 0; y < init_map.rows; y += init_map.rows-1)
    {
        for (size_t x = 0; x < init_map.cols; ++x)
        {
            map_t map = copy(&init_map);
            follow_beam(&map, x, y, (y == 0) ? DOWN : UP);
#ifdef PRINT
            print_map(map);
#endif
            size_t m = energized_tiles(map);
            max = (m > max) ? m : max;
            free(map.tiles);
        }
    }

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
    map_from_file(fd);
    fclose(fd);

    size_t pt_1 = part_1();
    printf("Part 1: %lu\n", pt_1);
    printf("Part 2: %d\n", part_2(pt_1));

    free(init_map.tiles);

    return EXIT_SUCCESS;
}
