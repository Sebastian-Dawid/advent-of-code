#include "vec.h"
#include <string.h>

vec_t* create_vec(vec_t *v, size_t elem_size)
{
    vec_t* vec = v;
    if (vec == NULL)
    {
        vec = (vec_t*) malloc(sizeof(vec_t));
    }
    
    vec->elem_size = elem_size;
    vec->length = 0;
    vec->capacity = 1;
    vec->elems = malloc(elem_size);

    return vec;
}

void vec_push(vec_t *v, const void *value)
{
    if (v->length == v->capacity)
    {
        v->capacity *= 2;
        v->elems = realloc(v->elems, v->elem_size * v->capacity);
    }
    memcpy(v->elems + v->length * v->elem_size, value, v->elem_size);
    v->length++;
}

void vec_pop(vec_t *v, void *value)
{
    if (value != NULL) memcpy(value, v->elems, v->elem_size);
    v->length--;
    memcpy(v->elems, v->elems + v->elem_size, v->elem_size * v->length);
}
