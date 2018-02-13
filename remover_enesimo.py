def remover_enesimo(s, n):
    #s = str(input("Ingrese la palabra"))
    i = 0
    nueva_Palabra = ""
    while i < len(s):  # solo pongo "<" ya que i empieza desde el 0
        Cifra_unitaria_s = s[i:i + 1]
        if i == n:
            i = i #Al hacer esto, mantengo el valor del "i" hasta el final del while, para que aumente en una unidad, no estoy guardando el valor de la posicion i en nueva_Palabra
        else:
            nueva_Palabra = nueva_Palabra + Cifra_unitaria_s
        i = i + 1

    return nueva_Palabra

print("La palabra queda: ", remover_enesimo("Hasta luego",3))
