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
%define SYS_READ    0
%define SYS_WRITE   1
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
hello_world:
    db "Hello World!", 0x0a ; 13 byte memory block containing
                            ; "Hello World!\n"
path:
    db "/etc/hosts", 0

bufsize:
    dq 0x10

;;;===========================================================
;;; Non-initialized data
;;;===========================================================
section .bss
arr:
    resb 4                  ; 4 byte memory block

buffer:
    resb 16

;;;===========================================================
;;; Code section
;;;===========================================================
section .text
    global _start           ; definition of the entrypoint
    extern write_to_stdout  ; this procedure is imported from
                            ; src/print.asm
    extern read_file        ; this procedure is imported from
                            ; src/read_file.asm

;;;===========================================================
;;; Entry Point
;;;===========================================================
_start:
    mov [arr], byte 0x48        ; Byte `H`
    mov [arr + 1], byte 0x69    ; Byte `i`
    mov [arr + 2], byte 0x21    ; Byte `!`
    mov [arr + 3], byte 0x0a    ; Byte `\n`

    mov rsi, arr                ; Address of our non-initialized
                                ; memory block of 4 bytes
    mov rdx, 0x4
    call write_to_stdout

    mov rsi, hello_world        ; Address of out pre-initialized
                                ; memory containing the
                                ; "Hello World!\n" string
    mov rdx, 0xd
    call write_to_stdout

    mov rax, [bufsize]
    mov rsi, path
    mov rdi, buffer
    call read_file

    mov rsi, buffer
    mov rdx, [bufsize]
    call write_to_stdout

    mov rax, SYS_EXIT
    mov rdi, 0
    syscall
