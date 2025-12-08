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

# struct Fusebox {
# u64 x, y, z
# u64 circuit
# } (size = 32 bytes)

# N*N symmetric connection matrix (N*(N+1)/2 bytes)
# Every fusebox is connected to itself
# Only the upper triangular matrix is stored

# List of the sizes of all N initial circuits (4*N bytes)
# If one circuit is absorbed into another that size is set to zero

# struct Circuits {
# Fusebox* fuseboxes; (offset 0)
# u8* connections;    (offset 8)
# u32* circuit_sizes; (offset 16)
# u64 size;           (offset 24)
# } (size = 32 bytes)

# u8* lookupConnection(u8* matrix, u64 i, u64 j);
# The address of the connection matrix is passed in %rdi
# The first index i is passed in %rsi
# The second index j is passed in %rdx
# The address of the element is returned in %rax
# Note that lookupConnection(m, i, j) == lookupConnection(m, j, i)
# The address is computed as %rdi + ((%rdx*(%rdx-1)) >> 1) + %rsi
# %rsi and %rdx are clobbered
lookupConnection:
	cmpq	%rsi,	%rdx
	jge	lookupConnection.addressComputation
	xorq	%rsi,	%rdx
	xorq	%rdx,	%rsi
	xorq	%rsi,	%rdx
lookupConnection.addressComputation:
	movq	%rdx,	%rax
	incq	%rdx
	mulq	%rdx
	shr	$1,	%rax
	addq	%rsi,	%rax
	addq	%rdi,	%rax
	ret

# Circuits parse(u8* file, u64 filesize)
#
# The address of the stack allocated return value is passed in %rdi
# The address of the file contents is passed in %rsi
# The filesize is passed in %rdx
parse:
	pushq	%rbx
	# &circuits = %rbp+24
	pushq	%rdi
	# &file = %rbp+16
	pushq	%rsi
	# &filesize = %rbp+8
	pushq	%rdx
	pushq	%rbp
	movq	%rsp,	%rbp

	# &count = %rbp-8 
	pushq	$0

	# i = 0
	movq	$0,	%rcx
	# do {
parse.findFuseboxCount:
	cmpb	$10,	(%rsi, %rcx)
	jne	parse.findFuseboxCount.postamble
	incq	-8(%rbp)
parse.findFuseboxCount.postamble:
	incq	%rcx
	cmpq	%rdx,	%rcx
	jl	parse.findFuseboxCount
	# } while (i < filesize)

	movq	$0,	%rbx
	# allocate list of fuseboxes
	movq	-8(%rbp),	%rcx
	leaq	(%rbx, %rcx, 8),	%rdi
	shl	$2,	%rdi
	call	alloc
	addq	$8,	%rax
	movq	24(%rbp),	%rdi
	movq	%rax,	(%rdi)

	# allocate matrix of connections
	movq	-8(%rbp),	%rax
	mulq	%rax
	addq	-8(%rbp),	%rax
	movq	$2,	%rcx
	movq	$0,	%rdx
	divq	%rcx
	movq	%rax,	%rdi
	call	alloc
	addq	$8,	%rax
	movq	24(%rbp),	%rdi
	movq	%rax,	8(%rdi)

	# allocate list of circuit sizes
	movq	-8(%rbp),	%rcx
	leaq	(%rbx, %rcx, 4),	%rdi
	call	alloc
	addq	$8,	%rax
	movq	24(%rbp),	%rdi
	movq	%rax,	16(%rdi)

	movq	-8(%rbp),	%rax
	movq	%rax,	24(%rdi)

	# &circuits = %rbp-16
	pushq	(%rdi)
	# &connections = %rbp-24
	pushq	8(%rdi)
	# &circuit_sizes = %rbp-32
	pushq	16(%rdi)
	# &character_count = %rbp-40
	pushq	$0

	movq	$0,	%rcx
	movq	16(%rbp),	%rsi
	# do {
parse.initialize:
	# set circuit size to 1
	movq	-32(%rbp),	%rdi
	movl	$1,	(%rdi, %rcx, 4)

	pushq	%rsi
	movq	-24(%rbp),	%rdi
	movq	%rcx,	%rsi
	movq	%rcx,	%rdx
	call	lookupConnection
	movb	$1,	(%rax)
	popq	%rsi

	# parse fusebox position
	pushq	%rsi
	movq	%rsi,	%rdi
	movq	$44,	%rsi
	leaq	-40(%rbp),	%rdx
	call	parseNumber
	popq	%rsi
	addq	-40(%rbp),	%rsi
	movq	-16(%rbp),	%rdi
	leaq	(%rbx, %rcx, 8),	%rdx
	shl	$2,	%rdx
	movq	%rax,	(%rdi, %rdx)

	pushq	%rsi
	movq	%rsi,	%rdi
	movq	$44,	%rsi
	leaq	-40(%rbp),	%rdx
	call	parseNumber
	popq	%rsi
	addq	-40(%rbp),	%rsi
	movq	-16(%rbp),	%rdi
	leaq	(%rbx, %rcx, 8),	%rdx
	shl	$2,	%rdx
	movq	%rax,	8(%rdi, %rdx)

	pushq	%rsi
	movq	%rsi,	%rdi
	movq	$44,	%rsi
	leaq	-40(%rbp),	%rdx
	call	parseNumber
	popq	%rsi
	addq	-40(%rbp),	%rsi
	movq	-16(%rbp),	%rdi
	leaq	(%rbx, %rcx, 8),	%rdx
	shl	$2,	%rdx
	movq	%rax,	16(%rdi, %rdx)
	movq	%rcx,	24(%rdi, %rdx)

	# postamble
	incq	%rcx
	cmpq	-8(%rbp),	%rcx
	jl	parse.initialize
	# } while (i < count)

	leave
	popq	%rdx
	popq	%rsi
	popq	%rdi
	popq	%rbx
	ret

