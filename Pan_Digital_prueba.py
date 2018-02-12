def PanPrimo(n):
    respuesta=False
    #n=int(input("Ingrese el numero: "))
    temp=str(n)
    Cero=temp.find(str(0)) #cuando el numero no se encuentre esta funcion retorna un (-1)
    Uno=temp.find(str(1))
    Dos = temp.find(str(2))
    Tres = temp.find(str(3))
    Cuatro = temp.find(str(4))
    Cinco = temp.find(str(5))
    Seis = temp.find(str(6))
    Siete = temp.find(str(7))
    Ocho = temp.find(str(8))
    Nueve = temp.find(str(9))

    # encontrando el numero 0
    if Cero==-1:
        rpta0=False
    else:
        rpta0=True

    #encontrando el numero 1
    if Uno==-1:
        rpta1=False
    else:
        rpta1=True

    # encontrando el numero 2
    if Dos == -1:
        rpta2 = False
    else:
        rpta2 = True

    # encontrando el numero 3
    if Tres == -1:
        rpta3 = False
    else:
        rpta3 = True

    # encontrando el numero 4
    if Cuatro==-1:
        rpta4=False
    else:
        rpta4=True

    #encontrando el numero 5
    if Cinco==-1:
        rpta5=False
    else:
        rpta5=True

    # encontrando el numero 6
    if Seis == -1:
        rpta6 = False
    else:
        rpta6 = True

    # encontrando el numero 7
    if Siete == -1:
        rpta7 = False
    else:
        rpta7 = True

    # encontrando el numero 8
    if Ocho ==-1:
        rpta8= False
    else:
        rpta8= True

    #encontrando el numero 9
    if Nueve ==-1:
        rpta9 = False
    else:
        rpta9 = True


    return temp,rpta0,rpta1,rpta2,rpta3,rpta4,rpta5,rpta6,rpta7,rpta8,rpta9

print(PanPrimo(123456780))