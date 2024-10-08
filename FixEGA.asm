.model tiny
.code
org 100h

start:
    ; Save old INT 10h vector
    mov ax, 3510h
    int 21h
    mov word ptr [old_int10], bx
    mov word ptr [old_int10+2], es

    ; Install new INT 10h handler
    mov ax, 2510h
    mov dx, offset new_int10
    int 21h

    ; Terminate and stay resident
    mov dx, offset end_of_program
    int 27h

new_int10:
    ; Call the original INT 10h handler first
    mov [old_ax], ax
    pushf
    call dword ptr cs:[old_int10]
    pushf
    push ax
    push bx
    push cx
    push dx
    push ds
    push es

    mov ax, [old_ax]
    ; Check if it's a "set video mode" call (AH = 0)
    cmp ah, 0
    jne quick_exit_handler

    ; Check for supported video modes
    cmp al, 04h  ; 320x200 4-color CGA
    je set_palette
    cmp al, 05h  ; 320x200 4-color CGA
    je set_palette
    cmp al, 06h  ; 640x200 2-color CGA
    je set_palette
    cmp al, 0Dh  ; 320x200 16-color EGA
    je set_palette
    cmp al, 0Eh  ; 640x200 16-color EGA
    je set_palette
    ;cmp al, 10h  ; 640x350 16-color EGA (for testing)
    ;je set_palette
    jmp quick_exit_handler

quick_exit_handler:
exit_handler:
    pop es
    pop ds
    pop dx
    pop cx
    pop bx
    pop ax
    popf
    iret

set_palette:
    ; Set VGA palette for CGA/EGA compatibility
    mov dx, 3C8h  ; DAC Address Write Mode Register
    xor al, al
    out dx, al

    mov dx, 3C9h  ; DAC Data Register
    mov cx, 16    ; 16 colors to set

    xor si, si

palette_loop:
    test si, 40h  ; Test bit 6 of SI
    jnz exit_handler

    push si       ; Save SI

    test si, 10h  ; Test bit 3 of SI
    jz lower_half
    mov si, 24    ; Start at color 8 (8 * 3 = 24)
    jmp set_colors

lower_half:
    xor si, si    ; Start at color 0

set_colors:
    mov cx, 8     ; Set 8 colors

color_loop:
    ; Red component
    mov al, byte ptr cs:[palette_data + si]
    out dx, al
    inc si
    ; Green component
    mov al, byte ptr cs:[palette_data + si]
    out dx, al
    inc si
    ; Blue component
    mov al, byte ptr cs:[palette_data + si]
    out dx, al
    inc si
    loop color_loop

    pop si        ; Restore SI
    add si, 8     ; Move to next iteration
    jmp palette_loop

palette_data:
    ; CGA/EGA compatible palette (R, G, B values, 0-63 range)
    db 0, 0, 0    ; Black
    db 0, 0, 42   ; Blue
    db 0, 42, 0   ; Green
    db 0, 42, 42  ; Cyan
    db 42, 0, 0   ; Red
    db 42, 0, 42  ; Magenta
    db 42, 21, 0  ; Brown
    db 42, 42, 42 ; Light Gray
    db 21, 21, 21 ; Dark Gray
    db 21, 21, 63 ; Light Blue
    db 21, 63, 21 ; Light Green
    db 21, 63, 63 ; Light Cyan
    db 63, 21, 21 ; Light Red
    db 63, 21, 63 ; Light Magenta
    db 63, 63, 21 ; Yellow
    db 63, 63, 63 ; White

old_int10 dd ?
old_ax dw ?

end_of_program:

end start