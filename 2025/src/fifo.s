.section .data
.equ	SYS_MMAP,	9
.equ	SYS_MUNMAP,	11

.equ	STDOUT,	1

.section .text
.globl	fifoInit
.globl	fifoDeinit
.globl	fifoPush
.globl	fifoPop

# struct Fifo {
# u64 head
# u64 tail
# u64 size
# void* data
# } (size = 32 bytes)

# Fifo fifoInit(u64 size)
# The address of the return value is stored in %rdi
# The size of the fifo is stored in %rsi
fifoInit:
	pushq	%rdi
	pushq	%rsi
	pushq	%rbp
	movq	%rsp,	%rbp

	movq	$0,	(%rdi)
	movq	$0,	8(%rdi)
	movq	%rsi,	16(%rdi)

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
	movq	%rax,	24(%rdi)

	leave
	popq	%rsi
	popq	%rdi
	ret

# void fifoDeinit(Fifo* fifo)
# The address of the fifo is stored in %rdi
fifoDeinit:
	movq	$SYS_MUNMAP,	%rax
	movq	16(%rdi),	%rsi
	movq	24(%rdi),	%rdi
	syscall
	ret

# void fifoPush(Fifo* fifo, void* data, u64 size)
fifoPush:
	pushq	%rdi
	pushq	%rsi
	pushq	%rdx

	movq	(%rdi),	%rcx
	addq	%rdx,	(%rdi)

	pushq	%rcx
	movq	16(%rdi),	%rcx
	cmpq	%rcx,	(%rdi)
	jb	fifoPush.afterWrap
	movq	$0,	(%rdi)
fifoPush.afterWrap:
	popq	%rcx

	movq	24(%rdi),	%rdi
	addq	%rcx,	%rdi
	movq	$0,	%rcx
fifoPush.loop:
	movb	(%rsi, %rcx),	%al
	movb	%al,	(%rdi, %rcx)
	incq	%rcx
	cmpq	%rdx,	%rcx
	jl	fifoPush.loop

	popq	%rdx
	popq	%rsi
	popq	%rdi
	ret

# void fifoPop(Fifo* fifo, void* data, u64 size)
fifoPop:
	pushq	%rdi
	pushq	%rsi
	pushq	%rdx

	movq	8(%rdi),	%rcx
	addq	%rdx,	8(%rdi)

	pushq	%rcx
	movq	16(%rdi),	%rcx
	cmpq	%rcx,	8(%rdi)
	jb	fifoPop.afterWrap
	movq	$0,	8(%rdi)
fifoPop.afterWrap:
	popq	%rcx

	movq	24(%rdi),	%rdi
	addq	%rcx,	%rdi

	movq	$0,	%rcx
fifoPop.loop:
	movb	(%rdi, %rcx),	%al
	movb	%al,	(%rsi, %rcx)
	incq	%rcx
	cmpq	%rdx,	%rcx
	jl	fifoPop.loop

	popq	%rdx
	popq	%rsi
	popq	%rdi
	ret
