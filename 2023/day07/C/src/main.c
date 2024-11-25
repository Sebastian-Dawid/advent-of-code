#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

typedef enum
{
    FIVE = 6,
    FOUR = 5,
    FULL_HOUSE = 4,
    THREE = 3,
    TWO_PAIR = 2,
    PAIR = 1,
    HIGH = 0
} hand_type_t;

typedef struct
{
    char cards[5];
    char cards_pt1[5];
    char cards_pt2[5];
    hand_type_t type_pt1;
    hand_type_t type_pt2;
    size_t bid;
} hand_t;

typedef struct
{
    hand_t* values;
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
    vec->values = malloc(sizeof(hand_t));
    vec->length = 0;
    vec->capacity = 1;
    return vec;
}

void push(vec_t* vec, hand_t value)
{
    if (vec->length == vec->capacity)
    {
        vec->values = realloc(vec->values, sizeof(hand_t) * vec->capacity * 2);
        vec->capacity *= 2;
    }
    vec->values[vec->length] = value;
    vec->length++;
}

int less_than_pt1(const void* _a, const void* _b)
{
    const hand_t* a = _a;
    const hand_t* b = _b;

    if (a->type_pt1 > b->type_pt1) return 1;
    else if (a->type_pt1 < b->type_pt1) return -1;

    for (size_t i = 0; i < 5; ++i)
    {
        if (a->cards_pt1[i] < b->cards_pt1[i]) return -1;
        else if (a->cards_pt1[i] > b->cards_pt1[i]) return 1;
    }

    return 0;
}

int less_than_pt2(const void* _a, const void* _b)
{
    const hand_t* a = _a;
    const hand_t* b = _b;

    if (a->type_pt2 > b->type_pt2) return 1;
    else if (a->type_pt2 < b->type_pt2) return -1;

    for (size_t i = 0; i < 5; ++i)
    {
        if (a->cards_pt2[i] < b->cards_pt2[i]) return -1;
        else if (a->cards_pt2[i] > b->cards_pt2[i]) return 1;
    }

    return 0;
}

vec_t hands;

