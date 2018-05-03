BOARD=icestick
PINDEF=$(BOARD).pcf

ALL: bootloader.bin bootloader.rpt bootloader.asc

bootloader.blif: top.v
	yosys -p 'synth_ice40 -top top -blif $@' $<

%.asc: $(PINDEF) %.blif
	arachne-pnr -d 1k -o $@ -p $^

%.bin: %.asc	
	icepack $< $@

%.rpt: %.asc
	icetime -d hx1k -mtr $@ $^

prog: bootloader.bin
	iceprog $<

clean:
	rm -f bootloader.blif bootloader.asc bootloader.bin bootloader.rpt