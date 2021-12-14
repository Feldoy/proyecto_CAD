#include <iostream>
#include <cstdio>
#include <time.h>
#include <cuda_runtime.h>
#include <stdio.h>

using namespace std;

void Read(int** A, int** B, int *la, int *lb, const char *filename) {    
	FILE *fp;
	fp = fopen(filename, "r");
  	fscanf(fp, "%d %d\n", la, lb);

	int* Atemp = new int[(*la) * 2];
	int* Btemp = new int[(*lb) * 2];

	for (int i = 0; i < (*la); i++){
		fscanf(fp, "%d %d\n", &(Atemp[2*i]), &(Atemp[2*i + 1]));
	}

	for (int j = 0; j < (*lb); j++){
		fscanf(fp, "%d %d\n", &(Btemp[2*j]), &(Btemp[2*j + 1]));
	}

	*A = Atemp;
	*B = Btemp;
}

void ReadSoA(int** A, int** B, int *la, int *lb, const char *filename) {    
	FILE *fp;
	fp = fopen(filename, "r");
  	fscanf(fp, "%d %d\n", la, lb);

	int* Atemp = new int[(*la) * 2];
	int* Btemp = new int[(*lb) * 2];

	for (int i = 0; i < (*la); i++){
		fscanf(fp, "%d %d\n", &(Atemp[i]), &(Atemp[*la + i]));
	}

	for (int j = 0; j < (*lb); j++){
		fscanf(fp, "%d %d\n", &(Btemp[j]), &(Btemp[*lb + j]));
	}

	*A = Atemp;
	*B = Btemp;
}

void Write(int* intersecciones, int la, int lb, const char *filename) {
	FILE *fp;
	fp = fopen(filename, "w");

	for (int i = 0; i < (la*lb*2); i++){
		if (i%2 == 0){
			if ((i != 0) && (intersecciones[i] == 0) && (intersecciones[i+1] == 0)){
				break;
			}
			fprintf(fp, "%d %d\n", intersecciones[i], intersecciones[i + 1]);
		}
	}
	fclose(fp);
}

bool seIntersecta(int aStart, int aEnd, int bStart, int bEnd){

	if ((aEnd < bStart) || (bEnd < aStart)){
		return false;
	}
	else{
		return true;
	}
}

/*
for i en el largo de A
    for j in el largo de B

    Si A[i] se intersecta con B[j]
        Guardar (i,j)
*/
void interseccionConjuntos(int* A, int *B,int *intersecciones, 
						int la, int lb){		
	
	int aStart, aEnd, bStart, bEnd;
	int posicion = 0;
	
	for (int i = 0; i < la; i++){
		aStart = A[2*i];
		aEnd = A[2*i + 1];

		for (int j = 0; j < lb; j++){
			bStart = B[2*j];
			bEnd = B[2*j + 1];

			if (seIntersecta(aStart, aEnd, bStart, bEnd)){
				//Guardo el número del intervalo (partiendo de 0)
				printf("%d ", posicion);
				intersecciones[posicion] = i;
				intersecciones[posicion + 1] = j;
				posicion += 2;
			}
		}
	}
}

int main(int argc, char **argv){

	// Largo del arreglo A y B, respectivamente.
	int la, lb;
	// Conjuntos de intervalos A y B.
	int *A, *B;
	int *intersecciones;
	clock_t t1, t2;
	
	char filename[] = {"input.txt\0"};
	char outputFilename[] = {"output.txt\0"};

	Read(&A, &B, &la, &lb, filename); 

	// for (int i = 0; i < la*2; i++){
	// 	std::cout << A[i] << std::endl;
	// }

	// Parte CPU

	intersecciones = new int[la*lb*2];

	t1 = clock();
	interseccionConjuntos(A, B, intersecciones, la, lb);
	t2 = clock();

	double ms = 1000.0 * (double)(t2 -t1) / CLOCKS_PER_SEC;

	std::cout << "Tiempo algoritmo en CPU = " << ms << "[ms]" << std::endl;

	Write(intersecciones, la, lb, outputFilename);

	delete[] intersecciones;

	return 0;
}