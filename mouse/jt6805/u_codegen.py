import binascii
from bitarray import bitarray

fpw = open('6805.rom', 'w')
with open('6805.uc', 'r') as fp:
    for line in fp:
        line = '0' + line.strip()
        bts = bitarray(line)
        h = binascii.hexlify(bts, b' ', 5).decode()
        print(h)
        fpw.write(h)
        fpw.write("\n")
    fp.close()
    fpw.close()
