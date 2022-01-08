# Brainfuck JIT
#
# The brainfuck code is directly compiled to machine code.
# In the machine code, the register r13 is used to store the cell index.

.global brainfuck

.bss
CELLS: .skip 100000 # cells to operate on
INSTRUCTIONS: .skip 200000 # machine code instructions of the brainfuck

.text
newline: .asciz "\n"

# If DEBUG is defined we declare the file name and file mode
#ifdef DEBUG
	filename: .asciz "jit.out"
	filemode: .asciz "wb"
#endif

# character constants
.equ CHAR_NUL, 0x0
.equ CHAR_LT, 0x3C
.equ CHAR_GT, 0x3E
.equ CHAR_PLUS, 0x2B
.equ CHAR_MINUS, 0x2D
.equ CHAR_DOT, 0x2E
.equ CHAR_COMMA, 0x2C
.equ CHAR_LB, 0x5B
.equ CHAR_RB, 0x5D

# Brainfuck JIT entrypoint
#
# rdi should contain a NUL terminated string containing the brainfuck code
brainfuck:
	# compile code
	# rdi already contains the code
	call compile

	# execute the code
	movq %rax, %rdi # move instruction size to rdi
	call execute

	# print newline
	movq $newline, %rdi
	movq $0, %rax
	call printf

	# return
	movq $0, %rax
	ret

