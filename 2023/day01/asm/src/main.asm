;;;============================================================
;;; x86_64 linux assembly template
;;;
;;; Author: Sebastian Dawid (sdawid@techfak.uni-bielefeld.de)
;;;         github.com/Sebastian-Dawid
;;;
;;; Git:    git@github.com:Sebastian-Dawid/asm-template.git
;;;         https://github.com/Sebastian-Dawid/asm-template.git
;;;============================================================

;;;============================================================
;;; Definitions for syscalls (EXIT, WRITE, READ)
;;;============================================================
%define OPEN         2
%define CLOSE        3
%define FSTAT        5
%define MMAP         9
%define SYS_EXIT    60

;;;===========================================================
;;; Pre-initialized data
;;;===========================================================
section .data
part_1_format:
    db "Part 1: "

part_2_format:
    db "Part 2: "

;;;===========================================================
;;; Non-initialized data
;;;===========================================================
section .bss
statbuf:
    resb 256

filesize:
    resb 8

filebuf:
    resb 8

numbers:
    resb 2      ;; 2 bytes to store the first and last char of the current line

sum:
    resb 8      ;; 64 bit value to store the sum of all values

;;;===========================================================
;;; Code section
;;;===========================================================
section .text
    global _start           ; definition of the entrypoint
    extern write_to_stdout
    extern print_as_hex

;;;===========================================================
;;; Procedure to solve part 1 of the problem.
;;;===========================================================
part_1:
    mov rsi, [filebuf]       ;; copy address of file in memory to rsi
    mov r15, rsi
    add r15, [filesize] ;; calculate final address of size
    mov r14, 0          ;; flag to mark the first value as found

part_1_loop: ;; loop over all lines in file
    cmp rsi, r15
    jge part_1_loop_done
    
    cmp [rsi], byte 0x0a ;; if we have found a newline update sum and reset r14
    jne part_1_loop_not_newline

    mov rax, 0
    mov r12, 10
    mov r13, 0
    mov al, [numbers]
    mov r13b, [numbers+1]
    sub al, 0x30
    sub r13b, 0x30
    mul r12

    add [sum], rax
    add [sum], r13
    
    mov r14, 0
    jmp part_1_loop_inc

part_1_loop_not_newline:
    cmp [rsi], byte 0x30    ;; cahr '0'
    jl part_1_loop_inc

    cmp [rsi], byte 0x39    ;; char '9'
    jg part_1_loop_inc

    mov r13b, byte [rsi]    ;; copy the current char into a register
    cmp r14, 0x01           ;; have we already found a number in this line?
    je part_1_loop_not_first_digit
    
    mov [numbers], r13b
    mov r14, 1              ;; first digit found

part_1_loop_not_first_digit:
    mov [numbers+1], r13b

part_1_loop_inc:
    inc rsi
    jmp part_1_loop

part_1_loop_done:
    mov rsi, part_1_format
    mov rdx, 8
    call write_to_stdout
    
    mov rax, [sum]
    call print_as_hex
    ret

;;;===========================================================
;;; Procedure to check the contents of `rax` for a written digit
;;; The ascii value of the digit is returned in `rbx`.
;;; If no value was found `rbx` will be 0
;;;===========================================================
check_for_written_digit:
    push rdx
    mov rdx, 0
    mov rbx, 0x31

    ;;; check 3 letter words
    push rax
    and rax, 0xffffff

    mov rdx, "one"
    cmp rax, rdx
    je digit_return

    mov rbx, 0x32
    mov rdx, "two"
    cmp rax, rdx
    je digit_return
    
    mov rbx, 0x36
    mov rdx, "six"
    cmp rax, rdx
    je digit_return

    pop rax
    
    ;; check 4 letter words
    push rax
    shl rax, 32
    shr rax, 32
    
    mov rbx, 0x34
    mov rdx, "four"
    cmp rax, rdx
    je digit_return

    mov rbx, 0x35
    mov rdx, "five"
    cmp rax, rdx
    je digit_return
    
    mov rbx, 0x39
    mov rdx, "nine"
    cmp rax, rdx
    je digit_return
    
    pop rax
    
    ;; check 5 letter words
    push rax
    shl rax, 24
    shr rax, 24
    
    mov rbx, 0x33
    mov rdx, "three"
    cmp rax, rdx
    je digit_return

    mov rbx, 0x37
    mov rdx, "seven"
    cmp rax, rdx
    je digit_return
    
    mov rbx, 0x38
    mov rdx, "eight"
    cmp rax, rdx
    je digit_return

    mov rbx, 0

