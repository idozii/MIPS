#EXCERSISE 1:
.data
count: .space 128
string: .asciiz "a, c, b,a,+,1,2,a.b"
newline: .asciiz "\n"
comma_space: .asciiz ", "
semicolon_space: .asciiz "; "

.text
main:
    la $t0, string
    la $t1, count
    li $t2, 0

count_char:
    lb $t3, 0($t0)  
    beq $t3, $zero, exit_count
    li $t4, 44
    beq $t4, $t3, skip_char
    li $t5, 32
    beq $t5, $t3, skip_char
    la $t1, count
    add $t1, $t1, $t3
    lb $t4, 0($t1) 
    addi $t4, $t4, 1 
    sb $t4, 0($t1) 
    addi $t0, $t0, 1 
    j count_char

skip_char:
     addi $t0, $t0, 1
	j count_char
exit_count:
    li $t6, 1  
    li $t4, 128
print_loop:
    li $t2, 0 
    la $t1, count 
inner_loop:
    lb $t3, 0($t1)
    beq $t3, $zero, skip_inner_print 
    bne $t3, $t6, skip_inner_print  
    li $v0, 11   
    move $a0, $t2	
    syscall

    li $v0, 4    
    la $a0, comma_space
    syscall

    li $v0, 1 
    move $a0, $t3 
    syscall

    li $v0, 4
    la $a0, semicolon_space
    syscall
skip_inner_print:
    addi $t1, $t1, 1  
    addi $t2, $t2, 1 
    bne $t2, $t4, inner_loop

    addi $t6, $t6, 1  
    li $t5, 128
    bne $t6, $t5, print_loop 

    li $v0, 10
    syscall


#EXERCISE 2:
.data
array: .space 20
prompt: .asciiz "Enter integer: "
newline: .asciiz "\n"
space: .asciiz " "

.text
.globl main

main:
     li $t2, 5
     la $t0, array
     li $t1, 0

read_loop:
     li $v0, 4
     la $a0, prompt
     syscall

     li $v0, 5          
     syscall
     sw $v0, 0($t0)     
     addi $t0, $t0, 4   
     addi $t1, $t1, 1  
     bne $t1, $t2, read_loop

     la $t0, array
     li $t1, 0
check_divisibility:
     beq $t1, $t2, exit
     lw $t3, 0($t0)           
     rem $t4, $t3, 4           
     beqz $t4, print_element   
    
adjust_element:
     bge $t4, 3, round_up
     sub $t3, $t3, 1
     rem $t4, $t3, 4
     bnez $t4, adjust_element
     j print_element

round_up:
     add $t3, $t3, 1
     rem $t4, $t3, 4
     bnez $t4, round_up
     j print_element

print_element:
     li $v0, 1
     move $a0, $t3
     syscall

     li $v0, 4
     la $a0, space
     syscall

     addi $t0, $t0, 4   
     addi $t1, $t1, 1   
     j check_divisibility

exit:
     li $v0, 10
     syscall

#EXERCISE 3:
.data
prompt: .asciiz "Please insert element "
newline: .asciiz "\n"
second_largest_msg: .asciiz "Second largest value is "
index_msg: .asciiz ", found in index "
array: .space 40
comma: .asciiz ", "

.text
main:
    la $t0, array
    li $t1, 0
    li $t2, 10

read_loop:
    li $v0, 4
    la $a0, prompt
    syscall

    li $v0, 1
    addi $a0, $t1, 1
    syscall

    li $v0, 4
    la $a0, newline
    syscall

    li $v0, 5         
    syscall
    sw $v0, 0($t0)     
    addi $t0, $t0, 4  
    addi $t1, $t1, 1  
    bne $t1, $t2, read_loop

    la $t0, array
    lw $t3, 0($t0)     
    lw $t4, 0($t0)    
    addi $t0, $t0, 4
    li $t1, 10

find_largest:
    beq $t1, $t2, find_indexes  
    lw $t5, 0($t0)          
    bge $t5, $t3, update_largest
    bge $t5, $t4, update_second_largest
    j next_element

update_largest:
    move $t4, $t3             
    move $t3, $t5               
    j next_element

update_second_largest:
    move $t4, $t5              
    j next_element

next_element:
    addi $t0, $t0, 4            
    addi $t1, $t1, -1          
    j find_largest

find_indexes:
    li $v0, 4
    la $a0, second_largest_msg
    syscall

    li $v0, 1
    move $a0, $t4
    syscall

    li $v0, 4
    la $a0, index_msg
    syscall

    la $t0, array
    li $t1, 0

print_indexes:
    beq $t1, $t2, exit          
    lw $t5, 0($t0)              
    bne $t5, $t4, next_index   

    li $v0, 1
    move $a0, $t1
    syscall

    li $v0, 4
    la $a0, comma
    syscall

next_index:
    addi $t0, $t0, 4            
    addi $t1, $t1, 1          
    j print_indexes

exit:
    li $v0, 10
    syscall