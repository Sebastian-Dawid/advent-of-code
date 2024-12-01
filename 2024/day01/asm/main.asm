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
;;; Definitions for streams (STDIN, STDOUT)
;;;===========================================================
%define STDIN       0
%define STDOUT      1

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
    resb 144
filesize:
    resb 8
filebuffer:
    resb 8
sum:
    resb 8
left_min_index:
    resb 8
right_min_index:
    resb 8

;;;===========================================================
;;; Code section
;;;===========================================================
section .text
    global _start           ; definition of the entrypoint
    extern write_to_stdout  
    extern read_file  
    extern pow
    extern print_as_hex

parse:
    push rsi
    push rdi
    push rcx
    push rbp
    mov rbp, rsp
    sub rsp, 16

    mov qword [rbp-8], qword 0
    mov qword [rbp-16], qword 0

    dec rdi
    mov rcx, 0
parse.loop_first:
    cmp [rsi + rdi], byte 0x20
    je parse.loop_first.postamble

    mov rbx, 0
    mov bl, byte [rsi + rdi]
    sub rbx, 0x30                   ; get current digit

    push rsi
    push rdi
    mov rsi, 10
    mov rdi, rcx
    call pow
    mul rbx
    add qword [rbp-16], rax
    pop rdi
    pop rsi

    dec rdi
    inc rcx
    jmp parse.loop_first

parse.loop_first.postamble:
    dec rdi
    cmp [rsi + rdi], byte 0x20
    je parse.loop_first.postamble

    mov rcx, 0
parse.loop_second:
    mov rbx, 0
    mov bl, byte [rsi + rdi]
    sub rbx, 0x30                   ; get current digit

    push rsi
    push rdi
    mov rsi, 10
    mov rdi, rcx
    call pow
    mul rbx
    add qword [rbp-8], rax
    pop rdi
    pop rsi

    dec rdi
    inc rcx

    cmp rdi, 0
    jl parse.postamble
    jmp parse.loop_second

parse.postamble:
    mov rax, qword [rbp-8]
    mov rdx, qword [rbp-16]
    mov rsp, rbp
    pop rbp
    pop rcx
    pop rdi
    pop rsi
    ret

;;;=================================================
;;; Part one solution
;;;=================================================
part_1:
    push rbp
    mov rbp, rsp
    mov rsi, qword [filebuffer]
    mov r15, rsi
    mov rcx, qword [filesize]
    add r15, rcx
    mov r14, 0

    mov qword [sum], 0

part_1.loop:
    cmp rsi, r15
    jge part_1.postamble.1

    mov rdi, 0                      ; count line length
part_1.loop.line_length:
    cmp [rsi + rdi], byte 0x0a
    je part_1.loop.parse
    inc rdi
    jmp part_1.loop.line_length

part_1.loop.parse:
    ;; parse numbers
    call parse
    ;; push numbers onto the stack
    sub rsp, 16
    mov [rsp+16], rax
    mov [rsp+8], rdx
    add r14, 2

    add rsi, rdi
    inc rsi
    jmp part_1.loop

part_1.postamble.1:
    lea rsi, [rsp+8]
    mov rcx, 0

part_1.build_sum:
    mov r12, qword [rsi+(rcx*8)]            ; right min initial value
    mov r13, qword [rsi+(rcx*8)+8]          ; left min initial value

    mov qword [left_min_index], rcx
    mov qword [right_min_index], rcx

    mov rdx, rcx
    add rdx, 2
    cmp rdx, r14
    jge part_1.find_min.postamble
part_1.find_min:
    cmp r12, qword [rsi+(rdx*8)]
    jle part_1.find_min.no_new_right_min

    mov qword [right_min_index], rdx
    mov r12, qword [rsi+(rdx*8)]

part_1.find_min.no_new_right_min:
    cmp r13, qword [rsi+(rdx*8)+8]
    jle part_1.find_min.no_new_left_min

    mov qword [left_min_index], rdx
    mov r13, qword [rsi+(rdx*8)+8]