digit_return:
    pop rax
    pop rdx
    ret

;;;===========================================================
;;; Procedure to solve part 2 of the problem.
;;;===========================================================
part_2:
    mov rsi, [filebuf]      ;; copy address of file in memory to rsi
    mov r15, rsi
    add r15, [filesize]     ;; calculate final address of size
    mov r14, 0              ;; flag to mark the first value as found
    mov [sum], r14

part_2_loop:                ;; loop over all lines in file
    cmp rsi, r15
    jge part_2_loop_done
    
    cmp [rsi], byte 0x0a    ;; if we have found a newline update sum and reset r14
    jne part_2_loop_not_newline

    mov rax, 0
    mov r12, 10
    mov r13, 0
    mov al, [numbers]
    mov r13b, [numbers+1]
    sub al, 0x30
    sub r13b, 0x30
    mul r12

    add [sum], rax
    add [sum], r13
    
    mov r14, 0
    jmp part_2_loop_inc

part_2_loop_not_newline:
    cmp [rsi], byte 0x30    ;; cahr '0'
    jl part_2_loop_check_for_written_digit

    cmp [rsi], byte 0x39    ;; char '9'
    jg part_2_loop_check_for_written_digit

    mov r13b, byte [rsi]    ;; copy the current char into a register
    jmp part_2_loop_found_digit

part_2_loop_check_for_written_digit:
    mov rax, [rsi]
    call check_for_written_digit
    cmp rbx, 0
    je part_2_loop_inc      ;; we did not find a digit

    mov r13b, bl

part_2_loop_found_digit:
    cmp r14, 0x01           ;; have we already found a number in this line?
    je part_2_loop_not_first_digit

    mov [numbers], r13b
    mov r14, 1              ;; first digit found

part_2_loop_not_first_digit:
    mov [numbers+1], r13b

part_2_loop_inc:
    inc rsi
    jmp part_2_loop

part_2_loop_done:
    mov rsi, part_2_format
    mov rdx, 8
    call write_to_stdout

    mov rax, [sum]
    call print_as_hex
    ret

;;;===========================================================
;;; Entry Point
;;;===========================================================
_start:
    pop rbx
    pop rdi ;; throw away prog name
    pop rdi ;; get filename

    mov rax, OPEN
    mov rsi, 0
    syscall

    mov rdi, rax
    mov rax, FSTAT
    mov rsi, statbuf
    syscall

    push rdi                        ;; save fd

    mov rax, MMAP                   ;; mmap(addr, len, prot, flags, fd, off) syscall
    mov rsi, qword [statbuf+0x30]   ;; len
    mov [filesize], rsi             ;; copy filesize to memory for later
    mov rdx, 0x01                   ;; prot (PROT_READ)
    mov r10, 0x01                   ;; flags (MAP_SHARED)
    mov r8, rdi                     ;; fd
    mov rdi, 0                      ;; addr
    mov r9, 0                       ;; off
    syscall

    pop rdi                         ;; restore fd

    mov [filebuf], rax              ;; save address of mapped file

    mov rax, CLOSE
    syscall                         ;; close fd

    call part_1                     ;; solve part 1

    call part_2                     ;; solve part 2

    mov rax, SYS_EXIT
    mov rdi, 0
    syscall
