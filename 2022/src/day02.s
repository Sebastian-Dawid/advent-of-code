.section .data

.equ	SYS_READ,	0
.equ	SYS_WRITE,	1
.equ	SYS_OPEN,	2
.equ	SYS_CLOSE,	3
.equ	SYS_FSTAT,	5
.equ	SYS_MMAP,	9
.equ	SYS_EXIT,	60

.equ	STDOUT,		1

.section .text

.globl _start
.extern printNumber

.equ	ROCK,		1
.equ	PAPER,		2
.equ	SCISSORS,	3

# Shape of opponent is stored in %rdi
# Shape of player is in %rsi
# %rdi and %rsi may be clobbered
# Score is stored in %rax
scoreRound:
	pushq	%rbp
	movq	%rsp,	%rbp
	subq	$24,	%rsp
	movq	$0,	-8(%rbp)
	movq	$3,	-16(%rbp)
	movq	$6,	-24(%rbp)

	subq	%rsi,	%rdi
	cmpq	$0,	%rdi
	jnl	scoreRound.compute
	addq	$3,	%rdi
scoreRound.compute:
	cmpq	$1,	%rdi
	# loss
	cmoveq	-8(%rbp),	%rax
	# win
	cmovgq	-24(%rbp),	%rax
	# draw
	cmovlq	-16(%rbp),	%rax
	addq	%rsi,	%rax
	leave
	ret

# scores:
# shape: X (1), Y (2), Z (3)
# outcome: loss (0), draw (3), win (6)
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
	leaq	(%rsp),	%rsi
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

	movq	$2,	%rdi
	movq	$3,	%rsi
	call	scoreRound

	movq	%rax,	%rdi
	call	printNumber

	mov $60, %rax
	mov $0, %rdi
	syscall
