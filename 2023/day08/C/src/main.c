#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <search.h>

typedef struct
{
    char name[3];
    char left[3];
    char right[3];
} instruction_t;

int cmp(const void* _a, const void* _b)
{
    const instruction_t* a = _a;
    const instruction_t* b = _b;
    for (size_t i = 0; i < 3; ++i)
    {
        if (a->name[i] < b->name[i]) return -1;
        if (a->name[i] > b->name[i]) return 1;
    }
    return 0;
}

int cmp_pt2(const void* _a, const void* _b)
{
    const instruction_t* a = _a;
    const instruction_t* b = _b;
    if (a->name[2] < b->name[2]) return -1;
    if (a->name[2] > b->name[2]) return 1;
    return 0;
}

typedef struct
{
    instruction_t* values;
    size_t length;
    size_t capacity;
} vec_t;

vec_t* create_vec(vec_t* v)
{
    vec_t* vec = v;
    if (vec == NULL)
    {
        vec = malloc(sizeof(vec_t));
    }
    vec->length = 0;
    vec->capacity = 1;
    vec->values = malloc(sizeof(instruction_t));
    return vec;
}

void push(vec_t* vec, instruction_t value)
{
    if (vec->length >= vec->capacity)
    {
        vec->values = realloc(vec->values, sizeof(instruction_t) * vec->capacity * 2);
            vec->capacity *= 2;
    }
    vec->values[vec->length] = value;
    vec->length++;
}

vec_t instructions;
char* directions = NULL;

void read_instructions(FILE* fd)
{
    create_vec(&instructions);
    char* lineptr = NULL;
    size_t length, n;
    length = getline(&directions, &n, fd);              // grab directions
    length = getline(&lineptr, &n, fd);                 // skip empty line
    while ((length = getline(&lineptr, &n, fd)) != -1)  // loop over all remaining lines
    {
        instruction_t instruction;
        strncpy(instruction.name, lineptr, 3);
        strncpy(instruction.left, lineptr + 7, 3);
        strncpy(instruction.right, lineptr + 12, 3);


        push(&instructions, instruction);
    }
    free(lineptr);
    qsort(instructions.values, instructions.length, sizeof(instruction_t), cmp);
}

size_t part_1()
{
    size_t steps = 0;
    size_t len = strlen(directions) - 1; // - 1 to remove the '\n'

    _Bool found = 0;
    size_t idx = 0; // the vec is sorted therefore AAA is always the first item
    while (found == 0)
    {
        char lr = directions[steps % len];
        char* next = (lr == 'R') ? instructions.values[idx].right : instructions.values[idx].left;
        if (strncmp(next, "ZZZ", 3) == 0) found = 1;
        steps++;
        idx = ((size_t)bsearch(next, instructions.values, instructions.length, sizeof(instruction_t), cmp) - (size_t)instructions.values)/sizeof(instruction_t);
    }

    return steps;
}

size_t find(char* item)
{
    size_t idx = 0;
    while (strncmp(instructions.values[idx].name, item, 3) != 0)
    {
        idx++;
    }
    return idx;
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
    // find number of concurrent positions
    _Bool reached = 0;
    size_t concurrent_positions = 0;
    while (1)
    {
        if (instructions.values[concurrent_positions].name[2] != 'A')
        {
            break;
        }
        concurrent_positions++;
    }
    
    size_t positions[concurrent_positions];
    for (size_t i = 0; i < concurrent_positions; ++i)
    {
        positions[i] = i;
    }
    
    size_t steps[concurrent_positions];
    for (size_t i = 0; i < concurrent_positions; ++i) steps[i] = 0;
    size_t len = strlen(directions) - 1; // - 1 to remove the '\n'

    size_t found = 0;
    size_t iter = 0;
    while(found != concurrent_positions)
    {
        char lr = directions[iter % len];

        for (size_t i = 0; i < concurrent_positions; ++i)
        {
            if (instructions.values[positions[i]].name[2] == 'Z')
            {
                continue;
            }
            char* next = (lr == 'R') ? instructions.values[positions[i]].right : instructions.values[positions[i]].left;
            if (next[2] == 'Z')
            {
                found++;
            }
            positions[i] = find(next);
            steps[i]++;
        }

        iter++;
    }

    if (concurrent_positions == 1) return steps[0];

    size_t _lcm = 0;
    _lcm = lcm(steps[0], steps[1]);
    for (size_t i = 2; i < concurrent_positions; ++i)
    {
        _lcm = lcm(_lcm, steps[i]);
    }

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
    read_instructions(fd);
    fclose(fd);

    printf("Part 1: %ld\n", part_1());
    qsort(instructions.values, instructions.length, sizeof(instruction_t), cmp_pt2);
    printf("Part 2: %lu\n", part_2());

    free(instructions.values);
    free(directions);

    return EXIT_SUCCESS;
}
