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

# struct Network {
# u64 count       (offset  0)
# u64 you         (offset  8)
# u64 out         (offset 16)
# u8* connections (offset 24)
# } (size = 32 bytes)

# Network parse(u8* input, u64 length)
parse:
	pushq	%rbp
	movq	%rsp,	%rbp
	# &network = %rbp-8
	pushq	%rdi
	# &input = %rbp-16
	pushq	%rsi
	# &length = %rbp-24
	pushq	%rdx
	# &compressed = %rbp-32
	pushq	$0

	# while (i < length) {
	movq	$0,	%rcx
parse.findNodes:
	movl	$0,	%eax
	orb	(%rsi, %rcx),	%al
	shll	$8,	%eax
	orb	1(%rsi, %rcx),	%al
	shll	$8,	%eax
	orb	2(%rsi, %rcx),	%al

	subq	$4,	%rsp
	movl	%eax,	(%rsp)
	incq	(%rdi)

	addq	$3,	%rcx
	# while (input[i] != '\n') {
parse.findNodes.skip:
	incq	%rcx
	cmpb	$0xA,	(%rsi, %rcx)
	jne	parse.findNodes.skip
	# }

	incq	%rcx
	cmpq	-24(%rbp),	%rcx
	jl	parse.findNodes
	# }

	subq	$4,	%rsp
	# node 'out' has not outputs but needs to be considered
	movl	$0x006f7574,	(%rsp)
	incq	(%rdi)

	movq	%rsp,	-32(%rbp)

	# network.connections = alloc(network.count^2)
	movq	(%rdi),	%rax
	mulq	%rax
	movq	%rax,	%rdi
	call	alloc
	addq	$8,	%rax
	movq	-8(%rbp),	%rdi
	movq	%rax,	24(%rdi)

	# while (i < length) {
	movq	-24(%rbp),	%rdx
	movq	-16(%rbp),	%rsi
	movq	$0,	%rcx
parse.loop:
	movl	$0,	%r8d
	orb	(%rsi, %rcx),	%r8b
	shll	$8,	%r8d
	orb	1(%rsi, %rcx),	%r8b
	shll	$8,	%r8d
	orb	2(%rsi, %rcx),	%r8b

	movl	%r8d,	%edi
	movq	-32(%rbp),	%rsi
	movq	-24(%rbp),	%rdx
	call	parse.find
	movl	%eax,	%r8d
	movq	-16(%rbp),	%rsi

	movl	%edi,	%r11d
	movq	-8(%rbp),	%rdi
	movq	8(%rdi),	%r10
	cmpl	$0x00796f75,	%r11d
	cmoveq	%r8,	%r10
	movq	%r10,	8(%rdi)

	addq	$5,	%rcx
	# while (input[i-1] != '\n') {
parse.loop.inner:
	movl	$0,	%r9d
	orb	(%rsi, %rcx),	%r9b
	shll	$8,	%r9d
	orb	1(%rsi, %rcx),	%r9b
	shll	$8,	%r9d
	orb	2(%rsi, %rcx),	%r9b

	movl	%r9d,	%edi
	movq	-32(%rbp),	%rsi
	movq	-24(%rbp),	%rdx
	call	parse.find
	cmpl	$-1,	%eax
	je	parse.loop.inner.postamble
	movl	%eax,	%r9d
	movq	-16(%rbp),	%rsi

	movq	-8(%rbp),	%rdi
	movq	(%rdi),	%rax
	movq	24(%rdi),	%rdi

	# determine x and y
	mulq	%r8
	addq	%r9,	%rax

	# network.connections[y*network.count + x] = 1
	movb	$1,	(%rdi, %rax)

parse.loop.inner.postamble:
	addq	$4,	%rcx
	cmpb	$0xA,	-1(%rsi, %rcx)
	jne	parse.loop.inner
	# }

	movq	-24(%rbp),	%rdx
	cmpq	%rdx,	%rcx
	jl	parse.loop
	# }

	movq	-24(%rbp),	%rdx
	movq	-16(%rbp),	%rsi
	movq	-8(%rbp),	%rdi
	leave
	ret

parse.find:
	pushq	%rcx
	movq	$-1,	%rax
	movq	$0,	%rcx
parse.find.loop:
	cmpl	(%rsi, %rcx, 4),	%edi
	je	parse.find.found
	incq	%rcx
	cmpq	%rdx,	%rcx
	jl	parse.find.loop
parse.find.postamble:
	popq	%rcx
	ret
parse.find.found:
	movq	%rcx,	%rax
	jmp	parse.find.postamble

# u64 networkDFS(Network* network, u64 node)
networkDFS:
	pushq	%rdi
	pushq	%rsi
	pushq	%rbp
	movq	%rsp,	%rbp

	# if (node == network.out) return 1
	cmpq	$0,	%rsi
	je	networkDFS.foundOut

	# result = 0
	# &result = %rbp-8
	pushq	$0

	# for (i = 0; i < network.count; ++i) {
	# &i = %rbp-16
	pushq	$0
networkDFS.loop:
	movq	8(%rbp),	%rsi
	movq	(%rdi),	%rax
	mulq	%rsi
	addq	-16(%rbp),	%rax
	movq	24(%rdi),	%rdx
	# if (network.connections[node*network.count + i]) {
	cmpb	$0,	(%rdx, %rax)
	je	networkDFS.loop.postamble
	# result += networkDFS(network, i)
	movq	-16(%rbp),	%rsi
	call	networkDFS
	addq	%rax,	-8(%rbp)
	# }
networkDFS.loop.postamble:
	incq	-16(%rbp)
	movq	-16(%rbp),	%rcx
	cmpq	(%rdi),	%rcx
	jl	networkDFS.loop
	# }

	# return result
	movq	-8(%rbp),	%rax

networkDFS.postamble:
	leave
	popq	%rsi
	popq	%rdi
	ret
networkDFS.foundOut:
	movq	$1,	%rax
	jmp	networkDFS.postamble

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

	# &network = %rbp-40
	subq	$32,	%rsp
	movq	%rsp,	%rdi
	movq	-8(%rbp),	%rsi
	movq	56(%rbp),	%rdx
	call	parse

	leaq	-40(%rbp),	%rdi
	movq	-32(%rbp),	%rsi
	call	networkDFS

	movq	%rax,	%rdi
	call	printNumber

	mov	$SYS_EXIT,	%rax
	mov	$0,	%rdi
	syscall
