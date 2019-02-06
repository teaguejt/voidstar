BL_SOURCE   = startup/i386
C_SOURCE    = $(wildcard kernel/*.c screen/*.c io/*.c string/*.c i386/*.c mm/*.c)
ASSEMBLY    = $(wildcard i386/*.asm)
HEADERS     = $(wildcard kernel/*.h screen/*.h io/*.h)
INCLUDE     = $(shell pwd)/include/
OBJ         = ${C_SOURCE:.c=.o}
ASM_ELF     = ${ASSEMBLY:.asm=.elf}
ASM_OBJ     = ${ASSEMBLY:.asm=.o}

CC  = i686-elf-gcc
LD  = i686-elf-gcc
GDB = i386-elf-gdb

OSLDIR=target/i686-custom/release
OSLDIRDBG=target/i686-custom/debug
KBIN=kernel.bin
CFLAGS=-march=i686 -O0 -g -nostartfiles -nostdinc -nostdlib -ffreestanding -Tlink.ld\
       -L${OSLDIR} -L. -fno-builtin -fno-stack-protector -Wall -Wextra -Wl,--gc-sections\
       -L/usr/local/i686elfgcc/lib/gcc/i686-elf/6.2.0 -mno-red-zone -Wl,-gc-sections
XARGOFLAGS= --target i686-custom --release \
		   -- -C relocation-model=static --crate-type=staticlib

all: run_i386

kernel.bin: boot3.o xargokern
	${CC} ${CFLAGS} $< -o ${KBIN}  -lgcc -ljos

boot3.o: ${BL_SOURCE}/boot3.asm
	nasm $< -f elf -o $@

boot2.bin: ${BL_SOURCE}/boot2.asm
	nasm $< -f bin -o $@

boot1.bin: ${BL_SOURCE}/boot1.asm
	nasm $< -f bin -o $@

xargokern:
	xargo build --release --target=i686-custom --features "x86 has_screen text_mode"
	#rustc ${XARGOFLAGS}

jos.bin: boot1.bin boot2.bin kernel.bin
	cat $^ > jos.bin

runbl: boot1.bin boot2.bin
	cat $^ > jos.bin
	qemu-system-x86_64 -fda jos.bin -monitor stdio

run_i386: jos.bin
	qemu-system-x86_64 -fda jos.bin -monitor stdio

debug: jos.bin
	qemu-system-i386 -s -fda jos.bin &
	i386-elf-gdb -ex "target remote localhost:1234" -ex "symbol-file kernel.elf"

kernel.elf: boot3.o ${OBJ} ${ASM_ELF}
	i386-elf-ld -o $@  $^ -Ttext 0x100000

clean:
	rm -rf *.bin *.elf *.o ${OBJ} ${ASM_ELF}
	xargo clean
