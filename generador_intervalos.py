import random

############################################################
# Parte de generación de listas con números a utilizar para
# los intervalos

lista_numeros_1 = list()
lista_numeros_2 = list()
lista_A = list()
lista_B = list()

for i in range(5000):
    lista_numeros_1.append(random.randint(1, 100000))

for i in range(10000):
    lista_numeros_2.append(random.randint(1, 150000))

lista_sin_repeticion_1 = set(lista_numeros_1)
lista_sin_repeticion_2 = set(lista_numeros_2)

lista_final_1 = list(lista_sin_repeticion_1)
lista_final_2 = list(lista_sin_repeticion_2)

if ((len(lista_final_1) % 2) != 0):
    lista_final_1.pop()

if ((len(lista_final_2) % 2) != 0):
    lista_final_2.pop()

lista_A = sorted(lista_final_1)
lista_B = sorted(lista_final_2)

largo_A = len(lista_A)
largo_B = len(lista_B)

############################################################
# Parte para generar el archivo de salida

file = open("input.txt", "w")

print(str(int(largo_A / 2)) + " " + str(int(largo_B / 2)) , file=file)

for i in range(0, largo_A, 2):
    print(str(lista_A[i]) + " " + str(lista_A[i+1]) , file=file)

for i in range(0, largo_B, 2):
    print(str(lista_B[i]) + " " + str(lista_B[i+1]) , file=file)

file.close()