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

.equ	ABS_CONSTANT_F64,	0x7FFFFFFFFFFFFFFF

.section .text

.globl _start
.extern alloc
.extern copy
.extern memset
.extern printNumber
.extern parseNumber

.extern	fifoInit
.extern	fifoDeinit
.extern	fifoPush
.extern	fifoPop

.extern	rationalFromInt
.extern	rationalToInt
.extern rationalAdd
.extern	rationalSub
.extern	rationalMul
.extern	rationalDiv

# struct Machine 
# u16 number_lights
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

	movw	%cx,	(%rdi)

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

# struct LinearSystem {
# f64* equations (offset  0)
# u64 width      (offset  8)
# u64 height     (offset 16)
# } (size = 24 bytes)
# Assume the size of the allocation to be a multiple of 8 elements

# struct FreeVariables {
# u32 count     (offset 0)
# u32 variables (offset 4)
# } (size = 8 bytes)
# Note that FreeVariables.variables is treated as a bitset that marks which of the variables are free

# LinearSystem linearSystemFromMachine(Machine* machine)
linearSystemFromMachine:
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

	movzwq	(%rsi),	%rax
	movq	%rax,	16(%rdi)
	movslq	4(%rsi),	%rcx
	incq	%rcx
	movq	%rcx,	8(%rdi)
	mulq	%rcx
	shl	$3,	%rax
	movq	%rax,	%rdi
	call	alloc
	addq	$8,	%rax
	movq	16(%rbp),	%rdi
	movq	%rax,	(%rdi)

	movq	8(%rbp),	%rsi
	# buttons
	movq	8(%rsi),	%r8
	# joltages
	movq	16(%rsi),	%r9
	# matrix
	movq	(%rdi),	%r10

	# for (i = 0; i < system.height; ++i) {
	movq	$0,	%rcx
linearSystemFromMachine.fill:
	# for (j = 0; j < system.width-1; ++j) {
	movq	$0,	%r11
linearSystemFromMachine.fill.inner:
	# system.equations[i*system.width+j] = ((1 << i) & buttons[j]) > 0
	movq	$0,	%r12
	movq	$1,	%r13
	movq	$1,	%rax
	shl	%cl,	%rax
	movzwq	(%r8, %r11, 2),	%r15
	test	%r15,	%rax
	cmovnzq	%r13,	%r12
	movq	%r12,	(%r10,	%r11, 8)

	incq	%r11
	movq	8(%rdi),	%r13
	decq	%r13
	cmpq	%r13,	%r11
	jl	linearSystemFromMachine.fill.inner
	# }
	# system.equations[(i+1)*system.width-1] = joltages[i]
	movzwq	(%r9, %rcx, 2),	%r15
	movq	%r15,	(%r10,	%r11, 8)

	incq	%rcx
	movq	8(%rdi),	%r12
	leaq	(%r10, %r12, 8),	%r10
	cmpq	16(%rdi),	%rcx
	jl	linearSystemFromMachine.fill
	# }

	movq	16(%rbp),	%rdi
	call	linearSystemConvertToRational

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

# void linearSystemConvertToRational(LinearSystem* system)
# Convert a linear system with an integer matrix to a linear system with a Rational matrix.
# Note that this operation is performed in-place
linearSystemConvertToRational:
	pushq	%rdi
	pushq	%rbp
	movq	%rsp,	%rbp

	# &size = %rbp-8
	pushq	$0

	movq	8(%rdi),	%rax
	movq	16(%rdi),	%rcx
	mulq	%rcx
	movq	%rax,	-8(%rbp)

	movq	(%rdi),	%rdi

	movq	$0,	%rcx
linearSystemConvertToRational.loop:
	pushq	%rdi
	movq	(%rdi, %rcx, 8),	%rdi
	call	rationalFromInt
	popq	%rdi
	movq	%rax,	(%rdi, %rcx, 8)

	inc	%rcx
	cmpq	-8(%rbp),	%rcx
	jl	linearSystemConvertToRational.loop

	leave
	popq	%rdi
	ret

