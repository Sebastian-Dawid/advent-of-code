#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#define true 1
#define false 0

typedef enum __attribute__((__packed__))
{
    NONE,
    GT,
    LT
} cmp_type_t;

typedef enum __attribute__((__packed__))
{
    A,
    X,
    M,
    S,
    N // none
} rating_t;

typedef struct
{
    rating_t rating;
    cmp_type_t type;
    size_t value;
    char target[3];
} cmp_t;

typedef struct
{
    char name[3];
    cmp_t cmps[5];
    size_t num_ratings;
} workflow_t;

typedef struct
{
    workflow_t* workflows;
    size_t length;
    size_t capacity;
} workflows_t;

workflows_t* create_workflows(workflows_t* v)
{
    workflows_t* vec = v;
    if (vec == NULL)
    {
        vec = malloc(sizeof(workflows_t));
    }
    vec->length = 0;
    vec->capacity = 1;
    vec->workflows = malloc(sizeof(workflow_t));
    return vec;
}

void push(workflows_t* v, workflow_t w)
{
    if (v->length == v->capacity)
    {
        v->capacity *= 2;
        v->workflows = realloc(v->workflows, sizeof(workflow_t) * v->capacity);
    }
    v->workflows[v->length++] = w;
}

typedef struct
{
    size_t x;
    size_t m;
    size_t a;
    size_t s;
} part_t;

_Bool cmp_wf(cmp_t c, size_t val)
{
    if (c.type == NONE) return true;
    if (c.type == GT) return val > c.value;
    else return val < c.value;
}

typedef struct
{
    part_t* parts;
    size_t length;
    size_t capacity;
} parts_t;

parts_t* create_parts(parts_t* p)
{
    parts_t* parts = p;
    if (parts == NULL)
    {
        parts = malloc(sizeof(parts_t));
    }
    parts->length = 0;
    parts->capacity = 1;
    parts->parts = malloc(sizeof(part_t));
    return parts;
}

void push_part(parts_t* p, part_t part)
{
    if (p->length == p->capacity)
    {
        p->capacity *= 2;
        p->parts = realloc(p->parts, sizeof(part_t) * p->capacity);
    }
    p->parts[p->length++] = part;
}

workflows_t workflows = {0};
parts_t parts = {0};

void parse_file(FILE* fd)
{
    char* lineptr = NULL;
    size_t length, n;
    create_parts(&parts);
    create_workflows(&workflows);
    while ((length = getline(&lineptr, &n, fd)) != -1) // loop over all lines
    {
        if (length == 1) continue;
        
        if (lineptr[0] == '{')
        {
            part_t part = {0};

            size_t offset = strcspn(lineptr, "=") + 1;
            part.x = atol(lineptr + offset);
            offset += strcspn(lineptr + offset, "=") + 1;
            part.m = atol(lineptr + offset);
            offset += strcspn(lineptr + offset, "=") + 1;
            part.a = atol(lineptr + offset);
            offset += strcspn(lineptr + offset, "=") + 1;
            part.s = atol(lineptr + offset);

            push_part(&parts, part);
        }
        else
        {
            workflow_t workflow = {0};
            size_t offset = strcspn(lineptr, "{");
            for (size_t i = 0; i < offset; ++i)
            {
                workflow.name[i] = lineptr[i];
            }
            offset++;
            size_t idx = 0;
            while (offset < length)
            {
                if (*(lineptr + offset + 1) != '<' && *(lineptr + offset + 1) != '>')
                {
                    workflow.cmps[idx].rating = N;
                    workflow.cmps[idx].type = NONE;
                    strncpy(workflow.cmps[idx].target, lineptr + offset, strcspn(lineptr + offset, "}"));
                    break;
                }

                size_t value = atol(lineptr + offset + 2);
                cmp_type_t type = (lineptr[offset + 1] == '>') ? GT : LT;
                char* target = lineptr + offset + strcspn(lineptr + offset, ":") + 1;
                size_t str_len = strcspn(target, ",");
                workflow.cmps[idx].type = type;
                workflow.cmps[idx].value = value;
                for (size_t i = 0; i < str_len; ++i) workflow.cmps[idx].target[i] = target[i];
                for (size_t i = str_len; i < 3; ++i) workflow.cmps[idx].target[i] = 0;
                switch (lineptr[offset])
                {
                    case 'a':
                        workflow.cmps[idx].rating = A;
                        break;
                    case 'm':
                        workflow.cmps[idx].rating = M;
                        break;
                    case 'x':
                        workflow.cmps[idx].rating = X;
                        break;
                    case 's':
                        workflow.cmps[idx].rating = S;
                        break;
                }
                idx++;
                offset += strcspn(lineptr + offset, ",") + 1;
            }
            workflow.num_ratings = idx + 1;
            push(&workflows, workflow);
        }
    }
    free(lineptr);
}

