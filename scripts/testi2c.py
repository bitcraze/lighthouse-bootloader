#!/usr/bin/env python3

import pyftdi.i2c
import time

i2c = pyftdi.i2c.I2cController()

i2c.configure('ftdi://ftdi:232h/1')

# print(dir(i2c))

fpga = i2c.get_port(0x2F)

# print("Test presence ...")
# fpga.read(1, relax=False)

# print("Write commande ...")
# fpga.write(b"\x01\x00\x00\x05\x00\x9f", relax=True)

# time.sleep(1)

# print("Retrieve result ...")
# chip_id = fpga.read(5, relax=True)

fpga.write(b"\x01\x01\x00\x00\x00\xAB")

chip_id = fpga.exchange(b"\x01\x01\x00\x0f\x00\x9f", 6, relax = True)

print("flash ID: ", end='')
for b in chip_id:
    print("0x{:02X}".format(b), end=' ')
print()


fpga.write(b"\x01\x04\x00\x00\x01\x03\x00\x00\x00")
data = fpga.read(257)
for b in data:
    print("0x{:02X}".format(b), end=' ')
print()