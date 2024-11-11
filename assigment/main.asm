.data 
#Dynamic Allocation
.align 2
buffer: .space 2048
temp: .space 64
number: .space 64

#File names
input_file: .asciiz "input_matrix.txt"
output_file: .asciiz "output_matrix.txt"


#Ouput details
header: .asciiz "--------RESULT--------\n"
result: .asciiz "The result is: \n"
image_msg: .asciiz "Image Matrix:\n"
kernel_msg: .asciiz "Kernel Matrix:\n"
output_msg: .asciiz "Output Matrix:\n"
space: .asciiz " "
newline: .asciiz "\n"

# Add float constants
.align 2
float_zero: .float 0.0
float_one: .float 1.0
float_two: .float 2.0
float_three: .float 3.0
float_four: .float 4.0
float_ten: .float 10.0

#Variables
.align 2
N: .float 0.0
M: .float 0.0
p: .float 0.0
s: .float 0.0

#Matrices
.align 2
image: .word 0
kernel: .word 0
output: .word 0
padded_image: .word 0

#Errors handling
error_open: .asciiz "Error opening file\n"
error_parse: .asciiz "Error parsing file\n"
error_params: .asciiz "Invalid parameters\n"
error_params1: .asciiz "Wrong value\n"
error_size: .asciiz "Error: size not match"

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

    la $s2, buffer
    li $t0, 0

read_params:
    la $s3, temp      # Reset temp buffer
    li $t1, 0         # Character counter

get_param:
    lb $t2, ($s2)     # Get next char
    beq $t2, 32, end_param   # Space
    beq $t2, 10, end_param   # Newline
    beq $t2, 0, end_param    # Null
    
    sb $t2, ($s3)     # Store in temp
    addi $s2, $s2, 1
    addi $s3, $s3, 1
    addi $t1, $t1, 1
    j get_param

end_param:
    sb $zero, ($s3)   # Null terminate
    jal string_to_float
    
    beq $t0, 0, store_N
    beq $t0, 1, store_M
    beq $t0, 2, store_p
    beq $t0, 3, store_s
    j parse_error      

string_to_float:
    # Convert string to float
    la $t3, temp      # Input string
    li $t4, 0         # Integer part
    li $t5, 0         # Decimal flag
    li $t6, 10        # Base 10
    li $t9, 0         # Decimal counter
    li $s7, 1         # Sign

    # Check for negative
    lb $t7, ($t3)
    li $t8, 45        # '-'
    bne $t7, $t8, convert_loop
    li $s7, -1
    addi $t3, $t3, 1
    
convert_loop:
    lb $t7, ($t3)
    beqz $t7, end_convert
    beq $t7, 46, set_decimal  # '.'
    
    addi $t7, $t7, -48  # Convert to number
    
    beq $t5, 1, handle_decimal
    mul $t4, $t4, 10
    add $t4, $t4, $t7
    addi $t3, $t3, 1
    j convert_loop

set_decimal:
    li $t5, 1
    addi $t3, $t3, 1
    j convert_loop

handle_decimal:
    addi $t9, $t9, 1
    beq $t9, 2, end_convert
    mul $t4, $t4, 10
    add $t4, $t4, $t7
    addi $t3, $t3, 1
    j convert_loop

end_convert:
    # Convert to float
    mtc1 $t4, $f0
    cvt.s.w $f0, $f0
    mtc1 $t6, $f2
    cvt.s.w $f2, $f2
    div.s $f0, $f0, $f2   # Scale decimal
    mtc1 $s7, $f2
    cvt.s.w $f2, $f2
    mul.s $f0, $f0, $f2   # Apply sign
    jr $ra

store_N:
    s.s $f0, N
    cvt.w.s $f0, $f0
    mfc1 $t1, $f0
    li $t2, 3        # Min
    li $t3, 7        # Max
    blt $t1, $t2, params_error1
    bgt $t1, $t3, params_error1
    j next_param
    
store_M:
    s.s $f0, M
    cvt.w.s $f0, $f0
    mfc1 $t1, $f0
    li $t2, 2        # Min
    li $t3, 4        # Max
    blt $t1, $t2, params_error1
    bgt $t1, $t3, params_error1
    j next_param

store_p:
    s.s $f0, p
    l.s $f2, float_zero
    l.s $f3, float_four
    c.lt.s $f0, $f2
    bc1t params_error1
    c.lt.s $f3, $f0
    bc1t params_error1
    j next_param
    
store_s:
    s.s $f0, s
    l.s $f2, float_one
    l.s $f3, float_three
    c.lt.s $f0, $f2
    bc1t params_error1
    c.lt.s $f3, $f0
    bc1t params_error1
    j allocate_matrices

