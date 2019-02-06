global __asm_getreg

__asm_getreg:
    push ebp
    mov ebp, esp
    push esi
    mov esi, [ebp + 8]
    mov [esi], eax
    mov [esi + 4], ebx
    mov [esi + 8], ecx,
    mov [esi + 12], edx
    mov [esi + 16], esp
    pop esi
    pop ebp
    ret
