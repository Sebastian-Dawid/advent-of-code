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

.globl	_start
.extern alloc
.extern printNumber
.extern parseNumber
.extern	numberOfDigits
.extern	power

# The number to check is given in %rdi
# The same number is returned in %rax if
# it consists of duplicates otherwise 0
# will be stored in %rax
consistsOfDuplicates:
	pushq	%rbx
	pushq	%rcx
	pushq	%rdx
	pushq	%rdi
	pushq	%rsi
	pushq	%rbp
	movq	%rsp,	%rbp

	# determine digits/2
	call	numberOfDigits
	# &digits = %rbp-8
	pushq	%rax
	movq	$0,	%rdx
	movq	$2,	%rcx
	divq	%rcx
	# &(digits/2) = %rbp-16
	pushq	%rax

	# i = 1
	movq	$1,	%rsi

	# while (i <= digits/2) {
consistsOfDuplicates.loop:
	cmpq	-16(%rbp),	%rsi
	jg	consistsOfDuplicates.loop.foundNothing

	# if (digits % i != 0) continue
	movq	-8(%rbp),	%rax
	movq	$0,	%rdx
	divq	%rsi
	cmpq	$0,	%rdx
	jne	consistsOfDuplicates.loop.postamble

	# p = 10^i
	movq	$10,	%rdi
	call	power
	movq	%rax,	%rbx

	# base = N % p
	# M = N / p
	movq	16(%rbp),	%rax
	movq	$0,	%rdx
	divq	%rbx
	movq	%rdx,	%rcx

	# while (M > 0) {
consistsOfDuplicates.loop.inner:
	cmpq	$0,	%rax
	jle	consistsOfDuplicates.loop.inner.else
	# current = M % p
	# M = M / p
	movq	$0,	%rdx
	divq	%rbx
	# if (current != base) break;
	cmpq	%rcx,	%rdx
	jne	consistsOfDuplicates.loop.postamble
	jmp	consistsOfDuplicates.loop.inner
	# } else {
consistsOfDuplicates.loop.inner.else:
	# return N
	movq	16(%rbp),	%rax
	jmp	consistsOfDuplicates.postamble
	# }
consistsOfDuplicates.loop.postamble:
	# i++
	incq	%rsi
	jmp	consistsOfDuplicates.loop
	# }

consistsOfDuplicates.loop.foundNothing:
	# return 0
	movq	$0,	%rax
consistsOfDuplicates.postamble:
	leave
	popq	%rsi
	popq	%rdi
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

	# Save pointer to file contents on the stack
	pushq	%rbp
	movq	%rsp,	%rbp

	# &filesize = %rbp+0x38
	# file = %rbp-8
	pushq	%rax

	movq	$SYS_CLOSE,	%rax
	movq	%r8,	%rdi
	syscall

	# Make space for the number of bytes read by parseNumber
	# &count = %rbp-16
	pushq	$0

	# i = 0
	# &i = %rbp-24
	pushq	$0

	# &start = %rbp-32
	pushq	$0
	# &end = %rbp-40
	pushq	$0

	# &result = %rbp-48
	pushq	$0

	# &result2 = %rbp-56
	pushq	$0

	# do {
loop:
	movq	-8(%rbp),	%rdi
	addq	-24(%rbp),	%rdi
	movq	$45,	%rsi
	leaq	-16(%rbp),	%rdx
	call	parseNumber
	movq	%rax,	-32(%rbp)
	# i += count
	movq	-16(%rbp),	%rcx
	addq	%rcx,	-24(%rbp)

	movq	-8(%rbp),	%rdi
	addq	-24(%rbp),	%rdi
	movq	$45,	%rsi
	leaq	-16(%rbp),	%rdx
	call	parseNumber
	movq	%rax,	-40(%rbp)
	# i += count
	movq	-16(%rbp),	%rcx
	addq	%rcx,	-24(%rbp)

	# current = start
	movq	-32(%rbp),	%rbx
	# while (current <= end) {
loop.inner:
	cmpq	-40(%rbp),	%rbx
	jg	loop.postamble

	movq	%rbx,	%rdi
	call	consistsOfDuplicates
	addq	%rax,	-56(%rbp)

	# digits = numberOfDigits(current)
	movq	%rbx,	%rdi
	call numberOfDigits
	
	# digits = digits/2
	movq	$0,	%rdx
	movq	$2,	%rcx
	divq	%rcx

	# if (rem != 0) continue;
	cmpq	$0,	%rdx
	jne	loop.inner.postamble

	# divisor = 10^digits
	movq	$10,	%rdi
	movq	%rax,	%rsi
	call	power
	movq	%rax,	%rcx

	# current = p*10^digits + q
	movq	%rbx,	%rax
	movq	$0,	%rdx
	divq	%rcx

	# if (p == q) result++
	cmpq	%rax,	%rdx
	jne	loop.inner.postamble
	addq	%rbx,	-48(%rbp)

loop.inner.postamble:
	# current++
	incq	%rbx
	# }
	jmp	loop.inner

loop.postamble:
	movq	-24(%rbp),	%rcx
	# } while (i < filesize);
	cmpq	0x38(%rbp),	%rcx
	jl	loop

	movq	-48(%rbp),	%rdi
	call	printNumber
	movq	-56(%rbp),	%rdi
	call	printNumber

	mov $60, %rax
	mov $0, %rdi
	syscall
