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
