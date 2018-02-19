4.bss

.lcomm clean_code, 300000
.lcomm stack, 300000
.lcomm vector_val, 300000

.text

format_nr: .asciz "%ld goodchar\n"

#	a) edi will first point to the beggining of clean_Code, in which
#	we will save just the brainfuck characters
#	b) stack will store the instruction adresses for the loops
#	vector_val will store the "variables" value in each position
#	c) the position counter will be r8d
#	d) the way I did loops is that after each ']'i stored the adress of it's
#	specific opening bracket, so whenever we meet an ']', we take the value of the specific
#	variable at the position of the opening bracket, save it in rax, check if rax is 0,
#	if rax is not 0, we start executing the loop. it will do this until the specific 
#	variable becomes 0. when it becomes 0, we will continue processing the next clean_code 
#	character, by moving to ebx the next instruction, instead of the instruction pointed by
#	the corresponding opening bracket( having the adress of the [ after it s specific ]
#	would make an infinite loop, unless the value of the variable becomes 0, and thus 
#	, after checking it in the [ process code part, we move the instruction adress continue
#	after the [<<which was moved after ]>> thus continuing the execution of the rest of the code, 
#	not the loop).


.global brainfuck

# Your brainfuck subroutine will receive one argument:
# a zero terminated string which is the name of the file that contains the code to execute.
	

brainfuck:
	
	pushq %rbp
	movq %rsp, %rbp
	
	movl $clean_code, %edi	#edi will store the values that are stosb'd, in the array called "clean code"
				#after we selected just the brainfuck commands from the input
	movq %rax, %rsi		#rax 	holds the input
	
	xor %ecx, %ecx
	xorq %r12, %r12
	xor %ebx, %ebx
	

select_good_characters:			
	
	lodsb			#load one character at a time from rsi to al
	test %al, %al		#we check for null, if not -> process
	je process_clean_code
	
	cmp $0x3E, %al                         #>
  	je valid_character
	cmp $0x3C, %al                         #<
  	je valid_character
	cmp $0x2B, %al                         #+
  	je valid_character
	cmp $0x2D, %al                         #-
  	je valid_character
	cmp $0x2E, %al                         #.
  	je valid_character
	cmp $0x2C, %al                         #,
  	je valid_character
	cmp $0x5B, %al                         #[
  	je open_square_bracket
	cmp $0x5D, %al                         #]
   	je close_square_bracket
	
        jmp select_good_characters             #invalid, ignore

valid_character:

	stosb					#store the good chars in clean code
	incl %ecx				#ecx stores the instruction (as in a pointer)
	jmp select_good_characters

open_square_bracket:
	stosb					#store the char [ 
	movl %ecx, stack( ,%ebx, 4) 		#move instruction pointer in stack, for corresponding
						# '[', ebx storing the count of (opened - closed) brackets	
	incl %ebx			

	add $4, %edi				#instruction size is 4, so we make space for it, so we can put
						# the corresponding  ] adress here later
					
	add $5, %ecx				#make the instruction pointer point to next instruction,
						
	jmp select_good_characters

close_square_bracket:
	stosb					#store the char ] 
	
	decl %ebx				#decrement ebx, so we know which opening bracket corresponds to 
						#this one

	movl stack(,%ebx, 4),%edx		#take the adress of previous [ 
	
	movl %edx, (%edi)			#and put it right after the ]
	addl $4, %edi				#next 4 bytes are the instruction pointed to
	incl %edx				#make edx point right after our [, in which we have empty space,
						#reserved for our closing bracket's adress
	movl %ecx,clean_code(%edx)		#put adress after the [
	addl $5, %ecx 				#point to next instruction
	jmp select_good_characters

process_clean_code:

	xorq %r14,%r14
	xorl %ebx, %ebx				#i = 0		
	xorl %r8d, %r8d		

loop:													
	mov clean_code(%ebx), %al		#clean_code[i] -> al			

  	cmpb $0x00, %al			
  	je end				
 	cmp $0x3E, %al				#  >
  	je next_position				
 	cmpb $0x3C, %al				# <
 	je previous_position				
	cmpb $0x2B, %al				# +
 	je inc				
  	cmpb $0x2D, %al				# -
	je dec				
  	cmpb $0x2E, %al				# .
	je output				
 	cmpb $0x2C, %al				# ,
	je input				
  	cmpb $0x5B, %al				# [
 	je start_loop				
 	cmpb $0x5D, %al				# ]
	je endloop				
	
processed:
	incq %r14			
 	incl %ebx				#point to next instruction, to continue execution			
 	jmp loop				
next_position:
	incl %r8d				#move to next variable			
 	jmp processed				
previous_position:
					
	decl %r8d				#move to anterior variable			
	jmp processed				
inc:					
	incq vector_val(, %r8d, 8)		#increase the value stored in variable no. r8d				
	jmp processed				
dec:
							
	decq vector_val(, %r8d, 8) 		#decrease value stored in variable no. r8d					
 	jmp processed				
output:
					
	movq $1, %rax 				
 	movq $1, %rdi				
 	leaq vector_val(, %r8d, 8), %rsi	#output value of vector_val[r8d]		
 	movq $1, %rdx				
 	syscall				
 	jmp processed				
input:
					
	movq $0, %rax					
	movq $0, %rdi				
	movq $1, %rdx				
	leaq vector_val(, %r8d, 8), %rsi	#save value from console in vector_val[r8d]			
	syscall				
 	jmp processed				
start_loop:					
	movq vector_val(, %r8d, 8),%rax		#save in rax the value of variable for loop				
	testq %rax, %rax			
	jne will_execute				
	incl %ebx				# if rax is 0, point to it's relevant ]
	movl clean_code(%ebx), %ebx		#execute starting from closing bracket adress		
	
will_execute:
					
	add $5, %ebx				#skip the ] adress, start executing loop|| else if rax was 0,
						#add 5 will jump over the adress of starting bracket, and go to 
						#the instruction that was originally after the closing bracket,
						#so after the loop	
	jmp loop				

endloop:	
					
	movq vector_val(, %r8d, 8),%rax		#check value of variable			
	testq %rax, %rax				
	je stop_loop				
	incl %ebx				#if it s not 0, will start executin from adress of the opening 
						#bracket, which means -do loop again
	mov clean_code(%ebx), %ebx				
	
stop_loop:
					
	addl $5, %ebx				#if it was not 0, before adding 5, we were pointed to [
						#skipping five will jump to first instruction in the loop,
						#thus starting executing it, else if rax was 0, we would've
						#jumped to the instruction originally after the ], thus ending
						#the loop			
 	jmp loop				
	
end:

	movq %rbp, %rsp
	popq %rbp
	ret