# f64 f64abs(f64 x)
# The value of x if passed in %[x|y|z]mm0
# The absolute value is returned in %[x|y|z]mm0
f64abs:
	movq	$ABS_CONSTANT_F64,	%rax
	vpbroadcastq	%rax,	%zmm1
	vpandq	%zmm0,	%zmm1,	%zmm0
	ret

# FreeVariables gaussianElimination(LinearSystem* system)
# Perfom gaussian elimination for the first min(system.height, system.width-1) rows of the system.
# The address of system is passed in %rdi
gaussianElimination:
	pushq	%r8
	pushq	%r9
	pushq	%r10
	pushq	%r11
	pushq	%r12
	pushq	%r13
	pushq	%r14
	pushq	%r15
	pushq	%rdi
	pushq	%rbp
	movq	%rsp,	%rbp

	# rows = min(system.width-1, system.height)
	movq	8(%rdi),	%r14
	leaq	-1(%r14),	%r14
	movq	16(%rdi),	%r15
	cmpq	%r15,	%r14
	cmovlq	%r14,	%r15

	# &pivot = %rbp-8
	pushq	$0
	# &scalar = %rbp-16
	pushq	$0
	
	# &i*width = %rbp-24
	pushq	$0

	# &i = %rbp-32
	pushq	$0
	# &j = %rbp-40
	pushq	$0
	# &cmp = %rbp-48
	pushq	$0

	# &freeVariables = %rbp-56
	pushq	$0

	# for (i = 0; i < rows; ++i) {
gaussianElimination.loop:
	movq	8(%rbp),	%rdi
	movq	-32(%rbp),	%rax
	movq	8(%rdi),	%rcx
	mulq	%rcx
	movq	%rax,	-24(%rbp)

	# find pivot
	# scalar = f64abs(system.equations[i*system.width + i])
	movq	(%rdi),	%rdi
	movq	-32(%rbp),	%rcx
	addq	-24(%rbp),	%rcx
	vpbroadcastq	(%rdi, %rcx, 8),	%xmm0
	call	f64abs
	movq	%xmm0,	-16(%rbp)
	# pivot = i
	movq	-32(%rbp),	%rax
	movq	%rax,	-8(%rbp)

	# for (j = i+1; j < system.height; ++j) {
	movq	-32(%rbp),	%rcx
	incq	%rcx
	movq	%rcx,	-40(%rbp)
gaussianElimination.loop.findPivot:
	movq	8(%rbp),	%rdi
	movq	8(%rdi),	%rax
	movq	-40(%rbp),	%rcx
	mulq	%rcx
	addq	-32(%rbp),	%rax

	# if (scalar >= f64abs(system.equations[j*system.width + i])) continue
	movq	(%rdi),	%rdi
	vpbroadcastq	(%rdi, %rax, 8),	%xmm0
	call	f64abs
	vcomisd	-16(%rbp),	%xmm0
	jna	gaussianElimination.loop.findPivot.postamble

	# pivot = j
	movq	-40(%rbp),	%rax
	movq	%rax,	-8(%rbp)
	# scalar = f64abs(system.equations[j*system.width + i])
	movq	%xmm0,	-16(%rbp)
gaussianElimination.loop.findPivot.postamble:
	incq	-40(%rbp)
	movq	8(%rbp),	%rdi
	movq	16(%rdi),	%rcx
	cmpq	%rcx,	-40(%rbp)
	jl	gaussianElimination.loop.findPivot
	# }

	# swap rows i and pivot
	# pivot*system.width
	movq	-8(%rbp),	%rax
	movq	8(%rdi),	%rcx
	mulq	%rcx
	# for (j = 0; j < system.width; ++j) {
	movq	$0,	%rcx
