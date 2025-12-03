.section .data

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
	# Pop argc, progname and first command-line input
	popq	%rdi
	popq	%rdi
	popq	%rdi

	movq	$SYS_OPEN,	%rax
	movq	$0,	%rsi
	syscall

	# Allocate buffer for fstat output
	subq	$144,	%rsp
	movq	%rax,	%rdi
	movq	$SYS_FSTAT,	%rax
	movq	%rsp,	%rsi
	syscall

	# Map file to program memory
	movq	$SYS_MMAP,	%rax
	movq	0x30(%rsp),	%rsi
	movq	$1,	%rdx
	movq	$1,	%r10
	movq	%rdi,	%r8
	movq	$0,	%rdi
	movq	$0,	%r9
	syscall

	# Set up base pointer to stack
	pushq	%rbp
	movq	%rsp,	%rbp

	# &filesize = %rbp+0x38
	# &file = %rbp-8
	pushq	%rax

	movq	$SYS_CLOSE,	%rax
	movq	%r8,	%rdi
	syscall

	# &i = %rbp-16
	pushq	$1

	# &total = %rbp-24
	pushq	$0
	# &max1 = %rbp-32
	pushq	$0
	# &max2 = %rbp-40
	pushq	$0

	# do {
loop:
	# max1 = max2 = 0
	movq	$0,	-32(%rbp)
	movq	$0,	-40(%rbp)
	movq	-16(%rbp),	%rcx
	# while(str[i] != '\n') {
loop.inner:
	movq	-8(%rbp),	%rsi
	movzbq	(%rsi, %rcx),	%rax
	movzbq	-1(%rsi, %rcx),	%rbx

	cmpq	$0xA,	%rax
	je	loop.inner.after

	# if (max1 < str[i-1]) {
	cmpq	%rbx,	-32(%rbp)
	jge	loop.inner.noMax1
	# max1 = str[i-1];
	movq	%rbx,	-32(%rbp)
	# max2 = str[i];
	movq	%rax,	-40(%rbp)
	# }
loop.inner.noMax1:
	# if (max2 < str[i]) {
	cmpq	%rax,	-40(%rbp)
	jge	loop.inner.postamble
	# max2 = str[i];
	movq	%rax,	-40(%rbp)
	# }

loop.inner.postamble:
	# i++
	incq	%rcx
	jmp	loop.inner
	# }

loop.inner.after:
	movq	%rcx,	-16(%rbp)

	# total += 10 * (max1 - 0x30) + (max2 - 0x30)
	movq	-32(%rbp),	%rax
	subq	$0x30,	%rax
	movq	$10,	%rcx
	mulq	%rcx
	addq	-40(%rbp),	%rax
	subq	$0x30,	%rax
	addq	%rax,	-24(%rbp)

	# i+=2
	addq	$2,	-16(%rbp)
	# } while(i < filesize);
	movq	0x38(%rbp),	%rcx
	cmpq	%rcx,	-16(%rbp)
	jl	loop
	
	movq	-24(%rbp),	%rdi
	call	printNumber

	mov $60, %rax
	mov $0, %rdi
	syscall
