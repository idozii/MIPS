.data
#Dynamic Allocation
.align 2
buffer: .space 2048
temp: .space 64
number: .space 64
temp_length: .word 0
temp_int: .space 16                       # Temporary buffer for integer digits

#File names
input_file: .asciiz "input_matrix.txt"
output_file: .asciiz "output_matrix.txt"

#Ouput details
header: .asciiz "--------RESULT--------\n"
image_msg: .asciiz "Image Matrix:\n"
kernel_msg: .asciiz "Kernel Matrix:\n"
padded_msg: .asciiz "Padded Matrix:\n"
output_msg: .asciiz "Output Matrix:\n"
space: .asciiz " "
newline: .asciiz "\n"

# Add float constants
.align 2
float_zero: .float 0.0
float_half:   .float 0.5                    
float_one: .float 1.0
float_two: .float 2.0
float_three: .float 3.0
float_four: .float 4.0
float_five: .float 5.0
float_ten: .float 10.0
float_hundred: .float 100.0
float_epsilon: .float 1.0e-6  # Small value to compare against

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
output_size: .word 0

#Errors handling
error_open: .asciiz "Error opening file\n"
error_write: .asciiz "Error writing to file\n"
error_parse: .asciiz "Error parsing file\n"
error_params: .asciiz "Invalid parameters\n"
error_params1: .asciiz "Wrong value (image size<3)\n"
error_params2: .asciiz "Wrong value (image size>7)\n"
error_params3: .asciiz "Wrong value (kernel size<2)\n"
error_params4: .asciiz "Wrong value (kernel size>4)\n"
error_params5: .asciiz "Wrong value (p<0)\n"
error_params6: .asciiz "Wrong value (p>4)\n"
error_params7: .asciiz "Wrong value (s<1)\n"
error_params8: .asciiz "Wrong value (s>3)\n"
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
    bgt $t1, $t3, params_error2
    j next_param
    
store_M:
    s.s $f0, M
    cvt.w.s $f0, $f0
    mfc1 $t1, $f0
    li $t2, 2        # Min
    li $t3, 4        # Max
    blt $t1, $t2, params_error3
    bgt $t1, $t3, params_error4
    j next_param

store_p:
    s.s $f0, p
    l.s $f2, float_zero
    l.s $f3, float_four
    c.lt.s $f0, $f2
    bc1t params_error5
    c.lt.s $f3, $f0
    bc1t params_error6
    j next_param
    
store_s:
    s.s $f0, s
    l.s $f2, float_one
    l.s $f3, float_three
    c.lt.s $f0, $f2
    bc1t params_error7
    c.lt.s $f3, $f0
    bc1t params_error8
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
    mfc1 $s4, $f0       # Kernel size (M)
    mul $s6, $s4, $s4   # Total elements M*M
    li $t0, 0           # Counter

parse_kernel:
    beq $t0, $s6, finish_parsing
    la $t8, temp
    li $t1, 0

get_kernel_num:
    lb $t2, ($s2)
    beqz $t2, end_kernel_num    # Check for end
    beq $t2, 32, skip_kernel_space  # Space
    beq $t2, 10, skip_kernel_space  # Newline
    
    sb $t2, ($t8)              
    addi $t8, $t8, 1
    addi $t1, $t1, 1
    addi $s2, $s2, 1
    j get_kernel_num

skip_kernel_space:
    addi $s2, $s2, 1
    beqz $t1, get_kernel_num    # If no chars read, continue
    j end_kernel_num

end_kernel_num:
    beqz $t1, parse_kernel      # Skip if empty
    sb $zero, ($t8)            # Null terminate
    jal string_to_float        
    s.s $f0, ($s3)            # Store in kernel
    addi $s3, $s3, 4          
    addi $t0, $t0, 1          
    j parse_kernel 

finish_parsing:
    jal check_if_padding
    j print_all_matrices
    
check_if_padding:
    # First check if kernel is larger than image when no padding
    l.s $f0, N
    l.s $f1, M
    c.lt.s $f0, $f1        # Check if N < M
    bc1f continue_check    # If N >= M, continue

    # If N < M, check if padding is 0
    l.s $f0, p
    l.s $f1, float_zero
    c.eq.s $f0, $f1
    bc1t size_error       # If p=0 and N<M, error
    
continue_check:
    # Original padding check continues here
    l.s $f0, p
    l.s $f1, float_zero
    c.eq.s $f0, $f1
    bc1t no_padding     # If p=0, skip padding
  
    j setup_padding

