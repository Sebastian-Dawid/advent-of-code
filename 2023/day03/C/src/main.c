#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <sys/param.h>

uint32_t part_1(FILE* fd)
{
    char* lineptrs[] = { NULL, NULL, NULL };
    size_t length, n;
    uint32_t sum = 0;
    length = getline(&lineptrs[1], &n, fd);
    while (getline(&lineptrs[2], &n, fd) != -1) // loop over all lines
    {
        // extract numbers from line
        size_t offset = 0;
        while (offset < length)
        {
            size_t local_offset = strcspn(lineptrs[1] + offset, "0123456789");
            size_t numlength = strspn(lineptrs[1] + offset + local_offset, "0123456789");

            offset += local_offset;
            uint32_t number = atoi(lineptrs[1] + offset);

            if (offset >= length) break;

            // check if number is preceeded by symbol on this line
            if ((int)offset - 1 > 0 && lineptrs[1][offset - 1] != '.')
            {
                sum += number;
                offset += numlength;
                continue;
            }
            else if (offset + numlength < length - 1 && lineptrs[1][offset + numlength] != '.')
            {
                sum += number;
                offset += numlength;
                continue;
            }

            // previous line
            if (lineptrs[0] != NULL)
            {
                int found = 0;
                for (int32_t i = 0; i < numlength + 2; ++i)
                {
                    if ((int)offset - 1 + i < 0 || offset - 1 + i > length - 1)
                    {
                        continue;
                    }
                    char ch = lineptrs[0][offset - 1 + i];
                    if (ch != 0x0a && ch != '.' && (ch < 0x30 || ch > 0x39))
                    {
                        found = 1;
                        break;
                    }
                }
                if (found)
                {
                    sum += number;
                    offset += numlength;
                    continue;
                }
            }
            // next line
            for (int32_t i = 0; i < numlength + 2; ++i)
            {
                if ((int)offset - 1 + i < 0 || offset - 1 + i > length - 1)
                {
                    continue;
                }
                char ch = lineptrs[2][offset - 1 + i];
                if (ch != 0x0a && ch != '.' && (ch < 0x30 || ch > 0x39))
                {
                    sum += number;
                    break;
                }
            }

            offset += numlength;
        }

        char* tmp = lineptrs[0];
        lineptrs[0] = lineptrs[1];
        lineptrs[1] = lineptrs[2];
        lineptrs[2] = tmp;
    }

    size_t offset = 0;
    while (offset < length)
    {
        size_t local_offset = strcspn(lineptrs[1] + offset, "0123456789");
        size_t numlength = strspn(lineptrs[1] + offset + local_offset, "0123456789");

        offset += local_offset;
        uint32_t number = atoi(lineptrs[1] + offset);
        if (offset >= length) break;

        // check if number is preceeded by symbol on this line
        if ((int)offset - 1 > 0 && lineptrs[1][offset - 1] != '.')
        {
            sum += number;
            offset += numlength;
            continue;
        }
        else if (offset + 1 < length - 1 && lineptrs[1][offset + numlength] != '.')
        {
            sum += number;
            offset += numlength;
            continue;
        }

        for (size_t i = 0; i < numlength + 2; ++i)
        {
            if ((int)offset - 1 + i < 0 || offset - 1 + i > length - 1)
            {
                continue;
            }
            char ch = lineptrs[0][offset - 1 + i];
            if (ch != 0x0a && ch != '.' && (ch < 0x30 || ch > 0x39))
            {
                sum += number;
                break;
            }
        }
        offset += numlength;
    }

    free(lineptrs[0]);
    free(lineptrs[1]);
    free(lineptrs[2]);
    return sum;
}

