#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

typedef struct
{
    char* color;
    uint32_t number;
} limits_t;

limits_t lut[] = {
    { "red", 12 },
    { "green", 13 },
    { "blue", 14 }
};

_Bool check_against_lut(char* group, uint32_t num)
{
    for (uint32_t i = 0; i < 3; ++i)
    {
        if (strstr(group, lut[i].color) != NULL)
        {
            if (num > lut[i].number)
            {
                return 1;
            }
            break;
        }
    }
    return 0;
}

uint32_t part_1(FILE* fd)
{
    char* lineptr = NULL;
    size_t length, n;
    uint32_t sum = 0;
    uint32_t id = 1;
    while ((length = getline(&lineptr, &n, fd)) != -1) // loop over all lines
    {
        uint32_t game_possible = 1;
        // remove beginning of line
        size_t offset = strcspn(lineptr, ":") + 2;
        // go through all groups and check if the exceed the limits
        char* group_1 = NULL;
        char* group_2 = NULL;
        char* group_3 = NULL;
        uint32_t g1 = -1, g2 = -1, g3 = -1;
        while (offset < strlen(lineptr))
        {
            char* rem = lineptr + offset;

            size_t group_length = strcspn(rem, ";");
            size_t group_1_length = strcspn(rem, ",");
            size_t group_2_length = strcspn(rem + group_1_length + 2, ",;");
            int32_t group_3_length = group_length - group_1_length - group_2_length - 4;

            group_1 = realloc(group_1, group_1_length);
            strncpy(group_1, rem, group_1_length);
            g1 = atoi(group_1);
            if (check_against_lut(group_1, g1))
            {
                game_possible = 0;
                break;
            }
            if (group_2_length > 0)
            {
                group_2 = realloc(group_2, group_2_length);
                strncpy(group_2, rem + group_1_length + 2, group_2_length);
                g2 = atoi(group_2);
                if (check_against_lut(group_2, g2))
                {
                    game_possible = 0;
                    break;
                }
            }
            if (group_3_length > 0)
            {
                group_3 = realloc(group_3, group_3_length);
                strncpy(group_3, rem + group_1_length + group_2_length + 4, group_3_length);
                g3 = atoi(group_3);
                if (check_against_lut(group_3, g3))
                {
                    game_possible = 0;
                    break;
                }
            }
            offset += strcspn(rem, ";") + 2;
        }
        free(group_1);
        free(group_2);
        free(group_3);
        // if not add the id to the sum
        if (game_possible == 1)
        {
            sum += id;
        }
        id++;
    }
    free(lineptr);
    return sum;
}

uint32_t part_2(FILE* fd)
{
    char* lineptr = NULL;
    size_t length, n;
    uint32_t sum = 0;
    while ((length = getline(&lineptr, &n, fd)) != -1)
    {
        size_t offset = strcspn(lineptr, ":") + 2;
        uint32_t max_red = 0, max_green = 0, max_blue = 0;
        char* group = NULL;
        while (offset < strlen(lineptr))
        {
            char* rem = lineptr + offset;
            size_t len = strcspn(rem, ",;");
            group = realloc(group, len);
            strncpy(group, rem, len);
            
            uint32_t num = atoi(group);

            if (strstr(group, "red") != NULL) max_red = (max_red < num) ? num : max_red;
            else if (strstr(group, "green") != NULL) max_green = (max_green < num) ? num : max_green;
            else if (strstr(group, "blue") != NULL) max_blue = (max_blue < num) ? num : max_blue;

            offset += strcspn(rem, ",;") + 2;
        }
        free(group);
        sum += max_red * max_green * max_blue;
    }

    free(lineptr);
    return sum;
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
    printf("Part 1: %d\n", part_1(fd));
    fclose(fd);

    fd = fopen(filename, "r"); // reopen stream
    printf("Part 2: %d\n", part_2(fd));
    fclose(fd);

    return EXIT_SUCCESS;
}