no_padding:
    l.s $f0, N           
    l.s $f1, M           
    sub.s $f2, $f0, $f1  
    l.s $f3, float_one
    add.s $f2, $f2, $f3  # N-M+1
    
    # Convert to integer
    cvt.w.s $f2, $f2
    mfc1 $t0, $f2        
    
    # Allocate output matrix
    mul $t1, $t0, $t0    
    sll $t1, $t1, 2      
    
    li $v0, 9            
    move $a0, $t1
    syscall
    sw $v0, output       

    sw $t0, output_size
    
    j calculate_convolution

setup_padding:
    j calculate_padding

calculate_padding:
    # Use the provided padding value directly
    l.s $f0, p
    cvt.w.s $f0, $f0
    mfc1 $s1, $f0        # s1 = padding size
    
    # Calculate new padded matrix size = N + 2*padding
    l.s $f0, N
    cvt.w.s $f0, $f0
    mfc1 $s2, $f0        # s2 = N
    add $s3, $s2, $s1    
    add $s3, $s3, $s1    # s3 = new_size = N + 2*padding

    # Allocate and initialize padded matrix with zeros
    mul $t0, $s3, $s3
    sll $t0, $t0, 2
    li $v0, 9
    move $a0, $t0
    syscall
    sw $v0, padded_image

    # Initialize with zeros
    move $t0, $v0        # Start address
    mul $t1, $s3, $s3    # Total elements
    l.s $f2, float_zero  # Load 0.0
init_padded:
    s.s $f2, ($t0)       # Store zero
    addi $t0, $t0, 4     # Next element
    addi $t1, $t1, -1    # Decrement counter
    bnez $t1, init_padded

    # Copy original matrix to center
    lw $s4, image        # Source matrix
    lw $s5, padded_image # Destination matrix
    li $t0, 0            # Row counter
copy_row_pad:
    li $t1, 0            # Column counter
copy_element_pad:
    # Calculate source address 
    mul $t2, $t0, $s2    # Row offset = row * N
    add $t2, $t2, $t1    # Add column
    sll $t2, $t2, 2      # Multiply by 4 for float
    add $t2, $t2, $s4    # Add base source address

    # Calculate destination address with correct padding offset
    add $t3, $t0, $s1    # Add padding to row index
    mul $t3, $t3, $s3    # Multiply by padded width
    add $t3, $t3, $t1    # Add original column index
    add $t3, $t3, $s1    # Add padding to column index
    sll $t3, $t3, 2      # Multiply by 4 for float
    add $t3, $t3, $s5    # Add base destination address

    # Copy value
    l.s $f0, ($t2)       # Load from source
    s.s $f0, ($t3)       # Store to destination

    addi $t1, $t1, 1     # Next column
    blt $t1, $s2, copy_element_pad

    addi $t0, $t0, 1     # Next row
    blt $t0, $s2, copy_row_pad

    sw $s3, output_size  # Store new size for later use
    j calculate_convolution

calculate_convolution:
    # Determine if padding is applied
    l.s $f0, p
    l.s $f1, float_zero
    c.eq.s $f0, $f1
    bc1t use_original_image  # If p == 0, use the original image

    # Use padded image
    lw $s1, padded_image     # $s1 = address of padded image
    lw $s3, output_size      # $s3 = size of padded image
    j continue_convolution

use_original_image:
    lw $s1, image            # $s1 = address of original image
    l.s $f0, N
    cvt.w.s $f0, $f0
    mfc1 $s3, $f0            # $s3 = N (size of original image)

continue_convolution:
    lw $s2, kernel           # $s2 = address of kernel
    l.s $f0, M
    cvt.w.s $f0, $f0
    mfc1 $s6, $f0            # $s6 = M (kernel size)
    l.s $f0, s
    cvt.w.s $f0, $f0
    mfc1 $s7, $f0            # $s7 = s (stride)

    # Calculate output size: output_size = ((input_size - kernel_size) / stride) + 1
    sub $t0, $s3, $s6            # t0 = input_size - kernel_size
    div $t0, $t0, $s7            # t0 = (input_size - kernel_size) / stride
    mflo $t0                     # Get quotient from division
    addi $t0, $t0, 1             # t0 = output_size
    sw $t0, output_size          # Store output_size
    move $t9, $t0                # $t9 = output_size

    # Allocate output matrix
    mul $t1, $t9, $t9            # total elements = output_size * output_size
    sll $t1, $t1, 2              # bytes needed = total elements * 4
    li $v0, 9                    # syscall for sbrk
    move $a0, $t1
    syscall
    sw $v0, output               # Store output matrix address
    move $s0, $v0                # $s0 = output matrix address

    # Convolution loops
    li $t0, 0                    # Output row index