_Bool part_accepted(part_t* part)
{
    workflow_t wf;
    for (size_t i = 0; i < workflows.length; ++i)
    {
        if (strcmp(workflows.workflows[i].name, "in") == 0)
        {
            wf = workflows.workflows[i];
            break;
        }
    }
    
    while (1)
    {
        char next_workflow[3] = {0};
        for (size_t i = 0; i < wf.num_ratings; ++i)
        {
            size_t val = 0;
            if (wf.cmps[i].rating == A) val = part->a;
            else if (wf.cmps[i].rating == X) val = part->x;
            else if (wf.cmps[i].rating == S) val = part->s;
            else if (wf.cmps[i].rating == M) val = part->m;
            if (cmp_wf(wf.cmps[i], val))
            {
                strcpy(next_workflow, wf.cmps[i].target);
                break;
            }
        }

        for (size_t i = 0; i < workflows.length; ++i)
        {
            if (strcmp(workflows.workflows[i].name, next_workflow) == 0)
            {
                wf = workflows.workflows[i];
                break;
            }
        }

        if (strcmp(next_workflow, "A") == 0)
        {
            return true;
        }
        else if (strcmp(next_workflow, "R") == 0)
        {
            return false;
        }
    }
}

size_t part_1()
{
    size_t sum = 0;

    for (size_t i = 0; i < parts.length; ++i)
    {
        if (part_accepted(parts.parts + i))
        {
            part_t p = parts.parts[i];
            sum += p.a + p.x + p.m + p.s;
        }
    }

    return sum;
}

typedef struct
{
    struct {size_t min; size_t max;} a;
    struct {size_t min; size_t max;} x;
    struct {size_t min; size_t max;} m;
    struct {size_t min; size_t max;} s;
} hypercube_t;

// sets `a` to the first split. the other half is returned.
// order in `v = (x, a, m, s)`.
// only one value should be set in `v` all others are assumes to be `0`
hypercube_t split_at(hypercube_t* a, size_t v[4])
{
    hypercube_t res = *a;

    if (v[0] != 0)
    {
        res.x.min = v[0];
        a->x.max = v[0] - 1;
    }
    if (v[1] != 0)
    {
        res.a.min = v[1];
        a->a.max = v[1] - 1;
    }
    if (v[2] != 0)
    {
        res.m.min = v[2];
        a->m.max = v[2] - 1;
    }
    if (v[3] != 0)
    {
        res.s.min = v[3];
        a->s.max = v[3] - 1;
    }

    return res;
}

size_t magnitude(hypercube_t h)
{
    return (h.a.max - (h.a.min - 1)) * (h.x.max - (h.x.min - 1)) * (h.m.max - (h.m.min - 1)) * (h.s.max - (h.s.min - 1));
}

size_t accepted_options(char* name, hypercube_t h)
{
    if (strcmp(name, "A") == 0) return magnitude(h);
    if (strcmp(name, "R") == 0) return 0;

    workflow_t wf;
    for (size_t i = 0; i < workflows.length; ++i)
    {
        if (strcmp(workflows.workflows[i].name, name) == 0)
        {
            wf = workflows.workflows[i];
            break;
        }
    }
    size_t accepted = 0;
    for (size_t i = 0; i < wf.num_ratings - 1; ++i)
    {
        size_t v[4] = {0};
        switch (wf.cmps[i].rating) {
            case A:
                v[1] = (wf.cmps[i].type == GT) ? wf.cmps[i].value + 1 : wf.cmps[i].value;
                break;
            case X:
                v[0] = (wf.cmps[i].type == GT) ? wf.cmps[i].value + 1 : wf.cmps[i].value;
                break;
            case M:
                v[2] = (wf.cmps[i].type == GT) ? wf.cmps[i].value + 1 : wf.cmps[i].value;
                break;
            case S:
                v[3] = (wf.cmps[i].type == GT) ? wf.cmps[i].value + 1 : wf.cmps[i].value;
                break;
            default:
                break;
        }
        hypercube_t tmp = split_at(&h, v);
        if (wf.cmps[i].type == LT)
        {
            accepted += accepted_options(wf.cmps[i].target, h);
            h = tmp;
        }
        else
        {
            accepted += accepted_options(wf.cmps[i].target, tmp);
        }
    }
    accepted += accepted_options(wf.cmps[wf.num_ratings - 1].target, h);

    return accepted;
}

size_t part_2()
{
    hypercube_t hc = { {1, 4000}, {1, 4000}, {1, 4000}, {1, 4000} };
    return accepted_options("in", hc);
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
    parse_file(fd);
    fclose(fd);

    printf("Part 1: %lu\n", part_1());
    printf("Part 2: %lu\n", part_2());

    free(parts.parts);
    free(workflows.workflows);

    return EXIT_SUCCESS;
}
