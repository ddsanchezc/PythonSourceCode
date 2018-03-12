#inserta strings en una lista

texto = input("Ingrese un string: ")
no_olvidar = texto.split(",") #la coma seria el separador
no_olvidar.sort() #Para ordenar la lista de menor a mayor (en orden alfabetico)
print(no_olvidar)