conv_row_loop:
    bge $t0, $t9, convolution_done   # If t0 >= output_size, end loop
    li $t1, 0                    # Output column index

conv_col_loop:
    bge $t1, $t9, next_output_row   # If t1 >= output_size, go to next row
    
    # Initialize sum accumulator
    l.s $f10, float_zero

    # Inner loops for kernel
    li $t2, 0                    # Kernel row index
kernel_row_loop:
    bge $t2, $s6, accumulate     # If t2 >= kernel_size, accumulate sum
    li $t3, 0                    # Kernel column index
kernel_col_loop:
    bge $t3, $s6, next_kernel_row

    # Calculate input indices
    mul $t4, $t0, $s7            # input_row = output_row * stride
    add $t4, $t4, $t2            # input_row += kernel_row
    mul $t5, $t1, $s7            # input_col = output_col * stride
    add $t5, $t5, $t3            # input_col += kernel_col

    # Calculate input element address
    mul $t6, $t4, $s3            # t6 = input_row * input_size
    add $t6, $t6, $t5            # t6 += input_col
    sll $t6, $t6, 2              # t6 *= 4 (bytes per float)
    add $t6, $t6, $s1            # t6 = address of input element

    # Calculate kernel element address
    mul $t7, $t2, $s6            # t7 = kernel_row * kernel_size
    add $t7, $t7, $t3            # t7 += kernel_col
    sll $t7, $t7, 2              # t7 *= 4
    add $t7, $t7, $s2            # t7 = address of kernel element

    # Load values and multiply
    l.s $f0, 0($t6)              # Load input value
    l.s $f1, 0($t7)              # Load kernel value
    mul.s $f2, $f0, $f1          # Multiply values
    add.s $f10, $f10, $f2        # Accumulate sum

    addi $t3, $t3, 1             # t3++
    j kernel_col_loop

next_kernel_row:
    addi $t2, $t2, 1             # t2++
    j kernel_row_loop

accumulate:
    # Store sum into output matrix
    mul $t8, $t0, $t9            # t8 = output_row * output_size
    add $t8, $t8, $t1            # t8 += output_col
    sll $t8, $t8, 2              # t8 *= 4
    add $t8, $t8, $s0            # t8 = address in output matrix
    s.s $f10, 0($t8)             # Store the accumulated sum

    addi $t1, $t1, 1             # t1++
    j conv_col_loop

next_output_row:
    addi $t0, $t0, 1             # t0++
    j conv_row_loop

convolution_done:
    # Convolution complete, proceed to print or further processing
    j print_all_matrices

round_for_print:
    li $t7, 0             

    l.s $f2, float_zero
    c.lt.s $f12, $f2      # Test if negative
    bc1f do_round         # If positive, continue
    neg.s $f12, $f12      # Make positive
    li $t7, 1             # Flag that number was negative
    j do_round
    
do_round:
    l.s $f2, float_ten    
    mul.s $f14, $f12, $f2  # Multiply by 10
    
    l.s $f3, float_one
    l.s $f4, float_two
    div.s $f3, $f3, $f4    # Get 0.5
    add.s $f14, $f14, $f3  # Add for rounding
    
    cvt.w.s $f14, $f14     # To integer
    cvt.s.w $f14, $f14     # Back to float
    
    div.s $f14, $f14, $f2  # Divide by 10
    
    # Check for small values close to zero
    abs.s $f16, $f14       # Absolute value
    l.s $f17, float_epsilon
    c.lt.s $f16, $f17      # Compare with epsilon
    bc1f check_sign        # If not close to zero, proceed
    l.s $f14, float_zero   # Set to zero

check_sign:
    beqz $t7, done         # If was positive, skip restoring sign
    neg.s $f14, $f14       # Restore negative

done:
    # Ensure zero is positive
    abs.s $f16, $f14       # Get the absolute value
    l.s $f2, float_zero
    c.eq.s $f16, $f2       # Compare with 0.0
    bc1f set_result        # If not zero, proceed
    mov.s $f14, $f2       # Set to positive zero if it is zero

