#ifndef MAP_H
#define MAP_H

#include <stddef.h>
#include <stdint.h>

typedef enum __attribute__((__packed__))
{
    NORTH,
    EAST,
    SOUTH,
    WEST
} dir_t;

typedef struct
{
    int64_t  key;
    size_t  value;
    uint8_t blocks;
    dir_t   dir;
} node_t;

typedef struct
{
    node_t* values;
    size_t length;
    size_t capacity;
} map_t;

map_t* create_map(map_t* m);
void erase(map_t* m, node_t node);
void insert(map_t* m, node_t node);
size_t find_min_key(map_t* m);

#endif
