BOARD=lighthouse4_revd
PIN_DEF=$(BOARD).pcf
DEVICE=up5k

all: bootloader_multi.bin bootloader.bin bootloader.rpt bootloader.asc

%.blif: %.v
	yosys -p 'synth_ice40 -top top -blif $@' $<

%.asc: %.blif
	arachne-pnr -d $(subst up,,$(subst hx,,$(subst lp,,$(DEVICE)))) -o $@ -p $(PIN_DEF) $^

%.bin: %.asc
	icepack -s $< $@

%_multi.bin: %.bin
	cp $^ $^.0
	cp $^ $^.1
	icemulti -vv -a 17 -o $@ $^.0 $^.1

%.rpt: %.asc
	icetime -d $(DEVICE) -mtr $@ $<

%_tb: %_tb.v %.v
	iverilog -o $@ $^ `yosys-config --datdir/ice40/cells_sim.v`

%_tb.vcd: %_tb
	vvp $< +vcd=$@

%_syn.v: %.blif
	yosys -p 'read_blif -wideports $^; write_verilog $@'

%_syntb: %_tb.v %_syn.v
	iverilog -o $@ $^ `yosys-config --datdir/ice40/cells_sim.v`

%_syntb.vcd: %_syntb
	vvp -N $< +vcd=$@

prog: bootloader_multi.bin
	iceprog $<

clean:
	rm -f bootloader.blif bootloader.asc bootloader.bin bootloader.rpt bootloader_multi.bin