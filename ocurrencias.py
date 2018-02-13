def ocurrencias(string):

  string = str(input("Ingrese los digitos: "))
  i=0
  Cont_Unos = 0
  Cont_Ceros = 0
  while i < len(string): #solo pongo "<" ya que i empieza desde el 0
      Cifra_unitaria_string = string[i:i + 1]
      if Cifra_unitaria_string == str(1):
          Cont_Unos = Cont_Unos + 1
      if Cifra_unitaria_string == str(0):
          Cont_Ceros = Cont_Ceros + 1
      i = i + 1

  diferencia = Cont_Unos - Cont_Ceros

  return diferencia

print("La diferencia de Unos y ceros es: ",ocurrencias("11000110101"))