part_1.find_min.no_new_left_min:
    add rdx, 2
    cmp rdx, r14
    jl part_1.find_min

part_1.find_min.postamble:
    cmp r12, r13
    jl part_1.build_sum.left_greater_right
    mov r11, r12
    sub r11, r13
    jmp part_1.build_sum.postamble

part_1.build_sum.left_greater_right:
    mov r11, r13
    sub r11, r12

part_1.build_sum.postamble:
    add qword [sum], r11

    mov rbx, qword [left_min_index]
    mov r11, qword [rsi+(rbx*8)+8]
    mov r10, qword [rsi+(rcx*8)+8]
    mov qword [rsi+(rcx*8)+8], r11
    mov qword [rsi+(rbx*8)+8], r10

    mov rbx, qword [right_min_index]
    mov r11, qword [rsi+(rbx*8)]
    mov r10, qword [rsi+(rcx*8)]
    mov qword [rsi+(rcx*8)], r11
    mov qword [rsi+(rbx*8)], r10

    add rcx, 2
    cmp rcx, r14
    jl part_1.build_sum

part_1.postamble.2:
    mov rax, qword [sum]
    mov rsi, sum
    mov rsp, rbp
    pop rbp
    ret

;;;===========================================================
;;; Part 2 solution
;;;===========================================================
part_2:
    push rbp
    mov rbp, rsp
    mov rsi, qword [filebuffer]
    mov r15, rsi
    mov rcx, qword [filesize]
    add r15, rcx
    mov r14, 0

    mov qword [sum], 0

part_2.loop:
    cmp rsi, r15
    jge part_2.postamble.1

    mov rdi, 0                      ; count line length
part_2.loop.line_length:
    cmp [rsi + rdi], byte 0x0a
    je part_2.loop.parse
    inc rdi
    jmp part_2.loop.line_length

part_2.loop.parse:
    ;; parse numbers
    call parse
    ;; push numbers onto the stack
    sub rsp, 16
    mov [rsp+16], rax
    mov [rsp+8], rdx
    add r14, 2

    add rsi, rdi
    inc rsi
    jmp part_2.loop
part_2.postamble.1:
    lea rsi, [rsp+8]
    mov rcx, 0

part_2.find_sim:
    mov rax, qword [rsi+(rcx*8)+8]      ; load left value
    mov rbx, 0                          ; value count in right list

    mov rdx, 0
part_2.find_sim.loop:
    cmp rax, qword [rsi+(rdx*8)]
    jne part_2.find_sim.loop.not_equal
    inc rbx
part_2.find_sim.loop.not_equal:
    add rdx, 2
    cmp rdx, r14
    jl part_2.find_sim.loop

    mul rbx
    add qword [sum], rax
    add rcx, 2
    cmp rcx, r14
    jl part_2.find_sim

part_2.postamble.2:
    mov rax, qword [sum]
    mov rsi, sum
    mov rsp, rbp
    pop rbp
    ret

;;;===========================================================
;;; Entry Point
;;;===========================================================
_start:
    pop rbx                 ; argc
    pop rdi                 ; program name
    pop rdi                 ; input filepath

    mov rax, OPEN
    mov rsi, 0
    syscall                 ; open input file
                            ; fd is written to rax

    mov rdi, rax
    mov rax, FSTAT
    mov rsi, statbuf
    syscall                 ; use fstat to get the filesize

    push rdi                ; save file descriptor

    mov rax, MMAP
    mov rsi, qword [statbuf+0x30]   ; filesize
    mov [filesize], rsi             ; copy filesize to memory
    mov rdx, 0x01                   ; PROT_READ
    mov r10, 0x01                   ; MAP_SHARED
    mov r8, rdi                     ; fd
    mov rdi, 0
    mov r9, 0
    syscall                         ; map the input file into program memory

    pop rdi                 ; restore file descriptor

    mov [filebuffer], rax   ; save address of mapped file

    mov rax, CLOSE
    syscall                 ; close file descriptor

    call part_1
    call print_as_hex

    call part_2
    call print_as_hex

    mov rax, SYS_EXIT
    mov rdi, 0
    syscall
