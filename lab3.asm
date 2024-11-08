#EXCERSISE 1:
.data
    input_msg: .asciiz "Please insert a: "
    input_msg1: .asciiz "Please insert b: "
    input_msg2: .asciiz "Please insert c: "
    print_msg1: .asciiz "x1= "
    print_msg2: .asciiz "x2= "
    one_solution: .asciiz "There is one solution, x = "
    error_msg: .asciiz "There is no real solution"
    linear_msg: .asciiz "The solution is x = "
    zero_b_msg: .asciiz "b must not be 0"
    newline: .asciiz "\n"

.text
main:
    li $v0, 4           
    la $a0, input_msg  
    syscall
    li $v0, 6          
    syscall
    mov.s $f1, $f0    

    li.s $f8, 0.0
    c.eq.s $f1, $f8
    bc1t linear_case

    li $v0, 4
    la $a0, input_msg1
    syscall
    li $v0, 6          
    syscall
    mov.s $f2, $f0    

    li $v0, 4
    la $a0, input_msg2
    syscall
    li $v0, 6          
    syscall
    mov.s $f3, $f0    

linear_case:
    # Input b
    li $v0, 4
    la $a0, input_msg1
    syscall
    li $v0, 6          
    syscall
    mov.s $f2, $f0
    
    # Check if b = 0
    c.eq.s $f2, $f8
    bc1t invalid_linear
    
    # Input c
    li $v0, 4
    la $a0, input_msg2
    syscall
    li $v0, 6
    syscall
    mov.s $f3, $f0
    
    # Solve linear equation: x = -c/b
    neg.s $f4, $f3
    div.s $f5, $f4, $f2
    
    # Print result
    li $v0, 4
    la $a0, linear_msg
    syscall
    li $v0, 2
    mov.s $f12, $f5
    syscall
    j exit

invalid_linear:
    li $v0, 4
    la $a0, zero_b_msg
    syscall
    j exit

calculation_step:
    mul.s $f4, $f2, $f2    # b^2
    li.s $f5, 4.0         
    mul.s $f6, $f1, $f3    # ac
    mul.s $f6, $f6, $f5    # 4ac
    sub.s $f7, $f4, $f6    # discriminant

    # Check discriminant
    li.s $f8, 0.0
    c.lt.s $f7, $f8       
    bc1t print_error
    
    c.eq.s $f7, $f8        
    bc1t one_sol

two_solutions:
    # Calculate x1 = (-b + sqrt(discriminant))/(2a)
    sqrt.s $f9, $f7        # sqrt(discriminant)
    neg.s $f10, $f2        # -b
    add.s $f11, $f10, $f9  # -b + sqrt(discriminant)
    li.s $f12, 2.0
    mul.s $f13, $f1, $f12  # 2a
    div.s $f14, $f11, $f13 # x1

    # Calculate x2 = (-b - sqrt(discriminant))/(2a)
    sub.s $f11, $f10, $f9  # -b - sqrt(discriminant)
    div.s $f15, $f11, $f13 # x2

    li $v0, 4
    la $a0, print_msg1
    syscall
    li $v0, 2
    mov.s $f12, $f14
    syscall
    
    li $v0, 4
    la $a0, newline
    syscall
    
    li $v0, 4
    la $a0, print_msg2
    syscall
    li $v0, 2
    mov.s $f12, $f15
    syscall
    j exit

one_sol:
    neg.s $f10, $f2        # -b
    li.s $f11, 2.0
    mul.s $f12, $f1, $f11  # 2a
    div.s $f13, $f10, $f12 # x

    li $v0, 4
    la $a0, one_solution
    syscall
    li $v0, 2
    mov.s $f12, $f13
    syscall
    j exit

print_error:
    li $v0, 4
    la $a0, error_msg
    syscall

exit:
    li $v0, 10
    syscall

#EXERCISE 2:
.data
input_msg: .asciiz "Please insert a: "
input_msg1: .asciiz "Please insert b: "
input_msg2: .asciiz "Please insert c: "
input_msg3: .asciiz "Please insert d: "
input_msg4: .asciiz "Please insert e: "
input_msg5: .asciiz "Please insert u: "
input_msg6: .asciiz "Please insert v: "
result_msg: .asciiz "Result is: "

.text
main:
    li $v0, 4           
    la $a0, input_msg  
    syscall
    li $v0, 6          
    syscall
    mov.s $f1, $f0    

    li $v0, 4
    la $a0, input_msg1
    syscall
    li $v0, 6          
    syscall
    mov.s $f2, $f0    

    li $v0, 4
    la $a0, input_msg2
    syscall
    li $v0, 6          
    syscall
    mov.s $f3, $f0  

    li $v0, 4
    la $a0, input_msg3
    syscall
    li $v0, 6          
    syscall
    mov.s $f4, $f0  

    li $v0, 4
    la $a0, input_msg4
    syscall
    li $v0, 6          
    syscall
    mov.s $f5, $f0  

    li $v0, 4
    la $a0, input_msg5
    syscall
    li $v0, 6          
    syscall
    mov.s $f6, $f0  

    li $v0, 4
    la $a0, input_msg6
    syscall
    li $v0, 6          
    syscall
    mov.s $f7, $f0  

print_result:
    mov.s $f25, $f7     # Save v in temporary register
    # Calculate F(u)
    mov.s $f7, $f6    
    jal calculate_F    
    mov.s $f8, $f0      # Store F(u)

    # Calculate F(v)
    mov.s $f7, $f25   
    jal calculate_F    
    mov.s $f9, $f0      # Store F(v)

    sub.s $f12, $f8, $f9

    li $v0, 4
    la $a0, result_msg 
    syscall
    li $v0, 2           
    syscall

