#añadiendo libreria
import math

def promedio_std(lista):
    lista_entrante=str(input("Ingrese los elementos de la lista: "))
    lista_string = lista_entrante.split(",")

    lista = []
    for x in lista_string:
        numero=int(x)
        lista.append(numero)

    #lista

    #promedio
    suma=0
    i=0
    for i in lista:
        suma = suma + i
    prom = suma/len(lista)

    #desviacion
    j=0
    sumcuadrado=0
    for j in lista:
        sumcuadrado = sumcuadrado + (j-prom)**2
    desv = math.sqrt(sumcuadrado)/len(lista)
    return prom,desv

print(promedio_std([]))
