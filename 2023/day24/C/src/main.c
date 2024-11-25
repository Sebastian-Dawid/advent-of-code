#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <gsl/gsl_blas.h>
#include <gsl/gsl_linalg.h>
#include "vec.h"

#define true  1
#define false 0

typedef struct
{
    double x, y, z;
} vec3_t;

typedef struct
{
    vec3_t pos;
    vec3_t vel;
} hailstone_t;

vec_t hailstones = {0};

void read_hailstones_from_file(FILE* fd)
{ create_vec(&hailstones, sizeof(hailstone_t));
    char* lineptr = NULL;
    size_t length, n;
    while ((length = getline(&lineptr, &n, fd)) != -1)
    {
        char* line = lineptr;
        hailstone_t stone = {0};
        stone.pos.x = atof(line);
        line += strcspn(line, ",") + 2;
        stone.pos.y = atof(line);
        line += strcspn(line, ",") + 2;
        stone.pos.z = atof(line);
        line += strcspn(line, "@") + 2;
        stone.vel.x = atof(line);
        line += strcspn(line, ",") + 2;
        stone.vel.y = atof(line);
        line += strcspn(line, ",") + 2;
        stone.vel.z = atof(line);
        vec_push(&hailstones, &stone);
    }
    free(lineptr);
}

vec3_t line_line_2d(hailstone_t l_1, hailstone_t l_2, double* t, double* u)
{
    vec3_t res = {0};

    vec3_t p_1 = { l_1.pos.x - l_1.vel.x, l_1.pos.y - l_1.vel.y, 0 };
    vec3_t p_2 = l_1.pos;
    vec3_t p_3 = { l_2.pos.x - l_2.vel.x, l_2.pos.y - l_2.vel.y, 0 };
    vec3_t p_4 = l_2.pos;

    double _t = ((p_1.x - p_3.x)*(p_3.y - p_4.y) - (p_1.y - p_3.y)*(p_3.x - p_4.x))
        /((p_1.x - p_2.x)*(p_3.y - p_4.y) - (p_1.y  - p_2.y)*(p_3.x - p_4.x));
    double _u = ((p_1.x - p_3.x)*(p_1.y - p_2.y) - (p_1.y - p_3.y)*(p_1.x - p_2.x))
        /((p_1.x - p_2.x)*(p_3.y - p_4.y) - (p_1.y  - p_2.y)*(p_3.x - p_4.x));

    if (t != NULL) *t = _t;
    if (u != NULL) *u = _u;

    res.x = l_1.pos.x + l_1.vel.x * _t;
    res.y = l_1.pos.y + l_1.vel.y * _t;

    return res;
}

size_t part_1(double min, double max)
{
    size_t count = 0;
    _Bool found[hailstones.length];
    memset(found, false, sizeof(_Bool) * hailstones.length);
    for (size_t i = 0; i < hailstones.length; ++i)
    {
        hailstone_t A = ((hailstone_t*)hailstones.elems)[i];
        for (size_t j = i + 1; j < hailstones.length; ++j)
        {
            hailstone_t B = ((hailstone_t*)hailstones.elems)[j];
            double t = 0, u = 0;
            vec3_t intersect = line_line_2d(A, B, &t, &u);
            if (min <= intersect.x && intersect.x <= max && min <= intersect.y && intersect.y <= max && 0 < t && 0 < u)
            {
                found[i] = true;
                found[j] = true;
                count++;
                //printf("(%g, %g) and (%g, %g) intersect at (%.1f, %.1f), t: %.1f, u: %.1f\n", A.pos.x, A.pos.y, B.pos.x, B.pos.y, intersect.x, intersect.y, t, u);
            }
        }
    }

    return count;
}

/*
 *  p0 + t_i*v0 = p_i + t_i * v_i <=> (p0 - p_i) x (v0 - v_i) = 0
 *
 *  we have 6 unknowns so we need to choose 3 indices to solve.
 *  choose i = 0, i = 1 and i = 0, i = 2 to solve.
 */
double part_2()
{
    hailstone_t a = ((hailstone_t*)hailstones.elems)[0];
    hailstone_t b = ((hailstone_t*)hailstones.elems)[1];
    hailstone_t c = ((hailstone_t*)hailstones.elems)[2];
    double _rhs[] = {
        (b.pos.y * b.vel.x - b.pos.x * b.vel.y) - (a.pos.y * a.vel.x - a.pos.x * a.vel.y),
        (c.pos.y * c.vel.x - c.pos.x * c.vel.y) - (a.pos.y * a.vel.x - a.pos.x * a.vel.y),
        
        (b.pos.x * b.vel.z - b.pos.z * b.vel.x) - (a.pos.x * a.vel.z - a.pos.z * a.vel.x),
        (c.pos.x * c.vel.z - c.pos.z * c.vel.x) - (a.pos.x * a.vel.z - a.pos.z * a.vel.x),
        
        (b.pos.z * b.vel.y - b.pos.y * b.vel.z) - (a.pos.z * a.vel.y - a.pos.y * a.vel.z),
        (c.pos.z * c.vel.y - c.pos.y * c.vel.z) - (a.pos.z * a.vel.y - a.pos.y * a.vel.z),
    };
    double _M[] = {
        a.vel.y - b.vel.y, b.vel.x - a.vel.x,               0.0, b.pos.y - a.pos.y, a.pos.x - b.pos.x,               0.0,
        a.vel.y - c.vel.y, c.vel.x - a.vel.x,               0.0, c.pos.y - a.pos.y, a.pos.x - c.pos.x,               0.0,
        b.vel.z - a.vel.z,               0.0, a.vel.x - b.vel.x, a.pos.z - b.pos.z,               0.0, b.pos.x - a.pos.x,
        c.vel.z - a.vel.z,               0.0, a.vel.x - c.vel.x, a.pos.z - c.pos.z,               0.0, c.pos.x - a.pos.x,
                      0.0, a.vel.z - b.vel.z, b.vel.y - a.vel.y,               0.0, b.pos.z - a.pos.z, a.pos.y - b.pos.y,
                      0.0, a.vel.z - c.vel.z, c.vel.y - a.vel.y,               0.0, c.pos.z - a.pos.z, a.pos.y - c.pos.y
    };
    gsl_matrix_view M = gsl_matrix_view_array(_M, 6, 6);
    gsl_vector_view rhs = gsl_vector_view_array(_rhs, 6);
    gsl_permutation* p = gsl_permutation_alloc(6);
    gsl_vector* v = gsl_vector_alloc(6);

    int s;
    gsl_linalg_LU_decomp(&M.matrix, p, &s);
    gsl_linalg_LU_solve(&M.matrix, p, &rhs.vector, v);

    gsl_vector_fprintf(stdout, v, "%g");

    double sum = v->data[0] + v->data[1] + v->data[2];
    
    gsl_vector_free(v);
    gsl_permutation_free(p);

    return sum;
}

int main(int argc, char** argv)
{
    if (argc != 4)
    {
        fprintf(stderr, "Usage: <prog> <filename> <min> <max>");
        return EXIT_FAILURE;
    }

    const char* filename = argv[1]; // grab filename
    FILE* fd = fopen(filename, "r");
    read_hailstones_from_file(fd);
    fclose(fd);

    printf("Part 1: %lu\n", part_1(atof(argv[2]), atof(argv[3])));
    printf("Part 2: %20.f\n", part_2());

    free(hailstones.elems);

    return EXIT_SUCCESS;
}
