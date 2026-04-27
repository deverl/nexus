
import uuid

m = uuid.getnode()

a = []

while m:
    n = int(m % 256)
    m = int(m / 256)
    s = hex(n)
    s = s.replace("0x", "")
    s = s.replace("L", "")
    a.insert(0, s)

while len(a) < 6:
    a.insert(0,"00")

addr = ':'.join(a)

print(addr)

