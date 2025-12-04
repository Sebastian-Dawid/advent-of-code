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

# struct Map {
# u64 width; (offset 0)
# u64 height; (offset 8)
# u8* map; (offset 16)
# } (size 24)

# The address of the map is passed in %rdi
# The horizontal index is passed in %rsi
# The vertical index is passed in %rdx
# The address of the value at (%rsi, %rdx) is returned in %rax
lookup:
	pushq	%rdi
	pushq	%rsi
	pushq	%rdx

	movq	%rdx,	%rax
	movq	(%rdi),	%rcx
	mulq	%rcx
	leaq	(%rax, %rsi),	%rcx
	movq	16(%rdi),	%rsi

	leaq	(%rsi, %rcx),	%rax

	popq	%rdx
	popq	%rsi
	popq	%rdi
	ret

# The address of the map is passed in %rdi
# The horizontal index is passed in %rsi
# The vertical index is passed in %rdx
# The sum of the neighborhood of the given tile
checkNeighborhood:
	pushq	%rbx
	pushq	%rsi
	pushq	%rdx

	movq	$0,	%rbx

	# -1, -1
	leaq	-1(%rsi),	%rsi
	leaq	-1(%rdx),	%rdx
	call	lookup
	addb	(%rax),	%bl
	# -1,  0
	leaq	1(%rdx),	%rdx
	call	lookup
	addb	(%rax),	%bl
	# -1,  1
	leaq	1(%rdx),	%rdx
	call	lookup
	addb	(%rax),	%bl
	#  0, -1
	leaq	1(%rsi),	%rsi
	leaq	-2(%rdx),	%rdx
	call	lookup
	addb	(%rax),	%bl
	#  0,  1
	leaq	2(%rdx),	%rdx
	call	lookup
	addb	(%rax),	%bl
	#  1, -1
	leaq	1(%rsi),	%rsi
	leaq	-2(%rdx),	%rdx
	call	lookup
	addb	(%rax),	%bl
	#  1,  0
	leaq	1(%rdx),	%rdx
	call	lookup
	addb	(%rax),	%bl
	#  1,  1
	leaq	1(%rdx),	%rdx
	call	lookup
	addb	(%rax),	%bl

	movq	%rbx,	%rax

	popq	%rdx
	popq	%rsi
	popq	%rbx
	ret

# The string encoding the map is passed in %rdi
# The address of the struct is passed in %rsi
parse:
	pushq	%rdi
	pushq	%rdx
	pushq	%rsi
	pushq	%rbp
	movq	%rsp,	%rbp
	# &file = %rbp-8
	pushq	%rdi
	# &map.width = %rbp-16
	pushq	(%rsi)
	# &map.height = %rbp-24
	pushq	8(%rsi)
	# &map.map = %rbp-32
	pushq	16(%rsi)
	
	decq	-16(%rbp)
	decq	-24(%rbp)

	# &i = %rbp-40
	pushq	$1
	# &j = %rbp-48
	pushq	$1

	# for (i = 1; i < map.height-1; ++i) {
parse.loop.height:
	movq	-40(%rbp),	%rcx
	cmpq	%rcx,	-24(%rbp)
	jle	parse.loop.height.after
	movq	$1,	-48(%rbp)
	# for (j = 1; j < map.width-1; ++j) {
parse.loop.width:
	movq	-16(%rbp),	%rax
	movq	-48(%rbp),	%rcx
	cmpq	%rcx,	%rax
	jle	parse.loop.width.after

	movq	-40(%rbp),	%rdx
	decq	%rdx
	mulq	%rdx
	decq	%rcx
	leaq	(%rax, %rcx),	%rax
	movq	-8(%rbp),	%rsi
	# if (str[(i-1)*map.width-1 + (j-1)] == '@') map[j, i] = 1
	cmpb	$64,	(%rsi, %rax)
	jne	parse.loop.width.postamble

	movq	8(%rbp),	%rdi
	movq	-48(%rbp),	%rsi
	movq	-40(%rbp),	%rdx
	call	lookup
	movb	$1,	(%rax)
parse.loop.width.postamble:
	incq	-48(%rbp)
	jmp	parse.loop.width
	# }
parse.loop.width.after:
	incq	-40(%rbp)
	jmp	parse.loop.height
	# }
