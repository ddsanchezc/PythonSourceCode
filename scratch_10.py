numero_leido = int(input("inserta un numero >> "))
numero = int(numero_leido)
contador = 0
verificar= False
for i in range(1,numero+1):
    if (numero% i)==0:
       contador = contador + 1
    if contador >= 3:
        verificar=True
        break

if contador==2 or verificar==False:
    print ("el numero es primo")
else:
    print ("el numero no es primo")