gaussianElimination.loop.swap:
	movq	8(%rbp),	%rdi
	movq	(%rdi),	%rdi
	# swap(eq[pivot*system.width + j], eq[i*system.width + j])
	leaq	(%rax, %rcx),	%r8
	movq	-24(%rbp),	%r9
	addq	%rcx,	%r9
	movq	(%rdi, %r8, 8),	%r10
	xorq	(%rdi, %r9, 8),	%r10
	xorq	%r10,	(%rdi, %r9, 8)
	xorq	(%rdi, %r9, 8),	%r10
	movq	%r10,	(%rdi, %r8, 8)

	incq	%rcx
	movq	8(%rbp),	%rdi
	cmpq	8(%rdi),	%rcx
	jl	gaussianElimination.loop.swap
	# }

	movq	(%rdi),	%rdi
	# scalar = system.equations[i*system.width + i]
	movq	-24(%rbp),	%rcx
	addq	-32(%rbp),	%rcx
	movq	(%rdi, %rcx, 8),	%rax
	movq	%rax,	-16(%rbp)

	# if (scalar == 0) {
	pxor	%xmm0,	%xmm0
	vucomisd	-16(%rbp),	%xmm0
	jne	gaussianElimination.loop.validRow
	# for (j = i+1; j < system.width-1; ++j) {
	movq	-32(%rbp),	%r8
	incq	%r8
gaussianElimination.loop.findValidColumn:
	movq	-24(%rbp),	%rax
	addq	%r8,	%rax
	movq	8(%rbp),	%rdi
	movq	(%rdi),	%rdi
	# if (!system.equations[i*system.width + j]) continue
	pxor	%xmm0,	%xmm0
	vucomisd	(%rdi, %rax, 8),	%xmm0
	je	gaussianElimination.loop.findValidColumn.postamble

	# for (k = 0; k < system.height; ++k) {
	movq	$0,	%r9
	movq	8(%rbp),	%rdi
gaussianElimination.loop.findValidColumn.swap:
	movq	8(%rdi),	%rax
	mulq	%r9
	movq	(%rdi),	%rdi

	movq	-32(%rbp),	%r10
	addq	%rax,	%r10
	movq	%r8,	%r11
	addq	%rax,	%r11

	# swap(eq[k*width + i], eq[k*width + j])
	movq	(%rdi, %r10, 8),	%r12
	xorq	(%rdi, %r11, 8),	%r12
	xorq	%r12,	(%rdi, %r11, 8)
	xorq	(%rdi, %r11, 8),	%r12
	movq	%r12,	(%rdi, %r10, 8)

	incq	%r9
	movq	8(%rbp),	%rdi
	cmpq	16(%rdi),	%r9
	jl	gaussianElimination.loop.findValidColumn.swap
	# }
	# break
	jmp	gaussianElimination.loop.validRow

gaussianElimination.loop.findValidColumn.postamble:
	incq	%r8
	movq	8(%rbp),	%rdi
	movq	8(%rdi),	%r9
	decq	%r9
	cmpq	%r9,	%r8
	jl	gaussianElimination.loop.findValidColumn
	# } else continue
	jmp	gaussianElimination.loop.postamble
	# }
gaussianElimination.loop.validRow:
	movq	8(%rbp),	%rdi
	movq	(%rdi),	%rdi
	# scalar = system.equations[i*system.width + i]
	movq	-24(%rbp),	%rcx
	addq	-32(%rbp),	%rcx
	movq	(%rdi, %rcx, 8),	%rax
	movq	%rax,	-16(%rbp)

	# for (j = i; j < system.width; ++i) {
	movq	-32(%rbp),	%rcx
	movq	8(%rbp),	%rdi
gaussianElimination.loop.div:
	movq	(%rdi),	%rdi
	# system.equations[i*system.width + j] /= scalar
	movq	-24(%rbp),	%r8
	addq	%rcx,	%r8
	movq	(%rdi, %r8, 8),	%xmm0
	vdivsd	-16(%rbp),	%xmm0,	%xmm0
	movq	%xmm0,	(%rdi, %r8, 8)

	incq	%rcx
	movq	8(%rbp),	%rdi
	cmpq	8(%rdi),	%rcx
	jl	gaussianElimination.loop.div
	# }

	# for (j = i+1; j < system.height; ++j) {
	movq	-32(%rbp),	%r8
	incq	%r8
