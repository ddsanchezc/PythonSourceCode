#PARA LEER ARCHIVOS

#lectura = open("telefonos.txt", "r") #primero se abre el archivo,
#leer=lectura.readline() #aqui se lee la primera linea
#print(leer)
#leer2=lectura.readline() #aqui se lee la segunda linea(si hubiese)
#print(leer2) #finalmente se imprime

#PARA ESCRIBIR ARCHIVOS
escritura = open("nuevaagenda.txt", "w") #primero se abre el archivo, si el archivo existe, se sobreescribirá
escritura.write("Uno \nDos \nTres")
escritura.close()