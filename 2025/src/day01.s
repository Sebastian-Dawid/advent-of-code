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
.extern modulo

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

	# Save pointer to file contents on the stack
	pushq	%rax

	movq	$SYS_CLOSE,	%rax
	movq	%r8,	%rdi
	syscall

	# str
	popq	%rbx
	# Current dial value (%rsp+24)
	pushq	$50
	# Number of zeros (%rsp+16)
	pushq	$0
	# Number of read characters (%rsp+8)
	pushq	$0
	# Index (%rsp)
	pushq	$0

	# do {
findPassword.loop:
	movq	(%rsp),	%rcx
	movb	(%rbx,	%rcx),	%r12b
	# i++
	incq	(%rsp)

	# N = parseNumber(str + i, '\n', &count)
	movq	%rbx,	%rdi
	addq	(%rsp),	%rdi
	movq	$0xA,	%rsi
	leaq	8(%rsp),	%rdx
	call	parseNumber

	# if (str[i] == 'L') N *= -1
	cmpb	$76,	%r12b
	jne	findPassword.positive
	movq	$-1,	%rcx
	mulq	%rcx
findPassword.positive:
	# number = dial + N
	movq	24(%rsp),	%rdi
	addq	%rax,	%rdi

	# dial = number % 100
	movq	$100,	%rsi
	call	modulo
	movq	%rax,	24(%rsp)

	# if (dial == 0) zeros++
	cmpq	$0,	24(%rsp)
	jne	findPassword.noZero
	incq	16(%rsp)
findPassword.noZero:

	# i += len
	movq	8(%rsp),	%rcx
	addq	%rcx,	(%rsp)
	# } while (i < filesize);
	movq	0x50(%rsp),	%rcx
	cmpq	%rcx,	(%rsp)
	jl	findPassword.loop

	movq	16(%rsp),	%rdi
	call printNumber

	mov $60, %rax
	mov $0, %rdi
	syscall
