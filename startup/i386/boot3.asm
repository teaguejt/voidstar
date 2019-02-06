[bits 32]
[extern _kmain]

SECTION .boot3
_start:
    mov eax, 'J'
    mov eax, 0x90000
    mov esp, eax
    jmp _kmain
    mov eax, 'J'
