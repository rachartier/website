---
title: "Horloge"
date: 2015-02-19T22:59:53+02:00
draft: true
comments: false
images:
---

Une simple horloge qui vous donne l'heure en toutes lettres. Elle donne les secondes, minutes et heures en anglais.

## Image
![](/img/horloge_banniere.png)

## Code

```c
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>
#include <math.h>
#include <stdbool.h>

struct s_position {
    int start;
    int end;
};

struct s_digits {
    int decade;
    int unit;
};

enum e_place {
    UNITS,
    MINUTES,
    HOURS
};

typedef struct s_position    POSITION;
typedef struct s_digits      DIGITS;
typedef enum   e_place       PLACE;

const char *digits[3] = {
    "TWENTYTHIRTYFORTYFIFTYZEROONETWOTHREEFORFIVESIXSEVENEIGHTNINETENELEVENTWELVEFIFTEEN SECONDS",
    "TWENTYTHIRTYFORTYFIFTYZEROONETWOTHREEFORFIVESIXSEVENEIGHTNINETENELEVENTWELVEFIFTEEN MINUTES",
    "ZEROONETWOTHREEFORFIVESIXSEVENEIGHTNINETENELEVENTWELVE                              HOURS"
};

const char *numToWord[19] = {
    "ZERO",
    "ONE",
    "TWO",
    "THREE",
    "FOR",
    "FIVE",
    "SIX",
    "SEVEN",
    "EIGHT",
    "NINE",
    "TEN",
    "ELEVEN",
    "TWELVE",
    "TWENTY",
    "THIRTY",
    "FORTY",
    "FIFTY",
    "TEEN",
    "FIFTEEN"
};

void    wait(int time) {
    clock_t end = clock() + (time * CLOCKS_PER_SEC);
    while(clock()< end);
}

POSITION get_wordPos(const char *word, PLACE where, bool decade)
{
    POSITION position   = {.start = 0, .end = 0};

    size_t  lenght      = strlen(digits[where]);
    size_t  lenght_word = strlen(word);
    size_t  lenght_word_found = 0;

    unsigned int x = 0;

    if(where != HOURS && !decade)
        x = 26;

    for(; x < lenght; ++x)
    {
    if(digits[where][x] == word[0])
    {
            int k =  0;

            position.start = x;

            while((lenght_word_found < lenght_word) &&
                  (digits[where][x + k] == word[lenght_word_found]))
            {
                ++k;
                ++lenght_word_found;
            }

            if(lenght_word_found == lenght_word)
            {
                position.end = k + position.start;

                return position;
            }

            lenght_word_found = 0;
        }
    }

    position.start = -1;
    position.end   = -1;

    return position;
}

int    get_digit(int number, int x)
{
    return ( number / ((int)pow(10, x-1)) % 10 );
}

DIGITS get_wordNum(int time)
{
    DIGITS    digit = {.decade = 0, .unit = 0};

    if(time > 12 && time != 15)
        digit.unit = get_digit(time, 1);

    if(time > 12 && time < 20)
        if(time == 15)
            digit.decade = 18;
        else
            digit.decade = 17;
    else if(time >= 20 && time < 30)
        digit.decade = 13;
    else if(time >= 30 && time < 40)
        digit.decade = 14;
    else if(time >= 40 && time < 50)
        digit.decade = 15;
    else if(time >= 50 && time < 60)
        digit.decade = 16;
    else
        digit.decade = time;

    return digit;
}

void     print_time(int time, PLACE where)
{
    size_t      lenght = strlen(digits[where]);

    POSITION    decadeWord = {.start = 0, .end = 0},
                unitWord   = {.start = 0, .end = 0};
    POSITION    name;

    DIGITS      wordNum = get_wordNum(time);

    switch(where)
    {
        case UNITS:
            name = get_wordPos("SECONDS", where, 0);
            break;
        case MINUTES:
            name = get_wordPos("MINUTES", where, 0);
            break;
        case HOURS:
            name = get_wordPos("HOURS", where, 0);
            break;
        default:
            ;
    }

    decadeWord = get_wordPos(numToWord[wordNum.decade], where, 1);

    if(wordNum.unit != 0)
        unitWord = get_wordPos(numToWord[wordNum.unit], where, 0);

    for(int x = 0; x < (int)lenght; x++)
    {
        if((x >= decadeWord.start && x < decadeWord.end)
        || (x >= unitWord.start && x < unitWord.end)
        || (x >= name.start && x < name.end))
            putchar(digits[where][x]);
        else
            putchar('+');
    }
}

void    print_clock(struct tm clock)
{
    print_time(clock.tm_sec, UNITS); putchar('\n');
    print_time(clock.tm_min, MINUTES); putchar('\n');
    print_time(clock.tm_hour, HOURS); putchar('\n');

    printf("\n");
}

int main(void)
{
    time_t    seconds;
    struct tm nowTime;

    while(1) {
        time(&seconds);
        nowTime = *localtime(&seconds);

        if(nowTime.tm_hour > 12)
            nowTime.tm_hour -= 12;

        print_clock(nowTime);

        wait(1);
    }
    return 0;
}
```
