def calcular_mcd(n1, n2):

    n1=int(input("Ingresar el primer numero: "))
    n2 = int(input("Ingresar el segundo numero: "))

    if n1 > n2:
        for i in range(1, n2 + 1):
            if n1 % i == 0 and n2 % i == 0:
                mcd = i
        return mcd
    else:
        for i in range(1, n1 + 1):
            if n1 % i == 0 and n2 % i == 0:
                mcd = i
        return mcd


print("El mcd es: ",calcular_mcd(0,0))