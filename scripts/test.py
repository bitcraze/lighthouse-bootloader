#!/usr/bin/env python3

from serial import Serial
from binascii import hexlify

fpga = Serial("/dev/ttyUSB1", 115200)

print ("Reseting bootloader ...")
fpga.send_break()
fpga.send_break()

fpga.write(b"\x01\x01\x00\x0F\x00\x9F")
print("Chip ID:", hexlify(fpga.read(15)))

tosend = b"\x01\x04\x00\x00\x10\x03\x00\x00\x00"
fpga.write(tosend)
received = fpga.read(0x1000)

data = received

with open("bootloader.bin", "rb") as f:
    verif = f.read(0x1000)
    if verif == data:
        print("First {} bytes verified succesfully!".format(0x1000))
    else:
        print("Verification of the first 256 bytes failed!")
        print(data)
        print("VS")
        print(verif)

