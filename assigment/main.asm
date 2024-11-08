.data 
#Dynamic Allocation
buffer: .space 2048

#File names
input_file: .asciiz "input_matrix.txt"
output_file: .asciiz "output_matrix.txt"
header: .asciiz "--------RESULT--------\n"

#Ouput details
result: .asciiz "The result is: \n"
image_msg: .asciiz "Image Matrix:\n"
kernel_msg: .asciiz "Kernel Matrix:\n"
output_msg: .asciiz "Output Matrix:\n"
padding_msg: .asciiz "Padded Matrix:\n"
space: .asciiz " "
newline: .asciiz "\n"

#Variables
N: .float 0.0
M: .float 0.0
p: .float 0.0
s: .float 0.0
temp: .space 16

#Matrices
image: .word 0
kernel: .word 0
output: .word 0
padded_image: .word 0

#Errors ha
error_open: .asciiz "Error opening file\n"
error_parse: .asciiz "Error parsing file\n"
error_params: .asciiz "Invalid parameters\n"
padding_error: .asciiz "Invalid padding/stride parameters\n"

.text
main:
    li $v0, 13
    la $a0, input_file
    li $a1, 0         
    li $a2, 0
    syscall
    bltz $v0, file_error
    move $s0, $v0      

    li $v0, 14
    move $a0, $s0
    la $a1, buffer
    li $a2, 2047       
    syscall
    bltz $v0, file_error
    move $s4, $v0     
    
    la $t0, buffer
    add $t0, $t0, $s4
    sb $zero, ($t0)

    li $v0, 16
    move $a0, $s0
    syscall

    li $v0, 9
    move $a0, $s4
    addiu $a0, $a0, 4  
    syscall
    move $s1, $v0     

    la $s2, buffer
    move $s3, $s1
    li $t0, 0

parse_first_row:
    la $s3, temp        
    li $t0, 0           

read_number:
    la $s3, temp        
    li $t1, 0           

get_chars:
    lb $t2, ($s2)        
    beq $t2, 32, finish_num  
    beq $t2, 10, finish_num  
    beq $t2, 0, finish_num   
    
    sb $t2, ($s3)        
    addi $s2, $s2, 1    
    addi $s3, $s3, 1     
    addi $t1, $t1, 1     
    j get_chars

finish_num:
    sb $zero, ($s3)      
    jal string_to_float
    
    beq $t0, 0, store_N
    beq $t0, 1, store_M
    beq $t0, 2, store_p
    beq $t0, 3, store_s
    j parse_error        

string_to_float:
    la $t3, temp         
    li $t4, 0          
    li $t5, 0           
    li $t6, 10          
    li $t9, 0           
    li $s7, 1           
    
    lb $t7, ($t3)
    li $t8, 45          
    bne $t7, $t8, str_to_float_loop
    li $s7, -1          
    addi $t3, $t3, 1    
    
str_to_float_loop:
    lb $t7, ($t3)      
    beq $t7, 0, finish_float  
    beq $t7, 46, decimal_point
    
    li $t8, 48          
    sub $t7, $t7, $t8   
    
    beq $t5, 1, handle_decimal
    mul $t4, $t4, 10    
    add $t4, $t4, $t7   
    addi $t3, $t3, 1    
    j str_to_float_loop
    
decimal_point:
    li $t5, 1           
    addi $t3, $t3, 1    
    j str_to_float_loop
    
handle_decimal:
    addi $t9, $t9, 1    
    beq $t9, 2, finish_float  
    mul $t4, $t4, 10    
    add $t4, $t4, $t7   
    addi $t3, $t3, 1    
    j str_to_float_loop
    
finish_float:
    mtc1 $t4, $f0      
    cvt.s.w $f0, $f0   
    mtc1 $t6, $f2      
    cvt.s.w $f2, $f2   
    div.s $f0, $f0, $f2
    
    mtc1 $s7, $f2
    cvt.s.w $f2, $f2    
    mul.s $f0, $f0, $f2
    
    jr $ra              

store_N:
    s.s $f0, N
    j next_num
store_M:
    s.s $f0, M
    j next_num
store_p:
    cvt.w.s $f0, $f0    
    cvt.s.w $f0, $f0    
    s.s $f0, p
    j next_num
store_s:
    cvt.w.s $f0, $f0    
    cvt.s.w $f0, $f0    
    s.s $f0, s
    j allocate_matrices

next_num:
    addi $t0, $t0, 1     
    addi $s2, $s2, 1     
    j read_number

