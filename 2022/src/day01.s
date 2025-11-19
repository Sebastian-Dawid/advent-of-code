.section .data

.equ SYS_READ,	0
.equ SYS_WRITE,	1
.equ SYS_OPEN,	2
.equ SYS_CLOSE,	3
.equ SYS_FSTAT,	5
.equ SYS_MMAP,	9
.equ SYS_EXIT,	60

.equ STDOUT,	1

.section .text
.globl _start

# Print the number stored in %rax to STDOUT
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
	movq	$10,	%rbx

	# Add a newline to the end of the string
	subq	$1,	%rsp
	movb	$0xA,	(%rsp)

	# do {
printNumber.loop:
	# value / 10 = 10 * result + remainder
	movq	$0,	%rdx
	divq	%rbx
	
	# Append a character to the front of the string
	subq	$1,	%rsp

	# Translate remainder to ASCII and store in string
	add	$0x30,	%dl
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

# Parse the number in the string at %rsi
# The number of digits in the number is given in %rdi
# The parsed number is written to %rax
parseNumber:
	pushq	%rbp
	movq	%rsp,	%rbp
	subq	$8,	%rsp
	movq	$10,	(%rsp)

	pushq	%rbx
	pushq	%rcx
	pushq	%rdx

	
	movq	$1,	%rcx
	movq	$1,	%rax
parseNumber.initialPower:
	mulq	-8(%rbp)
	incq	%rcx
	cmp	%rcx,	%rdi
	jne	parseNumber.initialPower

	movq	$0,	%rdx
	movq	$0,	%rcx
parseNumber.parse:
	movzbq	(%rsi),	%rbx
	subb	$0x30,	%bl
	imulq	%rax,	%rbx
	addq	%rbx,	%rcx
	divq	-8(%rbp)
	incq	%rsi
	cmp	$0,	%rax
	jne	parseNumber.parse

	movq	%rcx,	%rax

	popq	%rdx
	popq	%rcx
	popq	%rbx

	leave

	ret

# Parse the data at %rax
# Return address of sorted list of sums in %rax
parseData:
	# Determine number of elements
	# Alloc buffer
	# Sum up until empty line or EOF
	# Add to buffer in the appropriate spot
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
	leaq	(%rsp),	%rsi
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

	movq	(%rsp),	%rsi
	movq	$4,	%rdi
	call	parseNumber

	call printNumber

        mov $SYS_EXIT,	%rax
        mov $0, %rdi
        syscall