set_result:
    mov.s $f12, $f14       # Move the result to $f12
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
    l.s $f12, ($s3)           # Load kernel value
    jal round_for_print       # Round for display
    
    li $v0, 2                # Print float
    syscall
    
    li $v0, 4               # Print space
    la $a0, space
    syscall
    
    addi $s3, $s3, 4        # Next element
    addi $t1, $t1, 1
    bne $t1, $s4, print_kernel_element  # Continue row
    
    li $v0, 4               # Print newline at end of row
    la $a0, newline
    syscall
    
    addi $t0, $t0, 1        # Next row
    bne $t0, $s4, print_kernel
print_padded:
    # Only print padded matrix if padding was used
    l.s $f0, p
    l.s $f1, float_zero
    c.eq.s $f0, $f1
    bc1t print_output    # Skip if no padding

    li $v0, 4
    la $a0, padded_msg
    syscall

    l.s $f0, p
    cvt.w.s $f0, $f0
    mfc1 $s1, $f0        # $s1 = padding size (p)

    # Calculate padded_size = N + 2 * padding
    l.s $f0, N
    cvt.w.s $f0, $f0
    mfc1 $s2, $f0        # $s2 = N
    add $s4, $s2, $s1
    add $s4, $s4, $s1    # $s4 = padded_size = N + 2*p

    li $t0, 0           # Row counter

print_padded_row:
    li $t1, 0           # Column counter
print_padded_element:
    l.s $f12, ($s3)     # Load padded value
    jal round_for_print  # Round for display

    li $v0, 2           # Print float
    syscall

    li $v0, 4           # Print space
    la $a0, space
    syscall

    addi $s3, $s3, 4    # Next element
    addi $t1, $t1, 1    # Increment column
    blt $t1, $s4, print_padded_element

    li $v0, 4           # Print newline
    la $a0, newline
    syscall

    addi $t0, $t0, 1    # Next row
    blt $t0, $s4, print_padded_row

print_output:
    li $v0, 4
    la $a0, output_msg
    syscall

    lw $s3, output          # Load output matrix address
    lw $t9, output_size     # Load output size
    li $t0, 0               # Row counter

print_output_row:
    bge $t0, $t9, end_print_output
    li $t1, 0               # Column counter

print_output_element:
    bge $t1, $t9, next_row

    l.s $f12, ($s3)         # Load output value
    jal round_for_print     # Round for display

    li $v0, 2               # Print float
    syscall

    li $v0, 4               # Print space
    la $a0, space
    syscall

    addi $s3, $s3, 4        # Next element
    addi $t1, $t1, 1        # Increment column
    j print_output_element

next_row:
    li $v0, 4               # Print newline
    la $a0, newline
    syscall

    addi $t0, $t0, 1        # Next row
    j print_output_row

end_print_output:
    j write_output

write_output:
    # Open the output file for writing
    li $v0, 13                   # SYS_OPEN
    la $a0, output_file          # File name
    li $a1, 1                    # Write-only mode
    li $a2, 0                    # No flags
    syscall
    bltz $v0, file_error         # Check for error
    move $t8, $v0                # Use $t8 for file descriptor

    # Write header to the file
    la $a0, header               # Buffer address
    jal write_string_to_file

    # Write Output Matrix label
    la $a0, output_msg           # "Output Matrix:\n"
    jal write_string_to_file

    # Load output matrix information
    lw $s3, output               # $s3 = output matrix base address
    lw $t9, output_size          # $t9 = output matrix size

    move $t2, $s3                # $t2 = traversal pointer
    li $t0, 0                    # Row counter

write_output_row:
    bge $t0, $t9, end_write_output
    li $t1, 0                    # Column counter

write_output_element:
    bge $t1, $t9, write_newline

    l.s $f12, 0($t2)             # Load output value
    jal float_to_string          # Convert float to string

    # Write the string to file
    la $a0, number               # Buffer containing the string
    jal write_string_to_file

    # Write space
    la $a0, space
    jal write_string_to_file

    addi $t2, $t2, 4             # Next element address
    addi $t1, $t1, 1             # Increment column index
    j write_output_element

write_newline:
    # Write newline character
    la $a0, newline
    jal write_string_to_file

    addi $t0, $t0, 1             # Increment row index
    j write_output_row

end_write_output:
    # Close the output file
    li $v0, 16                   # SYS_CLOSE
    move $a0, $t8                # File descriptor in $t8
    syscall

    j exit