# Compile the brainfuck code to machine code
#
# rdi should contain a NUL terminated string containing the brainfuck code
#
# rax will contain the instruction size
compile:
	pushq %rbp # store caller's base pointer
	movq %rsp, %rbp # set base pointer to the stack pointer

	movq $0, %rsi # store code index
	movq $0, %rdx # store instruction index

	# macro for emitting 8 bits
	.macro emit_8 bytes:vararg
		.irp byte, \bytes # loop over all bytes
			movb \byte, INSTRUCTIONS(%rdx) # store byte
			incq %rdx # increment instruction index
		.endr
	.endm

	# macro for emitting 32 bits
	.macro emit_32 value
		movl \value, INSTRUCTIONS(%rdx) # store value
		addq $4, %rdx # add 4 to instruction index
	.endm

	# macro for emitting 64 bits
	.macro emit_64 value
		movq \value, INSTRUCTIONS(%rdx) # store value
		addq $8, %rdx # add 8 to instruction index
	.endm

	# movabs <address of first index CELLS>, %r13
	emit_8 $0x49, $0xBD
	leaq (CELLS), %r13
	emit_64 %r13

	# Compile loop
	c_loop:
		movb (%rdi, %rsi), %al # store current char in al
		incq %rsi # increment code index

		cmpb $CHAR_NUL, %al # if c == NUL
		je c_loop_end # jump to loop end

		cmpb $CHAR_LT, %al # if c == <
		je c_lt

		cmpb $CHAR_GT, %al # if c == >
		je c_gt

		cmpb $CHAR_PLUS, %al # if c == +
		je c_plus

		cmpb $CHAR_MINUS, %al # if c == -
		je c_minus

		cmpb $CHAR_DOT, %al # if c == .
		je c_dot

		cmpb $CHAR_COMMA, %al # if c == ,
		je c_comma

		cmpb $CHAR_LB, %al # if c == [
		je c_lb

		cmpb $CHAR_RB, %al # if c == ]
		je c_rb

		# ignore other chars
		jmp c_loop

	c_lt:
		movb $1, %bl # store count

		c_lt_loop:
			call skip_other_chars
			movb (%rdi, %rsi), %al # store current char in al

			cmpb $CHAR_LT, %al # if char != <
			jne c_lt_loop_end # jump to loop end

			incb %bl # increment count
			incq %rsi # increment code index

			cmpb $0xF, %bl # if count == F
			je c_lt_loop_end # jump to loop end
			jmp c_lt_loop # else continue loop

		c_lt_loop_end:
			# subq <count>, %r13
			emit_8 $0x49, $0x83, $0xED
			emit_8 %bl

			# continue compile loop
			jmp c_loop

	c_gt:
		movb $1, %bl # store count

		c_gt_loop:
			call skip_other_chars
			movb (%rdi, %rsi), %al # store current char in al

			cmpb $CHAR_GT, %al # if char != >
			jne c_gt_loop_end # jump to loop end

			incb %bl # increment count
			incq %rsi # increment code index

			cmpb $0xF, %bl # if count == F
			je c_gt_loop_end # jump to loop end
			jmp c_gt_loop # else continue loop

		c_gt_loop_end:
			# addq <count>, %r13
			emit_8 $0x49, $0x83, $0xC5
			emit_8 %bl

			# continue compile loop
			jmp c_loop

	c_plus:
		movb $1, %bl # store count

		c_plus_loop:
			call skip_other_chars
			movb (%rdi, %rsi), %al # store current char in al

			cmpb $CHAR_PLUS, %al # if char != +
			jne c_plus_loop_end # jump to loop end

			incb %bl # increment count
			incq %rsi # increment code index

			cmpb $0xFF, %bl # if count == FF
			je c_plus_loop_end # jump to loop end
			jmp c_plus_loop # else continue loop

		c_plus_loop_end:
			# addb <count>, (%13)
			emit_8 $0x41, $0x80, $0x45, $0x0
			emit_8 %bl

			# continue compile loop
			jmp c_loop

	c_minus:
		movb $1, %bl # store count

		c_minus_loop:
			call skip_other_chars
			movb (%rdi, %rsi), %al # store current char in al

			cmpb $CHAR_MINUS, %al # if char != -
			jne c_minus_loop_end # jump to loop end

			incb %bl # increment count
			incq %rsi # increment code index

			cmpb $0xFF, %bl # if count == FF
			je c_minus_loop_end # jump to loop end
			jmp c_minus_loop # else continue loop

		c_minus_loop_end:
			# subb <count>, (%13)
			emit_8 $0x41, $0x80, $0x6D, $0x0
			emit_8 %bl

			# continue compile loop
			jmp c_loop

	c_dot:
		# movq $1, %rax # sys_write
		# movq $1, %rdi # write to stdout
		# movq %r13, %rsi # store the address of the cell we want to put in rsi
		# movq $1, %rdx # write 1 byte
		# syscall
		emit_8 $0x48, $0xC7, $0xC0, $0x01, $0x00, $0x00, $0x00
		emit_8 $0x48, $0xC7, $0xC7, $0x01, $0x00, $0x00, $0x00
		emit_8 $0x4C, $0x89, $0xEE
		emit_8 $0x48, $0xC7, $0xC2, $0x01, $0x00, $0x00, $0x00
		emit_8 $0x0F, $0x05

		# continue compile loop
		jmp c_loop

	c_comma:
		# movq $0, %rax # sys_read
		# movq $2, %rdi # read from stdin
		# movq %13, %rsi # store the address of the cell we want to get in rsi
		# movq $1, %rdx # read 1 byte
		# syscall
		emit_8 $0x48, $0xC7, $0xC0, $0x00, $0x00, $0x00, $0x00
		emit_8 $0x48, $0xC7, $0xC7, $0x02, $0x00, $0x00, $0x00
		emit_8 $0x4C, $0x89, $0xEE
		emit_8 $0x48, $0xC7, $0xC2, $0x01, $0x00, $0x00, $0x00
		emit_8 $0x0F, $0x05

		# continue compile loop
		jmp c_loop

	c_lb:
		call skip_other_chars
		pushq %rsi # store current code index on the stack

		# check for -]
		movb (%rdi, %rsi), %al # store current char
		cmpb $CHAR_MINUS, %al # if c != -
		jne c_lb_emit_loop # emit loop

		incq %rsi # skip -
		call skip_other_chars

		movb (%rdi, %rsi), %al # store next char

		cmpb $CHAR_RB, %al # if c != ]
		jne c_lb_emit_loop # emit loop

		c_lb_emit_clear:
			incq %rsi # skip ]
			addq $8, %rsp # "pop" code index from stack, ignoring the value

			# movb $0, (%r13)
			emit_8 $0x41, $0xC6, $0x45, $0x00, $0x00

			# continue compile loop
			jmp c_loop

		c_lb_emit_loop:
			popq %rsi # restore code index

			# cmpb $0, (%r13)
			emit_8 $0x41, $0x80, $0x7D, $0x00, $0x00

			# store the instruction index on the stack
			pushq %rdx

			# je <offset>
			emit_8 $0x0F, $0x84
			emit_32 $0 # reserve 4 bytes for the jump offset, this will be updated later

			# continue compile loop
			jmp c_loop

	c_rb:
		# cmpb $0, (%r13)
		emit_8 $0x41, $0x80, $0x7D, $0x00, $0x00

		# store the offset of [
		popq %r10

		# calculate relative offset for ]
		movq %rdx, %r11 # store instruction after the ] jump in r11
		addq $6, %r11 # skip the jump instruction

		movq %r10, %r12 # store instruction after the [ jump in r12
		addq $6, %r12 # skip the jump instruction

		subq %r12, %r11 # calculate offset to jump, r11 - r12, stored in r11
		notq %r11 # flip bits
		incq %r11 # add 1

		# jne <offset>
		emit_8 $0x0F, $0x85
		emit_32 %r11d

		# calculate relative offset for [
		movq %r10, %r11 # store instrution after the [ jump in r11
		addq $6, %r11 # skip the jump instruction

		movq %rdx, %r12 # store instruction after the ] jump in r12

		subq %r11, %r12 # calculate offset to jump, r12 - r11, stored in r12

		addq $2, %r10 # add 2 to r10 to get the jump location
		movl %r12d, INSTRUCTIONS(%r10)

		# continue compile loop
		jmp c_loop

	c_loop_end:
		# ret
		emit_8 $0xC3

		movq %rdx, %rax # set the instruction size as the return value

		movq %rbp, %rsp # clear local variables from stack
		popq %rbp # restore caller's base pointer
		ret # return from subroutine