void find_hands(FILE* fd)
{
    char* lineptr = NULL;
    size_t length, n;
    while ((length = getline(&lineptr, &n, fd)) != -1) // loop over all lines
    {
        hand_t hand;
        strncpy(hand.cards, lineptr, 5);
        char counts[13] = {0};
        size_t offset = 0;
        for (uint8_t i = 0; i < 5; ++i)
        {
            switch (*(lineptr + offset))
            {
                case 'A':
                    counts[1] += 1;
                    hand.cards_pt1[i] = 12;
                    hand.cards_pt2[i] = 12;
                    break;
                case 'K':
                    counts[2] += 1;
                    hand.cards_pt1[i] = 11;
                    hand.cards_pt2[i] = 11;
                    break;
                case 'Q':
                    counts[3] += 1;
                    hand.cards_pt1[i] = 10;
                    hand.cards_pt2[i] = 10;
                    break;
                case 'J':
                    counts[0] += 1;
                    hand.cards_pt1[i] = 9;
                    hand.cards_pt2[i] = 0;
                    break;
                case 'T':
                    counts[4] += 1;
                    hand.cards_pt1[i] = 8;
                    hand.cards_pt2[i] = 9;
                    break;
                case '9':
                    counts[5] += 1;
                    hand.cards_pt1[i] = 7;
                    hand.cards_pt2[i] = 8;
                    break;
                case '8':
                    counts[6] += 1;
                    hand.cards_pt1[i] = 6;
                    hand.cards_pt2[i] = 7;
                    break;
                case '7':
                    counts[7] += 1;
                    hand.cards_pt1[i] = 5;
                    hand.cards_pt2[i] = 6;
                    break;
                case '6':
                    counts[8] += 1;
                    hand.cards_pt1[i] = 4;
                    hand.cards_pt2[i] = 5;
                    break;
                case '5':
                    counts[9] += 1;
                    hand.cards_pt1[i] = 3;
                    hand.cards_pt2[i] = 4;
                    break;
                case '4':
                    counts[10] += 1;
                    hand.cards_pt1[i] = 2;
                    hand.cards_pt2[i] = 3;
                    break;
                case '3':
                    counts[11] += 1;
                    hand.cards_pt1[i] = 1;
                    hand.cards_pt2[i] = 2;
                    break;
                case '2':
                    counts[12] += 1;
                    hand.cards_pt1[i] = 0;
                    hand.cards_pt2[i] = 1;
                    break;
            }
            offset++;
        }
        
        hand.type_pt1 = HIGH;
        for (uint8_t i = 0; i < 13; ++i)
        {
            if (hand.type_pt1 == PAIR && counts[i] == 2)
            {
                hand.type_pt1 = TWO_PAIR;
                break;
            }
            else if (hand.type_pt1 == PAIR && counts[i] == 3 || hand.type_pt1 == THREE && counts[i] == 2)
            {
                hand.type_pt1 = FULL_HOUSE;
                break;
            }
            else if (counts[i] == 4)
            {
                hand.type_pt1 = FOUR;
                break;
            }
            else if (counts[i] == 5)
            {
                hand.type_pt1 = FIVE;
                break;
            }
            else if (counts[i] == 2)
            {
                hand.type_pt1 = PAIR;
            }
            else if (counts[i] == 3)
            {
                hand.type_pt1 = THREE;
            }
        }

        hand.type_pt2 = HIGH;
        for (uint8_t i = 1; i < 13; ++i)
        {
            if (hand.type_pt2 == PAIR && counts[i] == 2)
            {
                hand.type_pt2 = TWO_PAIR;
                break;
            }
            else if (hand.type_pt2 == PAIR && counts[i] == 3 || hand.type_pt2 == THREE && counts[i] == 2)
            {
                hand.type_pt2 = FULL_HOUSE;
                break;
            }
            else if (counts[i] == 4)
            {
                hand.type_pt2 = FOUR;
                break;
            }
            else if (counts[i] == 5)
            {
                hand.type_pt2 = FIVE;
                break;
            }
            else if (counts[i] == 2)
            {
                hand.type_pt2 = PAIR;
            }
            else if (counts[i] == 3)
            {
                hand.type_pt2 = THREE;
            }
        }

        if (counts[0] == 5 || counts[0] == 4 || hand.type_pt2 == PAIR && counts[0] == 3
                || hand.type_pt2 == FOUR && counts[0] == 1 || hand.type_pt2 == THREE && counts[0] == 2)
        {
            hand.type_pt2 = FIVE;
        }
        else if (counts[0] == 3 || hand.type_pt2 == PAIR && counts[0] == 2 || hand.type_pt2 == THREE && counts[0] == 1)
        {
            hand.type_pt2 = FOUR;
        }
        else if (hand.type_pt2 == TWO_PAIR && counts[0] == 1)
        {
            hand.type_pt2 = FULL_HOUSE;
        }
        else if (hand.type_pt2 == HIGH && counts[0] == 2 || hand.type_pt2 == PAIR && counts[0] == 1)
        {
            hand.type_pt2 = THREE;
        }
        else if (hand.type_pt2 == HIGH && counts[0] == 1)
        {
            hand.type_pt2 = PAIR;
        }

        hand.bid = atoll(lineptr + offset);

        push(&hands, hand);
    }
    free(lineptr);
}

uint32_t winnings()
{
    size_t sum = 0;
    for (size_t i = 0; i < hands.length; ++i)
    {
        sum += (1 + i) * hands.values[i].bid;
    }
    return sum;
}

int main(int argc, char** argv)
{
    if (argc != 2)
    {
        fprintf(stderr, "Usage: <prog> <filename>");
        return EXIT_FAILURE;
    }

    create_vec(&hands);
    const char* filename = argv[1]; // grab filename
    FILE* fd = fopen(filename, "r");
    find_hands(fd);
    fclose(fd);

    qsort(hands.values, hands.length, sizeof(hand_t), less_than_pt1);
    printf("Part 1: %d\n", winnings());
    
    qsort(hands.values, hands.length, sizeof(hand_t), less_than_pt2);
    printf("Part 2: %d\n", winnings());

    free(hands.values);

    return EXIT_SUCCESS;
}
