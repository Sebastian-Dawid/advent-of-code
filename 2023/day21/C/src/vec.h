#pragma once
#include <stdlib.h>

typedef struct
{
    void* elems;
    size_t length;
    size_t capacity;
    size_t elem_size;
} vec_t;

/// Creates a vector of elements of size `elem_size`.
///
/// `vec_t* v`         - Pointer to an existing vec_t to initialize. May be `NULL`.
/// `size_t elem_size` - Size of the type of the elements to be stored in the vector.
///
/// Note: The memory allocated by this function has to be released by the caller at the end of the vectors lifetime.
vec_t* create_vec(vec_t* v, size_t elem_size);

/// Pushes the value at `value` onto `v`.
///
/// `vec_t* v`          - Pointer to the vector to push to.
/// `const void* value` - Pointer to the value to push.
void vec_push(vec_t* v, const void* value);

/// Pops the first element in `v` into `value`.
///
/// `vec_t* v`    - Pointer to the vector to pop from.
/// `void* value` - Pointer to a variable to the the value in.
///
/// Note: If `value` is `NULL` the value will be discarded.
void vec_pop(vec_t* v, void* value);
