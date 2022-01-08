# Brainfuck interpreter

.global brainfuck

.bss
CELLS: .skip 100000 # cells to operate on
OP_CODES: .skip 100000 # operations for the interpreter

.text
newline: .asciz "\n"

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

# opcode constants
.equ CODE_LEFT, 0x1
.equ CODE_RIGHT, 0x2
.equ CODE_ADD, 0x3
.equ CODE_SUB, 0x4
.equ CODE_PUT, 0x5
.equ CODE_GET, 0x6
.equ CODE_JMP_ZERO, 0x7
.equ CODE_JMP_NOT_ZERO, 0x8

# Brainfuck interpreter entrypoint
#
# rdi should contain a NUL terminated string containing the brainfuck code
brainfuck:
	pushq %rbp
	movq %rsp, %rbp

	# compile code
	# rdi already contains the code
	movq $0, %rdx
	movq $0, %rsi
	call compile
	
	# interpret opcodes
	call interpret
	
	# print newline
	movq $newline, %rdi
	movq $0, %rax
	call printf

	# return
	movq $0, %rax
	movq %rbp, %rsp
	popq %rbp
	ret

# Compile the brainfuck instructions
# rdi should contain the NUL terminated string
# rsi should contain the code index
# rdx should contain the opcode index
compile:
	pushq %rbp # store caller's base pointer
	movq %rsp, %rbp # set base pointer to the stack pointer

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
		movb $CODE_LEFT, OP_CODES(%rdx) # store opcode
		incq %rdx # increment opcode index

		movb $1, OP_CODES(%rdx) # store char count

		c_lt_loop:
			movb (%rdi, %rsi), %al # store current char in al

			cmpb $CHAR_LT, %al # if c != <
			jne c_lt_loop_end # jump to loop end

			incb OP_CODES(%rdx) # increment char count
			incq %rsi # increment code index

			cmpb $255, OP_CODES(%rdx) # if c_count == 255
			je c_lt_loop_end # jump to loop end
			jmp c_lt_loop # else continue loop

		c_lt_loop_end:
			incq %rdx # increment opcode index
			jmp c_loop

	c_gt:
		movb $CODE_RIGHT, OP_CODES(%rdx) # store opcode
		incq %rdx # increment opcode index

		movb $1, OP_CODES(%rdx) # store char count

		c_gt_loop:
			movb (%rdi, %rsi), %al # store current char in al

			cmpb $CHAR_GT, %al # if c != >
			jne c_gt_loop_end # jump to loop end

			incb OP_CODES(%rdx) # increment char count
			incq %rsi # increment code index

			cmpb $255, OP_CODES(%rdx) # if c_count == 255
			je c_gt_loop_end # jump to loop end
			jmp c_gt_loop # else continue loop

		c_gt_loop_end:
			incq %rdx # increment opcode index
			jmp c_loop

	c_plus:
		movb $CODE_ADD, OP_CODES(%rdx) # store opcode
		incq %rdx # increment opcode index

		movb $1, OP_CODES(%rdx) # store char count

		c_plus_loop:
			movb (%rdi, %rsi), %al # store current char in al

			cmpb $CHAR_PLUS, %al # if c != +
			jne c_plus_loop_end # jump to loop end

			incb OP_CODES(%rdx) # increment char count
			incq %rsi # increment code index

			cmpb $255, OP_CODES(%rdx) # if c_count == 255
			je c_plus_loop_end # jump to loop end
			jmp c_plus_loop # else continue loop

		c_plus_loop_end:
			incq %rdx # increment opcode index
			jmp c_loop

	c_minus:
		movb $CODE_SUB, OP_CODES(%rdx) # store opcode
		incq %rdx # increment opcode index

		movb $1, OP_CODES(%rdx) # store char count

		c_minus_loop:
			movb (%rdi, %rsi), %al # store current char in al

			cmpb $CHAR_MINUS, %al # if c != -
			jne c_minus_loop_end # jump to loop end

			incb OP_CODES(%rdx) # increment char count
			incq %rsi # increment code index

			cmpb $255, OP_CODES(%rdx) # if c_count == 255
			je c_minus_loop_end # jump to loop end
			jmp c_minus_loop # else continue loop

		c_minus_loop_end:
			incq %rdx # increment opcode index
			jmp c_loop

	c_dot:
		movb $CODE_PUT, OP_CODES(%rdx) # store opcode
		incq %rdx # increment opcode index
		jmp c_loop

	c_comma:
		movb $CODE_GET, OP_CODES(%rdx) # store opcode
		incq %rdx # increment opcode index
		jmp c_loop

	c_lb:
		movb $CODE_JMP_ZERO, OP_CODES(%rdx) # store opcode
		incq %rdx # increment opcode index

		pushq %rdx # store opcode index of the jump location
		addq $8, %rdx # add 8 to opcode index, as we need to reserve 8 bytes for the jump location

		jmp c_loop # recursively compile code

	c_rb:
		movb $CODE_JMP_NOT_ZERO, OP_CODES(%rdx) # store opcode
		incq %rdx # increment opcode index

		popq %r10 # pop jump location of the matching opening bracket

		movq %r10, %r11 # store a copy of r10 in r11
		addq $8, %r11 # add 8 to the location, as we want to jump to the instruction after the location
		movq %r11, OP_CODES(%rdx) # store jump location

		addq $8, %rdx # add 8 to opcode index, as the jump location is 8 bytes
		movq %rdx, OP_CODES(%r10) # patch the jump location of the opening bracket

		jmp c_loop

	c_loop_end:
		movq %rbp, %rsp # clear local variables from stack
		popq %rbp # restore caller's base pointer
		ret # return from subroutine

