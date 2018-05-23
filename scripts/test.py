#!/usr/bin/env python3

from serial import Serial
from binascii import hexlify

fpga = Serial("/dev/ttyUSB1", 115200)

print ("Reseting bootloader ...")
fpga.flushOutput()
fpga.send_break()
fpga.flushInput()

# Todo: Fix bug that prevents from sending command without answer
print("Resume from power down ...")
fpga.write(b"\x01\x01\x00\x00\x00\xAB")

fpga.write(b"\x01\x01\x00\x0F\x00\x9F")
print("Chip ID:", hexlify(fpga.read(15)))

# print("Write enable and erase first sector")
# fpga.write(b"\x01\x01\x00\x00\x00\x06")
# fpga.write(b"\x01\x04\x00\x00\x00\xD8\x00\x00\x00")

tosend = b"\x01\x04\x00\x00\x10\x03\x00\x00\x00"
fpga.write(tosend)
received = fpga.read(0x1000)

data = received

with open("bootloader_multi.bin", "rb") as f:
    verif = f.read(0x1000)
    if verif == data:
        print("First {} bytes verified succesfully!".format(0x1000))
    else:
        print("Verification of the first 256 bytes failed!")
        print(data)
        print("VS")
        print(verif)

print("Booting!")
fpga.write(b"\x00")
fpga.flush()

