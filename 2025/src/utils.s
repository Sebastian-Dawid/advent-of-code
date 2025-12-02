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

.globl	power
.globl	numberOfDigits
.globl	modulo
.globl	alloc
.globl	printNumber
.globl	parseNumber

# Compute %rdi^%rsi
# Note that %rsi is assumed to be unsigned.
# The result is stored in %rax
power:
	pushq	%rdi
	pushq	%rsi

	movq	$1,	%rax

power.loop:
	test	$0x1,	%rsi
	je	power.loop.noSquare
	imulq	%rdi
power.loop.noSquare:
	shr	$1,	%rsi

	cmpq	$0,	%rsi
	je	power.postamble

	pushq	%rax
	movq	%rdi,	%rax
	mulq	%rdi
	movq	%rax,	%rdi
	popq	%rax
	jmp	power.loop

power.postamble:
	popq	%rsi
	popq	%rdi
	ret

# The number is passed in %rdi
# The number of digits is stored in %rax
numberOfDigits:
	pushq	%rdi
	pushq	%rcx
	pushq	%rdx

	movq	%rdi,	%rax
	movq	$0,	%rdi
	movq	$10,	%rcx

numberOfDigits.loop:
	movq	$0,	%rdx
	divq	%rcx
	incq	%rdi
	cmpq	$0,	%rax
	jg	numberOfDigits.loop
	
	movq	%rdi,	%rax

	popq	%rdx
	popq	%rcx
	popq	%rdi
	ret

# Compute %rdi mod %rsi
# The result is stored in %rax
modulo:
	pushq	%rdi
	pushq	%rsi
	pushq	%rdx

	movq	%rdi,	%rax
	cqto
	idivq	%rsi

	cmpq	$0,	%rdx
	jge	modulo.positive

	addq	%rsi,	%rdx

modulo.positive:
	movq	%rdx,	%rax
	popq	%rdx
	popq	%rsi
	popq	%rdi
	ret
	

# Allocate %rdi bytes.
# The address of the allocation is returned in %rax.
# The first 8 bytes of the allocation store its size-8
alloc:
	pushq	%rdi
	pushq	%rsi
	pushq	%rdx
	pushq	%r10
	pushq	%r8
	pushq	%r9

	movq	$SYS_MMAP,	%rax
	# size
	movq	%rdi,	%rsi
	addq	$8,	%rsi
	# addr
	movq	$0,	%rdi
	# PROT_READ | PROT_WRITE
	movq	$3,	%rdx
	# MAP_PRIVATE | MAP_ANONYMOUS
	movq	$34,	%r10
	# No filedescriptor
	movq	$-1,	%r8
	# offset 0
	movq	$0,	%r9
	syscall

	subq	$8,	%rsi
	movq	%rsi,	(%rax)

	movq	$0,	%rdi
alloc.loop.zero:
	movb	$0,	8(%rax, %rdi)
	incq	%rdi
	cmpq	%rsi,	%rdi
	jne	alloc.loop.zero

	popq	%r9
	popq	%r8
	popq	%r10
	popq	%rdx
	popq	%rsi
	popq	%rdi
	ret

# Print the number stored in %rdi to STDOUT
# %rax and %rdx are clobbered
printNumber:
	# NOTE: divq performs an unsigned integer division where
	#       where %rax stores the result and %rdx stored the
	#       remainder

	pushq	%rcx
	pushq	%rbx

	pushq	%rbp
	movq	%rsp,	%rbp

	# uint8_t count = 0;
	movq	$1,	%rcx
	# value = %rdi
	movq	%rdi,	%rax

	# Add a newline to the end of the string
	subq	$8,	%rsp
	movq	$0xA,	(%rsp)

	# do {
printNumber.loop:
	# value / 10 = 10 * result + remainder
	movq	$0,	%rdx
	divq	-8(%rbp)
	
	# Append a character to the front of the string
	subq	$1,	%rsp

	# Translate remainder to ASCII and store in string
	addb	$0x30,	%dl
	movb	%dl,	(%rsp)
	incq	%rcx

	# } while (result > 0);
	cmp	$0,	%rax
	jnz	printNumber.loop

	# Write the string stored on the stack to STDOUT
	movq	%rsp,		%rsi
	movq	%rcx,		%rdx
	movq	$SYS_WRITE,	%rax
	movq	$STDOUT,	%rdi
	syscall

	leave
	popq	%rbx
	popq	%rcx
	ret

# Parse the number in the string at %rdi
# The termination character is stored in %rsi
# A pointer to where to store the number of read characters is stored in %rdx.
# The stored number of characters includes the termination character.
# The parsed number is written to %rax
# If the given string is not a number %rax will be set to ~0
parseNumber:
	pushq	%rbp
	movq	%rsp,	%rbp
	subq	$8,	%rsp
	movq	$10,	(%rsp)

	pushq	%rbx
	pushq	%rcx
	
	# i = 0
	movq	$0,	%rcx
	# while (str[i] != terminator) {
parseNumber.count.loop:
	cmpb	(%rdi, %rcx),	%sil
	je	parseNumber.count.loopEnd
	cmpb	$0x30,	(%rdi, %rcx)
	jl	parseNumber.count.loopEnd
	cmpb	$0x39,	(%rdi, %rcx)
	jg	parseNumber.count.loopEnd
	# i++
	incq	%rcx
	jmp	parseNumber.count.loop
	# }
parseNumber.count.loopEnd:
	# count = i+1
	leaq	1(%rcx),	%rbx
	movq	%rbx,	(%rdx)

	# if (i == 0) {
	cmp	$0,	%rcx
	jne	parseNumber.count.valid
	# return ~0
	notq	%rcx
	jmp	parseNumber.postamble
	# }
parseNumber.count.valid:
	# i = len
	movq	%rcx,	%rsi
	# result = 0
	movq	$0,	%rcx
	# digit = 1
	movq	$1,	%rax
	# do {
parseNumber.parse:
	# i--
	decq	%rsi
	# val = str[i] - 0x30
	movzbq	(%rdi, %rsi),	%rbx
	subb	$0x30,	%bl
	# result += digit * val
	imulq	%rax,	%rbx
	addq	%rbx,	%rcx
	# digit *= 10
	mulq	-8(%rbp)
	# } while(i > 0);
	cmp	$0,	%rsi
	jne	parseNumber.parse
parseNumber.postamble:
	movq	%rcx,	%rax
	popq	%rcx
	popq	%rbx
	leave
	ret
