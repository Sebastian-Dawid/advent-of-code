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

	movq	$SYS_MMAP,	%rax
	movq	0x30(%rsp),	%rsi
	movq	$1,	%rdx
	movq	$1,	%r10
	movq	%rdi,	%r8
	movq	$0,	%rdi
	movq	$0,	%r9
	syscall

	pushq	%rax

	movq	$SYS_CLOSE,	%rax
	movq	%r8,	%rdi
	syscall

	popq	%rax

	pushq	%rbp
	movq	%rsp,	%rbp
	pushq	%rax
	subq	$56,	%rsp
	
	movq	$0,	-56(%rbp)
	movq	$0,	-64(%rbp)

	movq	$0,	%rcx
loop:
	movq	-8(%rbp),	%rdi
	addq	%rcx,	%rdi
	movq	$45,	%rsi
	leaq	-16(%rbp),	%rdx
	call	parseNumber
	addq	-16(%rbp),	%rcx
	movq	%rax,	-24(%rbp)

	movq	-8(%rbp),	%rdi
	addq	%rcx,	%rdi
	movq	$44,	%rsi
	leaq	-16(%rbp),	%rdx
	call	parseNumber
	addq	-16(%rbp),	%rcx
	movq	%rax,	-32(%rbp)

	movq	-8(%rbp),	%rdi
	addq	%rcx,	%rdi
	movq	$45,	%rsi
	leaq	-16(%rbp),	%rdx
	call	parseNumber
	addq	-16(%rbp),	%rcx
	movq	%rax,	-40(%rbp)

	movq	-8(%rbp),	%rdi
	addq	%rcx,	%rdi
	movq	$10,	%rsi
	leaq	-16(%rbp),	%rdx
	call	parseNumber
	addq	-16(%rbp),	%rcx
	movq	%rax,	-48(%rbp)

	# a1 <= b1
	movq	-40(%rbp),	%rax
	cmpq	-24(%rbp),	%rax
	jl	sectionTwo.first
	je	sections.sameStart

# a1 < b1
sectionOne.first:
	# b1 <= a2
	movq	-40(%rbp),	%rax
	cmpq	-32(%rbp),	%rax
	jg	loop.postamble

	incq	-64(%rbp)

	# b2 <= a2
	movq	-48(%rbp),	%rax
	cmpq	-32(%rbp),	%rax
	jg	loop.postamble

	incq	-56(%rbp)
	jmp	loop.postamble

# b1 < a1
sectionTwo.first:
	# a1 <= b2
	movq	-24(%rbp),	%rax
	cmpq	-48(%rbp),	%rax
	jg	loop.postamble

	incq	-64(%rbp)

	# a2 <= b2
	movq	-32(%rbp),	%rax
	cmpq	-48(%rbp),	%rax
	jg	loop.postamble

	incq	-56(%rbp)
	jmp	loop.postamble

# b1 = a1
sections.sameStart:
	incq	-64(%rbp)
	incq	-56(%rbp)

loop.postamble:
	cmpq	0x38(%rbp),	%rcx
	jl	loop

	movq	-56(%rbp),	%rdi
	call printNumber
	movq	-64(%rbp),	%rdi
	call printNumber

	leave

	mov $60, %rax
	mov $0, %rdi
	syscall
