# Lighthouse deck bootloader

Bootloader for the [lighthouse deck](https://www.bitcraze.io/lighthouse-positioning-deck/).
Give access to the SPI flash from the deck two Serial port and I2C port.
The protocol is documented in the [Bitcraze wiki](https://wiki.bitcraze.io/doc:lighthouse:bootloader).


## Building and programming

To build the project you need the [Icestorm](http://www.clifford.at/icestorm/#install) toolchain. Icestorm, Yosys and Arachne-PNR needs to be installed and in the path.

If you want to flash the bootloader in the deck, you need to connect an FTDI addapter to the SPI flash of the deck the same way it is done in the Lattice iCEstick developement board.

When icestorm is installed, to build the bitstream and program the board:
```
make
make prog
```