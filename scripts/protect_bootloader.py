#!/usr/bin/env python3

# Access bootloader on /dev/ttyUSB1 and protects the first 128K of flash
# by setting the SR1 register to 0x28. This protects the bootloader for
# an ICE40UP5K chip

from serial import Serial
import time
from binascii import hexlify

fpga = Serial("/dev/ttyUSB1", 115200)

print ("Reseting bootloader ...")
fpga.flushOutput()
fpga.send_break()
fpga.write(b"\xbc")
fpga.flushOutput()
fpga.flushInput()

print("Resume from power down ...")
fpga.write(b"\x01\x01\x00\x00\x00\xAB")

fpga.write(b"\x01\x01\x00\x0F\x00\x9F")
print("Chip ID:", hexlify(fpga.read(15)))

print("Reading status register ...")
fpga.write(b"\x01\x01\x00\x01\x00\x05")
sr0 = fpga.read(1)[0]
print("Status register SR1: 0x{:02x}".format(sr0))

print("Writing SR0 to protect the first 128K of the flash...")
fpga.write(b"\x01\x01\x00\x00\x00\x06")
fpga.write(b"\x01\x02\x00\x00\x00\x01\x28")

time.sleep(1)

print("Reading status register ...")
fpga.write(b"\x01\x01\x00\x01\x00\x05")
sr0 = fpga.read(1)[0]
print("Status register SR1: 0x{:02x}".format(sr0))
