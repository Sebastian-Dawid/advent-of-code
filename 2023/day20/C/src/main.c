#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include "vec.h"

#define true  1
#define false 0

typedef enum __attribute__((__packed__))
{
    LOW,
    HIGH
} state_t;

typedef enum __attribute__((__packed__))
{
    UNTYPED,
    FLIP_FLOP,
    CONJUNCTION
} mod_type_t;

typedef struct
{
    char name[11];  /// Name of the source.
    state_t state;  /// State of the source.
    _Bool new;  /// Was this source updated since the last read.
} src_t;

typedef struct module_t
{
    char name[11];      /// Name of the module.
    state_t state;      /// Current state of the module.
    mod_type_t type;    /// Type of the module
    vec_t srcs;         /// vector of sources.
    vec_t dsts;         /// vector of destinations.
} module_t;

module_t* create_module(module_t* m, const char* name, mod_type_t type)
{
    module_t* module = m;
    if (module == NULL)
    {
        module = malloc(sizeof(module_t));
    }
    strcpy(module->name, name);
    module->state = LOW;
    module->type = type;
    create_vec(&module->srcs, sizeof(src_t));
    create_vec(&module->dsts, sizeof(char[11]));
    return module;
}

void add_src(module_t* m, src_t src)
{
    vec_push(&m->srcs, &src);
}

void add_dst(module_t* m, char dst[11])
{
    vec_push(&m->dsts, dst);
}

vec_t modules = {0};

_Bool module_present(char* name, size_t* idx)
{
    for (*idx = 0; *idx < modules.length; ++(*idx))
    {
        if (strncmp(name, ((module_t*)modules.elems)[*idx].name, 11) == 0)
        {
            return true;
        }
    }
    return false;
}

void read_modules_from_file(FILE* fd)
{
    char* lineptr = NULL;
    size_t length, n;
    create_vec(&modules, sizeof(module_t));
    while ((length = getline(&lineptr, &n, fd)) != -1) // loop over all lines
    {
        char* line = lineptr;
        char name[11] = {0};
        mod_type_t type = UNTYPED;
        src_t src = {0};
        size_t name_len = 11;

        if (line[0] == '%' || line[0] == '&')
        {
            type = (line[0] == '%') ? FLIP_FLOP : CONJUNCTION;
            name_len = strcspn(++line, " ");
        }
        strncpy(name, line, name_len);
        strncpy(src.name, line, name_len);

        size_t idx = 0;

        if (module_present(name, &idx) == false)
        {
            module_t mod = {0};
            create_module(&mod, name, type);
            vec_push(&modules, &mod);
            idx = modules.length - 1;
        }
        else
        {
            ((module_t*)modules.elems)[idx].type = type;
        }
        line += name_len + 4;

        while (line < lineptr + strlen(lineptr))
        {
            memset(name, 0, 11); // reset name to 0
            strncpy(name, line, strcspn(line, ",\n"));
            
            size_t i;
            if (module_present(name, &i) == false)
            {
                module_t mod = {0};
                create_module(&mod, name, UNTYPED);
                vec_push(&modules, &mod);
                i = modules.length - 1;
            }
            add_dst(modules.elems + idx * sizeof(module_t), name);  /// add destination for current module
            add_src(modules.elems + i * sizeof(module_t), src);     /// add current module as source for destination

            line += strcspn(line, ",") + 2;
        }

    }
    free(lineptr);
}

size_t cycles[4];

