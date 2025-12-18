.section .text

.globl	rationalFromInt
.globl	rationalToInt
.globl	rationalAdd
.globl	rationalSub
.globl	rationalMul
.globl	rationalDiv

# struct Rational {
# i32 numerator
# i32 denominator
# }

# u64 gcd(u64 a, u64 b)
gcd:
	movq	%rdi,	%rax
	movq	%rsi,	%rcx

gcd.loop:
	cmpq	$0,	%rcx
	je	gcd.postamble
	# y = x % y
	movq	$0,	%rdx
	divq	%rcx
	movq	%rcx,	%rax
	movq	%rdx,	%rcx
	jmp	gcd.loop
gcd.postamble:
	movq	$1,	%rcx
	cmpq	$0,	%rax
	cmoveq	%rcx,	%rax
	ret

abs:
	movl	%edi,	%eax
	negl	%eax
	cmovsl	%edi,	%eax
	ret

# Rational init(i32 numerator, i32 denominator)
init:
	pushq	%rdi
	pushq	%rsi
	pushq	%rbp
	movq	%rsp,	%rbp

	subq	$8,	%rsp

	# if (denominator == 0) return {0, 1}
	cmpq	$0,	%rsi
	je	init.zeroDenominator
	# if (denominator < 0) { numerator = -numerator; denominator = -denominator }
	jg	init.mainBody
	negl	%edi
	negl	%esi
init.mainBody:
	# common = gcd(abs(numerator), abs(denominator))
	movl	%edi,	-8(%rbp)
	call	abs
	movl	%esi,	%edi
	movl	%esi,	-4(%rbp)
	movl	%eax,	%esi
	call	abs
	movslq	%esi,	%rdi
	movslq	%eax,	%rsi
	call	gcd
	movl	%eax,	%ecx

	# return { numerator/common, denominator/common }
	movl	-8(%rbp),	%eax
	divl	%ecx
	movl	%eax,	-8(%rbp)
	movl	-4(%rbp),	%eax
	divl	%ecx
	movl	%eax,	-4(%rbp)
	movq	-8(%rbp),	%rax
init.postamble:
	leave
	popq	%rsi
	popq	%rdi
	ret
init.zeroDenominator:
	movl	$1,	%eax
	shlq	$32,	%rax
	orq	$0,	%rax
	jmp	init.postamble

# i64 rationalToInt(Rational x)
# %rdx encodes whether the result is valid or not
# where %rdx == 0 means valid
rationalToInt:
	pushq	%rdi

	movslq	(%rsp),	%rax
	movslq	4(%rsp),	%rcx
	divq	%rcx

	popq	%rdi
	ret

# Rational rationalFromInt(i32 n)
rationalFromInt:
	movl	$1,	%eax
	shlq	$32,	%rax
	orq	%rdi,	%rax
	ret

# Rational rationalAdd(Rational x, Rational y)
rationalAdd:
	pushq	%rdi
	pushq	%rsi
	pushq	%rbp
	movq	%rsp,	%rbp

	# denom = x.denominator * y.denominator
	movl	12(%rbp),	%eax
	movl	20(%rbp),	%ecx
	mull	%ecx
	movl	%eax,	%esi

	# num = x.numerator * y.denominator
	movl	16(%rbp),	%eax
	movl	12(%rbp),	%ecx
	mull	%ecx
	movl	%eax,	%edi

	# num += y.numerator * x.denominator
	movl	16(%rbp),	%eax
	movl	12(%rbp),	%ecx
	mull	%ecx
	addl	%eax,	%edi

	# init(num, denom)
	call	init

	leave
	popq	%rsi
	popq	%rdi
	ret

rationalSub:
	pushq	%rdi
	pushq	%rsi
	pushq	%rbp
	movq	%rsp,	%rbp

	# denom = x.denominator * y.denominator
	movl	12(%rbp),	%eax
	movl	20(%rbp),	%ecx
	mull	%ecx
	movl	%eax,	%esi

	# num = x.numerator * y.denominator
	movl	16(%rbp),	%eax
	movl	12(%rbp),	%ecx
	mull	%ecx
	movl	%eax,	%edi

	# num -= y.numerator * x.denominator
	movl	16(%rbp),	%eax
	movl	12(%rbp),	%ecx
	mull	%ecx
	subl	%eax,	%edi

	# init(num, denom)
	call	init

	leave
	popq	%rsi
	popq	%rdi
	ret

rationalMul:
	pushq	%rdi
	pushq	%rsi
	pushq	%rbp
	movq	%rsp,	%rbp

	# denom = x.denominator * y.denominator
	movl	12(%rbp),	%eax
	movl	20(%rbp),	%ecx
	mull	%ecx
	movl	%eax,	%esi

	# num = x.numerator * y.numerator
	movl	16(%rbp),	%eax
	movl	8(%rbp),	%ecx
	mull	%ecx
	movl	%eax,	%edi

	# init(num, denom)
	call	init

	leave
	popq	%rsi
	popq	%rdi
	ret

rationalDiv:
	pushq	%rdi
	pushq	%rsi
	pushq	%rbp
	movq	%rsp,	%rbp

	# denom = x.denominator * y.numerator
	movl	8(%rbp),	%eax
	movl	20(%rbp),	%ecx
	mull	%ecx
	movl	%eax,	%esi

	# num = x.numerator * y.denominator
	movl	16(%rbp),	%eax
	movl	12(%rbp),	%ecx
	mull	%ecx
	movl	%eax,	%edi

	# init(num, denom)
	call	init

	leave
	popq	%rsi
	popq	%rdi
	ret
