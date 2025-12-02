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

.globl	_start
.extern alloc
.extern printNumber
.extern parseNumber
.extern	numberOfDigits
.extern	power

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
	pushq	%rbp
	movq	%rsp,	%rbp

	# &filesize = %rbp+0x38
	# file = %rbp-8
	pushq	%rax

	movq	$SYS_CLOSE,	%rax
	movq	%r8,	%rdi
	syscall

	# Make space for the number of bytes read by parseNumber
	# &count = %rbp-16
	pushq	$0

	# i = 0
	# &i = %rbp-24
	pushq	$0

	# &start = %rbp-32
	pushq	$0
	# &end = %rbp-40
	pushq	$0

	# &result = %rbp-48
	pushq	$0

	# do {
loop:
	movq	-8(%rbp),	%rdi
	addq	-24(%rbp),	%rdi
	movq	$45,	%rsi
	leaq	-16(%rbp),	%rdx
	call	parseNumber
	movq	%rax,	-32(%rbp)
	# i += count
	movq	-16(%rbp),	%rcx
	addq	%rcx,	-24(%rbp)

	movq	-8(%rbp),	%rdi
	addq	-24(%rbp),	%rdi
	movq	$45,	%rsi
	leaq	-16(%rbp),	%rdx
	call	parseNumber
	movq	%rax,	-40(%rbp)
	# i += count
	movq	-16(%rbp),	%rcx
	addq	%rcx,	-24(%rbp)

	# current = start
	movq	-32(%rbp),	%rbx
	# while (current <= end) {
loop.inner:
	cmpq	-40(%rbp),	%rbx
	jg	loop.postamble

	# digits = numberOfDigits(current)
	movq	%rbx,	%rdi
	call numberOfDigits
	
	# digits = digits/2
	movq	$0,	%rdx
	movq	$2,	%rcx
	divq	%rcx

	# if (rem != 0) continue;
	cmpq	$0,	%rdx
	jne	loop.inner.postamble

	# divisor = 10^digits
	movq	$10,	%rdi
	movq	%rax,	%rsi
	call	power
	movq	%rax,	%rcx

	# current = p*10^digits + q
	movq	%rbx,	%rax
	movq	$0,	%rdx
	divq	%rcx

	# if (p == q) result++
	cmpq	%rax,	%rdx
	jne	loop.inner.postamble
	addq	%rbx,	-48(%rbp)

loop.inner.postamble:
	# current++
	incq	%rbx
	# }
	jmp	loop.inner

loop.postamble:
	movq	-24(%rbp),	%rcx
	# } while (i < filesize);
	cmpq	0x38(%rbp),	%rcx
	jl	loop

	movq	-48(%rbp),	%rdi
	call	printNumber

	mov $60, %rax
	mov $0, %rdi
	syscall
