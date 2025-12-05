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

	mov $60, %rax
	mov $0, %rdi
	syscall
