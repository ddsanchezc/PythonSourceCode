def mezclador(string_a, string_b):

  #string_a = str(input("Ingrese la primera palabra: "))
  #string_b = str(input("Ingrese la segunda palabra: "))
  Dos_Primeras_Cifras = string_a[0:2]
  Dos_Ultimas_Cifras = string_b[len(string_b)-2:len(string_b)+1]
  Total = Dos_Primeras_Cifras+Dos_Ultimas_Cifras

  return Total

print("La palabra formada es: ",mezclador("familia","abrigarse"))