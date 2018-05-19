#!/usr/bin/env python3

from serial import Serial

fpga = Serial("/dev/ttyUSB1", 9600)

fpga.send_break()
tosend = b"\x03\0\0\0" + b"\0"*16
fpga.write(tosend)
received = fpga.read(len(tosend))
fpga.send_break()

data = received[-16:]

for b in received:
    print(hex(b))

with open("bootloader.bin", "rb") as f:
    verif = f.read(16)
    if verif == data:
        print("First 16 bytes verified succesfully!")
    else:
        print("Verification of the first 16 bytes failed!")
        print(data)
        print("VS")
        print(verif)

