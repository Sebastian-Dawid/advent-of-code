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

	pushq	%rbp
	movq	%rsp,	%rbp

	# &filesize = %rbp+56
	# &file = %rbp-8
	pushq	%rax

	movq	$SYS_CLOSE,	%rax
	movq	%r8,	%rdi
	syscall

	movq	$0,	%rcx
	movq	-8(%rbp),	%rsi
	# do {
findLineLength:
	incq	%rcx
	cmpb	$10,	(%rsi, %rcx)
	jne	findLineLength
	# } while (file[i] != '\n');
	incq	%rcx

	movq	%rcx,	%r12

	# i = filesize - width
	movq	56(%rbp),	%rcx
	subq	%r12,	%rcx

	movq	$0,	%rdx
	movq	56(%rbp),	%rax
	divq	%r12
	movq	%rax,	%r8

	# &width_plus = %rbp-16
	pushq	$0
	# &width_mul = %rbp-24
	pushq	$0

	movq	%rcx,	%rbx

	# do {
findMatrixWidths:
	cmpb	$43, (%rsi, %rcx)
	jne	findMatrixWidths.mul
	incq	-16(%rbp)
findMatrixWidths.mul:
	cmpb	$42, (%rsi, %rcx)
	jne	findMatrixWidths.postamble
	incq	-24(%rbp)
findMatrixWidths.postamble:
	incq	%rcx
	cmpq	56(%rbp),	%rcx
	jl	findMatrixWidths
	# } while (i < filesize);

	# &plus_matrix = %rbp-32
	pushq	$0
	# &mul_matrix = %rbp-40
	pushq	$0
	# &operators = %rbp-48
	pushq	$0

	# allocate operator array
	movq	-16(%rbp),	%rdi
	addq	-24(%rbp),	%rdi
	call alloc
	addq	$8,	%rax
	movq	%rax,	-48(%rbp)

	# adjust size for plus matrix
	movq	$0,	%rdx
	movq	-16(%rbp),	%rax
	movq	$8,	%rcx
	divq	%rcx
	subq	%rdx,	%rcx
	addq	%rcx,	-16(%rbp)
	# allocate plus matrix
	movq	-16(%rbp),	%rax
	movq	$0,	%rdx
	leaq	(%rdx, %r8, 4),	%rcx
	mulq	%rcx
	movq	%rax,	%rdi
	call	alloc
	addq	$8,	%rax
	movq	%rax,	-32(%rbp)

	# allocate mul matrix
	movq	-24(%rbp),	%rax
	movq	$0,	%rdx
	leaq	(%rdx, %r8, 8),	%rcx
	mulq	%rcx
	movq	%rax,	%rdi
	call	alloc
	addq	$8,	%rax
	movq	%rax,	-40(%rbp)

	movq	%rbx,	%rcx
	movq	$0,	%rbx
	# do {
readOperators:	
	cmpb	$32,	(%rsi, %rcx)
	je	readOperators.postamble
	movq	-48(%rbp),	%rdi
	movzbq	(%rsi, %rcx),	%rax
	subq	$42,	%rax
	movb	%al,	(%rdi, %rbx)
	incq	%rbx
readOperators.postamble:
	incq	%rcx
	cmpq	$10,	(%rsi, %rcx)
	jne	readOperators
	# } while (file[i] != '\n');

	# i = 0
	movq	$0,	%r10
	# j = 0
	movq	$0,	%r11
	# k = 0 (operator index)
	movq	$0,	%r13
	# l = 0 (plus index)
	movq	$0,	%r14
	# m = 0 (mul index)
	movq	$0,	%r15

	# &count = %rbp-56
	pushq	$0

	movq	-8(%rbp),	%rdi
	# for (i = 0; i < rows-1; ++i) {
readNumbers.lines:
	# j = k = l = m = 0
	movq	$0,	%r11
	movq	$0,	%r13
	movq	$0,	%r14
	movq	$0,	%r15
	# do {
readNumbers.inner:
	# n = parseNumber(file + j, '\n', &count)
	movq	$10,	%rsi
	leaq	-56(%rbp),	%rdx
	call	parseNumber

	# j += count
	addq	-56(%rbp),	%r11
	addq	-56(%rbp),	%rdi
	# if (n = ~0) continue
	cmpq	$-1,	%rax
	je	readNumbers.inner.postamble2
	movq	%rax,	%rbx

	# if (!operators[k]) {
	movq	-48(%rbp),	%rsi
	cmpb	$0,	(%rsi, %r13)
	jne	readNumbers.inner.plus
	# mul[szm*i + m] = n
	movq	-24(%rbp),	%rax
	mulq	%r10
	addq	%r15,	%rax
	movq	-40(%rbp),	%rsi
	movq	%rbx,	(%rsi, %rax, 8)
	# m++
	incq	%r15
	jmp	readNumbers.inner.postamble
	# } else {
readNumbers.inner.plus:
	# plus[szp*i + l] = n
	movq	-16(%rbp),	%rax
	mulq	%r10
	addq	%r14,	%rax
	movq	-32(%rbp),	%rsi
	movl	%ebx,	(%rsi, %rax, 4)
	# l++
	incq	%r14
	# }
readNumbers.inner.postamble:
	# k++
	incq	%r13
readNumbers.inner.postamble2:
	cmpq	%r12,	%r11
	jl	readNumbers.inner
	# } while (j < row_len)
	incq	%r10
	leaq	-1(%r8),	%r9
	cmpq	%r9,	%r10
	jl	readNumbers.lines
	# }

	# &pt1 = $rbp-64
	pushq	$0
	
	movq	-32(%rbp),	%rdi
	movq	$0,	%r10
	# for (j = 0; j < row_len; j+=8) {
