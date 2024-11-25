#pragma once
#include <stdlib.h>

typedef struct
{
    void* values;
    size_t rows;
    size_t cols;
    size_t elem_size;
} mat_t;

mat_t* create_mat(mat_t* m, size_t cols, size_t rows, size_t elem_size);
void mat_add_row(mat_t* m, void* elems);
void* mat_value(mat_t* m, size_t i, size_t j);
