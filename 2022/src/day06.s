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

# The input string is passed in %rdi
# The length of the string passed in %rsi
# The length of the unique sequence is passed in %rdx
# The number of read characters before a set of N unique characters was found is returned in %rax
findMarker:
	pushq	%rbx
	pushq	%rcx
	pushq	%rbp
	movq	%rsp,	%rbp
	# u8 lut[26] = {0}
	subq	$26,	%rsp

	# i = 0
	movq	$0,	%rcx
	# do {
findMarker.memset:
	# lut[i] = 0
	movq	$0,	(%rsp,	%rcx)
	# i++
	incq	%rcx
	# } while (i < 26);
	cmpq	$26,	%rcx
	jl	findMarker.memset

	# i = 0
	movq	$0,	%rcx
	# do {
findMarker.preamble:
	# lut[str[i] - 97] += 1
	movzbq	(%rdi, %rcx),	%rax
	incq	-97(%rsp, %rax)
	# i++
	incq	%rcx
	# } while (i < N);
	cmpq	%rdx,	%rcx
	jl	findMarker.preamble

	# do {
findMarker.loop:
	# check for duplicates in current window
	# j = 0
	movq	$0,	%rbx
	# do {
findMarker.loop.check:
	# if (lut[j] >= 2) break;
	movzbq	(%rsp, %rbx),	%rax
	cmpq	$2,	%rax
	jge	findMarker.loop.body
	# j++
	incq	%rbx
	# } while (j < 26);
	cmpq	$26,	%rbx
	jl	findMarker.loop.check
	jmp	findMarker.postamble
findMarker.loop.body:
	# lut[str[i] - 97] += 1
	movzbq	(%rdi, %rcx),	%rax
	incq	-97(%rsp, %rax)

	# lut[str[i-N] - 97] -= 1
	subq	%rdx,	%rcx
	movzbq	(%rdi, %rcx),	%rax
	decq	-97(%rsp, %rax)
	addq	%rdx,	%rcx

	# i++
	incq	%rcx
	# } while (i < len);
	cmpq	%rsi,	%rcx
	jl	findMarker.loop

findMarker.postamble:
	movq	%rcx,	%rax
	leave
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
	movq	0x30(%rsp),	%rsi
	movq	$4,	%rdx
	call findMarker
	
	pushq	%rdi
	movq	%rax,	%rdi
	call printNumber
	popq	%rdi
	movq	0x30(%rsp),	%rsi
	movq	$14,	%rdx
	call findMarker
	
	movq	%rax,	%rdi
	call printNumber

	mov $60, %rax
	mov $0, %rdi
	syscall
