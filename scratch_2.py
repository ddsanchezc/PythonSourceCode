
temp=int(input("Ingrese la temperatura"))
print("f°    c°")
for temp in range(0,temp,2):
    print(temp," ",int((temp-32)*5/9))
