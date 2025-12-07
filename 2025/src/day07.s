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

# The ASCII code of the object is passed in %rdi
# The ID of the resulting element is returned in %rax
# nothing (.)  = 0
# beam (S)     = 1
# splitter (^) = 2
parseObject:
	movq	$2,	%rax
	cmpq	$94,	%rdi
	je	parseObject.postamble
	movq	$1,	%rax
	cmpq	$83,	%rdi
	je	parseObject.postamble
	movq	$0,	%rax
parseObject.postamble:
	ret

# The address of the map structure is stored in %rdi
# The address of the file contents is stored in %rsi
parse:
	# &map = %rbp+16
	pushq	%rdi
	# &file = %rbp+8
	pushq	%rsi
	pushq	%rbp
	movq	%rsp,	%rbp

	# &i = %rbp-8
	pushq	$0
	# &j = %rbp-16
	pushq	$0
	
	# for (i = 0; i < height; ++i) {
parse.loop:
	movq	$0,	-16(%rbp)
	# for (j = 0; j < width; ++j) {
parse.loop.inner:
	movq	16(%rbp),	%rdi
	movq	(%rdi),	%rcx
	movq	-8(%rbp),	%rax
	mulq	%rcx
	addq	-16(%rbp),	%rax
	movq	16(%rdi),	%rcx
	leaq	(%rcx, %rax),	%rcx
	pushq	%rcx

	# map[i*width + j] = parseObject(file[i*(width+1) + j])
	addq	-8(%rbp),	%rax
	movq	8(%rbp),	%rdi
	movzbq	(%rdi, %rax),	%rdi
	call	parseObject

	popq	%rdi
	movb	%al,	(%rdi)

	incq	-16(%rbp)
	movq	16(%rbp),	%rdi
	movq	(%rdi),	%rdi
	cmpq	%rdi,	-16(%rbp)
	jl	parse.loop.inner
	# }
	incq	-8(%rbp)
	movq	16(%rbp),	%rdi
	movq	8(%rdi),	%rdi
	cmpq	%rdi,	-8(%rbp)
	jl	parse.loop
	# }

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

	movq	$0,	%rcx
	movq	-8(%rbp),	%rdi
	# do {
findLineWidth:
	incq	%rcx
	cmpb	$10,	(%rdi, %rcx)
	jne	findLineWidth
	# } while (file[i] != '\n')

	# struct {
	# u64 width; (%rbp-32)
	# u64 height; (%rbp-24)
	# u8* map; (%rbp-16)
	# }
	subq	$24,	%rsp
	movq	%rcx,	-32(%rbp)

	# compute height
	incq	%rcx
	movq	56(%rbp),	%rax
	movq	$0,	%rdx
	divq	%rcx
	movq	%rax,	-24(%rbp)

	# allocate map
	movq	-32(%rbp),	%rcx
	mulq	%rcx
	movq	%rax,	%rdi
	call	alloc
	addq	$8,	%rax
	movq	%rax,	-16(%rbp)

	leaq	-32(%rbp),	%rdi
	movq	-8(%rbp),	%rsi
	call	parse

	# &pt1 = %rbp-40
	pushq	$0
	
	# i = 1
	movq	$1,	%r12

	# do {
simulate:

	# for (j = 0; j < width; ++j) {
	movq	$0,	%r13
simulate.inner:
	movq	-32(%rbp),	%rax
	mulq	%r12
	addq	%r13,	%rax
	addq	-16(%rbp),	%rax
	movq	%rax,	%rdi
	# current = map[i*width + j]
	movzbq	(%rdi),	%rax
	# above = map[(i-1)*width + j]
	subq	-32(%rbp),	%rdi
	movzbq	(%rdi),	%rbx
	addq	-32(%rbp),	%rdi

	# if (above != beam) continue
	cmpq	$1,	%rbx
	jne	simulate.inner.postamble

	# if (current == splitter) {
	cmpq	$2,	%rax
	jne	simulate.inner.propagate
	# map[i*width + j - 1] = beam
	movb	$1,	-1(%rdi)
	# map[i*width + j + 1] = beam
	movb	$1,	1(%rdi)
	incq	-40(%rbp)
	jmp	simulate.inner.postamble
	# }
simulate.inner.propagate:
	# map[i*width + j] = beam
	movb	$1,	(%rdi)
simulate.inner.postamble:
	incq	%r13
	cmpq	-32(%rbp),	%r13
	jl	simulate.inner
	# }

	incq	%r12
	cmpq	-24(%rbp),	%r12
	jl	simulate
	# } while (i < height)

	movq	-40(%rbp),	%rdi
	call	printNumber

	mov	$60,	%rax
	mov	$0,	%rdi
	syscall
