.section .data
.equ	SYS_WRITE,	1
.equ	SYS_MMAP,	9
.equ	SYS_MUNMAP,	11
.equ	SYS_EXIT,	60

.equ	STDOUT,	1

overflow_message:
	.asciz	"Lifo overflowed!\n"
underflow_message:
	.asciz	"Lifo underflowed!\n"
.equ	MESSAGE_LENGTH,	18

.section .text
.globl	lifoInit
.globl	lifoDeinit
.globl	lifoPush
.globl	lifoPop

# struct Lifo {
# u64 head
# u64 size
# void* data
# } (size = 24 bytes)

# Lifo lifoInit(u64 size)
# The address of the return value is stored in %rdi
# The size of the lifo is stored in %rsi
lifoInit:
	pushq	%rdi
	pushq	%rsi
	pushq	%rbp
	movq	%rsp,	%rbp

	movq	$0,	(%rdi)
	movq	%rsi,	8(%rdi)

	movq	$SYS_MMAP,	%rax
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
	movq	16(%rbp),	%rdi
	movq	%rax,	16(%rdi)

	leave
	popq	%rsi
	popq	%rdi
	ret

# void lifoDeinit(Lifo* lifo)
# The address of the lifo is stored in %rdi
lifoDeinit:
	movq	$SYS_MUNMAP,	%rax
	movq	8(%rdi),	%rsi
	movq	16(%rdi),	%rdi
	syscall
	ret

# void lifoPush(Lifo* lifo, void* data, u64 size)
lifoPush:
	movq	(%rdi),	%rcx
	addq	%rdx,	%rcx
	cmpq	8(%rdi),	%rcx
	jae	lifoPush.overflow

	movq	$0,	%rcx
lifoPush.loop:
	movb	(%rsi, %rcx),	%al
	pushq	%rsi
	movq	16(%rdi),	%rsi
	addq	(%rdi),	%rsi
	movb	%al,	(%rsi, %rcx)
	popq	%rsi

	incq	%rcx
	cmpq	%rdx,	%rcx
	jl	lifoPush.loop
	addq	%rdx,	(%rdi)
	ret
lifoPush.overflow:
	movq	$SYS_WRITE,	%rax
	movq	$STDOUT,	%rdi
	movq	$overflow_message,	%rsi
	movq	$MESSAGE_LENGTH,	%rdx
	syscall

	movq	$SYS_EXIT,	%rax
	movq	$1,	%rdi
	syscall

# void lifoPop(Lifo* lifo, void* data, u64 size)
lifoPop:
	movq	(%rdi),	%rcx
	subq	%rdx,	%rcx
	cmpq	$0,	%rcx
	jl	lifoPop.underflow

	subq	%rdx,	(%rdi)

	movq	$0,	%rcx
lifoPop.loop:
	pushq	%rsi
	movq	16(%rdi),	%rsi
	addq	(%rdi),	%rsi
	movb	(%rsi, %rcx),	%al
	popq	%rsi
	movb	%al,	(%rsi, %rcx)

	incq	%rcx
	cmpq	%rdx,	%rcx
	jl	lifoPop.loop

	ret
lifoPop.underflow:
	movq	$SYS_WRITE,	%rax
	movq	$STDOUT,	%rdi
	movq	$underflow_message,	%rsi
	movq	$MESSAGE_LENGTH,	%rdx
	syscall

	movq	$SYS_EXIT,	%rax
	movq	$1,	%rdi
	syscall
	
