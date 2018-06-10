CC=cc
ASMBIN=nasm
all: asm cc link clean
asm :
	$(ASMBIN) -f elf decode.asm
cc :
	$(CC) -m32 -std=c11 -c main.c
link :
	$(CC) -m32 -o test main.o decode.o
clean :
	rm *.o