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

void Write(int* intersecciones, int N, const char *filename) {
	FILE *fp;
	fp = fopen(filename, "w");
	for (int i = 0; i < N; i++){
		if (i%2 == 0){
			fprintf(fp, "%d %d\n", intersecciones[i], intersecciones[i + 1]);
		}
	}
	fclose(fp);
}


bool seInterseca(int aStart, int aEnd, int bStart, int bEnd){

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
void interseccionConjuntos(int* A, int *B, int *intersecciones,
							int la, int lb){		
	
	int aStart, aEnd, bStart, bEnd;
	int posicion = 0;
	
	for (int i = 0; i < la; i++){
		aStart = A[2*i];
		aEnd = A[2*i + 1];

		for (int j = 0; j < lb; j++){
			bStart = B[2*j];
			bEnd = B[2*j + 1];

			if (seInterseca(aStart, aEnd, bStart, bEnd)){
				//Guardo el número del intervalo (partiendo de 0)
				intersecciones[posicion] = i;
				intersecciones[posicion + 1] = j;
				posicion += 2;
			}
		}
	}
}


//Buscar el indice del intervalo de B que termina antes de que sStart inicie.
//Bend < astart
__device__ void binarySearchEnds(int *B, int lB, int aStart, int *slice){
	int low = 0;
	int high = lB - 1;

	while(low <= high){
		int mid = (low + high)/2;

		if (B[2*mid + 1] >= aStart){
			high = mid - 1;
		} else { // mid > target
			low = mid + 1;
		}
	}
	slice[0] = high;
}

//aend < Bstart
//Deberia ser correcto, buscar el elemento en B, que inicia despues de que sEnd termina.
//O sea, el siguiente numero mayor a sEnd.
__device__ void binarySearchStart(int *B, int lB, int sEnd, int *slice){
	int low = 0;
	int high = lB - 1;

	while(low <= high){
		int mid = (low + high)/2;
		if (B[2*mid] <= sEnd){
			low = mid + 1;
		} else { // mid > target
			high = mid - 1;
		}
	}
	slice[1] = low;
}

__device__ bool isAnIntersect(int aStart, int aEnd, int bStart, int bEnd){
	if ((aEnd < bStart) || (bEnd < aStart)){
		return false;
	}
	else{
		return true;
	}
}



__global__ void setIntersection_Kernel2(int *A, int *B, int lA, int lB, int *intercepts, int *lenIntercepts){
	int Id = threadIdx.x + blockIdx.x * blockDim.x;

	if (Id >= lA) return;

	int* slice = new int[2];
	int aStart = A[2*Id];
	int aEnd = A[2*Id + 1];

	binarySearchEnds(B, lB, aStart, slice);
	binarySearchStart(B, lB, aEnd, slice);

	printf("(%d, %d) - slice (%d, %d)\n",aStart, aEnd, slice[0]+1, slice[1]-1);

	if (slice[0] > slice[1]){
		//No hay interseccion.
		return;
	}

	int *tempInter = new int[2*(slice[1] - slice[0])];  
	int tempInterFounds = 0;
	int bStart, bEnd;
	
	for (int i = slice[0]; i <= slice[1]; i++){
		bStart = B[2*i];
		bEnd = B[2*i + 1];
		if (isAnIntersect(aStart, aEnd, bStart, bEnd)){
			tempInter[2 * tempInterFounds] = Id;
			tempInter[2 * tempInterFounds + 1] = i; 
			tempInterFounds += 1;
		}
	}
	
	__syncthreads();
	atomicAdd(lenIntercepts, tempInterFounds);

}

int main(int argc, char **argv){

	// Largo del arreglo A y B, respectivamente.
	int la, lb;
	// Conjuntos de intervalos A y B.
	int *A, *B;
	int *intersecciones;
	clock_t t1, t2;
	
	char filename[] = {"inputmid.txt\0"};
	char outputFilename[] = {"output.txt\0"};

	Read(&A, &B, &la, &lb, filename); 
	
	// Parte CPU

	intersecciones = new int[la*lb*2];

	t1 = clock();
	interseccionConjuntos(A, B, intersecciones, la, lb);
	t2 = clock();

	double ms = 1000.0 * (double)(t2 -t1) / CLOCKS_PER_SEC;

	std::cout << "Tiempo algoritmo en CPU = " << ms << "[ms]" << std::endl;
	
	int N = sizeof(intersecciones);

	Write(intersecciones, N, outputFilename);

	delete[] intersecciones;

	//Kernel 2 - Binary Search + ...

	cudaEvent_t ct1, ct2;
	int *Adev, *Bdev;
	int *interdev, *interhost;
	int *intercepts, *interceptsdev, *lenIntercepts, *lenInterceptsdev;
	lenIntercepts = 0;

    cudaEventCreate(&ct1);
    cudaEventCreate(&ct2);

    //KERNEL 1

    int gs, bs;
    cudaMalloc((void**)&Adev, 2 * la * sizeof(int));
    cudaMalloc((void**)&Bdev, 2 * lb * sizeof(int));
    cudaMalloc((void**)&interceptsdev, 2 * la * lb * sizeof(int));
    cudaMalloc((void**)&lenInterceptsdev, sizeof(int));

    cudaMemcpy(Adev, A, 2 * la * sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(Bdev, B, 2 * lb * sizeof(int), cudaMemcpyHostToDevice); 
    cudaMemcpy(lenInterceptsdev, lenIntercepts, sizeof(int), cudaMemcpyHostToDevice); 

    bs = 256;
    gs = (int)ceil((float) la / bs);

    cudaEventRecord(ct1);
    setIntersection_Kernel2<<<gs, bs>>>(Adev, Bdev, la, lb, interceptsdev, lenInterceptsdev);
    cudaEventRecord(ct2);
    cudaEventSynchronize(ct2);

    float dt;
    cudaEventElapsedTime(&dt, ct1, ct2);

    //cudaMemcpy(&maxValueHost, max, sizeof(int), cudaMemcpyDeviceToHost);
    printf("\nTiempo GPU1: %f[ms]\n", dt);
    //printf("Maximo: %d\n", maxValueHost);


}