#EXCERSISE 1:
.data
hello: .asciiz "Hello, "
strIn: .space 100

.text

main:
     li $v0, 8      
     la $a0, strIn      
     li $a1, 100        
     syscall            

     li $v0, 4          
     la $a0, hello   
     syscall           

     li $v0, 4          
     la $a0, strIn     
     syscall            

     li $v0, 10        
     syscall         
 
.data
prompt0: .asciiz "Please input element 0: "
prompt1: .asciiz "Please input element 1: "
prompt2: .asciiz "Please input element 2: "
prompt3: .asciiz "Please input element 3: "
prompt4: .asciiz "Please input element 4: "
index_prompt: .asciiz "Please enter index: "
newline: .asciiz "\n"
array: .space 20 

.text
.globl main

main:
    la $t0, array
    li $t1, 0 

input_loop:
    beq $t1, 5, input_done

    li $v0, 4
    beq $t1, 0, prompt0_label
    beq $t1, 1, prompt1_label
    beq $t1, 2, prompt2_label
    beq $t1, 3, prompt3_label
    beq $t1, 4, prompt4_label

prompt0_label:
    la $a0, prompt0
    j print_prompt
prompt1_label:
    la $a0, prompt1
    j print_prompt
prompt2_label:
    la $a0, prompt2
    j print_prompt
prompt3_label:
    la $a0, prompt3
    j print_prompt
prompt4_label:
    la $a0, prompt4

print_prompt:
    syscall

    li $v0, 5
    syscall
    sw $v0, 0($t0)

    addi $t1, $t1, 1
    addi $t0, $t0, 4
    j input_loop

input_done:
    li $v0, 4
    la $a0, index_prompt
    syscall

    li $v0, 5
    syscall
    move $t2, $v0

    la $t0, array
    sll $t2, $t2, 2
    add $t0, $t0, $t2
    lw $t3, 0($t0)

    li $v0, 1
    move $a0, $t3
    syscall

    li $v0, 4
    la $a0, newline
    syscall

    li $v0, 10
    syscall

#EXERCISE 3:
.data
prompt_a: .asciiz "Insert a: "
prompt_b: .asciiz "Insert b: "
prompt_c: .asciiz "Insert c: "
prompt_d: .asciiz "Insert d: "
result_msg: .asciiz "F = "
remainder_msg: .asciiz ", remainder "
newline: .asciiz "\n"

.text
main:
     li $v0, 4
     la $a0, prompt_a
     syscall
     li $v0, 5
     syscall
     move $t0, $v0 

     li $v0, 4
     la $a0, prompt_b
     syscall
     li $v0, 5
     syscall
     move $t1, $v0

     li $v0, 4
     la $a0, prompt_c
     syscall
     li $v0, 5
     syscall
     move $t2, $v0 

     li $v0, 4
     la $a0, prompt_d
     syscall
     li $v0, 5
     syscall
     move $t3, $v0

     addi $t4, $t0, 10     
     sub $t5, $t1, $t3
     mul $t4, $t4, $t5     
     mul $t6, $t0, 2       
     sub $t6, $t2, $t6     
     mul $t4, $t4, $t6    

     add $t7, $t0, $t1    
     add $t7, $t7, $t2     

     div $t4, $t7
     mflo $t8
     mfhi $t9       

     li $v0, 4
     la $a0, result_msg
     syscall

     li $v0, 1
     move $a0, $t8
     syscall

     li $v0, 4
     la $a0, remainder_msg
     syscall

     li $v0, 1
     move $a0, $t9
     syscall

     li $v0, 4
     la $a0, newline
     syscall

     li $v0, 10
     syscall

#EXERCISE 4:
.data
prompt: .asciiz "Please enter a positive integer less than 16: "
binary_msg: .asciiz "Its binary form is: "
binary: .space 5 

.text
main:
    li $v0, 4          
    la $a0, prompt   
    syscall        

    li $v0, 5        
    syscall            
    move $t0, $v0     

    li $t1, 16       
    bge $t0, $t1, exit

    la $t2, binary     
    addi $t2, $t2, 4
    li $t3, 4         

convert_loop:
    beq $t3, $zero, print_binary 
    addi $t2, $t2, -1   
    andi $t4, $t0, 1       
    addi $t4, $t4, 48      
    sb $t4, 0($t2)         
    srl $t0, $t0, 1       
    addi $t3, $t3, -1      
    j convert_loop         

print_binary:
    la $t2, binary
    addi $t2, $t2, 4
    sb $zero, 0($t2)

    li $v0, 4          
    la $a0, binary_msg 
    syscall          

    li $v0, 4          
    la $a0, binary     
    syscall            

exit:
    li $v0, 10      
    syscall          