;;;===========================================================
;;; Definitions required to write to stdout
;;;===========================================================
%define SYS_READ    0
%define SYS_WRITE   1
%define SYS_OPEN    2
%define STDOUT      1

section .bss
hex_string:
    resb 19

;;;===========================================================
;;; Code section
;;;===========================================================
section .text
    global write_to_stdout  ; this procedure is exported and
                            ; can be called from outside this
                            ; file
    global print_as_hex

;;;===========================================================
;;; Procedure to write the `rdx` bytes at `rsi` to stdout
;;;===========================================================
write_to_stdout:
    push rax
    push rdi
    
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    syscall

    pop rdi
    pop rax
    ret

;;;===========================================================
;;; procedure that prints the contents of `rax` in hexadecimal
;;; the value in `rax` is lost
;;;===========================================================
print_as_hex:
    push rsi
    push rdx
    push r14
    push r15

    mov r14, 0          ;; counter
    mov r15, 0
    mov rsi, hex_string+17

pah_loop:               ;; loop over 8 byte (64 bit)
    cmp r14, 16
    je pah_done
    mov r15b, al        ;; get lowes byte of rax

    shl r15b, 4         ;; shift out high 4 bits
    shr r15b, 4         ;; shift low 4 bits back into place

    cmp r15b, 10
    jl number

    add r15b, byte 0x57
    jmp add_to_string

number:
    add r15b, byte 0x30
add_to_string:
    mov [rsi], r15b

    shr rax, 4          ;; shift out the lowest 4 bit
    inc r14
    dec rsi
    jmp pah_loop

pah_done:
    mov [hex_string+18], byte 0x0a
    mov [hex_string+1], byte 0x78
    mov [hex_string], byte 0x30

    mov rsi, hex_string
    mov rdx, 19
    call write_to_stdout

    pop r15
    pop r14
    pop rdx
    pop rsi
    ret
