#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <search.h>

size_t hash(char* str, size_t n)
{
    size_t ret = 0;
    for (size_t i = 0; i < n; ++i)
    {
        ret += str[i];
        ret *= 17;
        ret = ret % 256;
    }
    return ret;
}

uint32_t part_1(FILE* fd)
{
    char* lineptr = NULL;
    size_t length, n;
    uint32_t sum = 0;
    if ((length = getline(&lineptr, &n, fd)) != -1) // loop over all lines
    {
        size_t offset = 0;
        while (offset < strlen(lineptr))
        {
            sum += hash(lineptr + offset, strcspn(lineptr + offset, ",\n"));
            offset += strcspn(lineptr + offset, ",\n") + 1;
        }
    }
    free(lineptr);
    return sum;
}

typedef struct
{
    char label[6];
    uint8_t focal_length;
} lens_t;

int cmp(const void* _a, const void* _b)
{
    const lens_t* a = _a;
    const lens_t* b = _b;
    return strncmp(a->label, b->label, 6);
}

typedef struct {
    lens_t* lenses;
    size_t length;
    size_t capacity;
} box_t;

box_t* create_box(box_t* b)
{
    box_t* box = b;
    if (box == NULL)
    {
        box = malloc(sizeof(box_t));
    }
    box->length = 0;
    box->capacity = 1;
    box->lenses = malloc(sizeof(lens_t));
    return box;
}

void push(box_t* b, lens_t lens)
{
    if (b->length == b->capacity)
    {
        b->lenses = realloc(b->lenses, sizeof(lens_t) * b->capacity * 2);
        b->capacity *= 2;
    }
    b->lenses[b->length] = lens;
    b->length++;
}

void delete(box_t* b, size_t i)
{
    for (int64_t j = i; j < b->length - 1; ++j)
    {
        b->lenses[j] = b->lenses[j + 1];
    }
    b->length--;
}

void print_box(box_t* b)
{
    for (size_t i = 0; i < b->length; ++i)
    {
        printf("[%.6s %u] ", b->lenses[i].label, b->lenses[i].focal_length);
    }
    printf("\n");
}


uint32_t part_2(FILE* fd)
{
    char* lineptr = NULL;
    size_t length, n;
    uint32_t sum = 0;
    box_t boxes[256] = {0};
    if ((length = getline(&lineptr, &n, fd)) != -1)
    {
        size_t offset = 0;
        while (offset < strlen(lineptr))
        {
            size_t len = strcspn(lineptr + offset, "=-");
            char label[6] = {0};
            for (size_t i = 0; i < len; ++i)
            {
                label[i] = *(lineptr + offset + i);
            }
            size_t box = hash(label, len);
            if (boxes[box].lenses == NULL)
            {
                create_box(&boxes[box]);
            }
            void* elem = lfind(label, boxes[box].lenses, &boxes[box].length, sizeof(lens_t), cmp);
            size_t idx = (elem == NULL) ? ~0 : (elem - (void*)boxes[box].lenses) / sizeof(lens_t);
            
            if (*(lineptr + offset + len) == '=')
            {
                lens_t lens = {0};
                for (size_t i = 0; i < len; ++i)
                {
                    lens.label[i] = label[i];
                }
                lens.focal_length = atoi(lineptr + offset + len + 1);
                if (idx != ~0)
                {
                    boxes[box].lenses[idx] = lens;
                }
                else
                {
                    push(&boxes[box], lens);
                }
            }
            else
            {
                if (idx != ~0)
                {
                    delete(&boxes[box], idx);
                }
            }

            offset += strcspn(lineptr + offset, ",") + 1;
        }
    }

    for (size_t i = 0; i < 256; ++i)
    {
        if (boxes[i].length == 0) continue;
        for (size_t j = 0; j < boxes[i].length; ++j)
        {
            sum += (i + 1) * (j + 1) * boxes[i].lenses[j].focal_length;
        }
    }

    free(lineptr);
    return sum;
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
    printf("Part 1: %d\n", part_1(fd));
    fclose(fd);

    fd = fopen(filename, "r"); // reopen stream
    printf("Part 2: %d\n", part_2(fd));
    fclose(fd);

    return EXIT_SUCCESS;
}
