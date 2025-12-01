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

# void visibility(u64* out, u8* map, u64 w, u64 h*w, u64 x, u64 y*w)
# void visibility(%rdi, %rsi, %rdx, %rcx, %r8, %r9)
visibility:
	pushq	%rax
	pushq	%rbx
	pushq	%rcx
	pushq	%rdx
	pushq	%r8
	pushq	%r9
	pushq	%rbp
	movq	%rsp,	%rbp

	# &w = %rbp-8
	pushq	%rdx
	# &(h*w) = %rbp-16
	pushq	%rcx
	# end = x (%rbp-24)
	pushq	%r8
	# inc = 1 (%rbp-32)
	pushq	$1

	# j = 0
	movq	$0,	%rbx
	# %rax = y*w
	movq	%r9,	%rax
	# x
	movq	%r8,	%rdx
	# map[y*w + x]
	leaq	(%rax, %rdx),	%rcx
	movzbq	(%rsi, %rcx),	%r9
	# next = east
	movq	$visibility.loop.west.post,	%r8
	jmp	visibility.loop

visibility.loop.west.post:
	# end = w
	movq	-8(%rbp),	%rbx
	movq	%rbx,	-24(%rbp)
	# j = x+1
	leaq	1(%rdx),	%rbx
	# next = north
	movq	$visibility.loop.east.post,	%r8
	jmp	visibility.loop

visibility.loop.east.post:
	# end = y*w
	movq	%rax,	-24(%rbp)
	# inc = w
	movq	-8(%rbp),	%rbx
	movq	%rbx,	-32(%rbp)
	# i = 0
	movq	$0,	%rbx
	# %rax = x
	movq	%rdx,	%rax
	# next = south
	movq	$visibility.loop.north.post,	%r8
	jmp	visibility.loop

visibility.loop.north.post:
	pushq	-24(%rbp)
	# end = h*w
	movq	-16(%rbp),	%rbx
	movq	%rbx,	-24(%rbp)
	# i = (y+1)*w
	popq	%rbx
	addq	-8(%rbp),	%rbx
	# next = finish
	movq	$visibility.ret,	%r8
	jmp	visibility.loop

	# while (j < end) {
	# while (i < end) {
visibility.loop:
	cmpq	-24(%rbp),	%rbx
	jge	visibility.success
	# if (map[y*w + j] >= map[y*w + x]) break
	# if (map[i*w + x] >= map[y*w + x]) break
	leaq	(%rax, %rbx),	%rcx
	cmpb	(%rsi, %rcx),	%r9b
	jg	visibility.loop.noBreak
	# jump to west.post if next dir is east
	# jump to east.post if next dir is north
	# jump to north.post if next dir is south
	# jump to ret if next dir is finish
	jmpq	*%r8
visibility.loop.noBreak:
	# j++
	# i+=w
	addq	-32(%rbp),	%rbx
	jmp	visibility.loop
	# } else {
visibility.success:
	# *out += 1
	incq	(%rdi)
	# return
	# }
visibility.ret:
	addq	$32,	%rsp
	leave
	popq	%r9
	popq	%r8
	popq	%rdx
	popq	%rcx
	popq	%rbx
	popq	%rax
	ret

# void scenicScore(u64* out, u8* map, u64 w, u64 h*w, u64 x, u64 y*w)
# void scenicScore(%rdi, %rsi, %rdx, %rcx, %r8, %r9)
scenicScore:
	pushq	%rax
	pushq	%rbx
	pushq	%rcx
	pushq	%rdx
	pushq	%r8
	pushq	%r9
	pushq	%r10
	pushq	%rbp
	movq	%rsp,	%rbp

	# &w = %rbp-8
	pushq	%rdx
	# &(h*w) = %rbp-16
	pushq	%rcx
	# end = -1 (%rbp-24)
	pushq	$-1
	# inc = 1 (%rbp-32)
	pushq	$-1
	# &(y*w) = %rbp-40
	pushq	%r9

	# count = 0
	movq	$0,	%r10
	# j = x-1
	leaq	-1(%r8),	%rbx
	# %rax = y*w
	movq	%r9,	%rax
	# x
	movq	%r8,	%rdx
	# map[y*w + x]
	leaq	(%rax, %rdx),	%rcx
	movzbq	(%rsi, %rcx),	%r9
	# next = east
	movq	$scenicScore.loop.west.post,	%r8
	jmp	scenicScore.loop

scenicScore.loop.west.post:
	# end = w
	movq	-8(%rbp),	%rbx
	movq	%rbx,	-24(%rbp)
	# inc = 1
	movq	$1,	-32(%rbp)
	# j = x+1
	leaq	1(%rdx),	%rbx
	# next = north
	movq	$scenicScore.loop.east.post,	%r8
	jmp	scenicScore.loop

scenicScore.loop.east.post:
	# inc = -w
	pushq	%rax
	pushq	%rdx

	movq	-8(%rbp),	%rax
	imulq	$-1,	%rax
	movq	%rax,	-32(%rbp)
	# end = -w
	movq	%rax,	-24(%rbp)

	popq	%rdx
	popq	%rax
	# i = (y-1)*w
	movq	-40(%rbp),	%rbx
	subq	-8(%rbp),	%rbx
	# %rax = x
	movq	%rdx,	%rax
	# next = south
	movq	$scenicScore.loop.north.post,	%r8
	jmp	scenicScore.loop

