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

# bool checkLattice(u8* lattice, u64* areas)
checkLattice:
	pushq	%rdi
	pushq	%rsi
	pushq	%rbp
	movq	%rsp,	%rbp

	# &area = %rbp-8
	pushq	$0
	# &count = %rbp-16
	pushq	$0
	# &sum = %rbp-24
	pushq	$0

	movq	$'x',	%rsi
	leaq	-16(%rbp),	%rdx
	call	parseNumber
	movq	%rax,	-8(%rbp)
	addq	-16(%rbp),	%rdi

	movq	$':',	%rsi
	leaq	-16(%rbp),	%rdx
	call	parseNumber
	movq	%rax,	%rcx
	movq	-8(%rbp),	%rax
	mulq	%rcx
	movq	%rax,	-8(%rbp)
	addq	-16(%rbp),	%rdi

	# while (lattice[i] != '\n') {
	movq	$0,	%rcx
checkLattice.loop:
	cmpb	$'\n',	-1(%rdi)
	je	checkLattice.loop.after
	
	movq	$0,	%rsi
	leaq	-16(%rbp),	%rdx
	call	parseNumber
	addq	-16(%rbp),	%rdi
	
	movq	8(%rbp),	%rsi
	movq	(%rsi, %rcx, 8),	%rdx
	mulq	%rdx

	addq	%rax,	-24(%rbp)

	incq	%rcx
	jmp	checkLattice.loop
	# }
checkLattice.loop.after:

	movq	$1,	%rax
	movq	$0,	%rdx
	movq	-24(%rbp),	%rcx
	# if (sum > area) return 0
	# return 1
	cmpq	-8(%rbp),	%rcx
	cmovgq	%rdx,	%rax
	movq	%rdi,	%rdx

	leave
	popq	%rsi
	popq	%rdi
	ret

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

	pushq	%rbp
	movq	%rsp,	%rbp

	# &filesize = %rbp+56
	# &file = %rbp-8
	pushq	%rax

	movq	$SYS_CLOSE,	%rax
	movq	%r8,	%rdi
	syscall

	# variables
	# &areas = %rbp-16
	pushq	$0
	# &result = %rbp-24
	pushq	$0

	# find number of shapes
	# while (file[i] != x) {
	movq	-8(%rbp),	%rdi
	movq	$0,	%rcx
	movq	$0,	%rdx
findNumberOfShapes:
	cmpb	$'x',	(%rdi, %rcx)
	je	findNumberOfShapes.after
	cmpb	$':',	(%rdi, %rcx)
	jne	findNumberOfShapes.postamble
	incq	%rdx
findNumberOfShapes.postamble:
	incq	%rcx
	jmp	findNumberOfShapes
	# }
findNumberOfShapes.after:

	# allocate list of areas
	shlq	$3,	%rdx
	subq	%rdx,	%rsp
	movq	%rsp,	-16(%rbp)

	movq	%rsp,	%rdi
	movq	$0,	%rsi
	call	memset

	# find areas of the shapes
	# while (file[i] != 'x') {
	movq	-8(%rbp),	%rdi
	movq	-16(%rbp),	%rsi
	movq	$0,	%rcx
	movq	$-1,	%rdx
findAreaOfShapes:
	cmpb	$'x',	(%rdi, %rcx)
	je	findAreaOfShapes.after
	cmpb	$':',	(%rdi, %rcx)
	jne	findAreaOfShapes.body
	incq	%rdx
findAreaOfShapes.body:
	cmpb	$'#',	(%rdi, %rcx)
	jne	findAreaOfShapes.postamble
	incq	(%rsi, %rdx, 8)
findAreaOfShapes.postamble:
	incq	%rcx
	jmp	findAreaOfShapes
	# }
findAreaOfShapes.after:

	# this only works on the real input
	leaq	-2(%rdi, %rcx),	%rdi
	# compute weighted sums and compare to total area of lattices
	movq	$0,	%rcx
loop:
	pushq	%rcx
	movq	-16(%rbp),	%rsi
	call	checkLattice
	movq	%rdx,	%rdi
	addq	%rax,	-24(%rbp)
	popq	%rcx

	movq	-8(%rbp),	%rdx
	addq	56(%rbp),	%rdx
	cmpq	%rdx,	%rdi
	jl	loop

	movq	-24(%rbp),	%rdi
	call	printNumber

	mov	$SYS_EXIT,	%rax
	mov	$0,	%rdi
	syscall