plusLoop:
	# vec = plus[j..j+8]
	vmovdqu	(%rdi, %r10, 4),	%ymm0
	movq	$1,	%r11
	# for (i = 1; i < rows-1; i++) {
plusLoop.inner:
	# vec += plus[i*row_len + j..j+8]
	movq	%r11,	%rax
	movq	-16(%rbp),	%rcx
	mulq	%rcx
	addq	%r10,	%rax
	vmovdqu	(%rdi, %rax, 4),	%ymm1
	vpaddd	%ymm0,	%ymm1,	%ymm0
	incq	%r11
	leaq	-1(%r8),	%r9
	cmpq	%r9,	%r11
	jl	plusLoop.inner
	# }
	# plus[j..j+8] = vec
	vmovdqu	%ymm0,	(%rdi, %r10, 4)
	addq	$8,	%r10
	cmpq	-16(%rbp),	%r10
	jl	plusLoop
	# }

	movq	$0,	%r10
	# for (i = 0; i < row_len; i++) {
loop.pt1.plus:
	# pt1 += plus[i]
	movq	$0,	%rcx
	movl	(%rdi, %r10, 4),	%ecx
	addq	%rcx,	-64(%rbp)
	incq	%r10
	cmpq	-16(%rbp),	%r10
	jl	loop.pt1.plus
	# }

	movq	-40(%rbp),	%rdi
	movq	$0,	%r10
	# for (j = 0; j < row_len; j+=8) {
mulLoop:
	# vec = mul[j]
	movq	(%rdi, %r10, 8),	%rbx
	movq	$1,	%r11
	# for (i = 1; i < rows-1; i++) {
mulLoop.inner:
	# vec += mul[i*row_len + j]
	movq	%r11,	%rax
	movq	-24(%rbp),	%rcx
	mulq	%rcx
	addq	%r10,	%rax
	movq	(%rdi, %rax, 8),	%rax
	mulq	%rbx
	movq	%rax,	%rbx
	incq	%r11
	leaq	-1(%r8),	%r9
	cmpq	%r9,	%r11
	jl	mulLoop.inner
	# }
	# mul[j] = vec
	movq	%rbx,	(%rdi, %r10, 8)
	addq	$1,	%r10
	cmpq	-24(%rbp),	%r10
	jl	mulLoop
	# }

	movq	$0,	%r10
	# for (i = 0; i < row_len; i++) {
loop.pt1.mul:
	# pt1 += mul[i]
	movq	(%rdi, %r10, 8),	%rcx
	addq	%rcx,	-64(%rbp)
	incq	%r10
	cmpq	-24(%rbp),	%r10
	jl	loop.pt1.mul
	# }
	
	movq	-64(%rbp),	%rdi
	call	printNumber

	# &pt2 = %rbp-72
	pushq	$0
	# &local = %rbp-80
	pushq	$0

	movq	-8(%rbp),	%rdi
	movq	56(%rbp),	%r10
	subq	%r12,	%r10

	# k = 0
	movq	$0,	%r14
	# do {
loop.pt2:
	# op = file[i]
	movzbq	(%rdi, %r10),	%r11

	# local = (op == '*') ? 1 : 0
	cmpq	$42,	%r11
	je	loop.pt2.mul
	movq	$0,	-80(%rbp)
	jmp	loop.pt2.inner
loop.pt2.mul:
	movq	$1,	-80(%rbp)

	# do {
loop.pt2.inner:
	# push chars onto stack top to bottom
	leaq	-2(%r8),	%r13
	decq	%rsp
	movb	$0,	(%rsp)
loop.pt2.inner.chars:
	# pushb file[j * linelen + k]
	movq	%r12,	%rax
	mulq	%r13
	addq	%r14,	%rax
	decq	%rsp
	movzbq	(%rdi, %rax),	%rdx
	movb	%dl,	(%rsp)

	decq	%r13
	cmpq	$0,	%r13
	jge	loop.pt2.inner.chars

	# n = parseNumber(&str, ' ', &count)
	movq	%rsp,	%rdi
	movq	$0,	%rsi
	leaq	-56(%rbp),	%rdx
	call	parseNumber

	movq	-8(%rbp),	%rdi

	leaq	(%r8),	%r13
	addq	%r13,	%rsp

	# if (n == -1) break
	cmpq	$-1,	%rax
	je	loop.pt2.inner.after
	# apply operation
	# if (op == '+') {
	cmpq	$42,	%r11
	je	loop.pt2.inner.mul
	addq	%rax,	-80(%rbp)
	jmp	loop.pt2.inner.postamble
	# } else {
loop.pt2.inner.mul:
	movq	-80(%rbp),	%rcx
	mulq	%rcx
	movq	%rax,	-80(%rbp)
	# }
loop.pt2.inner.postamble:
	incq	%r14
	incq	%r10
	jmp	loop.pt2.inner
	# } while (true)
loop.pt2.inner.after:
	# pt2 += local
	movq	-80(%rbp),	%rax
	addq	%rax,	-72(%rbp)

	incq	%r14
	incq	%r10
	cmpq	56(%rbp),	%r10
	jl	loop.pt2
	# } while (i < filesize);
	
	movq	-72(%rbp),	%rdi
	call	printNumber

	movq	$60,	%rax
	movq	$0,	%rdi
	syscall
