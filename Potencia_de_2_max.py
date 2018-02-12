def exponente(n):

    n = int(input("Ingresar el numero: "))
    i=0
    while n >= 2**i:
        i=i+1
        temp=str(2**(i-1))
    return i-1,temp

print("El exponente maximo es: ",exponente(0))
