OUTPUT_FORMAT("binary")
ENTRY(_kmain)
phys = 0x100000;
virt = 0xC0000000;
SECTIONS
{
    .boot3 virt : AT(virt) {
        boot3 = .;
        *(.text)
        . = ALIGN(4096);
    }
    .text :
    {
        code = .;
        *(.text)
    }
    .rodata :
    {
        rodata = .;
        *(.rodata)
        *(*.rodata)
    }
    .data :
    {
        data = .;
        *(.data)
        *(.data .data.* .got);
        . = ALIGN(4096);
    }
    .bss :
    {
        bss = .;
        *(.bss)
        . = ALIGN(4096);
    }
    end = .;
}