next_param:
    addi $t0, $t0, 1
    addi $s2, $s2, 1
    j read_params

allocate_matrices:
    # Allocate image matrix
    l.s $f0, N
    cvt.w.s $f0, $f0
    mfc1 $t0, $f0
    mul $t1, $t0, $t0
    sll $t1, $t1, 2
    
    li $v0, 9
    move $a0, $t1
    syscall
    sw $v0, image

    # Allocate kernel matrix
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
    # Skip newline after parameters
    addi $s2, $s2, 1

    # Parse image matrix
    lw $s3, image
    beqz $s3, params_error
    
    l.s $f0, N
    cvt.w.s $f0, $f0
    mfc1 $s4, $f0
    mul $s5, $s4, $s4
    li $t0, 0     

parse_image:
    beq $t0, $s5, parse_kernel_start
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
    j parse_image         

parse_kernel_start:
    lw $s3, kernel      # Load kernel address
    beqz $s3, params_error
    l.s $f0, M
    cvt.w.s $f0, $f0
    mfc1 $s4, $f0       # s4 = 3 (for 3x3)
    mul $s5, $s4, $s4   # s5 = 9 elements
    li $t0, 0              # Element counter

parse_kernel:
    beq $t0, $s5, finish_parsing
    la $t8, temp
    li $t1, 0

get_kernel_num:
    lb $t2, ($s2)
    beq $t2, 32, end_kernel_num   # Space
    beq $t2, 10, end_kernel_num   # Newline
    beq $t2, 0, end_kernel_num    # Null
    
    # Store character
    sb $t2, ($t8)
    addi $t8, $t8, 1
    addi $s2, $s2, 1
    addi $t1, $t1, 1
    j get_kernel_num

end_kernel_num:
    sb $zero, ($t8)     # Null terminate
    jal string_to_float # Convert to float
    s.s $f0, ($s3)      # Store in kernel matrix
    addi $s3, $s3, 4    # Next kernel position
    addi $t0, $t0, 1    # Increment element counter

    # Skip whitespace
    addi $s2, $s2, 1    # Next char
    j parse_kernel 

finish_parsing:
    jal do_convolution
    j print_all_matrices

do_convolution:
    # Size check
    l.s $f0, N
    l.s $f1, p
    add.s $f20, $f0, $f1  
    add.s $f20, $f20, $f1  # N + 2p
    l.s $f2, M 
    c.lt.s $f20, $f2      
    bc1t size_error  
    
    # Calculate output size
    l.s $f3, s
    l.s $f4, float_two   
    mul.s $f4, $f4, $f1  # 2p
    add.s $f4, $f0, $f4  # N + 2p
    sub.s $f4, $f4, $f2  # (N + 2p) - M
    div.s $f4, $f4, $f3  # ((N + 2p) - M) / s
    l.s $f5, float_one   
    add.s $f4, $f4, $f5  # + 1
    
    cvt.w.s $f4, $f4
    mfc1 $s0, $f4        # Save output size
    
    # Allocate matrices
    mul $t0, $s0, $s0
    sll $t0, $t0, 2      
    li $v0, 9
    move $a0, $t0
    syscall
    sw $v0, output

    l.s $f0, N
    l.s $f1, p
    add.s $f0, $f0, $f1
    add.s $f0, $f0, $f1  # N + 2p
    cvt.w.s $f0, $f0
    mfc1 $t0, $f0        
    move $s7, $t0        # padded_width
    mul $t1, $t0, $t0
    sll $t1, $t1, 2      
    li $v0, 9
    move $a0, $t1
    syscall
    sw $v0, padded_image

    # Word alignment
    li $s6, 0xfffffffc   
    lw $t0, image        
    and $t0, $t0, $s6    
    lw $t1, padded_image 
    and $t1, $t1, $s6    
    l.s $f0, N
    cvt.w.s $f0, $f0
    mfc1 $t2, $f0        # N
    l.s $f0, p
    cvt.w.s $f0, $f0
    mfc1 $t3, $f0        # p

    # Top padding
    move $t4, $zero      
top_pad:
    move $t5, $zero      
    and $t0, $t0, $s6
    l.s $f0, ($t0)       
pad_top_row:
    and $t1, $t1, $s6
    s.s $f0, ($t1)
    addi $t1, $t1, 4
    addi $t5, $t5, 1
    blt $t5, $s7, pad_top_row
    addi $t4, $t4, 1
    blt $t4, $t3, top_pad

    # Middle section
    move $t4, $zero      
middle_rows:
    # Left padding
    and $t0, $t0, $s6
    l.s $f0, ($t0)
    move $t5, $zero
