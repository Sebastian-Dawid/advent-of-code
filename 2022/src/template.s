.section .data
msg:
	.ascii "All your codebase are belong to us.\n"

.equ	SYS_READ,	0
.equ	SYS_WRITE,	1
.equ	SYS_OPEN,	2
.equ	SYS_CLOSE,	3
.equ	SYS_FSTAT,	5
.equ	SYS_MMAP,	9
.equ	SYS_EXIT,	60

.equ	STDOUT,	1

.section .text

.globl _start
.extern alloc
.extern printNumber
.extern parseNumber

_start:
        mov $msg, %rsi
        mov $36, %rdx
        mov $1, %rax
        mov $1, %rdi
	syscall

	mov $60, %rax
	mov $0, %rdi
	syscall
