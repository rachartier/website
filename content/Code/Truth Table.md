---
title: "Truth Table"
date: 2017-11-07T23:00:35+02:00
draft: true
comments: false
images:
---

Générateur de table de vérité avec la notation polonaise inverse.

L'utilisation se fait via la ligne de commande: 
```
gcc truthtable.c -Wall -Wextra -std=c11 -lm -o ttable
./ttable "expression"
```

L'expression doit être une expression ecrite via la notation polonaise inverse comme suit:

+    "<variable_1> [variable_2] <opérateur logique>" La répétition de ce processus permet de former une expression logique. Le programme va ensuite sortir la table de vérité corespondante, avec les noms des variables transmises.

## Mot clés (nom / abréviation):
### Opérateurs

+    and (&&)
+    or (||)
+    xor (^)
+    not (!)
+    eq (=)
+    nand
+    nor

### Constantes 

+    true
+    false

### Variables

+    une chaine de caractère
+    un caractère


## Exemples d'utilisations

```
./ttable "a b &&"
```

||b|a|Resultat|
|--- |--- |--- |--- |
|1|0|0|0|
|2|0|1|0|
|3|1|0|0|
|4|1|1|1|

```
./ttable "INTRUSION MISENMARCHE DETECTEUR && ||"
```

| |DETECTEUR|MISENMARCHE|INTRUSION|Resultat|
|--- |--- |--- |--- |--- |
|1 |0|0|0|0|
|2 |0|0|1|1|
|3 |0|1|0|0|
|4 |0|1|1|1|
|5 |1|0|0|0|
|6 |1|0|1|1|
|7 |1|1|0|1|
|8 |1|1|1|1|

## Code