# Interpret the brainfuck instructions
interpret:
	pushq %rbp # store caller's base pointer
	movq %rsp, %rbp # set base pointer to the stack pointer
	
	pushq $0 # opcode index
	pushq $0 # cell index
	
	i_loop:
		movq -8(%rbp), %rdi # store opcode index in rdi
		movq -16(%rbp), %rsi # store cell index in rsi

		movb OP_CODES(%rdi), %al # store current opcode in al
		incq -8(%rbp) # increment opcode index

		cmpb $CODE_LEFT, %al # if al == CODE_LEFT
		je i_left

		cmpb $CODE_RIGHT, %al # if al == CODE_RIGHT
		je i_right

		cmpb $CODE_ADD, %al # if al == CODE_ADD
		je i_add

		cmpb $CODE_SUB, %al # if al == CODE_SUB
		je i_sub

		cmpb $CODE_PUT, %al # if al == CODE_PUT
		je i_put

		cmpb $CODE_GET, %al # if al == CODE_GET
		je i_get

		cmpb $CODE_JMP_ZERO, %al # if al == CODE_JMP_ZERO
		je i_jmp_zero

		cmpb $CODE_JMP_NOT_ZERO, %al # if al == CODE_JMP_NOT_ZERO
		je i_jmp_not_zero

		# no more opcodes, so we're done
		jmp i_loop_end

	i_left:
		movq -8(%rbp), %rdi # store opcode index in rdi

		movb OP_CODES(%rdi), %al # store amount in al
		incq -8(%rbp) # increment opcode index

		movzx %al, %rdx
		subq %rdx, -16(%rbp) # subtract amount from cell index
		jmp i_loop

	i_right:
		movq -8(%rbp), %rdi # store opcode index in rdi

		movb OP_CODES(%rdi), %al # store amount in al
		incq -8(%rbp) # increment opcode index

		movzx %al, %rdx
		addq %rdx, -16(%rbp) # add amount to cell index
		jmp i_loop

	i_add:
		movq -8(%rbp), %rdi # store opcode index in rdi

		movb OP_CODES(%rdi), %al # store amount in al
		incq -8(%rbp) # increment opcode index
		
		addb %al, CELLS(%rsi) # add amount to cell index
		jmp i_loop

	i_sub:
		movq -8(%rbp), %rdi # store opcode index in rdi

		movb OP_CODES(%rdi), %al # store amount in al
		incq -8(%rbp) # increment opcode index

		subb %al, CELLS(%rsi) # subtract amount from cell index
		jmp i_loop

	i_put:
		movq -16(%rbp), %r10 # store cell index in r10

		movq $1, %rax # sys_write
		movq $1, %rdi # write to stdout
		leaq CELLS(%r10), %rsi # store the address of the cell we want to put in rsi
		movq $1, %rdx # write 1 byte
		syscall

		jmp i_loop

	i_get:
		movq -16(%rbp), %r10 # store cell index in r10

		movq $0, %rax # sys_read
		movq $2, %rdi # read from stdin
		leaq CELLS(%r10), %rsi # store the address of the cell we want to get in rsi
		movq $1, %rdx # read 1 byte
		syscall

		jmp i_loop

	i_jmp_zero:
		movq -16(%rbp), %rsi # store cell index in rsi
		movb CELLS(%rsi), %al # store cell value in al

		cmpb $0, %al # if al == 0
		je i_jmp_to_location # jump to the location

		# skip over the jump location and continue execution
		addq $8, -8(%rbp) # add 8 opcode index
		jmp i_loop

	i_jmp_not_zero:
		movq -16(%rbp), %rsi # store cell index in rsi
		movb CELLS(%rsi), %al # store cell value in al
		
		cmpb $0, %al # if al != 0
		jne i_jmp_to_location # jump to the location
		
		# skip over the jump location and continue execution
		addq $8, -8(%rbp) # add 8 to opcode index
		jmp i_loop
	
	i_jmp_to_location:
		movq -8(%rbp), %rdi # store cell index in rdi

		movq OP_CODES(%rdi), %rdx # store jump location in rdx
		movq %rdx, -8(%rbp) # make the jump location the opcode index

		jmp i_loop

	i_loop_end:
		movq %rbp, %rsp # clear local variables from stack
		popq %rbp # restore caller's base pointer
		ret # return from subroutine
