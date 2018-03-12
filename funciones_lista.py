#no_olvidar=["huevos","palta","lechuga","naranjas",7000]
no_olvidar_2="huevos,palta,lechuga,naranja" #solo usar para la funcion split
#for i in no_olvidar: #desde el primero hacia el ultimo, concatenando con un "no olvidar"
#    print("No olvidar: ",i)

######
#print (no_olvidar[::-1]) #desde el ultimo al primero
######


##########
# no_olvidar.append(23.56) #agrega solo un elemento
#no_olvidar.extend([25,"kevin"]) #agrega mas de un elemento
#no_olvidar.insert(2,5000) #agrega en la posicion x, un elemento
#no_olvidar.pop() #elimina el ultimo elemento de la lista (no necesita mas parametro)
#no_olvidar.remove("palta") #elimino el elemento de posicion x
#esta_elemento="lechuga" in no_olvidar #devolvera un valor True si el elemento se encuentra en la lista

########
#lista_creada=no_olvidar_2.split(",") #aqui crea la lista y a su vez lo ordena
#print("La lista creada es: ",lista_creada)
#tipo=type(lista_creada)
#print("Es de tipo:",tipo)
#########


#####################
#lista=['huevos','palta','lechuga','naranja']
#print("La lista original es: ",lista)
#lista.sort()
#print("La lista ordenada es: ",lista)
####################


###############
comprar=[[1800,"huevos"],[2300,"palta"],[450,"naranjas"],[610,"queso"]]
print("original: ",comprar)
comprar.sort()
print("ordenado: ",comprar)

##########