```c
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <string.h>
#include <stdint.h>
#include <ctype.h>
#include <math.h>
#include <stdbool.h>

#define TOKEN_MAX_LENGHT        (0xFF)
#define EXPRESSION_MAX_LENGHT   (0xFF)
#define STACK_SIZE              (0xFF)
#define N_KEYWORDS              (7)

#define SET_NTH_BIT(b, i, j)    (b = (i & (1 << j)) >> j)

typedef enum {
    UNDEFINED = -1,
    VAR,
    KEYWORD_ONE_OPE,
    KEYWORD_TWO_OPE
} operator_t;

bool builtin_and(bool a, bool b);
bool builtin_or(bool a, bool b);
bool builtin_xor(bool a, bool b);
bool builtin_not(bool a, bool b);
bool builtin_eq(bool a, bool b);
bool builtin_nor(bool a, bool b);
bool builtin_nand(bool a, bool b);

typedef struct {
    char        name[16];
    char        shortcut[8];
    operator_t  op;
    bool        (*builtin_op)(bool, bool);
} keyword_t;

static keyword_t _keyword[N_KEYWORDS] = {
    { "and", "&&",      KEYWORD_TWO_OPE,  builtin_and},
    { "or",  "||",      KEYWORD_TWO_OPE,  builtin_or},
    { "xor", "^",       KEYWORD_TWO_OPE,  builtin_xor},
    { "not", "!",       KEYWORD_ONE_OPE,  builtin_not},
    { "eq",  "=",       KEYWORD_TWO_OPE,  builtin_eq},
    { "nand", "",    KEYWORD_TWO_OPE,  builtin_nand},
    { "nor", "",     KEYWORD_TWO_OPE,  builtin_nor}
};

typedef struct {
    bool        bit;
    char        name[32];
} bitvar_t;

typedef struct {
    char        name[TOKEN_MAX_LENGHT];
    operator_t  op;
} token_t;

typedef struct {
    token_t token[STACK_SIZE];
    bool    arrbit[STACK_SIZE];

    size_t  size_arrbit;
    size_t  size_token;
    size_t  size_op;
} cstack_t;

typedef struct {
    bitvar_t    var[STACK_SIZE];

    size_t      size;
} var_t;

bool cpop(cstack_t *s) {
    return(s->arrbit[--s->size_arrbit]);
}

void cpush(cstack_t *s, bool bit) {  
    assert(s->size_arrbit < STACK_SIZE);

    s->arrbit[s->size_arrbit++] = bit;
}

void cadd_token(cstack_t *s, const char *name, operator_t op) {
    strcpy(s->token[s->size_token].name, name);
    s->token[s->size_token++].op = op;
}

void var_add(var_t *s, uint32_t bit, const char *name) {
    assert(s->size < STACK_SIZE);

    strcpy(s->var[s->size].name, name);

    s->var[s->size++].bit = bit;
}

int correct_varname(const char *str) {
    while(*str) {
        if(!isalpha(*str++))
            return 0;
    }
    return 1;
}

int already_exist(var_t *varr, const char *var) {
    for(uint32_t i = 0; i < varr->size; ++i) {
        if(strcmp(varr->var[i].name, var) == 0) {
            if(i == 0 || i == 1)
                return 2;    
            return 1;
        }
    }

    return 0;
}

int parse_string(cstack_t *cs, var_t *varr, char *str) {
    operator_t   op = VAR;

    int         tok_false_true = 2;

    char        *pch;
    char        *del = " ";

    pch = strtok(str, del);

    while(pch != NULL) {
        for(int i = 0; i < N_KEYWORDS ; ++i) {
            if(strcmp(pch, _keyword[i].name) == 0 
            || strcmp(pch, _keyword[i].shortcut) == 0) {
                if(_keyword[i].op != KEYWORD_ONE_OPE)
                    cs->size_op++;
                op = _keyword[i].op;
                break;
            }
        }

        if(op == VAR) {
            if(correct_varname(pch)) {
                int ret = already_exist(varr, pch); 
                
                if(ret == 0) {
                    var_add(varr, 0, pch);
                }
                else if(ret == 2) {
                    if(--tok_false_true) {
                        tok_false_true = 0;
                    }
                }
            }
            else {
                return 0;
            }
        }

        cadd_token(cs, pch, op);

        op  = VAR;
        pch = strtok(NULL, del);
    }
    
    if(cs->size_op >= (varr->size - tok_false_true)) {
        return 0;
    }

    return 1;
}

bitvar_t *bitvar_get_from_name(var_t *varr, const char *name) {
    for(uint32_t i = 0u; i < varr->size; ++i) {
        if(strcmp(varr->var[i].name, name) == 0)
            return &varr->var[i];
    }
    return NULL;
}



bool evaluate(const char *name, bool a, bool b) {
    for(int i = 0; i < N_KEYWORDS; ++i) {
        if(strcmp(name, _keyword[i].name) == 0
        || strcmp(name, _keyword[i].shortcut) == 0) {
            return (*_keyword[i].builtin_op)(a, b);
        }
    }

    return 0;
}

bool result_rpn(var_t *varr, cstack_t *cs) {
    int ret;
    
    if(cs->size_op > 0) {
        for(int i = 0; cs->token[i].op != UNDEFINED; ++i) {
            token_t acttok = cs->token[i];

            if(acttok.op == KEYWORD_TWO_OPE) {
                bool a = cpop(cs);
                bool b = cpop(cs);

                cpush(cs, evaluate(acttok.name, a, b));
            }
            else  if(acttok.op == KEYWORD_ONE_OPE) {
                bool a = cpop(cs);

                cpush(cs, evaluate(acttok.name, a, 0));
            }
            else {
                bitvar_t *b = bitvar_get_from_name(varr, acttok.name);

                cpush(cs, b->bit);
            }
        }
        ret = cpop(cs);
        
        cs->size_arrbit = 0;
    }
    else {
        ret = 0;
    }


    return ret;
}

void generate_truthtable(var_t *varr, cstack_t *cs) {
    uint32_t    nelem = varr->size;
    int         res;
    int         maxlenght;

    printf("     ");

    for(int j = varr->size - 1; j >= 0 ; --j) {
        int act_size = strlen(varr->var[j].name);
        if(act_size > maxlenght)
            maxlenght = act_size;
    }
    
    maxlenght += 2;

    for(int j = varr->size - 1; j >= 2 ; --j) {
        printf("%*s", maxlenght, varr->var[j].name);
    }

    printf("%*s", 7 + maxlenght, "Resultat");

    for(int i = 0; i < (1 << (nelem - 2)); ++i) {
        printf("\n%4d:", i);

        for(int j = nelem - 1; j > 1 ; --j) {
            SET_NTH_BIT(varr->var[j].bit, i, (j - 2));

            printf("%*d", maxlenght, varr->var[j].bit);
        }
        res = result_rpn(varr, cs);
        printf("%*d", maxlenght, res);
    }
}

void compute_truthtable(char *expr) {    
    var_t    varr = { .size = 0u };
    cstack_t cs = { .size_arrbit = 0u, 
                    .size_token = 0u,
                    .size_op = 0u };

    int      ret = 0;

    for(int i = 0; i < STACK_SIZE; ++i)
        cs.token[i].op = UNDEFINED;
    
    // Constants
    var_add(&varr, 1, "true");
    var_add(&varr, 0, "false");

    ret = parse_string(&cs, &varr, expr);
    
    if(ret) {
        generate_truthtable(&varr, &cs);
    
        putchar('\n');
    }
    else {
        fprintf(stderr, "Erreur: trop d'operandes\n");
    }
}

int main(int argc, char *argv[]) {
    if(argc == 2) {
        compute_truthtable(argv[1]);
    } 
    else {
        printf("Utilisation: ttable <expr>\n "
                "L'expression fonctionne avec la notation polonaise inverse du type: \"variable1 variable2 operateur_2_entrees\" ou \"variable1 operateur_1_entree\"\n"
                "Operateurs:    \n"
                "\t- and (&&)   \n"
                "\t- or  (||)   \n"
                "\t- xor (^)    \n"
                "\t- not (!)    \n"
                "\t- eq (=)     \n"
                "\t- nand       \n"
                "\t- nor        \n"
                "Constantes:    \n"
                "\t- true (1)   \n"
                "\t- false (0)  \n"
                "Variables:     \n"
                "\t- une chaine de caracteres\n"
                "\t- un caractere\n");

        return 1;
    }

    return 0;
}

bool builtin_and(bool a, bool b) {
    return a && b;
}

bool builtin_or(bool a, bool b) {
    return a || b;
}

bool builtin_xor(bool a, bool b) {
    return a ^ b;
}

bool builtin_not(bool a, bool b) {
    (void)b;
    
    return !a;
}

bool builtin_eq(bool a, bool b){
    return a == b;
}

bool builtin_nor(bool a, bool b) {
    return !(a || b);
}

bool builtin_nand(bool a, bool b) {
    return !(a && b);
}
```
