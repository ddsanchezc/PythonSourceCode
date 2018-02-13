def reemplazo(string):
    #string = str(input("Ingrese la palabra"))
    i = 0
    nueva_Palabra = ""
    while i < len(string):  # solo pongo "<" ya que i empieza desde el 0
        Cifra_unitaria_string = string[i:i + 1]

        if Cifra_unitaria_string == Cifra_unitaria_string.lower(): #si es que encuentra letra minuscula
            nueva_Palabra = nueva_Palabra + Cifra_unitaria_string #guardo la palabra como está
        else:
            Cifra_unitaria_string = "$" #primero reemplazo la mayuscula por la $
            nueva_Palabra = nueva_Palabra + Cifra_unitaria_string #luego guardo en nueva palabra

        i = i + 1

    return nueva_Palabra

print("La palabra queda: ", reemplazo("Viva la Vida"))
