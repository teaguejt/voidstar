ORG 0x7C00

; Setup segments
mov ax, cs
mov ds, ax
mov es, ax
mov ss, ax

; Since we're using "call" here, we need to have a (small) stack
mov sp, 0x7000

; Do it all. Clear the screen, print some stuff, load the rest of jOS from
; disk, switch to protected mode, relocate the kernel to 1 MiB, and jump to
; its first instruction. Not bad considering we're limited to 512 bytes ;-)
call clear_scr
mov si, welcome
call print_str
call print_nl
mov si, loading
call print_str
call load_jos
mov si, preswitch
call print_str
mov bx, [cursorx]
mov cx, [cursory]
jmp 0x8000
mov si, error
call print_str

hang:
    jmp hang

load_jos:
    mov cx, 3
load_loop:
    xor ah, ah
    int 0x13
    mov bx, 0x0
    mov es, bx
    mov bx, 0x8000
    mov dx, 0
    mov ch, 0
    mov cl, 2
    mov al, 0x4
    mov ah, 0x02
    int 0x13
    jnc load_exit
    sub cx, 1
    cmp cx, 0
    jz load_err
load_err:
    mov si, error
    call print_str
    jmp hang
load_exit:
    mov si, success
    call print_str
    call print_nl
    ret

print_str:
    mov bx, 0xB800
    mov es, bx
    xor bx, bx
    xor ax, ax
    mov bl, [cursory]
    mov al, [cursorx]
    mov cl, al
    imul bx, 0xA0
    imul ax, 0x02
    add bx, ax
    mov ah, 0x07
print_str_loop:
    lodsb
    cmp al,0
    jz print_str_out
    mov [es:bx], ax
    add bx, 0x02
    inc cl
    jmp print_str_loop
print_str_out:
    mov [cursorx], cl
    ret

print_nl:
    xor ax, ax
    mov [cursorx], al
    mov al, [cursory]
    add al, 1
    mov [cursory], al
    ret

clear_scr:
    mov bx, 0xB800
    mov es, bx
    mov al, 0x0
    mov cl, 0x07
clear_scr_loop:
    cmp bx, 0xFA0
    jz clear_scr_out
    mov [es:bx], al
    add bx, 0x01
    mov [es:bx], cl
    add bx, 0x01
    jmp clear_scr_loop
clear_scr_out:
    ret

error db " Failed", 0
success db " Bueno", 0
welcome db "jOS v0.1 alpha s1 BL", 0
loading db "Loading BL2/kernel from disk... ", 0
preswitch db "Jumping to S2 Bootloader... ", 0
postswitch db "Success.", 0
attempt db 0x3
cursorx db 0x0
cursory db 0x0

times 510-($-$$) db 0
dw 0xaa55