gaussianElimination.loop.inner:
	movq	8(%rbp),	%rdi
	# scalar = system.equations[j*system.width + i]
	movq	8(%rdi),	%rax
	mulq	%r8
	movq	%rax,	-40(%rbp)
	addq	-32(%rbp),	%rax
	movq	(%rdi),	%rdi
	movq	(%rdi, %rax, 8),	%rax
	movq	%rax,	-16(%rbp)

	# if (scalar == 0) continue
	pxor	%xmm0,	%xmm0
	vucomisd	-16(%rbp),	%xmm0
	je	gaussianElimination.loop.inner.postamble


	# for (k = i; k < system.width; ++k) {
	movq	-32(%rbp),	%r9
	movq	8(%rbp),	%rdi
gaussianElimination.loop.inner.inner:
	movq	(%rdi),	%rdi
	movq	-40(%rbp),	%rax
	addq	%r9,	%rax
	movq	-24(%rbp),	%r10
	addq	%r9,	%r10
	# system.equations[j*system.width + k] -= scalar * system.equations[i*system.width + k]
	movq	(%rdi, %r10, 8),	%xmm0
	vmulsd	-16(%rbp),	%xmm0,	%xmm1
	movq	(%rdi, %rax, 8),	%xmm2
	vsubsd	%xmm2,	%xmm1,	%xmm2
	movq	%xmm2,	(%rdi, %rax, 8)

	incq	%r9
	movq	8(%rbp),	%rdi
	cmpq	8(%rdi),	%r9
	jl	gaussianElimination.loop.inner.inner
	# }

gaussianElimination.loop.inner.postamble:
	incq	%r8
	movq	8(%rbp),	%rdi
	cmpq	16(%rdi),	%r8
	jl	gaussianElimination.loop.inner
	# }
	
gaussianElimination.loop.postamble:
	incq	-32(%rbp)
	cmpq	%r15,	-32(%rbp)
	jl	gaussianElimination.loop
	# }
	
	# if the system is not malformed system.width-1-rows variables should be free
	# find which variables are free by checking the diagonal of the system
	# all variables after rows are free by default

	# for (i = 0; i < system.width-1; ++i) {
	movq	$0,	%rcx
	movq	8(%rbp),	%rdi
gaussianElimination.findFreeVariables:
	movq	8(%rdi),	%rax
	mulq	%rcx
	addq	%rcx,	%rax
	movq	(%rdi),	%rdi
	# if (i < rows && system.equations[i*system.width + i] != 0) continue

	cmpq	%r15,	%rcx
	jge	gaussianElimination.findFreeVariables.body
	pxor	%xmm0,	%xmm0
	vucomisd	(%rdi, %rax, 8),	%xmm0
	jne	gaussianElimination.findFreeVariables.postamble

gaussianElimination.findFreeVariables.body:
	# freeVariables.count++
	incl	-56(%rbp)
	# freeVariables.variables |= (1 << i)
	movl	$1,	%eax
	shll	%cl,	%eax
	orl	%eax,	-52(%rbp)

gaussianElimination.findFreeVariables.postamble:
	incq	%rcx
	movq	8(%rbp),	%rdi
	movq	8(%rdi),	%r8
	decq	%r8
	cmpq	%r8,	%rcx
	jl	gaussianElimination.findFreeVariables
	# }

	movq	-56(%rbp),	%rax

	leave
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

# For the purpose of this function the FreeVariables structure should have a pointer to the values of the free variables
# appended i.e.
# struct FreeVariables {
# u32 count
# u32 variables
# u16* values
# }
# u64 backwardsSubstitution(LinearSystem* system, FreeVariables* variables)
backwardsSubstitution:
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

	# &solution = %rbp-8
	pushq	$0

	# push system.width-1 zeros to the stack (this is the storage for the solution)
	# for (i = 0; i < system.width - 1; ++i) {
	movq	$0,	%rcx
	movq	8(%rdi),	%r15
	decq	%r15
backwardsSubstitution.initSolution:
	# push 0
	pushq	$0
	incq	%rcx
	cmpq	%r15,	%rcx
	jl	backwardsSubstitution.initSolution
	# }
	movq	%rsp,	-8(%rbp)
	

	# k = 0 (index of the value of the next free variable)
	movq	$0,	%r15
	# for (i = system.width - 2; i >= 0; --i) {
	movslq	8(%rdi),	%rcx
	subq	$2,	%rcx
