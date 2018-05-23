#!/usr/bin/env python3
import sys
import serial
import struct

OFFSET = 0x020000

def protocol_reset():
    fpga.flushOutput()
    fpga.send_break()
    fpga.flushInput()

def boot():
    fpga.write(b"\0")

def spi_xfer(command, answer_size = 0):
    if type(command) is int:
        command = bytes([command])
    if type(command) is list:
        command = bytes(command)

    cmd = struct.pack("<BHH", 0x01, len(command), answer_size)
    cmd += command
    fpga.write(cmd)
    return fpga.read(answer_size)

def flash_read(address, length):
    address_bin = struct.pack(">L", address)[-3:]
    command = b"\x03" + address_bin
    return spi_xfer(command, length)

def flash_erase_sector(address):
    # Write enable
    spi_xfer(0x06)

    address_bin = struct.pack(">L", address)[-3:]
    command = b"\xD8" + address_bin
    return spi_xfer(command)

def flash_program_page(address, data):
    assert(len(data) <= 256)
    # Write enable
    spi_xfer(0x06)

    address_bin = struct.pack(">L", address)[-3:]
    command = b"\x02" + address_bin + data
    return spi_xfer(command)

def flash_read_status():
    return spi_xfer(0x05, 1)[0]

def flash_wait_program_complete():
    while flash_read_status() & 0x01 != 0:
        pass

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Usage: {} <serial_port> <baudrate> <bitstream.bin>".format(sys.argv[0]))
        sys.exit(1)
    
    fpga = serial.Serial(sys.argv[1], int(sys.argv[2]))

    with open(sys.argv[3], 'rb') as f:
        bitstream = f.read()
    
    protocol_reset()

    # Waking up memory
    spi_xfer(0xAB)

    # Read ID
    chip_id = spi_xfer(0x9F, 20)

    print("flash ID: ", end='')
    for b in chip_id:
        print("0x{:02X}".format(b), end=' ')
    print()

    print("Comparing first and last 256 bytes ...")
    beginning = flash_read(OFFSET + 0, 256)
    end = flash_read(OFFSET + len(bitstream)-256, 256)
    if beginning == bitstream[:256] and end == bitstream[-256:]:
        print("Identical! Booting ...")
        boot()
    else:
        print("Different bitstream, flashing the new one ...")

        print("Erasing 64K at 0x{:08X}".format(OFFSET))
        flash_erase_sector(OFFSET)
        flash_wait_program_complete()
        
        print("Programming ...")
        toprogram = bitstream
        currentPage = 0
        while len(toprogram) > 0:
            flash_program_page(OFFSET + (currentPage * 256), toprogram[:256])
            flash_wait_program_complete()
            toprogram = toprogram[256:]
            currentPage += 1

        print("Verifying ...")
        verify = flash_read(OFFSET, len(bitstream))
        if bitstream != verify:
            print("Verification failed! Erasing bitstream")
            flash_erase_sector(OFFSET)
            flash_wait_program_complete()
            sys.exit(1)

        print("Booting!")
        boot()

        
