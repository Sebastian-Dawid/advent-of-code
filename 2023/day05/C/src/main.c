#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

typedef struct
{
    size_t dst_start;
    size_t src_start;
    size_t length;
} mapping_t;

_Bool src_in_range(mapping_t* mapping, size_t value)
{
    return mapping->src_start <= value && value < mapping->src_start + mapping->length;
}

_Bool dst_in_range(mapping_t* mapping, size_t value)
{
    return mapping->dst_start <= value && value < mapping->dst_start + mapping->length;
}

typedef struct
{
    mapping_t* mappings;
    size_t length;
    size_t capacity;
} table_t;

table_t* create_table(table_t* t)
{
    table_t* table = t;
    if (table == NULL)
    {
        table = malloc(sizeof(table_t));
    }
    table->length = 0;
    table->capacity = 1;
    table->mappings = malloc(sizeof(mapping_t));
    return table;
}

void delete_table(table_t* table)
{
    free(table->mappings);
    free(table);
}

void push(table_t* table, mapping_t mapping)
{
    if (table->length == table->capacity)
    {
        table->mappings = realloc(table->mappings, sizeof(mapping_t) * table->capacity * 2);
        table->capacity *= 2;
    }
    table->mappings[table->length] = mapping;
    table->length++;
}

size_t find_mapped_value(table_t* table, size_t value)
{
    size_t mapped = value;
    for (size_t i = 0; i < table->length; ++i)
    {
        if (src_in_range(&table->mappings[i], value))
        {
            mapped = table->mappings[i].dst_start + (value - table->mappings[i].src_start);
            break;
        }
    }
    return mapped;
}

size_t find_seed(table_t* table, size_t value)
{
    size_t mapped = value;
    for (size_t i = 0; i < table->length; ++i)
    {
        if (dst_in_range(&table->mappings[i], value))
        {
            mapped = table->mappings[i].src_start + (value - table->mappings[i].dst_start);
            break;
        }
    }
    return mapped;
}

size_t seeds[20];
size_t seed_count = 0;
table_t tables[7];
size_t t_idx = ~0;

void generate_tables(FILE* fd)
{
    char* lineptr = NULL;
    size_t length, n;

    length = getline(&lineptr, &n, fd);
    char* rem = lineptr + strcspn(lineptr, ":") + 2;
    size_t offset = 0;
    while (offset < strlen(rem))
    {
        seeds[seed_count] = atoll(rem + offset);
        offset += strcspn(rem + offset, " ") + 1;
        seed_count++;
    }
    while ((length = getline(&lineptr, &n, fd)) != -1) // loop over all lines
    {
        if (length < 2) continue;
        if (strstr(lineptr, "map") != NULL)
        {
            t_idx++;
            create_table(&tables[t_idx]);
            continue;
        }
        if (t_idx == ~0) continue;

        mapping_t mapping;
        mapping.dst_start = atoll(lineptr);
        size_t offset = strcspn(lineptr, " ") + 1;
        mapping.src_start = atoll(lineptr + offset);
        offset += strcspn(lineptr + offset, " ") + 1;
        mapping.length = atoll(lineptr + offset);
        push(&tables[t_idx], mapping);
    }
    free(lineptr);
}

size_t part_1()
{
    size_t min = ~0;

    for (size_t i = 0; i < seed_count; ++i)
    {
        size_t val = seeds[i];
        for (size_t j = 0; j < 7; ++j)
        {
            val = find_mapped_value(&tables[j], val);
        }
        min = (val < min) ? val : min;
    }

    return min;
}

_Bool is_valid_seed(size_t value)
{
    for (size_t i = 0; i < seed_count; i+=2)
    {
        if (seeds[i] <= value && value < seeds[i] + seeds[i + 1])
        {
            return 1;
        }
    }

    return 0;
}

size_t part_2()
{
    size_t location = 0;
    size_t seed = location;
    for (size_t i = 0; i < 7; ++i)
    {
        seed = find_seed(&tables[6 - i], seed);
    }

    while (is_valid_seed(seed) == 0)
    {
        seed = location;
        for (size_t i = 0; i < 7; ++i)
        {
            seed = find_seed(&tables[6 - i], seed);
        }
        location++;
    }
    
    return location - 1;
}

int main(int argc, char** argv)
{
    if (argc != 2)
    {
        fprintf(stderr, "Usage: %s <filename>\n", argv[0]);
        return EXIT_FAILURE;
    }

    const char* filename = argv[1]; // grab filename
    FILE* fd = fopen(filename, "r");
    generate_tables(fd);
    fclose(fd);

    printf("Part 1: %ld\n", part_1());
    printf("Part 2: %ld\n", part_2());

    for (size_t i = 0; i < 7; ++i)
    {
        free(tables[i].mappings);
    }

    return EXIT_SUCCESS;
}