parse.loop.height.after:

	addq	$48,	%rsp
	leave
	popq	%rsi
	popq	%rdx
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

	# &filesize = %rbp+8
	# &file = %rbp-8
	pushq	%rax

	movq	$SYS_CLOSE,	%rax
	movq	%r8,	%rdi
	syscall

	# &(struct {
	# u64 width;
	# u64 height;
	# u8* map;
	# } = {0}) = %rbp-32
	subq	$24,	%rsp
	movq	$0,	-32(%rbp)
	movq	$0,	-24(%rbp)
	movq	$0,	-16(%rbp)

	# find width
	movq	$0,	%rcx
	movq	-8(%rbp),	%rsi
findWidth:
	cmpb	$0xA,	(%rsi, %rcx)
	je	findWidth.after
	incq	%rcx
	jmp	findWidth
findWidth.after:

	movq	%rcx,	-32(%rbp)
	incq	-32(%rbp)

	# find height
	movq	$0,	%rcx
findHeight:
	cmpq	0x38(%rbp),	%rcx
	jge	findHeight.after
	addq	-32(%rbp),	%rcx
	incq	-24(%rbp)
	jmp	findHeight
findHeight.after:

	incq	-32(%rbp)
	addq	$2,	-24(%rbp)

	# allocate space for the map
	movq	-32(%rbp),	%rax
	movq	-24(%rbp),	%rcx
	mulq	%rcx
	movq	%rax,	%rdi
	call	alloc
	addq	$8,	%rax

	movq	%rax,	-16(%rbp)

	movq	-8(%rbp),	%rdi
	leaq	-32(%rbp),	%rsi
	call	parse

	# &i = %rbp-40
	pushq	$1
	# &j = %rbp-48
	pushq	$1
	# &pt1 = %rbp-56
	pushq	$0
	# &pt2 = %rbp-64
	pushq	$0

	# for (i = 1; i < map.height-1; i++) {
pt1.loop:
	movq	$1,	-48(%rbp)
	# for (j = 1; j < map.width-1; j++) {
pt1.loop.inner:
	# if (map[j, i] == 1 && neighborhood[j, i] < 4) pt1++
	leaq	-32(%rbp),	%rdi
	movq	-48(%rbp),	%rsi
	movq	-40(%rbp),	%rdx
	call	lookup
	cmpb	$1,	(%rax)
	jne	pt1.loop.inner.postamble

	call	checkNeighborhood
	
	cmpq	$4,	%rax
	jge	pt1.loop.inner.postamble

	incq	-56(%rbp)

pt1.loop.inner.postamble:
	incq	-48(%rbp)
	movq	-48(%rbp),	%rcx
	incq	%rcx
	cmpq	-32(%rbp),	%rcx
	jl	pt1.loop.inner
	# }
	incq	-40(%rbp)
	movq	-40(%rbp),	%rcx
	incq	%rcx
	cmpq	-24(%rbp),	%rcx
	jl	pt1.loop
	# }

	# &local = %rbp-72
	pushq	$0

	# do {
pt2.loop:
	movq	$1,	-40(%rbp)
	movq	$1,	-48(%rbp)
	movq	$0,	-72(%rbp)
	
	# for (i = 1; i < map.height-1; i++) {
pt2.loop.inner:
	movq	$1,	-48(%rbp)
	# for (j = 1; j < map.width-1; j++) {
pt2.loop.inner.inner:
	# if (map[j, i] == 1 && neighborhood[j, i] < 4) local++
	leaq	-32(%rbp),	%rdi
	movq	-48(%rbp),	%rsi
	movq	-40(%rbp),	%rdx
	call	lookup
	cmpb	$1,	(%rax)
	jne	pt2.loop.inner.inner.postamble

	call	checkNeighborhood
	
	cmpq	$4,	%rax
	jge	pt2.loop.inner.inner.postamble

	incq	-72(%rbp)
	call	lookup
	movb	$0,	(%rax)

pt2.loop.inner.inner.postamble:
	incq	-48(%rbp)
	movq	-48(%rbp),	%rcx
	incq	%rcx
	cmpq	-32(%rbp),	%rcx
	jl	pt2.loop.inner.inner
	# }
	incq	-40(%rbp)
	movq	-40(%rbp),	%rcx
	incq	%rcx
	cmpq	-24(%rbp),	%rcx
	jl	pt2.loop.inner
	# }
	# pt2 += local
	movq	-72(%rbp),	%rax
	addq	%rax,	-64(%rbp)
	cmpq	$0,	%rax
	jg	pt2.loop
	# } while (local > 0);

	movq	-56(%rbp),	%rdi
	call	printNumber
	movq	-64(%rbp),	%rdi
	call	printNumber

	mov $60, %rax
	mov $0, %rdi
	syscall
