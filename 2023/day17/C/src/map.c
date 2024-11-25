#include "map.h"
#include <stdlib.h>
#include <string.h>

map_t* create_map(map_t* m)
{
    map_t* map = m;
    if (map == NULL)
    {
        map = malloc(sizeof(map_t));
    }
    map->length = 0;
    map->capacity = 1;
    map->values = malloc(sizeof(node_t));
    return map;
}

void erase(map_t *m, node_t node)
{
    for (size_t i = 0; i < m->length; ++i)
    {
        if (m->values[i].key == node.key && m->values[i].dir == node.dir)
        {
            for (int64_t j = i; j < m->length - 1; ++j)
            {
                m->values[j] = m->values[j + 1];
            }
            m->length--;
            break;
        }
    }
}

void insert(map_t* m, node_t node)
{
    for (size_t i = 0; i < m->length; ++i)
    {
        if (m->values[i].key == node.key && m->values[i].dir == node.dir && m->values[i].blocks == node.blocks)
        {
            m->values[i] = node;
            return;
        }
    }
    if (m->capacity == m->length)
    {
        m->capacity *= 2;
        m->values = realloc(m->values, m->capacity * sizeof(node_t));
    }
    m->values[m->length++] = node;
}

size_t find_min_key(map_t *m)
{
    size_t min = 0;
    for (size_t i = 0; i < m->length; ++i)
    {
        if (m->values[min].value > m->values[i].value) min = i;
    }
    return min;
}