# u64 dist(Fusebox* a, Fusebox* b)
dist:
	subq	$8,	%rsp
	movq	$0,	%rax
	movq	(%rdi),	%rax
	subq	(%rsi),	%rax
	imulq	%rax
	movq	%rax,	(%rsp)

	movq	8(%rdi),	%rax
	subq	8(%rsi),	%rax
	imulq	%rax
	addq	%rax,	(%rsp)

	movq	16(%rdi),	%rax
	subq	16(%rsi),	%rax
	imulq	%rax
	addq	%rax,	(%rsp)

	movq	(%rsp),	%rax
	addq	$8,	%rsp
	ret

# void connectClosest(Circuits* circuits);
# The address of the circuits structure is passed in %rdi
connectClosest:
	pushq	%r13
	pushq	%r14
	pushq	%rdx
	# &circuits = %rbp+8
	pushq	%rdi
	pushq	%rbp
	movq	%rsp,	%rbp

	# &min = %rbp-8
	# min = ~0
	pushq	$-1

	# min_i = min_j = 0
	# &min_i = %rbp-16
	pushq	$0
	# &min_j = %rbp-24
	pushq	$0

	# for (j = 0; j < circuits->size; ++j) {
	movq	$0,	%r13
connectClosest.find:
	# for (i = 0; i < j; ++i) {
	movq	$0,	%r14
connectClosest.find.inner:
	cmpq	%r13,	%r14
	jge	connectClosest.find.inner.after

	movq	8(%rbp),	%rdi
	# u8* connection = loopupConnection(circuit->connections, i, j);
	movq	8(%rdi),	%rdi
	movq	%r14,	%rsi
	movq	%r13,	%rdx
	call	lookupConnection

	# if (*connection) continue
	cmpb	$1,	(%rax)
	je	connectClosest.find.inner.postamble

	# d = dist(i, j)
	movq	8(%rbp),	%rdi
	movq	(%rdi),	%rdi
	movq	$0,	%rdx
	leaq	(%rdx, %r13, 8), %rax
	shl	$2,	%rax
	leaq	(%rdi, %rax),	%rsi
	leaq	(%rdx, %r14, 8), %rax
	shl	$2,	%rax
	leaq	(%rdi, %rax),	%rdi
	call	dist

	# if (d >= min) continue
	cmpq	-8(%rbp),	%rax
	jae	connectClosest.find.inner.postamble

	# min_i = i
	movq	%r14,	-16(%rbp)
	# min_j = j
	movq	%r13,	-24(%rbp)
	# min = d
	movq	%rax,	-8(%rbp)
connectClosest.find.inner.postamble:
	incq	%r14
	jmp	connectClosest.find.inner
	# }
connectClosest.find.inner.after:
	incq	%r13
	movq	8(%rbp),	%rdi
	cmpq	24(%rdi),	%r13
	jl	connectClosest.find
	# }

	# circuits->connections[min_i, min_j] = 1
	movq	8(%rbp),	%rdi
	movq	8(%rdi),	%rdi
	movq	-16(%rbp),	%rsi
	movq	-24(%rbp),	%rdx
	call	lookupConnection
	movb	$1,	(%rax)

	# &old = %rbp-32
	pushq	$0
	# &new = %rbp-40
	pushq	$0
	movq	8(%rbp),	%rdi
	movq	(%rdi),	%rdi
	movq	$0,	%rdx
	# new = circuits->fuseboxes[min_i].circuit
	movq	-16(%rbp),	%r13
	leaq	(%rdx, %r13, 8), %r13
	shl	$2,	%r13
	movq	24(%rdi, %r13),	%rax
	movq	%rax,	-40(%rbp)
	# old = circuits->fuseboxes[min_j].circuit
	movq	-24(%rbp),	%r13
	leaq	(%rdx, %r13, 8), %r13
	shl	$2,	%r13
	movq	24(%rdi, %r13),	%r14
	movq	%r14,	-32(%rbp)

	movq	(%rdi, %r13),	%rax
	movq	-16(%rbp),	%r13
	leaq	(%rdx, %r13, 8), %r13
	shl	$2,	%r13
	movq	(%rdi, %r13),	%rcx
	mulq	%rcx
	pushq	%rax
	movq	%r14,	%rax
	# if (old == new) return
	cmpq	%rax,	-40(%rbp)
	je	connectClosest.postamble

	movq	8(%rbp),	%rdi
	movq	16(%rdi),	%rdi
	# old_size = circuits->circuit_sizes[old]
	movslq	(%rdi,	%rax, 4),	%rdx
	# circuits->circuit_sizes[old] = 0
	movl	$0,	(%rdi, %rax, 4)
	# circuits->circuit_sizes[new] += old_size
	movq	-40(%rbp),	%r14
	addl	%edx,	(%rdi, %r14, 4)

	movq	8(%rbp),	%rdi
	# for (i = 0; i < circuits->size; ++i) {
	movq	$0,	%r13
