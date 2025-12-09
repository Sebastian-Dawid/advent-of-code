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

# struct List {
# u64[2]* points; (offset 0)
# u64 size;       (offset 8)
# } (size 16 bytes)

# List parse(file, filesize)
#
# The address of the stack allocated `List` structure is passed in %rdi
# The address of the file contents is passed in %rsi
# The size of the file is passed in %rdx
parse:
	pushq	%rdi
	pushq	%rsi
	pushq	%rdx
	pushq	%rbp
	movq	%rsp,	%rbp

	# count = 0
	movq	$0,	%rdx
	# i = 0
	movq	$0,	%rcx
	# do {
parse.count:
	# if (file[i] == '\n') count++
	cmpb	$10,	(%rsi, %rcx)
	jne	parse.count.postamble
	incq	%rdx
parse.count.postamble:
	incq	%rcx
	cmpq	8(%rbp),	%rcx
	jl	parse.count
	# } while (i < filesize)
	# list.size = count
	movq	%rdx,	8(%rdi)

	# allocate points
	movq	%rdx,	%rdi
	shl	$4,	%rdi
	call	alloc
	addq	$8,	%rax
	movq	24(%rbp),	%rdi
	# list.points = alloc(list.size * 16)
	movq	%rax,	(%rdi)

	# &char_count  = %rbp-8
	pushq	$0

	movq	$0,	%rdx
	movq	$0,	%rcx
parse.loop:
	pushq	%rdx
	pushq	%rcx
	movq	16(%rbp),	%rdi
	addq	%rcx,	%rdi
	movq	$44,	%rsi
	leaq	-8(%rbp),	%rdx
	call	parseNumber
	popq	%rcx
	addq	-8(%rbp),	%rcx
	pushq	%rax

	pushq	%rcx
	movq	16(%rbp),	%rdi
	addq	%rcx,	%rdi
	movq	$44,	%rsi
	leaq	-8(%rbp),	%rdx
	call	parseNumber
	popq	%rcx
	addq	-8(%rbp),	%rcx
	popq	%rsi
	popq	%rdx

	movq	24(%rbp),	%rdi
	movq	(%rdi),	%rdi
	shl	$4,	%rdx
	movq	%rsi,	(%rdi, %rdx)
	movq	%rax,	8(%rdi, %rdx)
	shr	$4,	%rdx

	incq	%rdx
	movq	24(%rbp),	%rdi
	cmpq	8(%rdi),	%rdx
	jl	parse.loop

	leave
	popq	%rdx
	popq	%rsi
	popq	%rdi
	ret

# u64 abs(i64 x)
abs:
	pushq	%rdx
	movq	%rdi,	%rax
	cmpq	$0,	%rax
	jge	abs.postamble
	movq	$-1,	%rcx
	imulq	%rcx
abs.postamble:
	popq	%rdx
	ret

# u64 rectangle(u64[2]* a, u64[2]* b)
rectangle:
	pushq	%rdi
	pushq	%rsi
	pushq	%rdx
	
	movq	(%rdi),	%rax
	subq	(%rsi),	%rax

	movq	%rax,	%rdi
	call	abs
	incq	%rax
	pushq	%rax
	
	movq	24(%rsp),	%rdi
	movq	8(%rdi),	%rax
	subq	8(%rsi),	%rax

	movq	%rax,	%rdi
	call	abs
	incq	%rax

	popq	%rcx
	mulq	%rcx

	popq	%rdx
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

	# &list = %rbp-24
	subq	$16,	%rsp

	movq	%rsp,	%rdi
	movq	-8(%rbp),	%rsi
	movq	56(%rbp),	%rdx
	call	parse

	# &pt1 = %rbp-32
	pushq	$0

	# for (i = 0; i < list.size; ++i) {
	movq	$0,	%r13
loop:
	# for (j = i+1; j < list.size; ++j) {
	leaq	1(%r13),	%r14
loop.inner:
	cmpq	-16(%rbp),	%r14
	jge	loop.postamble
	# area = rectangle(i, j)
	shl	$4,	%r13
	shl	$4,	%r14
	movq	-24(%rbp),	%rsi
	leaq	(%rsi, %r13),	%rdi
	leaq	(%rsi, %r14),	%rsi
	shr	$4,	%r13
	shr	$4,	%r14
	call	rectangle
	# if (area <= pt1) continue
	cmpq	-32(%rbp),	%rax
	jle	loop.inner.postamble
	# pt1 = area
	movq	%rax,	-32(%rbp)
loop.inner.postamble:
	incq	%r14
	jmp	loop.inner
	# }
loop.postamble:
	incq	%r13
	cmpq	-16(%rbp),	%r13
	jl	loop
	# }

	movq	-32(%rbp),	%rdi
	call	printNumber

	mov	$SYS_EXIT,	%rax
	mov	$0,	%rdi
	syscall
