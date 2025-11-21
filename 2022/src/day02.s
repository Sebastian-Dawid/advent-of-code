.section .data

results:
	.byte	1, 0, 2

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

	# part1 = 0
	movq	$0,	%rbx
	# part2 = 0
	movq	$0,	%rdx
	# i = 0
	movq	$0,	%rcx
	# do {
loop:

	# shape1 = line[0] - 'A' + 1
	movzbq	(%rax, %rcx),	%rdi
	subq	$64,	%rdi
	# shape2 = line[3] - 'A' + 1
	movzbq	2(%rax, %rcx),	%rsi
	subq	$87,	%rsi
	
	pushq	%rax
	pushq	%rdi
	pushq	%rsi

	# part1 += scoreRound(shape1, shape2)
	call scoreRound
	addq	%rax,	%rbx

	popq	%rsi
	movq	$results,	%rax
	movzbq	-1(%rax, %rsi),	%rsi
	movq	(%rsp),	%rdi
	subq	%rsi,	%rdi
	movq	%rdi,	%rsi
	cmpq	$1,	%rsi
	jge	noMod
	addq	$3,	%rsi
noMod:
	popq	%rdi

	call scoreRound
	addq	%rax,	%rdx

	popq	%rax
	# i+= 4
	addq	$4,	%rcx
	# } while (i < filesize);
	cmpq	0x30(%rsp),	%rcx
	jl	loop
	
	pushq	%rdx
	movq	%rbx,	%rdi
	call printNumber

	popq	%rdi
	call printNumber

	mov $60, %rax
	mov $0, %rdi
	syscall
