CC=cc
ASMBIN=nasm
all : asm cc link clean
asm :
	$(ASMBIN) -g -f elf decode.asm
cc :
	$(CC) -g -m32 -std=c11 -c main.c
link :
	$(CC) -g -m32 -o test main.o decode.o
clean :
	rm *.o