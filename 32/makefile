CC=gcc
ASMBIN=nasm
all: asm cc link clean
asm:	$(ASMBIN) -f elf decode.asm
cc:		$(CC) -m32 -std=c11 -c main.c11
link:	$(CC) -m32 -o decode main.o decode.o
clean:	rm *.o