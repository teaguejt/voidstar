; Begin second stage bootloader
[bits 16]
ORG 0x8000

mov [cursorx], bx
mov [cursory], cx
mov si, success
call print_str
call print_nl
mov si, getmm
call print_str
call get_smap
mov si, success
call print_str
call print_nl

; Reset segments and switch to protected mode
mov si, protsw
call print_str
xor eax, eax
mov eax, prot_switch
call prot_switch

; Get the E820 map. Has to happen BEFORE the protected mode switch
; Yes, it uses extended registers from real mode. This is... weird
get_smap:
    mov ax, 0x0
    mov es, ax
    mov ax, 0x2000
    mov edx, 0x534D4150 ; Magic number
    xor ebx, ebx
get_smap_loop:
    mov di, ax          ; set up address of buffer, for jOS  0x2000
    mov eax, 0xE820     ; Function call
    mov ecx, 0x18       ; Structure size
    int 0x15
    ; last entry can be signified by:
    ; ebx = 0 OR carry flag set. Test both.
    jc get_smap_out
    push ax
    mov ax, [smaps_entries]
    inc ax
    mov [smaps_entries], ax
    pop ax
    mov [smaps_esize], cl
    cmp ebx, 0x0
    jz get_smap_out
    xor eax, 0x534D4150
    jnz get_smap_err
    mov ax, di
    add ax, 0x18
    jmp get_smap_loop
get_smap_out:
    ; Fill in the size and entry number
    mov ax, [smaps_entries]
    mov bx, 0x2400
    mov [bx], ax
    mov ax, [smaps_esize]
    mov bx, 0x2410
    mov [bx], ax
    ret
get_smap_err:
    mov si, error
    call print_str
    hlt
    jmp $
    

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

[bits 16]
; Create a dummy GDT. Since we're using paging, we don't
; really need this for long.
gdt_start:
    dd 0x0
    dd 0x0

gdt_code:
    dw 0xffff
    dw 0x0
    db 0x0
    db 10011010b
    db 11001111b
    db 0x0

gdt_data:
    dw 0xffff
    dw 0x0
    db 0x0
    db 10010010b
    db 11001111b
    db 0x0


gdt_end:

gdt_desc:
    dw gdt_end - gdt_start - 1
    dq gdt_start

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start
gdtr dw 0x0
     dd 0x0

prot_switch:
    mov eax, 0x0
    mov ds, ax
    cli
    lgdt[gdt_desc]
    mov eax, cr0
    or eax, 0x01
    mov cr0, eax
    jmp CODE_SEG:prot_init

[bits 32]
; Oh wow, I get to write this twice, too. Thank you
; segmentation, followed by a lack thereof
; Whatever. I have a whole 1k here. That's almost
; I N F I N I T E S T O R A G E
print_str32:
    pusha
    xor edx, edx
    xor ecx, ecx
    mov dl, [cursory]
    mov cl, [cursorx]
    push cx
    imul dx, 0xA0
    imul cx, 0x02
    add dx, cx
    add edx, 0xb8000
    mov cl, 0x0
print_str32_loop:
    mov al, [ebx]
    mov ah, 0x07
    cmp al, 0
    je print_str32_done
    inc cl
    mov [edx], ax
    add ebx, 1
    add edx, 2
    jmp print_str32_loop
print_str32_done:
    pop ax
    add al, cl
    mov [cursorx], al
    popa
    ret

print_nl32:
    pusha
    xor ax, ax
    mov [cursorx], al
    mov al, [cursory]
    add al, 1
    mov [cursory], al
    popa
    ret
    

prot_init:
    mov ax, DATA_SEG
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ebp, 0x90000
    mov esp, ebp
    mov ebx, success
    call print_str32
; We can't exactly go back to the beginning here.
; Execute this linearly to finalize.
call print_nl32
mov ebx, findpgs
call print_str32

;Since we have a guaranteed 30k free starting at
; 0x500, we're just gonna plop our first two pages
; down at 0x3000 (so we clear the memory map).
; 0x3000 = kernel's PGD
; 0x4000 = identity mapped stuff
; 0x5000 = the actual kernel
mov eax, 0x3000
mov [kernel_pgd], eax
mov eax, 0x4000
mov [kernel_pgt_1mb], eax
mov eax, 0x5000
mov [kernel_pgt_kern], eax
mov eax, [kernel_pgd]
mov ebx, [kernel_pgt_1mb]
mov ecx, [kernel_pgt_kern]

; Start populating the page table. The first two pages
; are INVALID
; Create the PGD entry

; Store the first mb page table in the first pgd entry
mov eax, [kernel_pgt_1mb]
mov ebx, [kernel_pgd]
or eax, 0x1
or eax, 0x2
or eax, 0x4
or eax, 0x8
or eax, 0x20
mov [ebx], eax

