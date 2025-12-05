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

# The address of the list of ranges is stored in %rdi
# The number of ranges is stored in %rsi
# The number to check is stored in %rdx
# %rax is set to 1 in case it is included and 0 if it is not
inRanges:
	pushq	%rsi
	# result = 0
	movq	$0,	%rax
	# i = 0
	movq	$0,	%rcx
	
	addq	%rsi,	%rsi

	# do {
inRanges.loop:
	# if (lo <= n <= hi) return 1
	cmpq	(%rdi, %rcx, 8),	%rdx
	jl	inRanges.loop.postamble
	cmpq	8(%rdi, %rcx, 8),	%rdx
	jg	inRanges.loop.postamble
	movq	$1,	%rax
	jmp	inRanges.postamble
inRanges.loop.postamble:
	addq	$2,	%rcx
	cmpq	%rsi,	%rcx
	jl	inRanges.loop
	# } while (i < range_count);

inRanges.postamble:
	popq	%rsi
	ret

# The address of the list of ranges is stored in %rdi
# The number of ragnes is stored in %rsi
# The total number of elements included in the ranges is returned in %rax
rangesTotalSize:
	pushq	%rbx
	pushq	%rcx
	pushq	%rdx
	pushq	%rsi
	
	addq	%rsi,	%rsi

	# how many ranges did we merge this iteration
	pushq	$0
	# repeat until no ranges were merged
rangesTotalSize.repeat:
	movq	$0,	(%rsp)
	movq	$0,	%rcx
	# for (i = 0; i < count; ++i) {
rangesTotalSize.loop:
	movq	$0,	%rbx
	# if (lo[i] == hi[i] == 0) continue
	cmpq	$0,	(%rdi, %rcx, 8)
	je	rangesTotalSize.loop.postamble
	cmpq	$0,	8(%rdi, %rcx, 8)
	je	rangesTotalSize.loop.postamble
	# for (j = 0; j < count; ++j) {
rangesTotalSize.loop.inner:
	# if (i == j) continue
	cmpq	%rcx,	%rbx
	je	rangesTotalSize.loop.inner.postamble
	
	# rem = 0
	movq	$0,	%rax
	# if (lo[i] >= lo[j] && lo[i] <= hi[j]) {
	movq	8(%rdi, %rbx, 8),	%rdx
	cmpq	(%rdi, %rcx, 8),	%rdx
	jl	rangesTotalSize.loop.inner.pt1
	movq	(%rdi, %rbx, 8),	%rdx
	cmpq	(%rdi, %rcx, 8),	%rdx
	jg	rangesTotalSize.loop.inner.pt1
	# lo[i] = lo[j]
	movq	%rdx,	(%rdi, %rcx, 8)
	# rem = true
	movq	$1,	%rax
	# }

rangesTotalSize.loop.inner.pt1:
	# if (hi[i] >= lo[j] && hi[i] <= hi[j]) {
	movq	(%rdi, %rbx, 8),	%rdx
	cmpq	8(%rdi, %rcx, 8),	%rdx
	jg	rangesTotalSize.loop.inner.pt2
	movq	8(%rdi, %rbx, 8),	%rdx
	cmpq	8(%rdi, %rcx, 8),	%rdx
	jl	rangesTotalSize.loop.inner.pt2
	# hi[i] = hi[j]
	movq	%rdx,	8(%rdi, %rcx, 8)
	# rem = true
	movq	$1,	%rax
	# }

rangesTotalSize.loop.inner.pt2:
	# if (rem) lo[j] = hi[j] = 0
	cmpq	$0,	%rax
	je	rangesTotalSize.loop.inner.postamble
	
	incq	(%rsp)
	movq	$0,	(%rdi, %rbx, 8)
	movq	$0,	8(%rdi, %rbx, 8)

rangesTotalSize.loop.inner.postamble:
	addq	$2,	%rbx
	cmpq	%rsi,	%rbx
	jl	rangesTotalSize.loop.inner
	# }
rangesTotalSize.loop.postamble:
	addq	$2,	%rcx
	cmpq	%rsi,	%rcx
	jl	rangesTotalSize.loop
	# }
	cmpq	$0,	(%rsp)
	jne	rangesTotalSize.repeat
	
	movq	$0,	%rax
	movq	$0,	%rcx
	# for (i = 0; i < count; ++i) {
rangesTotalSize.count:
	# if (lo[i] == hi[i] == 0) continue
	cmpq	$0,	(%rdi, %rcx, 8)
	je	rangesTotalSize.count.postamble
	cmpq	$0,	8(%rdi, %rcx, 8)
	je	rangesTotalSize.count.postamble
rangesTotalSize.count.body:
	# result += hi[i] - lo[i] + 1
	addq	8(%rdi, %rcx, 8),	%rax
	subq	(%rdi, %rcx, 8),	%rax
	incq	%rax
rangesTotalSize.count.postamble:
	addq	$2,	%rcx
	cmpq	%rsi,	%rcx
	jl	rangesTotalSize.count
	# }

	addq	$8,	%rsp
	popq	%rsi
	popq	%rdx
	popq	%rcx
	popq	%rbx
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
	
	# &count = %rbp-16
	pushq	$0
	# &i = %rbp-24
	pushq	$0
	
	# &range_count = %rbp-32
	pushq	$0

	# &pt1 = %rbp-40
	pushq	$0

	# just push ranges to the stack in backwards order (first range has the highest address)
	# do {
readRanges:
	# n1 = parseNumber(&file + i, '-', &count);
	movq	-8(%rbp),	%rdi
	addq	-24(%rbp),	%rdi
	movq	$45,	%rsi
	leaq	-16(%rbp),	%rdx
	call	parseNumber
	# i += count
	movq	-16(%rbp),	%rcx
	addq	%rcx,	-24(%rbp)
	# if (n1 == -1) break;
	cmp	$-1,	%rax
	je	readRanges.after
	movq	%rax,	%rbx
	# n2 = parseNumber(&file + i, '\n', &count);
	movq	-8(%rbp),	%rdi
	addq	-24(%rbp),	%rdi
	movq	$10,	%rsi
	leaq	-16(%rbp),	%rdx
	call	parseNumber
	# i += count
	movq	-16(%rbp),	%rcx
	addq	%rcx,	-24(%rbp)
	# add range 
	pushq	%rax
	pushq	%rbx

	# range_count++
	incq	-32(%rbp)
	jmp	readRanges
	# } while (true);
readRanges.after:

	# do {
checkRanges:
	# n = parseNumber(&file + i, '\n', &count)
	movq	-8(%rbp),	%rdi
	addq	-24(%rbp),	%rdi
	movq	$10,	%rsi
	leaq	-16(%rbp),	%rdx
	call	parseNumber
	# i += count
	movq	-16(%rbp),	%rcx
	addq	%rcx,	-24(%rbp)

	# pt1 += inRanges(ranges, range_count, n);
	movq	%rsp,	%rdi
	movq	-32(%rbp),	%rsi
	movq	%rax,	%rdx
	call	inRanges

	addq	%rax,	-40(%rbp)

	movq	-24(%rbp),	%rcx
	cmpq	0x38(%rbp),	%rcx
	jl	checkRanges
	# } while (i < filesize);

	movq	-40(%rbp),	%rdi
	call	printNumber

	movq	%rsp,	%rdi
	movq	-32(%rbp),	%rsi
	call	rangesTotalSize

	movq	%rax,	%rdi
	call	printNumber

	mov $60, %rax
	mov $0, %rdi
	syscall
