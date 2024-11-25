#include "mat.h"
#include <string.h>

mat_t* create_mat(mat_t *m, size_t cols, size_t rows, size_t elem_size)
{
    mat_t* mat = m;
    if (mat == NULL)
    {
        mat = malloc(sizeof(mat_t));
    }
    mat->rows = rows;
    mat->cols = cols;
    mat->elem_size = elem_size;
    mat->values = malloc(elem_size * cols * rows);
    return mat;
}

void mat_add_row(mat_t *m, void *elems)
{
    m->rows++;
    m->values = realloc(m->values, m->elem_size * m->rows * m->cols);
    memcpy(m->values + m->elem_size * m->cols * (m->rows - 1), elems, m->elem_size * m->cols);
}

void* mat_value(mat_t *m, size_t i, size_t j)
{
    return m->values + m->elem_size * i + m->elem_size * m->cols * j;
}
