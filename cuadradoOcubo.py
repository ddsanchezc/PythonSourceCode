numero=0
numero=int(input("Ingrese el numero: "))
temp=numero
if numero%2==0:
    numero=numero**3
else:
    numero=numero**2
print("el numero ingresado es:",temp,"y el resultado es: ",numero)