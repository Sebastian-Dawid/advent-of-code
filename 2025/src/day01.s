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

	pushq	%rbp
	movq	%rsp,	%rbp

	# Current dial value (%rbp-8)
	pushq	$50
	# Number of zeros (pt1) (%rbp-16)
	pushq	$0
	# Number of zeros (pt2) (%rbp-24)
	pushq	$0
	# Number of read characters (%rbp-32)
	pushq	$0
	# Index (%rbp-40)
	pushq	$0

	# do {
findPassword.loop:
	movq	-40(%rbp),	%rcx
	movb	(%rbx,	%rcx),	%r12b
	# i++
	incq	-40(%rbp)

	# N = parseNumber(str + i, '\n', &count)
	movq	%rbx,	%rdi
	addq	-40(%rbp),	%rdi
	movq	$0xA,	%rsi
	leaq	-32(%rbp),	%rdx
	call	parseNumber

	# N = N - 100*floor(N / 100)
	cqto
	movq	$100,	%rsi
	divq	%rsi
	addq	%rax,	-24(%rbp)
	cmpq	$0,	-8(%rbp)
	# if (last == 0 && (rem == 0 || rot == 'L')) pt2--;
	jne	findPassword.noDec
	cmpq	$0,	%rdx
	je	findPassword.dec
	cmpb	$76,	%r12b
	je	findPassword.dec
	jmp	findPassword.noDec
findPassword.dec:
	decq	-24(%rbp)
findPassword.noDec:
	movq	%rdx,	%rax

	# if (str[i] == 'L') N *= -1
	cmpb	$76,	%r12b
	jne	findPassword.positive
	movq	$-1,	%rcx
	mulq	%rcx
findPassword.positive:
	# number = dial + N
	movq	-8(%rbp),	%rdi
	addq	%rax,	%rdi

	cmpq	$0,	%rdi
	jle	findPassword.pass
	cmpq	$100,	%rdi
	jge	findPassword.pass
	jmp	findPassword.noPass
findPassword.pass:
	incq	-24(%rbp)

findPassword.noPass:
	# dial = number % 100
	movq	$100,	%rsi
	call	modulo
	movq	%rax,	-8(%rbp)

	# if (dial == 0) zeros++
	cmpq	$0,	-8(%rbp)
	jne	findPassword.noZero
	incq	-16(%rbp)
findPassword.noZero:

	# i += len
	movq	-32(%rbp),	%rcx
	addq	%rcx,	-40(%rbp)
	# } while (i < filesize);
	movq	0x38(%rbp),	%rcx
	cmpq	%rcx,	-40(%rbp)
	jl	findPassword.loop

	movq	-16(%rbp),	%rdi
	call printNumber
	movq	-24(%rbp),	%rdi
	call printNumber

	mov $60, %rax
	mov $0, %rdi
	syscall
