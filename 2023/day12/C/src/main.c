#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct
{
    struct
    {
        size_t str_pos;
        size_t count_pos;
        size_t block_length;
    } key;
    size_t possibilities;
} node_t;

_Bool cmp(node_t* a, node_t* b)
{
    return a->key.str_pos == b->key.str_pos && a->key.count_pos == b->key.count_pos && a->key.block_length == b->key.block_length;
}

typedef struct
{
    node_t* values;
    size_t length;
    size_t capacity;
} cache_t;

cache_t* create_cache(cache_t* c)
{
    cache_t* cache = c;
    if (cache == NULL)
    {
        cache = malloc(sizeof(cache_t));
    }
    cache->length = 0;
    cache->capacity = 1;
    cache->values = malloc(sizeof(node_t));
    return cache;
}

void push(cache_t* c, node_t value)
{
    if (c->length == c->capacity)
    {
        c->values = realloc(c->values, sizeof(node_t) * c->capacity * 2);
        c->capacity *= 2;
    }
    c->values[c->length] = value;
    c->length++;
}

size_t count_solutions(cache_t* cache, char* str, size_t len, size_t* counts, size_t arr_len, size_t str_pos, size_t count_pos, size_t block_length)
{
    node_t node;
    node.key.str_pos = str_pos;
    node.key.count_pos = count_pos;
    node.key.block_length = block_length;

    for (size_t i = 0; i < cache->length; ++i)
    {
        if (cmp(&node, &cache->values[i]))
        {
            return cache->values[i].possibilities;
        }
    }

    if (str_pos == len)
    {
        if (count_pos == arr_len && block_length == 0) return 1;
        else if (count_pos == arr_len-1 && counts[count_pos] == block_length) return 1;
        else return 0;
    }

    size_t num_solutions = 0;

    char possibilities[2] = { '.', '#' };

    for (size_t i = 0; i < 2; ++i)
    {
        if (str[str_pos] == possibilities[i] || str[str_pos] == '?')
        {
            if (possibilities[i] == '.' && block_length == 0)
            {
                num_solutions += count_solutions(cache, str, len, counts, arr_len, str_pos + 1, count_pos, 0);
            }
            else if (possibilities[i] == '.' && block_length > 0 && count_pos < arr_len && counts[count_pos] == block_length)
            {
                num_solutions += count_solutions(cache, str, len, counts, arr_len, str_pos + 1, count_pos + 1, 0);
            }
            else if (possibilities[i] == '#')
            {
                num_solutions += count_solutions(cache, str, len, counts, arr_len, str_pos + 1, count_pos, block_length + 1);
            }
        }
    }

    node.possibilities = num_solutions;
    push(cache, node);

    return num_solutions;
}

size_t part_1(FILE* fd)
{
    char* lineptr = NULL;
    size_t length, n;
    size_t sum = 0;
    while ((length = getline(&lineptr, &n, fd)) != -1) // loop over all lines
    {
        size_t counts[10] = {0};
        size_t offset, len, idx = 0;
        offset = len = strcspn(lineptr, " ");
        offset++;
        while (offset < strlen(lineptr))
        {
            counts[idx] = atoll(lineptr + offset);
            offset += strcspn(lineptr + offset, ",") + 1;
            idx++;
        }

        cache_t* cache = create_cache(NULL);
        sum += count_solutions(cache, lineptr, len, counts, idx, 0, 0, 0);
        free(cache->values);
        free(cache);
    }
    free(lineptr);
    return sum;
}

size_t part_2(FILE* fd)
{
    char* lineptr = NULL;
    size_t length, n;
    size_t sum = 0;
    while ((length = getline(&lineptr, &n, fd)) != -1) // loop over all lines
    {
        size_t counts[50] = {0};
        size_t offset, len, idx = 0;
        offset = len = strcspn(lineptr, " ");
        offset++;
        while (offset < strlen(lineptr))
        {
            counts[idx] = atoll(lineptr + offset);
            offset += strcspn(lineptr + offset, ",") + 1;
            idx++;
        }
        for (size_t i = 0; i < 5 * idx; ++i)
            counts[i] = counts[i % idx];

        char* str = malloc(len * 5 + 4);
        for (size_t i = 0; i < 4; ++i)
        {
            strncpy(str + (len + 1) * i, lineptr, len);
            str[len + (len + 1) * i] = '?';
        }
        strncpy(str + (len + 1) * 4, lineptr, len);

        cache_t* cache = create_cache(NULL);
        sum += count_solutions(cache, str, len * 5 + 4, counts, 5 * idx, 0, 0, 0);
        free(cache->values);
        free(cache);
        free(str);
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
    printf("Part 1: %lu\n", part_1(fd));
    fclose(fd);

    fd = fopen(filename, "r"); // reopen stream
    printf("Part 2: %lu\n", part_2(fd));
    fclose(fd);

    return EXIT_SUCCESS;
}
