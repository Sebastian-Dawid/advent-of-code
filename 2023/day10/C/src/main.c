#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

typedef enum
{
    NONE  = 0x0,
    NORTH = 0x1,
    EAST  = 0x2,
    SOUTH = 0x4,
    WEST  = 0x8,
    START = 0x10
} direction_t;

typedef enum
{
    OUT   = 0x0,
    ON    = 0x1,
    IN    = 0x2,
    UNDEF = 0xf
} state_t;

typedef struct
{
    char symbol;
    direction_t dirs;
    state_t state;
} tile_t;

tile_t tile_lut[] = {
    {'|', NORTH | SOUTH, UNDEF },
    {'-', EAST  | WEST,  UNDEF },
    {'L', NORTH | EAST,  UNDEF },
    {'J', NORTH | WEST,  UNDEF },
    {'7', SOUTH | WEST,  UNDEF },
    {'F', SOUTH | EAST,  UNDEF },
    {'.', NONE,          UNDEF },
    {'S', START,         UNDEF }
};

tile_t maze[19600]; // size of input
size_t start = 0;
size_t rows = 0;
size_t cols = 0;
size_t indices[19600];
size_t num_indices = 0;

void generate_maze(FILE* fd)
{
    char* lineptr = NULL;
    size_t length, n;
    size_t row = 0;
    while ((length = getline(&lineptr, &n, fd)) != -1) // loop over all lines
    {
        cols = length - 1;
        for (size_t i = 0; i < cols; ++i)
        {
            for (size_t j = 0; j < 8; ++j)
            {
                if (lineptr[i] == tile_lut[j].symbol)
                {
                    maze[row * cols + i] = tile_lut[j];
                    break;
                }
                if (lineptr[i] == 'S')
                {
                    start = row * cols + i;
                }
            }
        }
        row++;
    }
    rows = row;

    direction_t start_dir = NONE;
    if (start >= cols && maze[start - cols].dirs & SOUTH) start_dir |= NORTH; 
    if (start % cols != 0 && maze[start - 1].dirs & EAST) start_dir |= WEST;
    if (start != cols-1 && maze[start + 1].dirs & WEST) start_dir |= EAST;
    if (start < rows * cols && maze[start + cols].dirs & NORTH) start_dir |= SOUTH;
    maze[start].dirs |= start_dir;

    free(lineptr);
}

uint32_t part_1()
{
    size_t len = 0;
    size_t idx = start;
    tile_t* current_tile = &maze[start];
    direction_t prev_dir = NONE;

    do
    {
        if ((current_tile->dirs & (NORTH | SOUTH)) != (NORTH | SOUTH)
                && (current_tile->dirs & (EAST | WEST)) != (EAST | WEST))
        {
            indices[num_indices++] = idx;
        }
        if (current_tile->dirs & NORTH && prev_dir != NORTH)
        {
            idx -= cols;
            prev_dir = SOUTH;
        }
        else if (current_tile->dirs & EAST && prev_dir != EAST)
        {
            idx += 1;
            prev_dir = WEST;
        }
        else if (current_tile->dirs & WEST && prev_dir != WEST)
        {
            idx -= 1;
            prev_dir = EAST;
        }
        else if (current_tile->dirs & SOUTH && prev_dir != SOUTH)
        {
            idx += cols;
            prev_dir = NORTH;
        }
        else return -1; // error

        current_tile->state = ON;
        current_tile = &maze[idx];
        len++;
    } while (!(current_tile->dirs & START));

    return len;
}

size_t part_2(size_t pt_1)
{
    int64_t area = 0;

    // shoelace formula
    area += (indices[num_indices - 1] % cols) * ((indices[0] / cols) - (indices[num_indices - 2] / cols));
    area += (indices[0] % cols) * ((indices[1] / cols) - (indices[num_indices - 1] / cols));
    for (size_t i = 1; i < num_indices - 1; ++i)
    {
        area += (indices[i] % cols) * ((indices[i + 1] / cols) - (indices[i - 1] / cols));
    }

    return labs(area/2) + 1 - (pt_1/2);
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
    generate_maze(fd);
    fclose(fd);

    uint32_t pt_1 = part_1();
    printf("Part 1: %d\n", pt_1/2);
    printf("Part 2: %lu\n", part_2(pt_1));

    return EXIT_SUCCESS;
}