uint32_t part_2(FILE* fd)
{
    char* lineptrs[3] = {NULL, NULL, NULL};
    size_t length, n;
    uint32_t sum = 0;
    uint32_t times = 0;
    length = getline(&lineptrs[1], &n, fd);
    while (getline(&lineptrs[2], &n, fd) != -1) // loop over all lines
    {
        size_t offset = 0;
        while (offset < length)
        {
            size_t local_offset = strcspn(lineptrs[1] + offset, "*");
            offset += local_offset;
            if (offset >= length) break;

            size_t adjacent_numbers = 0;
            size_t nums[2] = { 0, 0 };

            // check same line
            if (offset - 1 >= 0 && lineptrs[1][offset - 1] >= 0x30 && lineptrs[1][offset - 1] <= 0x39)
            {
                size_t local_offset = 1;
                for (size_t j = 1; j < MIN(offset, 3); ++j)
                {
                    char ch = lineptrs[1][offset - 1 - j];
                    if (ch < 0x30 || ch > 0x39) break;
                    local_offset++;
                }
                uint32_t num = atoi(lineptrs[1] + offset - local_offset);
                adjacent_numbers++;
                if (adjacent_numbers <= 2) nums[adjacent_numbers - 1] = num;
            }
            if (offset + 1 < length && lineptrs[1][offset + 1] >= 0x30 && lineptrs[1][offset + 1] <= 0x39)
            {
                uint32_t num = atoi(lineptrs[1] + offset + 1);
                adjacent_numbers++;
                if (adjacent_numbers <= 2) nums[adjacent_numbers - 1] = num;
            }
            // check prev line
            int continous = 0;
            for (size_t i = 0; i < 3; ++i)
            {
                if (offset - 1 + i < 0) continue;
                char ch = lineptrs[0][offset - 1 + i];
                if (ch >= 0x30 && ch <= 0x39)
                {
                    if (continous == 0)
                    {
                        adjacent_numbers++;
                    }
                    continous++;
                }
                else
                {
                    if (continous)
                    {
                        size_t local_offset = 0;
                        for (size_t j = 1; j < 4; ++j)
                        {
                            char ch = lineptrs[0][offset - 1 - j + i];
                            if (ch < 0x30 || ch > 0x39) break;
                            local_offset++;
                        }
                        uint32_t num = atoi(lineptrs[0] + offset - 1 + i - local_offset);
                        if (adjacent_numbers <= 2) nums[adjacent_numbers - 1] = num;
                    }
                    continous = 0;
                }
            }
            if (continous > 0)
            {
                uint32_t num = atoi(lineptrs[0] + offset + 2 - continous);
                if (adjacent_numbers <= 2) nums[adjacent_numbers - 1] = num;
            }
            // check next line
            continous = 0;
            for (size_t i = 0; i < 3; ++i)
            {
                if (offset - 1 + i >= length) continue;
                char ch = lineptrs[2][offset - 1 + i];
                if (ch >= 0x30 && ch <= 0x39)
                {
                    if (continous == 0)
                    {
                        adjacent_numbers++;
                    }
                    continous++;
                }
                else
                {
                    if (continous)
                    {
                        size_t local_offset = 0;
                        for (size_t j = 1; j < 4; ++j)
                        {
                            char ch = lineptrs[2][offset - 1 - j + i];
                            if (ch < 0x30 || ch > 0x39) break;
                            local_offset++;
                        }
                        uint32_t num = atoi(lineptrs[2] + offset - 1 + i - local_offset);
                        if (adjacent_numbers <= 2) nums[adjacent_numbers - 1] = num;
                    }
                    continous = 0;
                }
            }
            if (continous > 0)
            {
                uint32_t num = atoi(lineptrs[2] + offset + 2 - continous);
                if (adjacent_numbers <= 2) nums[adjacent_numbers - 1] = num;
            }


            if (adjacent_numbers == 2)
            {
                sum += nums[0] * nums[1];
            }

            offset++;
        }

        char* tmp = lineptrs[0];
        lineptrs[0] = lineptrs[1];
        lineptrs[1] = lineptrs[2];
        lineptrs[2] = tmp;
    }
    size_t offset = 0;
    while (offset < length)
    {
        size_t local_offset = strcspn(lineptrs[1] + offset, "*");
        offset += local_offset;
        if (offset >= length) break;

        size_t adjacent_numbers = 0;
        size_t nums[2] = { 0, 0 };

        // check same line
        if (offset - 1 >= 0 && lineptrs[1][offset - 1] >= 0x30 && lineptrs[1][offset - 1] <= 0x39)
        {
            size_t local_offset = 1;
            for (size_t j = 1; j < 4; ++j)
            {
                char ch = lineptrs[1][offset - 1 - j];
                if (ch < 0x30 || ch > 0x39) break;
                local_offset++;
            }
            uint32_t num = atoi(lineptrs[1] + offset - local_offset);
            adjacent_numbers++;
            if (adjacent_numbers <= 2) nums[adjacent_numbers - 1] = num;
        }
        if (offset + 1 < length && lineptrs[1][offset + 1] >= 0x30 && lineptrs[1][offset + 1] <= 0x39)
        {
            uint32_t num = atoi(lineptrs[1] + offset + 1);
            adjacent_numbers++;
            if (adjacent_numbers <= 2) nums[adjacent_numbers - 1] = num;
        }
        // check prev line
        int continous = 0;
        for (size_t i = 0; i < 3; ++i)
        {
            if (offset - 1 + i < 0) continue;
            char ch = lineptrs[0][offset - 1 + i];
            if (ch >= 0x30 && ch <= 0x39)
            {
                if (continous == 0)
                {
                    adjacent_numbers++;
                }
                continous++;
            }
            else
            {
                if (continous)
                {
                    size_t local_offset = 0;
                    for (size_t j = 1; j < 4; ++j)
                    {
                        char ch = lineptrs[0][offset - 1 - j + i];
                        if (ch < 0x30 || ch > 0x39) break;
                        local_offset++;
                    }
                    uint32_t num = atoi(lineptrs[0] + offset - 1 + i - local_offset);
                    if (adjacent_numbers <= 2) nums[adjacent_numbers - 1] = num;
                }
                continous = 0;
            }
        }
        if (continous > 0)
        {
            uint32_t num = atoi(lineptrs[0] + offset + 2 - continous);
            if (adjacent_numbers <= 2) nums[adjacent_numbers - 1] = num;
        }

        if (adjacent_numbers == 2)
        {
            sum += nums[0] * nums[1];
        }

        offset++;
    }
    free(lineptrs[0]);
    free(lineptrs[1]);
    free(lineptrs[2]);
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