connectClosest.updateCircuits:
	# if (circuits->fuseboxes[i].circuit != old) continue
	movq	$0,	%rdx
	movq	(%rdi),	%rdi
	leaq	(%rdx, %r13, 8),	%rax
	shl	$2,	%rax
	movq	24(%rdi, %rax),	%rdx
	cmpq	%rdx,	-32(%rbp)
	jne	connectClosest.updateCircuits.postamble
	# circuits->fuseboxes[i].circuit = new
	movq	-40(%rbp),	%rdx
	movq	%rdx,	24(%rdi, %rax)
connectClosest.updateCircuits.postamble:
	movq	8(%rbp),	%rdi
	incq	%r13
	cmpq	24(%rdi),	%r13
	jl	connectClosest.updateCircuits
	# }
connectClosest.postamble:
	popq	%rax
	leave
	popq	%rdi
	popq	%rdx
	popq	%r14
	popq	%r13
	ret

# u64 findMax(u32* list, u64 length, u64 below)
findMax:
	pushq	%rbx

	movq	$0,	%rax
	movq	$0,	%rcx
findMax.loop:
	cmpq	$-1,	%rdx
	je	findMax.loop.maxCompare
	cmpq	%rcx,	%rdx
	je	findMax.loop.postamble

	movslq	(%rdi, %rcx, 4),	%rbx
	movslq	(%rdi, %rdx, 4),	%r8
	cmpq	%rbx,	%r8
	jb	findMax.loop.postamble

findMax.loop.maxCompare:
	movslq	(%rdi, %rcx, 4),	%rbx
	movslq	(%rdi, %rax, 4),	%r8
	cmpq	%rbx,	%r8
	jae	findMax.loop.postamble
	movq	%rcx,	%rax
findMax.loop.postamble:
	incq	%rcx
	cmpq	%rsi,	%rcx
	jl	findMax.loop

	popq	%rbx
	ret

_start:
	# Pop argc, progname and first command-line input
	popq	%rdi
	popq	%rdi
	popq	%rdi

	popq	%rsi
	pushq	%rdi
	pushq	$0
	movq	%rsi,	%rdi
	movq	$0,	%rsi
	movq	%rsp,	%rdx
	call	parseNumber
	movq	%rax,	%r15
	addq	$8,	%rsp
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

	subq	$32,	%rsp
	movq	%rsp,	%rdi
	movq	-8(%rbp),	%rsi
	movq	56(%rbp),	%rdx
	call	parse

	movq	$0,	%r14
loop:
	movq	%rsp,	%rdi
	call	connectClosest
	incq	%r14
	cmpq	%r15,	%r14
	jl	loop

	# &result = %rbp-48
	pushq	$1

	movq	24(%rdi),	%rsi
	movq	16(%rdi),	%rdi
	movq	$-1,	%rdx
	call	findMax

	pushq	%rax
	movslq	(%rdi, %rax, 4),	%rax
	movq	-48(%rbp),	%rcx
	mulq	%rcx
	movq	%rax,	-48(%rbp)
	popq	%rdx
	call	findMax

	pushq	%rax
	movslq	(%rdi, %rax, 4),	%rax
	movq	-48(%rbp),	%rcx
	mulq	%rcx
	movq	%rax,	-48(%rbp)
	popq	%rdx
	call	findMax

	movq	-48(%rbp),	%rcx
	movslq	(%rdi, %rax, 4),	%rax
	mulq	%rcx

	movq	%rax,	%rdi
	call	printNumber

	# &pt2 = %rbp-56
	pushq	$0

loop2:
	leaq	-40(%rbp),	%rdi
	call	connectClosest
	movq	%rax,	-56(%rbp)
	movq	$0,	%rcx
	movq	$0,	%r13
countCircuits:
	movq	16(%rdi),	%rsi
	cmpl	$0,	(%rsi, %r13, 4)
	je	countCircuits.postamble
	incq	%rcx
countCircuits.postamble:
	incq	%r13
	cmpq	24(%rdi),	%r13
	jl	countCircuits
	cmpq	$1,	%rcx
	jne	loop2

	movq	-56(%rbp),	%rdi
	call	printNumber

	mov	$SYS_EXIT,	%rax
	mov	$0,	%rdi
	syscall
