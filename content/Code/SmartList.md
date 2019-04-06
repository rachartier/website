---
title: "SmartList"
date: 2016-10-05T22:59:58+02:00
draft: true
comments: false
images:
---

Un programme qui cherche et complete une suite logique dans une liste de nombres donnes.

1.    Il faut tout d'abord executer le programme via "./smartlist"
2.    Ensuite, il faut entrer un nombre (N), ce qui permettra d'ecrire N termes.
3.    Enfin, il faut mettre une chaine de caracteres contenant la suite. Exemples:
	+ "0 1 2"
	+ "9 4"
	+ "100 50 25"
	+ "1 2 4"
	+ "1 1"
	+ ...

Execution:
```
./smartlist 10 "1 2 3" 
./smartlist 42 "1.8 5.3" 
./smartlist 20 "2 1 0.5"
```

Le programme va ensuite déterminer le type de la suite

+ "UNKNOW": Il n'y aucune suite logique, du type ("1 2 5")
+ "CONSTANT": La suite est constante ("1 1 1")
+ "GEOMETRIC": N est divisible par N-1 (2 1 0.5)
+ "ARITHMETIC": Repère si la suite peut additionner N et N-1 ou soustraire N et N-1

Ensuite, il fais le calcul pour les X membres de la suite.

## Code

```c
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <float.h>
#include <math.h>

enum	e_sequence_type {
	UNKNOW,
	CONSTANT,
	GEOMETRIC,
	ARITHMETIC
};

typedef enum e_sequence_type	t_sequence_type;

static int essentiallyEqual(float a, float b) {
    return fabs(a - b) <= ( (fabs(a) > fabs(b) ? fabs(b) : fabs(a)) * FLT_EPSILON);
}

int	get_string_carac_numbers(char *str_opt, float *array_sequence)
{
	unsigned 	n_carac 	= 0u;
	char 		delimiters[] 	= ", -+";
	char 		*pch 		= NULL;

	pch = strtok(str_opt, delimiters);

	while(pch != NULL) {
		array_sequence[n_carac++] = atof(pch);

		pch = strtok(NULL, delimiters);
	}

	return n_carac;
}

t_sequence_type get_sequence_type(float *array_sequence, size_t n_elem) {
	size_t 	index;
	float 	tmp;
	int 	err = 0;

	tmp = array_sequence[0];
	for(index = 1; index < n_elem && err != 1; ++index) { // Si les nombres sont "CONSTANT"
		if(!essentiallyEqual((array_sequence[index]), tmp))
			err = 1;
	}

	if(!err) return CONSTANT; err = 0;

	tmp = array_sequence[1] - array_sequence[0];
	for(index = 2; index < n_elem && err != 1; ++index) { // Si les nombres sont "ARITHMETIC"
		if(!essentiallyEqual((array_sequence[index] - array_sequence[index - 1]), tmp))
			err = 1;
	}

	if(!err) return ARITHMETIC; err = 0;

	tmp = array_sequence[1] / array_sequence[0];
	for(index = 2; index < n_elem && err != 1; ++index) { // Si les nombres sont "GEOMETRIC"
		if(!essentiallyEqual((array_sequence[index] / array_sequence[index - 1]), tmp))
			err = 1;
	}

	if(!err) return GEOMETRIC; err = 0;

	return UNKNOW;
}

void continue_sequence(t_sequence_type sequenceType, float *array_sequence, size_t n_to_print) {
	unsigned 	index;
	float 		factor;
	float 		value;

	switch(sequenceType)
	{
	case ARITHMETIC:
		factor 	= array_sequence[1] - array_sequence[0];
		value 	= array_sequence[0];

		printf("Type: Arithmetique\nRaison: %f\n\n", factor);

		for(index = 1; index < n_to_print; ++index) {
			printf("[%u] %.3f\n", index, value);
			value += factor;
		}
		break;
	case GEOMETRIC:
		factor 	= array_sequence[1] / array_sequence[0];
		value 	= array_sequence[0];

		printf("Type: Geometrique\nRaison: %f\n\n", factor);

		for(index = 1; index < n_to_print; ++index) {
			printf("[%u] %.3f\n", index, value);
			value *= factor;
		}
		break;

	case CONSTANT:
		value = array_sequence[0];

		printf("Type: Constante\n\n");

		for(index = 1; index < n_to_print; ++index)
			printf("[%u] %.3f\n", index, value);
		break;

	case UNKNOW:
		printf("Il n'y a aucune sequence logique trouvee.\n");
		break;

	default:
		break;
	}
}

int main(int argc, char *argv[]) {
	if(argc != 3) {
		fprintf(stderr, "Erreur: il faut 3 arguments.");
		return 1;
	}

	t_sequence_type	sequence_type;

	size_t 		n_to_print 	= (unsigned)atoi(argv[1]);
	size_t 		size_string_ope = strlen(argv[2]);
	float 		*array_sequence	= malloc(size_string_ope * sizeof(float));
	int 		n;

	if(array_sequence == NULL) {
		fprintf(stderr, "Erreur: memoire allouee indisponible");
		return 1;
	}

	n = get_string_carac_numbers(argv[2], array_sequence);

	sequence_type = get_sequence_type(array_sequence, n);

	continue_sequence(sequence_type, array_sequence, n_to_print);

	free(array_sequence);

    return 0;
}
```

