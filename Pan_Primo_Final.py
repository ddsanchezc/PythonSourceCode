def PanPrimo(n):
    temp=str(n) #Aqui convierto el numero en un string (para que pueda buscar el caracter después
    respuestaPD=False #inicializo la variable respuestaPD

    #BUSCADORES
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

    #condicion final
    if rpta0==True and rpta1==True and rpta2==True and rpta3==True and rpta4==True and rpta5==True and rpta6==True and rpta7==True and rpta8==True and rpta9==True:
        respuestaPD=True

    #una vez comprobado que el numero es pandigital
    if respuestaPD==True:
        # Encontrando las 3 ultimas cifras
        TresUCifras = temp[len(temp) - 3:len(temp) + 1] #la funcion len() me bota la longitud de caracteres de la variable temp

        # Saber si las 3 ultimas conforman un numero primo
        contador = 0
        for i in range(1, int(TresUCifras) + 1):
            if int(TresUCifras) % i == 0:
                contador = contador + 1
        if contador == 2:
            respuestaPP = True
        else:
            respuestaPP = False

    else:
        respuestaPP = False

    return respuestaPP


print(PanPrimo(10123485769))
