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

# (List, u64, u64) compressCoordinates(List* original)
#
# The address of the stack allocated return value is stored in %rdi
# The address of the original list of positions is stored in %rsi
#
# Note that the last u64 of the return value is returned via %rax and
# is the size of the grid that contains the compressed polygon
compressCoordinates:
	pushq	%r8
	pushq	%r9
	pushq	%r10
	pushq	%r11
	pushq	%r12
	pushq	%r13
	pushq	%r14
	pushq	%r15
	pushq	%rdx
	pushq	%rbx
	pushq	%rdi
	pushq	%rsi
	pushq	%rbp
	movq	%rsp,	%rbp

	# original.size
	movq	8(%rsi),	%rdx
	# original.list
	movq	(%rsi),	%rsi

	# &ycomp = %rbp-8
	pushq	$0
	# &xcomp = %rbp-16
	pushq	$0

	movq	$0,	%rbx
	# sort + remove duplicates
compressCoordinates.xy:
	cmpq	$8,	%rbx
	ja	compressCoordinates.xy.after
	# below = ~0
	movq	$-1,	%r8
	# compressed_length = 0
	movq	$0,	%r9
	# while (true) {
compressCoordinates.loop:
	# local = 0
	movq	$0,	%r10
	# double_up = 0
	movq	$0,	%r11
	# for (j = 0; j < original.size; ++j) {
	movq	$0,	%r12
compressCoordinates.loop.inner:
	shl	$4,	%r12
	addq	%rbx,	%r12
	movq	(%rsi, %r12),	%rcx
	subq	%rbx,	%r12
	shr	$4,	%r12
	# if (original.list[j].x < below && original.list[j].x >= local) {
	cmpq	%rcx,	%r8
	jbe	compressCoordinates.loop.inner.postamble
	cmpq	%rcx,	%r10
	ja	compressCoordinates.loop.inner.postamble

	# local = original.list[j].x
	movq	%rcx,	%r10

	# jnext = j+1%original.size
	leaq	1(%r12),	%r13
	movq	$0,	%r15
	cmpq	%r13,	%rdx
	cmovaeq	%r15,	%r13

	movq	$0,	%r11
	shl	$4,	%r13
	addq	%rbx,	%r13
	movq	(%rsi, %r13),	%rax
	leaq	1(%rcx),	%r15
	# if (original.list[j].x + 1 < original.list[jnext].x) double_up = 1
	movq	$1,	%r14
	cmpq	%rax,	%r15
	cmovbq	%r14,	%r11
	leaq	-1(%rcx),	%r15
	# else if (original.list[j].x - 1 > original.list[jnext].x) double_up = -1
	movq	$-1,	%r14
	cmpq	%rax,	%r15
	cmovaq	%r14,	%r11
	# }
compressCoordinates.loop.inner.postamble:
	incq	%r12
	cmpq	%rdx,	%r12
	jl	compressCoordinates.loop.inner
	# }

	# if (local == 0) break
	cmpq	$0,	%r10
	je	compressCoordinates.loop.after

	# if (double_up == 1 && local+1 < below) {
	leaq	1(%r10),	%rcx
	cmpq	$1,	%r11
	jne	compressCoordinates.loop.noPositiveDoubleUp
	cmpq	%rcx,	%r8
	jbe	compressCoordinates.loop.noPositiveDoubleUp
	# push local+1
	pushq	%rcx
	# compressed_length++
	incq	%r9
	# }
compressCoordinates.loop.noPositiveDoubleUp:
	# below = local
	movq	%r10,	%r8
	# push	local
	pushq	%r10
	# compressed_length++
	incq	%r9

	# if (double_up == -1) {
	cmpq	$-1,	%r11
	jne	compressCoordinates.loop
	leaq	-1(%r10),	%rcx
	# push local-1
	pushq	%rcx
	# below = local-1
	movq	%rcx,	%r8
	# compressed_length++
	incq	%r9
	# }
	jmp	compressCoordinates.loop
	# }
compressCoordinates.loop.after:
	pushq	%r9
	movq	%rsp,	-16(%rbp, %rbx)
	addq	$8,	%rbx
	jmp	compressCoordinates.xy

