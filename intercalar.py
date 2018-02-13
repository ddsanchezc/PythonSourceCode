def intercalar(string_a, string_b):

  #string_a = str(input("Ingrese la primera palabra: "))
  #string_b = str(input("Ingrese la segunda palabra: "))
  i=0
  temp=""
  while i < len(string_a):
      Cifra_unitaria_string_a = string_a[i:i + 1]
      temp = temp + Cifra_unitaria_string_a + string_b
      i = i + 1

  return temp

print("La palabra formada es: ",intercalar("paz","so"))