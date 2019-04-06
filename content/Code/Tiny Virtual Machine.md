---
title: "Tiny Virtual Machine"
date: 2016-10-05T23:00:08+02:00
draft: true
comments: false
images:
---

Tiny Virtual Machine est un programme qui, en lisant un fichier source, va interpreter les commandes donnees par le-dit fichier.

Chaque commande est constituee de quatre parties: une est l'opération, la deuxieme est l'emplacement dans le registre (0x00 - 0x10), la troisieme et quatrieme sont les nombres affectes par l'operation

Les operations:

+    0x01: les additions
+    0x02: les soustractions
+    0x03: les multiplications
+    0x04: les divisions
+    0x05: l'opérateur logique ET
+    0x06: l'opérateur logique OU
+    0x07: l'opérateur logique OU EXCLUSIF
+    0x08: le modulo (%)
+    0x09: decalage de bits vers la gauche
+    0x0A: decalage de bits vers la droite
+    0x0B: l'operateur NON

Methodes d'affichage:

+    0x20: affiche un entier
+    0x21: affiche une lettre

Saisir l'entree du clavier:

+    0x22

Exemple

Creez un fichier vide a l'endroit ou se trouve le fichier source et nommez le "code". Avec un editeur hexadecimal (comme HexEdit), entrez le code suivant:
```
01 00 0F 0F 02 01 0F 05 03 02 0F 0F 04 03 10 02 05 04 0F 0F 06 05 0F 0F 07 06 0F 0F 08 07 06 04 09 08 09 03 0A 09 06 05 0B 0A 09 02 20 00 20 01 20 0A 22 0B 20 0B
```

`01 00 0F 0F`, qui est la premiere operation a effectuer, pourrait se traduire par: "je veux une addition que je place dans le registre numero 0x00 et cette addition est `0F + 0F` "

Compilez le programme: 

```
gcc tinyvirtualmachine.c -o tinyvirtualmachine -Wall -Wextra
./tinyvirtualmachine "code"
```

## Code

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdbool.h>

#define N_REGISTERS     16

#define ADD  0x01
#define SUB  0x02
#define MUL  0x03
#define DIV  0x04
#define AND  0x05
#define OR   0x06
#define XOR  0x07
#define MOD  0x08
#define BITWISE_L 0x09
#define BITWISE_R 0x0A
#define NOT  0x0B

#define PRNT_I 0x20
#define PRNT_C 0x21
#define GET_I  0x22

enum {
    ERR_INPUT = 1,
    ERR_EXPR,
    ERR_REG,
    ERR_LAST
};

struct s_cpu {
    long int        reg[N_REGISTERS];
    long int        size;      
    unsigned        ins;        
    unsigned char   *code;
};

typedef struct s_cpu    CPU;

long int getfilesize(FILE *file)
{
    long int size;

    fseek(file, 0, SEEK_END);
    size = ftell(file);

    rewind(file);

    return size;
}

CPU *cpu_create(unsigned char *code, unsigned size)  {
    CPU     *cpu = malloc(sizeof(CPU));

    if(!cpu)
        return NULL;

    cpu->ins = 0;
    cpu->size = size;
    cpu->code = code;

    for(int i = 0; i < N_REGISTERS; ++i)
        cpu->reg[i] = 0;

    return cpu;
}

void cpu_destroy(CPU *cpu) {
    if(cpu)
        free(cpu);
}

long get_input(int *err) {
    long    res = 0;
    char    str[16] = {'\0'};
    
    fgets(str, 16, stdin);

    if(isalpha(str[0]) && str[1] == '\n')
        res = (int)str[0];
    else {
        for(unsigned i = 0; i < strlen(str) - 1 && !*err; ++i)
            if(!isdigit(str[i])) {
                *err = ERR_INPUT;
                break;
             }
        if(!*err)
            res = atol(str);
    }
    return res;
}

void handle_err(int err, unsigned instruction) {
    static const char *err_msg[] = {
        "Keyboard input is incorrect",
        "Incorrect expression",
        "Inexistant register"
    };
 
    if(err > 0 && err < ERR_LAST) {
        fprintf(stderr, "Instruction %u\n", instruction);
        fprintf(stderr, "%s\n", err_msg[err - 1]);
    }
}

void cpu_run(CPU *cpu) {
    if(!cpu)
        return;
    
    int err = 0;

    cpu->ins = 0;

    while(cpu->ins < cpu->size && !err) {
        switch(cpu->code[cpu->ins]) {
            #define OPERATION(instruction, op) \
            case instruction: {\
                ++cpu->ins; \
                if(cpu->ins + 2 < cpu->size) {\
                    if(cpu->code[cpu->ins] > N_REGISTERS) \
                        err = ERR_REG; \
                    cpu->reg[cpu->code[cpu->ins]] = cpu->code[cpu->ins + 1] op cpu->code[cpu->ins + 2]; \
                    cpu->ins += 2; \
                } \
                else \
                    err = ERR_EXPR;\
                break; \
            }

            OPERATION(ADD, +)
            OPERATION(SUB, -)
            OPERATION(MUL, *)
            OPERATION(DIV, /)
            OPERATION(AND, &)
            OPERATION(OR,  |)
            OPERATION(XOR, ^)
            OPERATION(MOD, %)
            OPERATION(BITWISE_L, <<)
            OPERATION(BITWISE_R, >>)
            
            #undef OPERATION
            case NOT:
                ++cpu->ins;
                if(cpu->ins + 1 <= cpu->size) {
                    cpu->reg[cpu->code[cpu->ins]] = ~cpu->code[cpu->ins + 1];
                    ++cpu->ins;
                }
            case PRNT_I:
                ++cpu->ins;
                printf("Register[%u] = %ld\n", cpu->code[cpu->ins], cpu->reg[cpu->code[cpu->ins]]);
                break;
            case PRNT_C:
                ++cpu->ins;
                printf("Register[%u] = %c\n", cpu->code[cpu->ins], (isalnum(cpu->reg[cpu->code[cpu->ins]]))?(char)cpu->reg[cpu->code[cpu->ins]]:' ');
                break;
            case GET_I:
                ++cpu->ins;
                printf("? ");                
                    
                cpu->reg[cpu->code[cpu->ins]] = get_input(&err);
                break;
        }
        handle_err(err, cpu->ins);
        ++cpu->ins; 
    }
        
}

int main(int argc, char *argv[]) {
    (void)argc;
    
    unsigned char *code = NULL;
    long int  size;

    if(argv[1] == NULL)
        return -1;

    CPU     *cpu;
    FILE    *file = fopen(argv[1], "rb");

    if(!file) {
        perror("fopen");
        return -1;
    }

    printf("File loaded\n");

    size = getfilesize(file);
    code = malloc(size);

    fread(code, sizeof(unsigned), size, file);
    fclose(file);

    cpu = cpu_create(code, size);

    if(!cpu)
        return -1;

    cpu_run(cpu);
    cpu_destroy(cpu);

    free(code);

    return 0;
}
```
