.section .data

.equ	SYS_READ,	0
.equ	SYS_WRITE,	1
.equ	SYS_OPEN,	2
.equ	SYS_CLOSE,	3
.equ	SYS_FSTAT,	5
.equ	SYS_MMAP,	9
.equ	SYS_MUNMAP,	11
.equ	SYS_EXIT,	60

.equ	STDOUT,	1

.section .text

.globl _start
.extern alloc
.extern printNumber
.extern parseNumber

.extern	fifoInit
.extern	fifoDeinit
.extern	fifoPush
.extern	fifoPop

# struct Machine 
# u16 current
# u16 target
# u32 btns_len
# u16* buttons
# u16* joltages
# } (size = 24 bytes)

# Machine parse(u8* input)
#
# The address of the return value on the stack is passed in %rdi
# The address of the input string is passed in %rsi
parseMachine:
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
	pushq	%rbp
	movq	%rsp,	%rbp

	movq	$0,	%rcx
	movw	$0,	2(%rdi)
	# do {
parseMachine.indicatorLights:
	# if ((input + 1)[i] != '#') continue
	cmpb	$'#',	1(%rsi, %rcx)
	jne	parseMachine.indicatorLights.postamble
	# target |= (1 << i)
	movw	$1,	%r9w
	shl	%cl,	%r9w
	orw	%r9w,	2(%rdi)
	# i++
parseMachine.indicatorLights.postamble:
	incq	%rcx
	cmpb	$']',	1(%rsi, %rcx)
	jne	parseMachine.indicatorLights
	# } while ((input + 1)[i] != ']')

	movq	%rcx,	%r8
	addq	$2,	%r8
	# allocate joltages
	movq	%rcx,	%rdi
	shl	$1,	%rdi
	call	alloc
	addq	$8,	%rax
	movq	16(%rbp),	%rdi
	movq	%rax,	16(%rdi)

	# btns_len = 0
	movq	$0,	%rcx
	# j = 0
	movq	$0,	%r9
	movq	%rsi,	%r10
	addq	%r8,	%r10
	# do {
parseMachine.buttonCount:
	# if (input[i + j] == '(') btns_len++
	cmpb	$'(',	(%r10, %r9)
	jne	parseMachine.buttonCount.postamble
	incq	%rcx
parseMachine.buttonCount.postamble:
	incq	%r9
	cmpb	$'{',	(%r10, %r9)
	jne	parseMachine.buttonCount
	# } while (input[i + j] != '{')
	
	movq	%rcx,	4(%rdi)
	# allocate buttons
	movq	%rcx,	%rdi
	shl	$1,	%rdi
	call	alloc
	addq	$8,	%rax
	movq	16(%rbp),	%rdi
	movq	%rax,	8(%rdi)

	# &count = %rbp-8
	pushq	$0

	addq	$2,	%r8
	# j = 0
	movq	$0,	%r9
	# do {
parseMachine.buttons:
	# btn = 0
	movw	$0,	%r10w
	# do {
parseMachine.buttons.inner:
	# n = parseNumber(input + i, ',', &count)
	leaq	(%rsi, %r8),	%rdi
	movq	$',',	%rsi
	leaq	-8(%rbp),	%rdx
	call	parseNumber
	movq	%rax,	%rcx
	# i += count
	addq	-8(%rbp),	%r8
	# btn |= (1 << n)
	movw	$1,	%r11w
	shl	%cl,	%r11w
	orw	%r11w,	%r10w
	movq	8(%rbp),	%rsi
	cmpb	$')',	-1(%rsi, %r8)
	jne	parseMachine.buttons.inner
	# } while (input[i-1] != ')')
	movq	16(%rbp),	%rdi
	movq	8(%rdi),	%r11
	# buttons[j] = btn
	movw	%r10w,	(%r11, %r9, 2)
	# j++
	incq	%r9
	addq	$2,	%r8
	cmpb	$'{',	-1(%rsi, %r8)
	jne	parseMachine.buttons
	# } while (input[i-1] != '{')

	# j = 0
	movq	$0,	%r9
	movq	8(%rbp),	%rsi
	# do {
