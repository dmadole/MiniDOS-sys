
sys.bin: sys.asm
	asm02 -L -b sys.asm
	rm -f sys.build

clean:
	rm -f sys.lst
	rm -f sys.bin