compressCoordinates.xy.after:

	movq	%rdx,	%rdi
	shl	$4,	%rdi
	call	alloc
	addq	$8,	%rax

	movq	16(%rbp),	%rdi
	movq	8(%rbp),	%rsi

	movq	%rax,	(%rdi)
	movq	%rdx,	8(%rdi)
	movq	-16(%rbp),	%rax
	movq	(%rax),	%rax
	movq	%rax,	16(%rdi)

	movq	(%rdi),	%r9
	movq	(%rsi),	%r10
	# for (i = 0; i < original.size; ++i) {
	movq	$0,	%r8
compressCoordinates.fill:
	shl	$4,	%r8
	# new.list[i].x = findMapping(original.list[i].x, xcomp)
	movq	(%r10, %r8),	%rdi
	movq	-16(%rbp),	%rsi
	call	findMapping
	movq	%rax,	(%r9, %r8)
	# new.list[i].y = findMapping(original.list[i].y, ycomp)
	movq	8(%r10, %r8),	%rdi
	movq	-8(%rbp),	%rsi
	call	findMapping
	movq	%rax,	8(%r9, %r8)
	shr	$4,	%r8
	incq	%r8
	cmpq	%rdx,	%r8
	jl	compressCoordinates.fill
	# }

	movq	-8(%rbp),	%rax
	movq	(%rax),	%rax
	movq	-16(%rbp),	%rcx
	movq	(%rcx),	%rcx
	mulq	%rcx

	leave
	popq	%rsi
	popq	%rdi
	popq	%rbx
	popq	%rdx
	popq	%r15
	popq	%r14
	popq	%r13
	popq	%r12
	popq	%r11
	popq	%r10
	popq	%r9
	popq	%r8
	ret

# u64 findMapping(u64 value, u64* compressed)
# The value to find the mapping of is stored in %rdi
# The address of the list of compressed values is stored in %rsi
findMapping:
	movq	$0,	%rax
findMapping.loop:
	cmpq	8(%rsi, %rax, 8),	%rdi
	je	findMapping.after
	incq	%rax
	cmpq	(%rsi),	%rax
	jl	findMapping.loop
findMapping.after:
	ret

# void markBorder(u8* map, List* list, u64 width)
markBorder:
	pushq	%r8
	pushq	%r9
	pushq	%r10
	pushq	%r11
	pushq	%r12
	pushq	%r13
	pushq	%r14
	pushq	%r15

	movq	$0,	%r8
	# for (i = 0; i < list.size; ++i) {
markBorder.loop:
	# inext = (i+1) % list.size
	movq	$0,	%r15
	leaq	1(%r8),	%r9
	cmpq	8(%rsi),	%r9
	cmovae	%r15,	%r9

	# a = list.list[i]
	shl	$4,	%r8
	movq	(%rsi),	%r10
	addq	%r8,	%r10
	movq	(%r10),	%r11
	movq	8(%r10),	%r12
	shr	$4,	%r8
	# b = list.list[inext]
	shl	$4,	%r9
	movq	(%rsi),	%r13
	addq	%r9,	%r13

	# dir = b - a
	movq	(%r13),	%r14
	subq	%r11,	%r14
	movq	8(%r13),	%r15
	subq	%r12,	%r15

	# dir.x = (dir.x != 0) ? sign(dir.x) : 0
	# dir.y = (dir.y != 0) ? sign(dir.y) : 0
	movq	$1,	%r10
	cmpq	$0,	%r14
	cmovgq	%r10,	%r14
	cmpq	$0,	%r15
	cmovgq	%r10,	%r15

	movq	$-1,	%r10
	cmpq	$0,	%r14
	cmovlq	%r10,	%r14
	cmpq	$0,	%r15
	cmovlq	%r10,	%r15

	# while (a != b) {
markBorder.loop.inner:
	cmpq	(%r13),	%r11
	jne	markBorder.loop.inner.body
	cmpq	8(%r13),	%r12
	je	markBorder.loop.inner.after
markBorder.loop.inner.body:
	# map[a.y * width + a.x] = 2
	pushq	%rdx
	movq	%r12,	%rax
	mulq	%rdx
	popq	%rdx
	addq	%r11,	%rax
	movb	$2,	(%rdi, %rax)

	# a += dir
	addq	%r14,	%r11
	addq	%r15,	%r12
	jmp	markBorder.loop.inner
	# }
