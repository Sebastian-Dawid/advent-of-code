#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include "map.h"

typedef struct
{
    size_t num_nodes;
    size_t width;
    uint8_t* edges;
} graph_t;

graph_t* create_graph(graph_t* g, size_t width)
{
    graph_t* graph = g;
    if (graph == NULL)
    {
        graph = malloc(sizeof(graph_t));
    }
    
    graph->width = width;
    graph->num_nodes = width * width;
    graph->edges = malloc(sizeof(uint8_t) * graph->num_nodes);

    return graph;
}

graph_t graph = {0};

void graph_from_file(FILE* fd)
{
    char* lineptr = NULL;
    size_t length, n, idx = 0;
    while ((length = getline(&lineptr, &n, fd)) != -1)
    {
        if (graph.edges == NULL)
        {
            create_graph(&graph, length - 1);
        }

        for (size_t i = 0; i < length - 1; ++i)
        {
            graph.edges[idx] = lineptr[i] - 0x30;
            idx++;
        }
    }
    free(lineptr);
}

size_t dijkstra(const graph_t* graph, size_t start, dir_t dir, size_t min, size_t max)
{
    size_t pi[graph->num_nodes][4][10];
    for (size_t i = 0; i < graph->num_nodes; ++i)
    {
        for (size_t j = 0; j < 4; ++j)
        {
            for (size_t k = 0; k < 10; ++k) pi[i][j][k] = ~0;
        }
    }
    pi[start][dir][0] = 0;
    pi[start][SOUTH][0] = 0;

    map_t to_visit;
    create_map(&to_visit);
    node_t node = { start, pi[start][dir][0], 0, dir };
    insert(&to_visit, node);
    node_t node2 = { start, pi[start][dir][0], 0, SOUTH };
    insert(&to_visit, node2);

    while (to_visit.length > 0)
    {
        int64_t u = find_min_key(&to_visit);
        node_t current = to_visit.values[u];
        if (current.key == graph->num_nodes - 1)
        {
            free(to_visit.values);
            return current.value;
        }
        erase(&to_visit, current);

        node_t neighbors[3];
        size_t num_neighbors = 0;

        if (current.blocks < min)
        {
            switch (current.dir)
            {
                case NORTH:
                    neighbors[0].key = current.key - graph->width;
                    break;
                case EAST:
                    neighbors[0].key = current.key + 1;
                    break;
                case SOUTH:
                    neighbors[0].key = current.key + graph->width;
                    break;
                case WEST:
                    neighbors[0].key = current.key - 1;
                    break;
            }
            neighbors[0].dir = current.dir;
            neighbors[0].blocks = current.blocks + 1;
            num_neighbors = 1;
        }
        else
        {
            switch (current.dir)
            {
                case NORTH:
                    neighbors[0].dir = WEST;
                    neighbors[0].key = current.key - 1;
                    neighbors[1].dir = EAST;
                    neighbors[1].key = current.key + 1;
                    neighbors[2].key = current.key - graph->width;
                    break;
                case EAST:
                    neighbors[0].dir = NORTH;
                    neighbors[0].key = current.key - graph->width;
                    neighbors[1].dir = SOUTH;
                    neighbors[1].key = current.key + graph->width;
                    neighbors[2].key = current.key + 1;
                    break;
                case SOUTH:
                    neighbors[0].dir = EAST;
                    neighbors[0].key = current.key + 1;
                    neighbors[1].dir = WEST;
                    neighbors[1].key = current.key - 1;
                    neighbors[2].key = current.key + graph->width;
                    break;
                case WEST:
                    neighbors[0].dir = SOUTH;
                    neighbors[0].key = current.key + graph->width;
                    neighbors[1].dir = NORTH;
                    neighbors[1].key = current.key - graph->width;
                    neighbors[2].key = current.key - 1;
                    break;
            }
            neighbors[0].blocks = 1;
            neighbors[1].blocks = 1;
            num_neighbors = 2;
            if (current.blocks < max)
            {
                neighbors[2].dir = current.dir;
                neighbors[2].blocks = current.blocks + 1;
                num_neighbors++;
            }
        }

        for (size_t i = 0; i < num_neighbors; ++i)
        {
            if (neighbors[i].key < 0 || neighbors[i].key >= graph->num_nodes) continue;
            if (neighbors[i].dir == EAST && neighbors[i].key % graph->width == 0) continue;
            if (neighbors[i].dir == WEST && neighbors[i].key % graph->width == graph->width - 1) continue;
            size_t new_cost = current.value + graph->edges[neighbors[i].key];
            size_t k = neighbors[i].key, d = neighbors[i].dir, b = neighbors[i].blocks;
            if (new_cost < pi[k][d][b])
            {
                pi[k][d][b] = new_cost;
                neighbors[i].value = new_cost;
                insert(&to_visit, neighbors[i]);
            }
        }
    }

    return ~0;
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
    graph_from_file(fd);
    fclose(fd);

    printf("Part 1: %lu\n", dijkstra(&graph, 0, EAST, 0, 3));
    printf("Part 2: %lu\n", dijkstra(&graph, 0, EAST, 4, 10));

    free(graph.edges);
    
    return EXIT_SUCCESS;
}