; Store the kernel's pgt in the 768th (3GB) pgd entry
mov eax, [kernel_pgt_kern]
mov ebx, [kernel_pgd]
mov ecx, 0x300
imul ecx, 0x4
add ebx, ecx
or eax, 0x1
or eax, 0x2
or eax, 0x4
or eax, 0x8
or eax, 0x20
mov [ebx], eax


; Identity map the first megabyte (256 entries)
; This way video memory, BDA, and initial paging structures have 1:1
; physical:virtual mapping and we don't have to worry about anything
; getting "lost"
mov ebx, [kernel_pgt_1mb]
mov eax, 0x0000         ; The zero page
mov ecx, 0x0
ident_map_loop:
    or eax, 0x1             ; Page is present (duh)
    or eax, 0x2             ; Page is read/write
    or eax, 0x4             ; Page is supervisor-only
    or eax, 0x8             ; Use write-through caching for page tables
    ; or eax, 0x10          ; We want to cache these
    or eax, 0x20            ; Page has been accessed
    ; or eax, 0x40          ; 4k pages
    mov [ebx], eax
    add ebx, 0x4            ; Next entry in page table
    add eax, 0x1000         ; Next page phys. addr.
    add ecx, 0x1            ; Increment count
    cmp ecx, 0x100          ; Have we filled in 256 entries?
    jnz ident_map_loop
jmp setup_kernel_pages

; Perform a protected mode read-any-copy from the floppy drive
load_kernel_from_floppy:
    mov cx, 0
    mov dx, 0x3F4           ; Master status register for floppy controller
    in ax, dx 
    floppy_ready_loop:
        and ax, 0xC0
        cmp ax, 0x80
        je floppy_mode_good
        cmp cx, 3
        je floppy_failure
        call fdd_reset
        inc cx
    floppy_mode_good:
    mov ebx, floppygood
    call print_str32
    jmp $

; Map the kernel's starting address to 3GB. Higher half is best half
; In release mode, the kernel is only a few k, but in debug mode it's
; a bit bigger. Since we know we have 512k between 0x80000 and 1M,
; just go ahead and map it all (128 pages).
; Why is it called "higher half?" In 32-bit, it really should be
; "Highest quarter."
setup_kernel_pages:

mov eax, 0x100000
mov ebx, [kernel_pgt_kern]
mov ecx, 0x0
kern_map_loop:
    or eax, 0x1             ; Page is present (duh)
    or eax, 0x2             ; Page is read/write
    ; or eax, 0x04          ; Page is supervisor-only
    or eax, 0x8             ; Use write-through caching for page tables
    ; or eax, 0x10          ; We want to cache these
    or eax, 0x20            ; Page has been accessed
    ; or eax, 0x40          ; 4k pages
    mov [ebx], eax
    add ebx, 0x4            ; Next entry in page table
    add eax, 0x1000         ; Next page phys. addr.
    add ecx, 0x1            ; Increment count
    cmp ecx, 0x80           ; Have we filled in 6 entries?
    jnz kern_map_loop

KERN_BEGIN:
    ; Move kernel to phys. 0x100000
    mov esi, 0x8400
    mov edi, 0x100000
    mov ecx, 0x10000
    rep movsw
    ; Enable paging
    mov eax, [kernel_pgd]   ; Already 12-bit aligned :-)
    mov cr3, eax
    mov eax, cr0
    or eax, 0x80000001
    mov cr0, eax
    mov ebx, success
    call print_str32
    ; Jump to the kernel!
    jmp 0xC0000000

fdd_reset:
    pusha
    xor ax, ax
    mov dx, 0x3F2
    in ax, dx
    mov bx, ax
    mov ax, 4
    out dx, ax
    mov eax, 0
    fdd_reset_loop:
        add eax, 1
        cmp eax, 1000000000
        jne fdd_reset_loop
    mov ax, bx
    out dx, ax
    popa
    ret

floppy_failure:
    mov ebx, floppyerr
    call print_str32
    hlt
    

[bits 16]
error db "Failed", 0
success db "Bueno", 0
getmm db "Getting memory map... ", 0
protsw db "Switching to protected mode... ", 0
findpgs db "Enabling paging... ", 0
floppyerr db "Floppy disk error", 0
floppygood db "Floppy disk OK", 0

cursorx db 0x0
cursory db 0x0
smaps_entries dw 0x0
smaps_esize dw 0x0
kernel_pgd dd 0x0
kernel_pgt_1mb dd 0x0
kernel_pgt_kern dd 0x0

times 1024 - ($ - $$) db 0
