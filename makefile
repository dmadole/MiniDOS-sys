
all: sys.bin

lbr: sys.lbr

clean:
	rm -f sys.lst
	rm -f sys.bin
	rm -f sys.lbr

sys.bin: sys.asm boot.asm include/bios.inc include/kernel.inc
	asm02 -L -b sys.asm
	rm -f sys.build

sys.lbr: sys.bin
	rm -f sys.lbr
	lbradd sys.lbr sys.bin

