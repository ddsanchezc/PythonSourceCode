print("INFORMACION: ","si es Ejecutivo:0","Jefe:1","Externo:2")
cargo=int(input("ingrese el cargo del trabajador"))
if cargo==0:
    sueldo=90
elif cargo==1:
    sueldo=100
else:
    sueldo=50
print("Su sueldo es: ",sueldo)