allocate_matrices:
    l.s $f0, N
    cvt.w.s $f0, $f0    
    mfc1 $t0, $f0        
    mul $t1, $t0, $t0    
    sll $t1, $t1, 2      
    
    li $v0, 9
    move $a0, $t1
    syscall
    sw $v0, image        

    l.s $f0, M
    cvt.w.s $f0, $f0     
    mfc1 $t0, $f0        
    mul $t1, $t0, $t0    
    sll $t1, $t1, 2      
    
    li $v0, 9
    move $a0, $t1
    syscall
    sw $v0, kernel       

    j parse_matrices      

parse_matrices:
    addi $s2, $s2, 1
    lw $s3, image        
    l.s $f0, N
    cvt.w.s $f0, $f0
    mfc1 $s4, $f0        
    mul $s5, $s4, $s4    
    li $t0, 0            

parse_image:
    la $t8, temp         
    li $t1, 0            

get_image_num:
    lb $t2, ($s2)        
    beq $t2, 32, end_image_num  
    beq $t2, 10, end_image_num  
    beq $t2, 0, end_image_num   
    
    sb $t2, ($t8)        
    addi $s2, $s2, 1     
    addi $t8, $t8, 1     
    addi $t1, $t1, 1     
    j get_image_num

end_image_num:
    sb $zero, ($t8)      
    jal string_to_float  
    
    s.s $f0, ($s3)       
    addi $s3, $s3, 4     
    addi $t0, $t0, 1     
    addi $s2, $s2, 1     
    
    bne $t0, $s5, parse_image  

    addi $s2, $s2, 1
    lw $s3, kernel       
    l.s $f0, M
    cvt.w.s $f0, $f0
    mfc1 $s4, $f0        
    mul $s5, $s4, $s4    
    li $t0, 0            

parse_kernel:
    la $t8, temp         
    li $t1, 0            

get_kernel_num:
    lb $t2, ($s2)
    beq $t2, 32, end_kernel_num
    beq $t2, 10, end_kernel_num
    beq $t2, 0, end_kernel_num
    
    sb $t2, ($t8)
    addi $s2, $s2, 1
    addi $t8, $t8, 1
    addi $t1, $t1, 1
    j get_kernel_num

end_kernel_num:
    sb $zero, ($t8)
    jal string_to_float
    
    s.s $f0, ($s3)
    addi $s3, $s3, 4
    addi $t0, $t0, 1
    addi $s2, $s2, 1
    
    bne $t0, $s5, parse_kernel

    jal do_convolution
    j print_all_matrices

do_convolution:
    l.s $f0, N
    l.s $f1, p
    l.s $f2, M
    l.s $f3, s
    
    li.s $f4, 2.0
    mul.s $f4, $f4, $f1
    add.s $f4, $f0, $f4
    sub.s $f4, $f4, $f2
    div.s $f4, $f4, $f3
    li.s $f5, 1.0
    add.s $f4, $f4, $f5
    
    cvt.w.s $f4, $f4
    mfc1 $s0, $f4
    
    mul $t0, $s0, $s0
    sll $t0, $t0, 2
    li $v0, 9
    move $a0, $t0
    syscall
    sw $v0, output
    
    l.s $f0, N
    l.s $f1, p
    add.s $f0, $f0, $f1
    add.s $f0, $f0, $f1
    cvt.w.s $f0, $f0
    mfc1 $t0, $f0
    mul $t1, $t0, $t0
    sll $t1, $t1, 2
    li $v0, 9
    move $a0, $t1
    syscall
    sw $v0, padded_image
    
    lw $t0, padded_image
    move $t1, $t0
    l.s $f0, N
    l.s $f1, p
    add.s $f0, $f0, $f1
    add.s $f0, $f0, $f1
    cvt.w.s $f0, $f0
    mfc1 $t2, $f0
    mul $t3, $t2, $t2
    
zero_pad:
    mtc1 $zero, $f0
    s.s $f0, ($t1)
    addi $t1, $t1, 4
    addi $t3, $t3, -1
    bgtz $t3, zero_pad
    
    lw $t0, image
    lw $t1, padded_image
    l.s $f0, p
    cvt.w.s $f0, $f0
    mfc1 $t2, $f0
    l.s $f0, N
    cvt.w.s $f0, $f0
    mfc1 $t3, $f0
    l.s $f0, N
    l.s $f1, p
    add.s $f0, $f0, $f1
    add.s $f0, $f0, $f1
    cvt.w.s $f0, $f0
    mfc1 $t4, $f0
    
    mul $t5, $t2, $t4
    add $t5, $t5, $t2
    sll $t5, $t5, 2
    add $t1, $t1, $t5
    
