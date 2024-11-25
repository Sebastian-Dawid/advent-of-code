#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include "vec.h"
#include "mat.h"

#define MAT_PRINT(m, format, type)\
{\
    for (size_t i = 0; i < m.rows; ++i)\
    {\
        for (size_t j = 0; j < m.cols; ++j)\
        {\
            printf(format, *(type *)mat_value(&m, j, i));\
        }\
        printf("\n");\
    }\
}

#define true  1
#define false 0

typedef struct
{
    char a[3];
    char b[3];
} connection_t;


typedef struct
{
    char name[3];
    size_t id;
} mapping_t;

typedef struct
{
    int val;
    vec_t vec;
} tuple_t;

struct graph_t
{
    size_t num_nodes;
    mat_t adj;
} graph = {0};

void vec_copy(vec_t *dst, vec_t *src)
{
    dst->length = src->length;
    dst->elem_size = src->elem_size;
    dst->capacity = src->capacity;
    dst->elems = malloc(dst->elem_size * dst->capacity);
    memcpy(dst->elems, src->elems, dst->capacity * dst->elem_size);
}

size_t get_id(vec_t* v, char name[3])
{
    for (size_t i = 0; i < v->length; ++i)
    {
        mapping_t* m = v->elems + i * sizeof(mapping_t);
        if (strncmp(m->name, name, 3) == 0) return m->id;
    }
    return ~0l;
}

_Bool in_connections(vec_t* v, connection_t* con)
{
    for (size_t i = 0; i < v->length; ++i)
    {
        connection_t* c = v->elems + i * sizeof(connection_t);
        if (strncmp(c->a, con->a, 3) == 0
                && strncmp(c->b, con->b, 3) == 0
                || strncmp(c->a, con->b, 3) == 0
                && strncmp(c->b, con->a, 3) == 0) return true;
    }
    return false;
}

void read_graph_from_file(FILE* fd)
{
    vec_t mappings = {0};
    create_vec(&mappings, sizeof(mapping_t));
    vec_t connections = {0};
    create_vec(&connections, sizeof(connection_t));
    char* lineptr = NULL;
    size_t length, n;
    size_t id = 0;
    while ((length = getline(&lineptr, &n, fd)) != -1)
    {
        connection_t con;
        strncpy(con.a, lineptr, 3);
        if (get_id(&mappings, con.a) == ~0)
        {
            mapping_t mapping = {0};
            strncpy(mapping.name, con.a, 3);
            mapping.id = id++;
            vec_push(&mappings, &mapping);
        }

        char* line = lineptr + 5;
        while (line < lineptr + strlen(lineptr))
        {
            strncpy(con.b, line, 3);
            if (get_id(&mappings, con.b) == ~0)
            {
                mapping_t mapping = {0};
                strncpy(mapping.name, con.b, 3);
                mapping.id = id++;
                vec_push(&mappings, &mapping);
            }
            if (in_connections(&connections, &con) == false)
                vec_push(&connections, &con);
            line += 4;
        }
    }
    free(lineptr);

    graph.num_nodes = mappings.length;
    create_mat(&graph.adj, mappings.length, mappings.length, sizeof(int));

    for (size_t i = 0; i < connections.length; ++i)
    {
        connection_t* con = connections.elems + i * sizeof(connection_t);
        size_t a = get_id(&mappings, con->a);
        size_t b = get_id(&mappings, con->b);

        *(int*)mat_value(&graph.adj, a, b) = 1;
        *(int*)mat_value(&graph.adj, b, a) = 1;
    }

    free(connections.elems);
    free(mappings.elems);
}

size_t max_idx(int* w, size_t len)
{
    int max = INT_MIN;
    size_t max_idx = 0;
    for (size_t i = 0; i < len; ++i)
    {
        if (w[i] > max)
        {
            max = w[i];
            max_idx = i;
        }
    }
    return max_idx;
}

tuple_t pair_min(tuple_t a, tuple_t b)
{
    if (a.val < b.val) return a;
    else if (b.val < a.val) return b;

    tuple_t ret;
    size_t len;
    if (a.vec.length < b.vec.length)
    {
        len = a.vec.length;
        ret = a;
    }
    else
    {
        len = b.vec.length;
        ret = b;
    }
    for (size_t i = 0; i < len; ++i)
    {
        if (((int*)a.vec.elems)[i] < ((int*)b.vec.elems)[i]) return a;
        else if (((int*)b.vec.elems)[i] < ((int*)a.vec.elems)[i]) return b;
    }
    return ret;
}

tuple_t global_min_cut(mat_t* adj)
{
    tuple_t best = { INT_MAX, 0 };
    size_t n = adj->rows;
    vec_t co;
    create_vec(&co, sizeof(vec_t));
    for (size_t i = 0; i < n; ++i)
    {
        vec_t v;
        create_vec(&v, sizeof(int64_t));
        vec_push(&v, &i);
        vec_push(&co, &v);
    }

    for (size_t ph = 1; ph < n; ++ph)
    {
        int w[n];
        memcpy(w, adj->values, n * sizeof(int));
        size_t s = 0, t = 0;
        for (size_t it = 0; it < n - ph; ++it)
        {
            w[t] = INT_MIN;
            s = t;
            t = max_idx(w, n);
            for (size_t i = 0; i < n; ++i)
            {
                w[i] += *(int*)mat_value(adj, i, t);
            }
        }
        tuple_t potential = { w[t] - *(int*)mat_value(adj, t, t), 0};
        vec_copy(&potential.vec, (vec_t*)co.elems + t);
        best = pair_min(best, potential);
        vec_t* cot = (vec_t*)co.elems + t;
        vec_t* cos = (vec_t*)co.elems + s;
        for (size_t i = 0; i < cot->length; ++i)
        {
            vec_push(cos, ((int*)cot->elems + i));
        }
        for (size_t i = 0; i < n; i++)
            *(int*)mat_value(adj, i, s) += *(int*)mat_value(adj, i, t);
        for (size_t i = 0; i < n; i++)
            *(int*)mat_value(adj, s, i) += *(int*)mat_value(adj, t, i);
        *(int*)mat_value(adj, t, 0) = INT_MIN;
    }

    return best;
}

int part_1()
{
    tuple_t ret = global_min_cut(&graph.adj);
    return ret.vec.length * (graph.num_nodes - ret.vec.length);
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
    read_graph_from_file(fd);
    fclose(fd);
    // MAT_PRINT(graph.adj, "%d ", int);

    printf("Part 1: %d\n", part_1());
    
    free(graph.adj.values);

    return EXIT_SUCCESS;
}
