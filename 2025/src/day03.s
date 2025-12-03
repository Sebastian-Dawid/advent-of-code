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
.extern	copy

# The start of the byte array to search is passed in %rdi
# The number of maxima to find is passed in %rsi
# %rax will contain the resulting number
sequentialMaxima:
	# allocate space for the window of maxima
	subq	%rsi,	%rsp
	movq	$0,	%rcx
sequentialMaxima.alloc:
	movb	$0,	(%rsp, %rcx)
	incq	%rcx
	cmpq	%rsi,	%rcx
	jl	sequentialMaxima.alloc

	pushq	%rbp
	movq	%rsp,	%rbp
	
	# &max = %rbp+8
	# &str = %rbp-8
	pushq	%rdi
	# &len = %rbp-16
	pushq	%rsi

	# i = len-1 (%rbp-24)
	pushq	$0
	leaq	-1(%rsi),	%rcx
	movq	%rcx,	-24(%rbp)

	# while (str[i] != '\n') {
sequentialMaxima.loop:
	movq	-8(%rbp),	%rdi
	movq	-24(%rbp),	%rcx
	cmpb	$0xA,	(%rdi, %rcx)
	je	sequentialMaxima.loop.after

	movq	$0,	%rcx
	# for (j = 0; j < len; ++j) {
sequentialMaxima.loop.inner:
	leaq	8(%rbp, %rcx),	%rdi
	movq	-8(%rbp),	%rsi
	addq	-24(%rbp),	%rsi
	subq	-16(%rbp),	%rsi
	addq	%rcx,	%rsi
	incq	%rsi
	movb	(%rsi),	%al
	# if (max[j] < str[i-(len-1-j)]) {
	cmpb	(%rdi),	%al
	jle	sequentialMaxima.loop.inner.postamble
	# copy(max + j, str + i - (len-1-j), len-j)
	movq	-16(%rbp),	%rdx
	subq	%rcx,	%rdx
	call	copy
	jmp	sequentialMaxima.loop.inner.after
	# break
	# }
sequentialMaxima.loop.inner.postamble:
	incq	%rcx
	jmp	sequentialMaxima.loop.inner
	# }
sequentialMaxima.loop.inner.after:
	incq	-24(%rbp)
	jmp	sequentialMaxima.loop
	# }

sequentialMaxima.loop.after:

	# &result = %rbp-32
	pushq	$0

	# i = 0
	movq	$0,	%rsi
	# for (i = 0; i < len; ++i) {
sequentialMaxima.sum:
	cmpq	%rsi,	-16(%rbp)
	jle	sequentialMaxima.sum.after
	# result += 10^i * max[len - (i+1)]
	movq	$10,	%rdi
	call	power

	incq	%rsi

	leaq	8(%rbp),	%rdx
	addq	-16(%rbp),	%rdx
	subq	%rsi,	%rdx
	movzbq	(%rdx),	%rdx
	subq	$0x30,	%rdx
	mulq	%rdx
	addq	%rax,	-32(%rbp)

	jmp	sequentialMaxima.sum
	# }

sequentialMaxima.sum.after:
	popq	%rax
	popq	%rcx
	popq	%rsi
	popq	%rdi
	leave
	addq	%rsi,	%rsp
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
	pushq	$0
	# &line_length = %rbp-24
	pushq	$0

	# pt1 = 0 (%rbp-32)
	pushq	$0
	# pt2 = 0 (%rbp-40)
	pushq	$0

	movq	-8(%rbp),	%rax
	# find line length
findLineLength:
	movq	-24(%rbp),	%rcx
	incq	-24(%rbp)
	cmpb	$0xA,	(%rax, %rcx)
	jne	findLineLength

	# do {
loop:
	movq	-8(%rbp),	%rdi
	addq	-16(%rbp),	%rdi
	movq	$2,	%rsi
	call sequentialMaxima
	addq	%rax,	-32(%rbp)

	movq	-8(%rbp),	%rdi
	addq	-16(%rbp),	%rdi
	movq	$12,	%rsi
	call sequentialMaxima
	addq	%rax,	-40(%rbp)

	movq	-24(%rbp),	%rcx
	addq	%rcx,	-16(%rbp)
	# } while(i < filesize);
	movq	0x38(%rbp),	%rcx
	cmpq	%rcx,	-16(%rbp)
	jl	loop
	
	movq	-32(%rbp),	%rdi
	call	printNumber
	movq	-40(%rbp),	%rdi
	call	printNumber

	mov $60, %rax
	mov $0, %rdi
	syscall