backwardsSubstitution.loop:
	movl	$1,	%r8d
	shll	%cl,	%r8d
	# if ((1 << i) & variables.variables) {
	testl	4(%rsi),	%r8d
	jz	backwardsSubstitution.loop.else
	# solution[i] = variables.values[k]
	movq	8(%rsi),	%rax
	movzwq	(%rax, %r15, 2),	%rax
	movq	%rax,	%xmm0
	vcvtqq2pd	%xmm0,	%xmm0
	movq	-8(%rbp),	%rax
	movq	%xmm0,	(%rax, %rcx, 8)
	# k++
	incq	%r15
	# continue
	jmp	backwardsSubstitution.loop.postamble
	# }
backwardsSubstitution.loop.else:
	# solution[i] = system.equations[(i+1)*system.width-1]
	leaq	1(%rcx),	%rax
	movq	8(%rdi),	%rdx
	mulq	%rdx
	movq	(%rdi),	%r10
	movq	-8(%r10, %rax, 8),	%rdx
	movq	-8(%rbp),	%r9
	movq	%rdx,	(%r9, %rcx, 8)
	subq	8(%rdi),	%rax
	shl	$3,	%rax
	addq	%rax,	%r10
	# for (j = system.width - 2; j > i; --j) {
	movq	8(%rdi),	%r8
	subq	$2,	%r8
backwardsSubstitution.loop.inner:
	cmpq	%rcx,	%r8
	jle	backwardsSubstitution.loop.postamble
	# solution[i] -= solution[j] * system.equations[i*system.width + j]
	movq	(%r9, %r8, 8),	%xmm0
	vmulsd	(%r10, %r8, 8), %xmm0, %xmm1
	movq	(%r9,	%rcx, 8),	%xmm2
	vsubsd	%xmm1,	%xmm2,	%xmm2
	movq	%xmm2,	(%r9, %rcx, 8)

	decq	%r8
	jmp	backwardsSubstitution.loop.inner
	# }

backwardsSubstitution.loop.postamble:
	decq	%rcx
	cmpq	$0,	%rcx
	jge	backwardsSubstitution.loop
	# }

	movq	8(%rdi),	%rcx
	decq	%rcx

	pxor	%xmm0,	%xmm0
backwardsSubstitution.sum:
	popq	%rax
	movq	%rax,	%xmm1
	pxor	%xmm3,	%xmm3
	ucomisd	%xmm1,	%xmm3
	ja	backwardsSubstitution.negativeSolution
	vaddsd	%xmm1,	%xmm0,	%xmm0

	decq	%rcx
	cmpq	$0,	%rcx
	jge	backwardsSubstitution.sum

	vcvtpd2qq	%xmm0,	%xmm0
	movq	%xmm0,	%rax

backwardsSubstitution.postamble:
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
backwardsSubstitution.negativeSolution:
	movq	$-1,	%rax
	jmp	backwardsSubstitution.postamble

# u64 linearSystemSearchSolutionSpace(LinearSystem* system, FreeVariables* variables, u64 bound, u64 depth,
#                                     u64 current_cost, u64 current_min)
linearSystemSearchSolutionSpace:
	pushq	%rbp
	movq	%rsp,	%rbp
	# &system = %rbp-8
	pushq	%rdi
	# &variables = %rbp-16
	pushq	%rsi
	# &bound = %rbp-24
	pushq	%rdx
	# &depth = %rbp-32
	pushq	%rcx
	# &current_cost = %rbp-40
	pushq	%r8
	# &current_min = %rbp-48
	pushq	%r9
	pushq	%r10

	# if (current_cost >= current_min) return current_min;
	cmpq	%r9,	%r8
	cmovae	%r9,	%rax
	jae	linearSystemSearchSolutionSpace.postamble

	# if (depth == variables.count) {
	cmpl	(%rsi),	%ecx
	jne	linearSystemSearchSolutionSpace.mainBody
	# candidate = backwardsSubstitution(system, variables);
	call	backwardsSubstitution
	movq	-48(%rbp),	%r9
	# if (candidate < 0 || candidate >= current_min) return current_min
	cmpq	$0,	%rax
	cmovlq	%r9,	%rax
	jl	linearSystemSearchSolutionSpace.postamble
	cmpq	%r9,	%rax
	cmovaq	%r9,	%rax
	# return candidate
	jmp	linearSystemSearchSolutionSpace.postamble
	# }