# Skip characters that are not brainfuck instructions
#
# rdi should contain a NUL terminated string containing the brainfuck code
# rsi should contain code index
skip_other_chars:
	pushq %rbp # store caller's base pointer
	movq %rsp, %rbp # set base pointer to the stack pointer

	s_loop:
		movb (%rdi, %rsi), %al # store current char in al

		cmpb $CHAR_NUL, %al # if c == NUL
		je s_loop_end

		cmpb $CHAR_LT, %al # if c == <
		je s_loop_end

		cmpb $CHAR_GT, %al # if c == >
		je s_loop_end

		cmpb $CHAR_PLUS, %al # if c == +
		je s_loop_end

		cmpb $CHAR_MINUS, %al # if c == -
		je s_loop_end

		cmpb $CHAR_DOT, %al # if c == .
		je s_loop_end

		cmpb $CHAR_COMMA, %al # if c == ,
		je s_loop_end

		cmpb $CHAR_LB, %al # if c == [
		je s_loop_end

		cmpb $CHAR_RB, %al # if c == ]
		je s_loop_end

		incq %rsi # increment code index
		jmp s_loop # continue loop

	s_loop_end:
		movq %rbp, %rsp # clear local variables from stack
		popq %rbp # restore caller's base pointer
		ret # return from subroutine

# Execute the compiled brainfuck code
#
# rdi should contain the instruction size
execute:
	pushq %rbp # store caller's base pointer
	movq %rsp, %rbp # set base pointer to the stack pointer

	pushq %rdi # store the instruction size on the stack

	# If DEBUG is defined the JIT code should be written to a file
	#ifdef DEBUG
		# open file
		movq $filemode, %rsi # mode
		movq $filename, %rdi # name
		call fopen

		# store file on stack
		pushq %rax

		# write to file
		movq -16(%rbp), %rcx # file
		movq -8(%rbp), %rdx # amount
		movq $1, %rsi # size
		leaq (INSTRUCTIONS), %rdi # memory
		call fwrite

		# close file
		movq -16(%rbp), %rdi # file
		call fclose

		# remove file from stack
		popq %rax
	#endif

	# allocate RW memory
	movq $0, %r9 # offset
	movq $-1, %r8 # fd
	movq $34, %rcx # flags (MAP_PRIVATE | MAP_ANONYMOUS)
	movq $3, %rdx # prot (PROT_READ | PROT_WRITE)
	movq -8(%rbp), %rsi # length
	movq $0, %rdi # addr
	call mmap

	pushq %rax # store program memory on the stack

	# copy instructions to new memory region
	movq -8(%rbp), %rdx # size
	leaq (INSTRUCTIONS), %rsi # source
	movq -16(%rbp), %rdi # destination
	call memcpy

	# make memory executable
	movq $5, %rdx # prot (PROT_READ | PROT_EXEC)
	movq -8(%rbp), %rsi # size
	movq -16(%rbp), %rdi # address
	call mprotect

	# execute the code at the new memory
	call * -16(%rbp)

	# clean the allocated memory
	movq -8(%rbp), %rsi # length
	movq -16(%rbp), %rdi # address
	call munmap

	movq %rbp, %rsp # clear local variables from stack
	popq %rbp # restore caller's base pointer
	ret # return from subroutine
