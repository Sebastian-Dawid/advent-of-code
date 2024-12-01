;;;===========================================================
;;; Definitions required to write to stdout
;;;===========================================================
%define SYS_READ    0
%define SYS_WRITE   1
%define SYS_OPEN    2

%define STDIN       0
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
    global read_file
    global read_stdin
    global pow
    global print_as_hex

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

;;;===========================================================
;;; Performs rsi^rdi and stores the result in rdx:rax
;;;===========================================================
pow:
    cmp rdi, 0
    je pow.zero
    push rcx
    mov rcx, 1
    mov rax, rsi
pow.loop:
    cmp rcx, rdi
    jge pow.postamble
    mul rsi
    inc rcx
    jmp pow.loop
pow.postamble:
    pop rcx
    ret
pow.zero:
    mov rax, 1
    mov rdx, 0
    ret

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
;;; Procedure to read `rdx` bytes from STDIN into the buffer
;;; at `rsi`. The number of bytes read will be written to `rdx`.
;;;===========================================================
read_stdin:
    push rax
    push rdi

    mov rax, SYS_READ
    mov rdi, STDIN
    syscall

    mov rdx, rax

    pop rdi
    pop rax
    ret

;;;===========================================================
;;; Procedure to open and read `rax` bytes of a file `rsi`
;;; into a given buffer `rdi`
;;;===========================================================
read_file:
    push rax
    push rdx
    push rdi
    push rsi
    
    mov r8, rax         ;; save the number of bytes to read
    mov r9, rdi         ;; save address of the buffer

    mov rax, SYS_OPEN   ;; open syscall
    mov rdi, rsi        ;; filepath
    mov rsi, 0          ;; O_READONLY
    syscall

    mov rdi, rax        ;; file descriptor
    mov rax, SYS_READ   ;; read syscall
    mov rsi, r9         ;; address of buffer
    mov rdx, r8         ;; size of buffer
    syscall

    pop rsi
    pop rdi
    pop rdx
    pop rax
    ret