linearSystemSearchSolutionSpace.mainBody:
	# budget = max(0, current_min - current_cost)
	movq	$0,	%r10
	movq	%r9,	%rax
	subq	%r8,	%rax
	cmpq	%r8,	%r9
	cmovaq	%rax,	%r10
	# new_bound = min(bound, budget)
	cmpq	%r10,	%rdx
	cmovaq	%r10,	%rdx

	# for (i = 0; i < new_bound; ++i) {
	movq	$0,	%r10
linearSystemSearchSolutionSpace.loop:
	cmpq	%rdx,	%r10
	jae	linearSystemSearchSolutionSpace.postamble

	# variables.values[depth] = i
	movq	8(%rsi),	%rsi
	movw	%r10w,	(%rsi, %rcx, 2)
	movq	-16(%rbp),	%rsi
	# candidate = linearSystemSearchSolutionSpace(system, variables, new_bound, depth + 1,
	#                                             current_cost + i, current_min)
	incq	%rcx
	addq	%r10,	%r8
	call	linearSystemSearchSolutionSpace
	movq	%rax,	%r9

	# if (current_min <= current_cost + i) return candidate
	cmpq	%r8,	%r9
	jbe	linearSystemSearchSolutionSpace.postamble

	subq	%r10,	%r8
	decq	%rcx

	incq	%r10
	jmp	linearSystemSearchSolutionSpace.loop
	# }

linearSystemSearchSolutionSpace.postamble:
	popq	%r10
	popq	%r9
	popq	%r8
	popq	%rcx
	popq	%rdx
	popq	%rsi
	popq	%rdi
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

	# &system = %rbp-72
	subq	$24,	%rsp
	# &variables = %rbp-88
	subq	$16,	%rsp
	# &pt2 = %rbp-96
	pushq	$0

	# free variables buffer
	subq	$40,	%rsp
	movq	%rsp,	-80(%rbp)

loop:
	leaq	-32(%rbp),	%rdi
	movq	-8(%rbp),	%rsi
	addq	-40(%rbp),	%rsi
	call	parseMachine
	addq	%rax,	-40(%rbp)

	leaq	-32(%rbp),	%rdi
	call	machineBFS
	addq	%rax,	-48(%rbp)

	leaq	-72(%rbp),	%rdi
	leaq	-32(%rbp),	%rsi
	call	linearSystemFromMachine
	leaq	-72(%rbp),	%rdi
	call	gaussianElimination
	movq	%rax,	-88(%rbp)

	movq	%rsp,	%rdi
	movq	$0,	%rsi
	movq	$40,	%rdx
	call	memset

	movq	$0,	%rcx
	movq	$0,	%rdx
	movq	-16(%rbp),	%rdi
loop.findSearchBound:
	movw	(%rdi, %rcx, 2),	%ax
	cmpw	%ax,	%dx
	cmovbw	%ax,	%dx

	incq	%rcx
	cmpw	-32(%rbp),	%cx
	jl	loop.findSearchBound
	incq	%rdx

	leaq	-72(%rbp),	%rdi
	leaq	-88(%rbp),	%rsi
	movq	$0,	%rcx
	movq	$0,	%r8
	movq	$-1,	%r9
	call	linearSystemSearchSolutionSpace
	addq	%rax,	-96(%rbp)

	movq	%rax,	%rdi
	call	printNumber

	movq	-40(%rbp),	%r8
	cmpq	56(%rbp),	%r8
	jl	loop

	movq	-48(%rbp),	%rdi
	call	printNumber

	movq	-96(%rbp),	%rdi
	call	printNumber

	movl	$4,	%edi
	call	rationalFromInt
	movq	%rax,	%rsi

	movl	$2,	%edi
	call	rationalFromInt
	movq	%rax,	%rdi

	call	rationalDiv

	mov	$SYS_EXIT,	%rax
	mov	$0,	%rdi
	syscall