markBorder.loop.inner.after:
	incq	%r8
	cmpq	8(%rsi),	%r8
	jl	markBorder.loop
	# }

	popq	%r15
	popq	%r14
	popq	%r13
	popq	%r12
	popq	%r11
	popq	%r10
	popq	%r9
	popq	%r8
	ret

# void floodFill(u8* map, u64 width, u64 height)
floodFill:
	pushq	%r8
	pushq	%r9
	pushq	%r10
	pushq	%r11
	pushq	%r12
	pushq	%r13
	pushq	%r14
	pushq	%r15
	pushq	%rdi
	pushq	%rsi
	pushq	%rdx
	pushq	%rbp
	movq	%rsp,	%rbp
	# add initial points to the stack

	# for (i = 0; i < height; ++i) {
	movq	$0,	%r8
floodFill.initHeight:
	# push (i, 0)
	pushq	%r8
	pushq	$0

	# push (i, width-1)
	pushq	%r8
	leaq	-1(%rsi),	%rcx
	pushq	%rcx

	incq	%r8
	cmpq	%rdx,	%r8
	jl	floodFill.initHeight
	# }

	# for (j = 0; j < width; ++j) {
	movq	$0,	%r8
floodFill.initWidth:
	# push (0, j)
	pushq	$0
	pushq	%r8

	# push (height-1, j)
	leaq	-1(%rdx),	%rcx
	pushq	%rcx
	pushq	%r8

	incq	%r8
	cmpq	%rsi,	%r8
	jl	floodFill.initWidth
	# }

	# do {
floodFill.loop:
	# pop (i, j)
	# j
	popq	%r13
	# i
	popq	%r12

	# if (map[i*width + j]) continue
	movq	%r12,	%rax
	pushq	%rdx
	mulq	%rsi
	popq	%rdx
	addq	%r13,	%rax
	cmpb	$0,	(%rdi, %rax)
	jne	floodFill.loop.postamble
	movb	$1,	(%rdi, %rax)
	# if (i > 0) push (i-1, j)
	cmpq	$0,	%r12
	jbe	floodFill.loop.first
	leaq	-1(%r12),	%rcx
	pushq	%rcx
	pushq	%r13
floodFill.loop.first:
	# if (i < height-1) push (i+1, j)
	leaq	-1(%rdx),	%rcx
	cmpq	%rcx,	%r12
	jae	floodFill.loop.second
	leaq	1(%r12),	%rcx
	pushq	%rcx
	pushq	%r13
floodFill.loop.second:
	# if (j > 0) push (i, j-1)
	cmpq	$0,	%r13
	jbe	floodFill.loop.third
	pushq	%r12
	leaq	-1(%r13),	%rcx
	pushq	%rcx
floodFill.loop.third:
	# if (j < width-1) push (i, j+1)
	leaq	-1(%rsi),	%rcx
	cmpq	%rcx,	%r13
	jae	floodFill.loop.postamble
	pushq	%r12
	leaq	1(%r13),	%rcx
	pushq	%rcx
floodFill.loop.postamble:
	cmpq	%rsp,	%rbp
	jne	floodFill.loop
	# } while (%rbp != %rsp)

	leave
	popq	%rdx
	popq	%rsi
	popq	%rdi
	popq	%r15
	popq	%r14
	popq	%r13
	popq	%r12
	popq	%r11
	popq	%r10
	popq	%r9
	popq	%r8
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
	# &pt2 = %rbp-40
	pushq	$0

	# compress coordinates
	# &compressed = %rbp-64
	subq	$24,	%rsp
	movq	%rsp,	%rdi
	leaq	-24(%rbp),	%rsi
	call	compressCoordinates

	# allocate map
	movq	%rax,	%r15
	movq	%rax,	%rdi
	call	alloc
	addq	$8,	%rax
	# &map = %rbp-72
	pushq	%rax
	# mark polygon border
	movq	-72(%rbp),	%rdi
	leaq	-64(%rbp),	%rsi
	movq	-48(%rbp),	%rdx
	call	markBorder
	# flood fill
	movq	-72(%rbp),	%rdi
	movq	-48(%rbp),	%rsi
	movq	%r15,	%rax
	movq	$0,	%rdx
	divq	%rsi
	movq	%rax,	%rdx
	call	floodFill
	# compute 2d prefix sum (but ignore the 2s in the map)
	# in the loop check if a given rectangle includes invalid points
	# maybe use a prefix matrix

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