copy_input:
    move $t6, $zero
copy_row:
    move $t7, $zero
copy_col:
    l.s $f0, ($t0)
    s.s $f0, ($t1)
    addi $t0, $t0, 4
    addi $t1, $t1, 4
    addi $t7, $t7, 1
    blt $t7, $t3, copy_col
    
    mul $t8, $t2, 2
    sll $t8, $t8, 2
    add $t1, $t1, $t8
    addi $t6, $t6, 1
    blt $t6, $t3, copy_row
    
    lw $t0, padded_image
    lw $t1, kernel
    lw $t2, output
    l.s $f0, s
    cvt.w.s $f0, $f0
    mfc1 $t3, $f0
    
    li $t4, 0
conv_row:
    li $t5, 0
conv_col:
    mtc1 $zero, $f12
    
    li $t6, 0
ker_row:
    li $t7, 0
ker_col:
    l.s $f0, ($t1)
    
    mul $t8, $t4, $t3
    add $t8, $t8, $t6
    l.s $f1, N
    l.s $f2, p
    add.s $f1, $f1, $f2
    add.s $f1, $f1, $f2
    cvt.w.s $f1, $f1
    mfc1 $t9, $f1
    mul $t8, $t8, $t9
    
    mul $t9, $t5, $t3
    add $t9, $t9, $t7
    add $t8, $t8, $t9
    
    sll $t8, $t8, 2
    add $t8, $t0, $t8
    l.s $f1, ($t8)
    
    mul.s $f0, $f0, $f1
    add.s $f12, $f12, $f0
    
    addi $t1, $t1, 4
    addi $t7, $t7, 1
    l.s $f0, M
    cvt.w.s $f0, $f0
    mfc1 $t8, $f0
    blt $t7, $t8, ker_col
    
    addi $t6, $t6, 1
    blt $t6, $t8, ker_row
    
    s.s $f12, ($t2)
    addi $t2, $t2, 4
    
    addi $t5, $t5, 1
    blt $t5, $s0, conv_col
    
    addi $t4, $t4, 1
    blt $t4, $s0, conv_row
    
    jr $ra

print_all_matrices:
    li $v0, 4
    la $a0, header
    syscall
    
    li $v0, 4
    la $a0, image_msg
    syscall
    
    lw $s3, image
    l.s $f0, N
    cvt.w.s $f0, $f0
    mfc1 $s4, $f0
    li $t0, 0
print_image:
    li $t1, 0
print_image_element:
    l.s $f12, ($s3)
    li $v0, 2
    syscall
    
    li $v0, 4
    la $a0, space
    syscall
    
    addi $s3, $s3, 4
    addi $t1, $t1, 1
    blt $t1, $s4, print_image_element
    
    li $v0, 4
    la $a0, newline
    syscall
    
    addi $t0, $t0, 1
    blt $t0, $s4, print_image
    
    li $v0, 4
    la $a0, kernel_msg
    syscall
    
    lw $s3, kernel
    l.s $f0, M
    cvt.w.s $f0, $f0
    mfc1 $s4, $f0
    li $t0, 0
print_kernel:
    li $t1, 0
print_kernel_element:
    l.s $f12, ($s3)
    li $v0, 2
    syscall
    
    li $v0, 4
    la $a0, space
    syscall
    
    addi $s3, $s3, 4
    addi $t1, $t1, 1
    blt $t1, $s4, print_kernel_element
    
    li $v0, 4
    la $a0, newline
    syscall
    
    addi $t0, $t0, 1
    blt $t0, $s4, print_kernel
    
    li $v0, 4
    la $a0, output_msg
    syscall
    
    lw $s3, output
    move $t0, $zero
print_output:
    move $t1, $zero
print_output_element:
    l.s $f12, ($s3)
    li $v0, 2
    syscall
    
    li $v0, 4
    la $a0, space
    syscall
    
    addi $s3, $s3, 4
    addi $t1, $t1, 1
    blt $t1, $s0, print_output_element
    
    li $v0, 4
    la $a0, newline
    syscall
    
    addi $t0, $t0, 1
    blt $t0, $s0, print_output
    
    j exit

file_error:
    li $v0, 4
    la $a0, error_open
    syscall
    j exit

parse_error:
    li $v0, 4
    la $a0, error_parse
    syscall
    j exit

params_error:
    li $v0, 4
    la $a0, error_params
    syscall
    j exit

exit:
    li $v0, 10
    syscall