parseMachine.joltages:
	# n = parseNumber(input + i, ',', &count)
	leaq	(%rsi, %r8),	%rdi
	movq	$',',	%rsi
	leaq	-8(%rbp),	%rdx
	call	parseNumber
	# i += count
	addq	-8(%rbp),	%r8
	# joltages[j] = n
	movq	16(%rbp),	%rdi
	movq	16(%rdi),	%r11
	movw	%ax,	(%r11, %r9, 2)
	incq	%r9
	movq	8(%rbp),	%rsi
	cmpb	$'\n',	(%rsi, %r8)
	jne	parseMachine.joltages
	# } while (input[i] != '\n')

	incq	%r8
	movq	%r8,	%rax

	leave
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

# u64 machineBFS(Machine* machine)
machineBFS:
	pushq	%r14
	pushq	%r15
	pushq	%rdi
	pushq	%rbp
	movq	%rsp,	%rbp

	# &fifo = %rbp-32
	subq	$32,	%rsp
	# Q = fifoInit(10 * 1024 * 1024 * 1024)
	leaq	-32(%rbp),	%rdi
	movq	$10737418240,	%rsi
	call	fifoInit

	# &current = %rbp-42
	subq	$10,	%rsp
	movq	$0,	-42(%rbp)
	movw	$0,	-34(%rbp)
	
	# fifoPush(Q, (0, 0))
	leaq	-32(%rbp),	%rdi
	leaq	-42(%rbp),	%rsi
	movq	$10,	%rdx
	call	fifoPush

	# do {
machineBFS.loop:
	# (d, v) = fifoPop(Q)
	leaq	-32(%rbp),	%rdi
	leaq	-42(%rbp),	%rsi
	movq	$10,	%rdx
	call	fifoPop
	
	movq	8(%rbp),	%rdi
	movw	2(%rdi),	%r15w
	# if (v == machine->target) return d
	cmpw	-34(%rbp),	%r15w
	je	machineBFS.postamble

	incq	-42(%rbp)
	# for (i = 0; i < machine->btns_len; ++i) {
	movq	$0,	%r14
machineBFS.loop.inner:
	# fifoPush(Q, (d+1, v xor machine->buttons[i]))
	movw	-34(%rbp),	%r15w
	pushq	%r15

	movq	8(%rbp),	%rdi
	movq	8(%rdi),	%rdi
	movw	(%rdi, %r14, 2),	%r15w
	xorw	%r15w,	-34(%rbp)

	leaq	-32(%rbp),	%rdi
	leaq	-42(%rbp),	%rsi
	movq	$10,	%rdx
	call	fifoPush

	popq	%r15
	movw	%r15w,	-34(%rbp)
	movq	8(%rbp),	%rdi
	incq	%r14
	cmpl	4(%rdi),	%r14d
	jl	machineBFS.loop.inner
	# }
	jmp	machineBFS.loop
	# } while (true)

machineBFS.postamble:
	# fifoDeinit(Q)
	leaq	-32(%rbp),	%rdi
	call	fifoDeinit
	
	movq	-42(%rbp),	%rax

	leave
	popq	%rdi
	popq	%r15
	popq	%r14
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

	# &machine = %rbp-32
	subq	$24,	%rsp

	# &start = %rbp-40
	pushq	$0
	# &pt1 = %rbp-48
	pushq	$0
loop:
	leaq	-32(%rbp),	%rdi
	movq	-8(%rbp),	%rsi
	addq	-40(%rbp),	%rsi
	call	parseMachine
	addq	%rax,	-40(%rbp)

	leaq	-32(%rbp),	%rdi
	call	machineBFS
	addq	%rax,	-48(%rbp)

	movq	-40(%rbp),	%r8
	cmpq	56(%rbp),	%r8
	jl	loop

	movq	-48(%rbp),	%rdi
	call	printNumber

	mov	$SYS_EXIT,	%rax
	mov	$0,	%rdi
	syscall