void propagate_pulse(vec_t* queue, size_t* low, size_t* high, size_t* cycle_count)
{
    while (queue->length > 0)
    {
        char name[11] = {0};
        vec_pop(queue, name);
        size_t idx;
        module_present(name, &idx);
        module_t* mod = modules.elems + idx * sizeof(module_t);

        for (size_t i = 0; i < mod->srcs.length; ++i)
        {
            src_t* src = mod->srcs.elems + i * sizeof(src_t);
            if (mod->type == FLIP_FLOP)
            {
                if (src->new)
                {
                    if (src->state == LOW)
                    {
                        mod->state = (mod->state == LOW) ? HIGH : LOW;
                    }
                    src->new = false;
                    break;
                }
            }
            else
            {
                mod->state = LOW;
                if (src->state == LOW)
                {
                    mod->state = HIGH;
                    break;
                }
            }
        }

        if (mod->state == HIGH && cycle_count != NULL)
        {
            if (strcmp("xf", mod->name) == 0 && cycles[0] == 0)
            {
                cycles[0] = *cycle_count;
            }
            else if (strcmp("cm", mod->name) == 0 && cycles[1] == 0)
            {
                cycles[1] = *cycle_count;
            }
            else if (strcmp("sz", mod->name) == 0 && cycles[2] == 0)
            {
                cycles[2] = *cycle_count;
            }
            else if (strcmp("gc", mod->name) == 0 && cycles[3] == 0)
            {
                cycles[3] = *cycle_count;
            }
        }

        for (size_t i = 0; i < mod->dsts.length; ++i)
        {
            if (mod->state == LOW) *low += 1;
            else *high += 1;

            size_t j;
            if (module_present(mod->dsts.elems + i * 11, &j))
            {
                module_t* dst_mod = modules.elems + j * sizeof(module_t);
                //printf("(%hhu) %s -%hhu> (%hhu) %.11s (%hhu)\n", mod->type, name, mod->state, dst_mod->type, dst_mod->name, dst_mod->state);

                for (size_t k = 0; k < dst_mod->srcs.length; ++k)
                {
                    src_t* src = dst_mod->srcs.elems + k * sizeof(src_t);
                    if (strncmp(name, src->name, 11) == 0)
                    {
                        if (dst_mod->type == FLIP_FLOP && mod->state == LOW) src->new = true;
                        src->state = mod->state;
                        break;
                    }
                }
                if (dst_mod->type != FLIP_FLOP || mod->state == LOW)
                    vec_push(queue, dst_mod->name);
            }
        }
    }
}

size_t part_1()
{
    size_t low = 0, high = 0;
    _Bool found = false;
    for (size_t i = 0; i < 1000; ++i)
    {
        vec_t queue;
        create_vec(&queue, sizeof(char[11]));
        vec_push(&queue, "broadcaster");
        low++;
        propagate_pulse(&queue, &low, &high, &i);
        free(queue.elems);
    }
    return low * high;
}

size_t lcm(size_t a, size_t b)
{
    size_t gcd;
    for (size_t i = 1; i <= a && i <= b; ++i)
    {
        if (a % i == 0 && b % i == 0)
        {
            gcd = i;
        }
    }

    return (a * b)/gcd;
}

size_t part_2()
{
    size_t low = 0, high = 0;
    
    size_t idx;
    module_present("zr", &idx);
    module_t* zr = modules.elems + idx * sizeof(module_t);
    module_t* preds[4];
    for (size_t i = 0; i < zr->srcs.length; ++i)
    {
        module_present(((src_t*)(zr->srcs.elems))[i].name, &idx);
        preds[i] = modules.elems + idx * sizeof(module_t);
    }
    
    for (size_t i = 1; i <= 100000; ++i)
    {
        vec_t queue;
        create_vec(&queue, sizeof(char[11]));
        vec_push(&queue, "broadcaster");
        propagate_pulse(&queue, &low, &high, &i);
        free(queue.elems);
        if (cycles[0] != 0 && cycles[1] != 0 && cycles[2] != 0 && cycles[3] != 0) break;
    }

    size_t _lcm = 0;
    _lcm = lcm(cycles[0], cycles[1]);
    _lcm = lcm(_lcm, cycles[2]);
    _lcm = lcm(_lcm, cycles[3]);
    return _lcm;
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
    read_modules_from_file(fd);
    fclose(fd);

    printf("Part 1: %lu\n", part_1());

    for (size_t i = 0; i < modules.length; ++i)
    {
        module_t* mod = modules.elems + i * sizeof(module_t);
        free(mod->srcs.elems);
        free(mod->dsts.elems);
    }
    free(modules.elems);

    fd = fopen(filename, "r");
    read_modules_from_file(fd);
    fclose(fd);
    
    printf("Part 2: %lu\n", part_2());
    
    for (size_t i = 0; i < modules.length; ++i)
    {
        module_t* mod = modules.elems + i * sizeof(module_t);
        free(mod->srcs.elems);
        free(mod->dsts.elems);
    }
    free(modules.elems);
    return EXIT_SUCCESS;
}