write_string_to_file:
    # Save the buffer address and file descriptor
    move $t0, $a0                # $t0 = buffer address (from $a0)
    move $t1, $t8                # $t1 = file descriptor (from $t8)

    # Initialize traversal pointer
    move $t2, $t0                # $t2 = traversal pointer

write_string_loop:
    lb $t3, ($t2)                # Load byte from buffer
    beqz $t3, write_string_done  # If null terminator, end loop
    addi $t2, $t2, 1             # Move to next byte
    j write_string_loop

write_string_done:
    subu $a2, $t2, $t0           # Calculate length: length = end - start
    move $a0, $t1                # $a0 = file descriptor
    move $a1, $t0                # $a1 = buffer address
    li $v0, 15                   # SYS_WRITE
    syscall
    jr $ra

# Subroutine to convert a float in $f12 to a string stored at 'number'
float_to_string:
    # Round the float to one decimal place
    li $t7, 0              # Sign flag

    l.s $f2, float_zero
    c.lt.s $f12, $f2       # Test if negative
    bc1f float_positive    # If positive, continue
    neg.s $f12, $f12       # Make positive
    li $t7, 1              # Flag that number was negative

float_positive:
    l.s $f2, float_ten    
    mul.s $f14, $f12, $f2  # Multiply by 10

    l.s $f3, float_one
    l.s $f4, float_two
    div.s $f3, $f3, $f4    # Get 0.5
    add.s $f14, $f14, $f3  # Add for rounding

    cvt.w.s $f14, $f14     # To integer

    # Extract integer and decimal parts
    mfc1 $t1, $f14         # $t1 = integer value (float * 10 rounded)
    div $t2, $t1, 10       # $t2 = integer part
    mflo $t2
    rem $t3, $t1, 10       # $t3 = decimal part
    mfhi $t3

    # Convert integer part to string
    la $a0, temp_int       # Temporary buffer
    li $t4, 0              # Digit counter

convert_int_part:
    bnez $t2, int_loop     # If $t2 != 0, proceed to loop
    j check_zero_int

int_loop:
    div $t5, $t2, 10       # Divide by 10
    mflo $t5
    rem $t6, $t2, 10       # Remainder
    mfhi $t6
    addi $t6, $t6, 48      # Convert to ASCII
    sb $t6, ($a0)
    addi $a0, $a0, 1
    addi $t4, $t4, 1
    move $t2, $t5
    bnez $t2, int_loop     # Loop if $t2 != 0

    j reverse_int_string

check_zero_int:
    li $t6, 48             # '0'
    sb $t6, ($a0)
    addi $a0, $a0, 1
    addi $t4, $t4, 1
    j reverse_int_string

reverse_int_string:
    # Reverse the integer string
    la $a0, temp_int
    add $a0, $a0, $t4      # Point to end
    sub $a0, $a0, 1        # Adjust for index
    la $a1, number         # Destination buffer
    beqz $t7, store_int    # If positive, skip storing '-'
    li $t6, 45             # '-'
    sb $t6, ($a1)
    addi $a1, $a1, 1

store_int:
    move $t5, $t4
copy_int_digits:
    lb $t6, ($a0)
    sb $t6, ($a1)
    addi $a0, $a0, -1
    addi $a1, $a1, 1
    addi $t5, $t5, -1
    bgtz $t5, copy_int_digits

    # Add decimal point
    li $t6, 46             # '.'
    sb $t6, ($a1)
    addi $a1, $a1, 1

    # Convert decimal part
    addi $t3, $t3, 48      # Convert to ASCII
    sb $t3, ($a1)
    addi $a1, $a1, 1

    # Null terminate
    sb $zero, ($a1)
    jr $ra

file_write_error:
    li $v0, 4
    la $a0, error_write
    syscall
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

params_error2:
    li $v0, 4
    la $a0, error_params2
    syscall
    j exit

params_error3:  
    li $v0, 4
    la $a0, error_params3
    syscall
    j exit

params_error4:
    li $v0, 4
    la $a0, error_params4
    syscall
    j exit

params_error5:
    li $v0, 4
    la $a0, error_params5
    syscall
    j exit

params_error6:
    li $v0, 4
    la $a0, error_params6
    syscall
    j exit

params_error7:
    li $v0, 4
    la $a0, error_params7
    syscall
    j exit

params_error8:
    li $v0, 4
    la $a0, error_params8
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