exit:
    li $v0, 10
    syscall

calculate_F:
    mul.s $f10, $f4, $f4     
    mul.s $f10, $f10, $f10   # d^4
    
    mul.s $f11, $f5, $f5     
    mul.s $f11, $f11, $f5    # e^3
    
    add.s $f12, $f10, $f11   
    
    mul.s $f13, $f7, $f7     
    mul.s $f14, $f13, $f13   
    mul.s $f15, $f14, $f13   
    mul.s $f16, $f15, $f7    # x^7
    
    li.s $f20, 7.0
    div.s $f21, $f1, $f20    
    div.s $f21, $f21, $f12  
    mul.s $f21, $f21, $f16   # (a/7(d^4 + e^3))*x^7
    
    li.s $f20, 6.0
    div.s $f22, $f2, $f20   
    div.s $f22, $f22, $f12   
    mul.s $f22, $f22, $f15   # (b/6(d^4 + e^3))*x^6
    
    li.s $f20, 2.0
    div.s $f23, $f3, $f20   
    div.s $f23, $f23, $f12  
    mul.s $f23, $f23, $f13   # (c/2(d^4 + e^3))*x^2
    
    add.s $f0, $f21, $f22  
    add.s $f0, $f0, $f23  

    jr $ra

#EXERCISE 3:
.data
    buffer: .space 2048
    input_file: .asciiz "raw_input.txt"
    output_file: .asciiz "formatted_result.txt"
    header: .asciiz "-----Student personal information-----\n"
    name_label: .asciiz "Name: "
    id_label: .asciiz "ID: "
    addr_label: .asciiz "Address: "
    age_label: .asciiz "Age: "
    rel_label: .asciiz "Religion: "
    newline: .asciiz "\n"
    comma: .asciiz ","

.text
main:
    li $v0, 13
    la $a0, input_file
    li $a1, 0         
    li $a2, 0
    syscall
    bltz $v0, exit
    move $s0, $v0      

    li $v0, 14
    move $a0, $s0
    la $a1, buffer
    li $a2, 2047       
    syscall
    bltz $v0, exit
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
copy_loop:
    beq $t0, $s4, print_both
    lb $t1, ($s2)
    sb $t1, ($s3)
    addi $s2, $s2, 1
    addi $s3, $s3, 1
    addi $t0, $t0, 1
    j copy_loop

print_both:
    li $v0, 4
    la $a0, header
    syscall

    move $s2, $s1
    li $s3, 0

terminal_loop:
    beq $s3, 5, write_file

    li $v0, 4
    beq $s3, 0, print_name_term
    beq $s3, 1, print_id_term
    beq $s3, 2, print_addr_term
    beq $s3, 3, print_age_term
    beq $s3, 4, print_rel_term

print_name_term:
    la $a0, name_label
    j print_field_term
print_id_term:
    la $a0, id_label
    j print_field_term
print_addr_term:
    la $a0, addr_label
    j print_field_term
print_age_term:
    la $a0, age_label
    j print_field_term
print_rel_term:
    la $a0, rel_label

print_field_term:
    syscall
    move $t0, $s2

print_content_term:
    lb $t1, ($t0)
    beqz $t1, end_field_term
    beq $t1, 44, end_field_term    # Check for comma
    
    li $v0, 11
    move $a0, $t1
    syscall
    
    addi $t0, $t0, 1
    j print_content_term

end_field_term:
    li $v0, 4
    la $a0, newline
    syscall
    
    addi $s2, $t0, 1
    addi $s3, $s3, 1
    j terminal_loop

write_file:
    # Reset for file writing
    move $s2, $s1
    li $s3, 0

    # Open output file
    li $v0, 13
    la $a0, output_file
    li $a1, 1
    li $a2, 0
    syscall
    bltz $v0, exit
    move $s0, $v0

    # Write header
    li $v0, 15
    move $a0, $s0
    la $a1, header
    li $a2, 39
    syscall
    bltz $v0, exit

file_loop:
    beq $s3, 5, close_file    # Process all 5 fields

    # Write appropriate label
    li $v0, 15
    move $a0, $s0
    beq $s3, 0, write_name_label
    beq $s3, 1, write_id_label
    beq $s3, 2, write_addr_label
    beq $s3, 3, write_age_label
    beq $s3, 4, write_rel_label

write_name_label:
    la $a1, name_label
    li $a2, 6
    j write_label
write_id_label:
    la $a1, id_label
    li $a2, 4
    j write_label
write_addr_label:
    la $a1, addr_label
    li $a2, 9
    j write_label
write_age_label:
    la $a1, age_label
    li $a2, 5
    j write_label
write_rel_label:
    la $a1, rel_label
    li $a2, 10

write_label:
    syscall
    move $t0, $s2

write_content:
    lb $t1, ($t0)
    beqz $t1, end_field
    beq $t1, 44, end_field    # Check for comma
    
    # Write character
    li $v0, 15
    move $a0, $s0
    sb $t1, ($sp)
    move $a1, $sp
    li $a2, 1
    syscall

    addi $t0, $t0, 1
    j write_content

end_field:
    li $v0, 15
    move $a0, $s0
    la $a1, newline
    li $a2, 1
    syscall
    
    addi $s2, $t0, 1
    addi $s3, $s3, 1
    j file_loop

close_file:
    li $v0, 16
    move $a0, $s0
    syscall

exit:
    li $v0, 10
    syscall

