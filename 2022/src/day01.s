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

# Allocate %rdi bytes.
# The address of the allocation is returned in %rax.
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
	cmpb	(%rdi,	%rcx),	%sil
	je	parseNumber.count.loopEnd
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

# Parse the data at %rdi. The filesize is passed through %rsi
# %rsi and %rsi are clobbered
# Return address of sorted list of sums in %rax
parseData:
	pushq	%rbp
	movq	%rsp,	%rbp
	subq	$32,	%rsp
	# address of file contents
	movq	%rdi,	-8(%rbp)
	# size of the file
	movq	%rsi,	-16(%rbp)
	# address of the allocated list
	movq	$0,	-24(%rbp)
	# number of read characters
	movq	$0,	-32(%rbp)
	movq	%rdi,	%rsi

	pushq	%rbx
	pushq	%rcx
	pushq	%rdx

	# Determine number of elements
	# i = 0
	movq	$0,	%rcx

	# count = 0
	movq	$0,	%rbx
	# do {
parseData.count.loop:
	# if (str[i] == '\n') {
	movb	(%rsi, %rcx),	%dl
	cmpb	$0xA,	%dl
	jne	parseData.count.loop.noLinebreak
	# count += 8
	addq	$8,	%rbx
	# }
parseData.count.loop.noLinebreak:
	# i++
	incq	%rcx
	# } while (i < filesize);
	cmp	-16(%rbp),	%rcx
	jne	parseData.count.loop
	# if (str[end] != '\n') {
	movb	-1(%rsi, %rcx),	%dl
	cmpb	$0xA,	%dl
	je parseData.count.fileEndLinebreak
	# count += 8
	addq	$8,	%rbx
	# }
parseData.count.fileEndLinebreak:

	# Alloc buffer
	movq	%rbx,	%rdi
	call	alloc

	movq	%rax,	-24(%rbp)

	# i = 0
	movq	$0,	%rcx
	# str
	movq	-8(%rbp),	%rdi
	# total = 0
	movq	$0,	%rbx
	# do {
parseData.sum.loop:
	# num = parseNumber(str, '\n', &count)
	movq	$0xA,	%rsi
	leaq	-32(%rbp),	%rdx
	call	parseNumber
	# str += count
	addq	-32(%rbp),	%rdi
	# i += count
	addq	-32(%rbp),	%rcx
	# if (num != -1) {
	cmpq	$-1,	%rax
	je	parseData.sum.loop.empty
	# total += num
	addq	%rax,	%rbx
	jmp	parseData.sum.loop.postamble
	# } else {
parseData.sum.loop.empty:
	# Insert total at the correct spot in the allocated buffer
	# The buffer is sorted descending
	
	pushq	%rcx
	pushq	%rdx

	# buf
	movq	-24(%rbp),	%rsi
	# len = length(buf)
	movq	(%rsi),	%rdx
	# i = 0
	movq	$0,	%rcx
	# do {
parseData.sum.loop.empty.loop:
	# if (buf[i] < v) {
	cmpq	%rbx, 8(%rsi, %rcx)
	jge	parseData.sum.loop.empty.loop.noSwitch
	# switch(buf[i], v);
	xorq	8(%rsi, %rcx),	%rbx
	xorq	%rbx,	8(%rsi, %rcx)
	xorq	8(%rsi, %rcx),	%rbx
	# }
parseData.sum.loop.empty.loop.noSwitch:
	# i++
	addq	$8,	%rcx
	# } while (i < len);
	cmp	%rcx,	%rdx
	jne	parseData.sum.loop.empty.loop

	popq	%rdx
	popq	%rcx

	# total = 0
	movq	$0,	%rbx
	# }
parseData.sum.loop.postamble:
	# } while (i < filesize);
	cmp	-16(%rbp),	%rcx
	jne	parseData.sum.loop

parseData.postamble:
	movq	-24(%rbp),	%rax
	popq	%rdx
	popq	%rcx
	popq	%rbx
	leave
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

	popq	%rdi
	movq	0x30(%rsp),	%rsi
	call	parseData

	pushq	%rax

	# part 1
	movq	8(%rax),	%rdi
	call	printNumber

	popq	%rax

	# part 2
	movq	8(%rax),	%rdi
	addq	16(%rax),	%rdi
	addq	24(%rax),	%rdi
	call	printNumber

        mov $SYS_EXIT,	%rax
        mov $0, %rdi
        syscall
