---
title: Bootloader protocol
page_id: bootloader_protocol
---

# Lighthouse deck bootloader

The [lighthouse deck](https://store.bitcraze.io/products/lighthouse-positioning-deck) is based on an [iCE40UP5K](https://www.latticesemi.com/Products/FPGAandCPLD/iCE40UltraPlus) FPGA. The FPGA boots from an SPI flash to the bootloader, it is then able to boot to another configuration image. The bootloader gives access to the SPI memory and to a boot command to boot the user image. This allows the deck to be updated easily from the Crazyflie or from the auxiliary serial port.

The bootloader protocol is inspired by the [TinyFpga USB bootloader](https://github.com/tinyfpga/TinyFPGA-Bootloader) but implemented on serial port and I2C bus. It gives a raw access to the SPI bus, this means that memory operation should be done using SPI commands following the [SPI memory documentation](https://www.winbond.com/resource-files/w25q80dv_revf_02112015.pdf).

## Interface protocols

### Uart protocol

There is two UARTs on the deck, UART0 on the Crazyflie deck interface and UART1 on 2.54mm soldering pads available for external communication. The bootloader is available on both UARTs. The UARTs are setup with a baudrate of 113200, one stop bit, no parity.

**Warning**: Version 1 of the bootloader has a bug that makes its baudrate be ~113200 instead of 115200 baud. This is a non-standard baudrate, it has been tested that using an FTDI USB-to-UART adapter setting a baudrate of 113200 works fine.

When using the UART, commands are sent on the RX line and answer will be sent back by the bootloader on the TX line. Since the bootloader and the Flash SPI bus are working much faster than the UART, there is no need for flow control.

To make sure the bootloader is waiting for a command, a break condition can be sent to the UART to reset the bootloader state. This is good to do before sending the first command in order to make sure the bootloader is not currently in the middle of a command.

Both UARTs are disabled at startup, this means that the bootloader will ignore all data and break condition coming from them. To enable an UART send the byte "0xBC". This will enable the UART and reset the bootloader state.

Since 0xBC is not an implemented command, the suggested sequence in order to start the communication is sending "Break condition" and then "0xBC". This will ensure the UART is enabled and the bootloader is ready to receive the next command.

**Note**: There is a priority between the different interfaces. The priority is UART0, UART1, I2C. This means that I2C is  enabled at startup and that if UART0 is enabled, UART1 is ignored.

### I2C protocol

The I2C 7 bit address is 0x2F. Sending command and receiving to answer from the bootloader is done with I2C read and write transaction.

Starting a write transaction will reset the bootloader state and send all the bytes written to the bootloader. The bootloader will then execute the command and write the answer to a memory buffer. Starting a read transaction will read from this memory buffer.

For example, after sending a command that will produce a 5 bytes answer, one should start a read transaction and read the 5 answer bytes.

The buffer is of 15KiB. If a command is executed that returns more than 15KiB bytes, the first bytes of the buffer will be overwritten.

## Bootloader protocol

All numbers are encoded in little endian. 

### Boot

The boot command will boot the firmware. It takes no arguments. The command instructs the bootloader to boot the firmware image, the FPGA will resets and boot on the firmware image from the flash.

Sent to the bootloader:

|  Byte #  |  Value  | Note |
| -------- | ------- | ---- |
|   0    |  0x00  | Boot command |

### SPI Exchange

The SPI exchange command execute one SPI transaction. On the SPI bus it asserts the CS pin, sends WLEN bytes and then receives RLEN bytes.

Sent to the bootloader:

|  Byte #  |  Value  | Note |
| -------- | ------- | ---- |
|  0       | 0x01   | SPI Exchange command |
|  1-2     | WLEN   | Write length |
|  3-4     | RLEN   | Read length |
|  5-(WLEN-4)  | Write data  | Data to write to the SPI device |

Received from the bootloader:

|  Byte #  |  Value  | Note |
| -------- | ------- | ---- |
|  0-(RLEN-1)  | Read data | Data read from the SPI device |

### Get version

Returns the bootloader version. Can be useful to identify that the firmware currently running is the bootloader.
currently only version 1 exists

Sent to the bootloader:

|  Byte #  |  Value  | Note |
| -------- | ------- | ---- |
|  0       | 0x02   | Get version command |

Received from the bootloader:

|  Byte #  |  Value  | Note |
| -------- | ------- | ---- |
|  0  | 0x01 | Bootloader version |

## Flash layout

The flash is layered as follow:

```text
 +-------------+ 
 |             |
 |             |
 |             |
 |             |
 | Free        |
 +-------------+  0x040000
 |             |
 |             |
 | Firmware    |
 +-------------+  0x020000
 |             |            \
 |             |            |
 | Bootloader  |            | Write protected
 +-------------+  0x0000a0  |
 | MBR         |            |
 +-------------+  0x000000  /
```

The write protection is implemented by setting the SR1 register in the SPI flash. This means that it can be disabled by clearing the SR1 register if updating the bootloader is required.

## Firmware versioning

The firmware is an iCE40 bitstream (The bitstream format has been [documented by the icestorm project](http://www.clifford.at/icestorm/format.html)). The bitstream start with the bytes 0xff 0x00 followed by a null terminated string and then 0x00 0xff. This null terminated string is a comment. In the Lighthouse deck this comment is used to store the version of the firmware as a version string. The intention is that the deck user (ie. the Crazyflie or other external board) must be able to find-out if the firmware is compatible or if it needs to be upgraded or downgraded.

The version string format is a base 10 integer number in ascii indicating the version. For example "1". It follows the rules of the C function strtol() to be decoded so the string can start with white-space, followed by an optional "+" or "-" followed by decimal digits. The decoding stops at the first non-digit character.

In the context of the lighthouse firmware, versions >= 1 are released version and should be in parity (or handled) by the client connecting the board in order to boot the firmware. Versions <= 0 are development version and the intention is that the client will then boot it without further check.

This format is simple enough for current needs and allows to add other fields later by separating it from the version with any non-decimal character.