scenicScore.loop.north.post:
	# end = h*w
	movq	-16(%rbp),	%rbx
	movq	%rbx,	-24(%rbp)
	# inc = w
	movq	-8(%rbp),	%rbx
	movq	%rbx,	-32(%rbp)
	# i = (y+1)*w
	movq	-40(%rbp),	%rbx
	addq	-8(%rbp),	%rbx
	# next = finish
	movq	$scenicScore.ret,	%r8
	jmp	scenicScore.loop

	# while (j != end) {
	# while (i != end) {
scenicScore.loop:
	cmpq	-24(%rbp),	%rbx
	je	scenicScore.next
	# count++
	incq	%r10
	# if (map[y*w + j] >= map[y*w + x]) break
	# if (map[i*w + x] >= map[y*w + x]) break
	leaq	(%rax, %rbx),	%rcx
	cmpb	(%rsi, %rcx),	%r9b
	jle	scenicScore.next
scenicScore.loop.noBreak:
	# j++
	# i+=w
	addq	-32(%rbp),	%rbx
	jmp	scenicScore.loop
	# }
scenicScore.next:
	# *out *= count
	pushq	%rax
	pushq	%rdx

	movq	(%rdi),	%rax
	mulq	%r10
	movq	%rax,	(%rdi)

	popq	%rdx
	popq	%rax
	# count = 0
	movq	$0,	%r10
	# jump to next
	jmpq	*%r8

scenicScore.ret:
	addq	$40,	%rsp
	leave
	popq	%r10
	popq	%r9
	popq	%r8
	popq	%rdx
	popq	%rcx
	popq	%rbx
	popq	%rax
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

	popq	%rdi

	# find width of map
	movq	$1,	%rcx
	# do {
findWidth.loop:
	# w++
	incq	%rcx
	# } while (str[w-1] != '\n');
	cmpb	$0xA,	-1(%rdi, %rcx)
	jne	findWidth.loop

	movq	0x30(%rsp),	%rax
	movq	$0,	%rdx
	# %rax = h
	divq	%rcx
	# %rcx = w
	decq	%rcx
	
	movq	$0,	%rdx
	mulq	%rcx
	# %rdx = w*h
	movq	%rax,	%rdx

	pushq	%rcx
	# allocate map
	movq	%rdi,	%rsi
	movq	%rax,	%rdi
	# %rax = map
	call	alloc
	popq	%rcx

	movq	%rax,	%rdi

	# i = 0
	movq	$0,	%r8
	# do {
fillMap.loop:
	# if (str[i] == '\n') n++
	cmpb	$0xA,	(%rsi, %r8)
	jne	fillMap.loop.noNewline
	decq	%rax
	jmp	fillMap.loop.postamble
fillMap.loop.noNewline:
	# else map[i-n] = str[i]
	movb	(%rsi, %r8),	%bl
	subb	$0x30,	%bl
	movb	%bl,	(%rax, %r8)
fillMap.loop.postamble:
	incq	%r8
	# } while (i < filesize);
	cmpq	0x30(%rsp),	%r8
	jl	fillMap.loop

	# %rsi = map
	movq	%rdi,	%rsi
	# swap %rcx and %rdx => %rdx = w, %rcx = h*w
	xorq	%rcx,	%rdx
	xorq	%rdx,	%rcx
	xorq	%rcx,	%rdx

	# x = 0
	movq	$0,	%r8
	# y*w = 0
	movq	$0,	%r9

	pushq	$1
	pushq	$1
	pushq	$0
	movq	%rsp,	%rdi

	# do {
map.loop:
	movq	$0,	%r8
	# do {
map.loop.inner:
	movq	%rsp,	%rdi
	pushq	%rsi
	pushq	%rdx
	pushq	%rcx
	pushq	%r8
	pushq	%r9
	call	visibility
	popq	%r9
	popq	%r8
	popq	%rcx
	popq	%rdx
	popq	%rsi

	leaq	8(%rsp),	%rdi
	pushq	%rsi
	pushq	%rdx
	pushq	%rcx
	pushq	%r8
	pushq	%r9
	call	scenicScore
	popq	%r9
	popq	%r8
	popq	%rcx
	popq	%rdx
	popq	%rsi

tmp:
	# scenic = max(scenic, current)
	movq	8(%rsp),	%rdi
	cmpq	16(%rsp),	%rdi
	cmovlq	16(%rsp),	%rdi
	movq	%rdi,	16(%rsp)
	movq	$1,	8(%rsp)

	# x++
	incq	%r8
	cmpq	%rdx,	%r8
	jl	map.loop.inner
	# } while (x < w);
	# y++
	addq	%rdx,	%r9
	cmpq	%rcx,	%r9
	jl	map.loop
	# } while (w*y < w*h);

	popq	%rdi
	call	printNumber
	popq	%rdi
	popq	%rdi
	call	printNumber

	mov $60, %rax
	mov $0, %rdi
	syscall