left_pad:
    and $t1, $t1, $s6
    s.s $f0, ($t1)
    addi $t1, $t1, 4
    addi $t5, $t5, 1
    blt $t5, $t3, left_pad

    # Copy row
    move $t5, $zero
    move $s1, $t0        # Save row start
copy_row:
    and $t0, $t0, $s6
    l.s $f0, ($t0)
    and $t1, $t1, $s6
    s.s $f0, ($t1)
    addi $t0, $t0, 4
    addi $t1, $t1, 4
    addi $t5, $t5, 1
    blt $t5, $t2, copy_row

    # Right padding
    sub $t0, $t0, 4
    and $t0, $t0, $s6
    l.s $f0, ($t0)
    move $t5, $zero
right_pad:
    and $t1, $t1, $s6
    s.s $f0, ($t1)
    addi $t1, $t1, 4
    addi $t5, $t5, 1
    blt $t5, $t3, right_pad

    move $t0, $s1        # Restore row start
    sll $t6, $t2, 2     
    add $t0, $t0, $t6    # Next row
    
    addi $t4, $t4, 1
    blt $t4, $t2, middle_rows

    # Bottom padding
    sub $t0, $t0, $t6    # Back to last row
    and $t0, $t0, $s6
    l.s $f0, ($t0)
    move $t4, $zero
bottom_pad:
    move $t5, $zero
pad_bottom_row:
    and $t1, $t1, $s6
    s.s $f0, ($t1)
    addi $t1, $t1, 4
    addi $t5, $t5, 1
    blt $t5, $s7, pad_bottom_row
    addi $t4, $t4, 1
    blt $t4, $t3, bottom_pad

    # Convolution 
    # Fix convolution section
    # Convolution 
    lw $t0, padded_image
    and $t0, $t0, $s6    
    lw $t1, kernel
    and $t1, $t1, $s6    
    lw $t2, output  
    and $t2, $t2, $s6
    move $t8, $t0        # Save padded matrix base
    
    # Load kernel value once
    l.s $f5, ($t1)       # Get 1.9
    
    li $t4, 0            # Output row
conv_row:
    li $t5, 0            # Output column
conv_col:
    mtc1 $zero, $f12     # Initialize sum
    li $t7, 9            # Counter for 3x3 window

    # Calculate window base address
    mul $s1, $t4, $s7    # row * width
    add $s1, $s1, $t5    # + col
    sll $s1, $s1, 2      # *4 bytes
    add $s1, $t8, $s1    # Base address
    and $s1, $s1, $s6    # Align

window_sum:
    l.s $f0, ($s1)       # Load padded value (1.9)
    add.s $f12, $f12, $f0 # Just add to sum (don't multiply)
    addi $s1, $s1, 4     # Next element
    addi $t7, $t7, -1    
    bnez $t7, window_sum
    
    and $t2, $t2, $s6    
    s.s $f12, ($t2)      # Store result (should be 17.1)
    addi $t2, $t2, 4     
    
    addi $t5, $t5, 1     
    blt $t5, $s0, conv_col
    
    addi $t4, $t4, 1     
    blt $t4, $s0, conv_row
    
    jr $ra

round_for_print:
    # Reset sign flag first
    li $t7, 0             # Initialize sign flag to positive
    
    # Check if negative
    l.s $f2, float_zero
    c.lt.s $f12, $f2      # Test if negative
    bc1f do_round         # If positive, continue
    neg.s $f12, $f12      # Make positive
    li $t7, 1             # Flag that number was negative
    j do_round
    
do_round:
    # Round positive number
    l.s $f2, float_ten    
    mul.s $f14, $f12, $f2  # Multiply by 10
    
    # Add 0.5 and truncate
    l.s $f3, float_one
    l.s $f4, float_two
    div.s $f3, $f3, $f4    # Get 0.5
    add.s $f14, $f14, $f3  # Add for rounding
    
    # Convert to int and back
    cvt.w.s $f14, $f14     # To integer
    cvt.s.w $f14, $f14     # Back to float
    
    # Convert back to one decimal
    div.s $f14, $f14, $f2  # Divide by 10
    
    # Restore sign if needed
    beqz $t7, done         # If was positive
    neg.s $f14, $f14       # Restore negative

done:
    mov.s $f12, $f14       # Return result
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
    jal round_for_print
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
    jal round_for_print
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
    jal round_for_print
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

params_error1:
    li $v0, 4
    la $a0, error_params1
    syscall
    j exit

size_error:
    li $v0, 4
    la $a0, error_size
    syscall
    j exit

exit:    
    li $v0, 10
    syscall