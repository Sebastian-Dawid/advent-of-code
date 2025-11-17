.section .data
msg:
	.ascii "All your codebase are belong to us.\n"

.section .text
.globl _start

_start:
        mov $msg, %rsi
        mov $36, %rdx
        mov $1, %rax
        mov $1, %rdi
	syscall

        mov $60, %rax
        mov $0, %rdi
        syscall
