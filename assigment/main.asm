.data
.align 2
buffer: .space 2048
temp: .space 64
number: .space 64
temp_length: .word 0
temp_int: .space 16

input_file: .asciiz "input_matrix.txt"
output_file: .asciiz "output_matrix.txt"

header: .asciiz "--------RESULT--------\n"
image_msg: .asciiz "Image Matrix:\n"
kernel_msg: .asciiz "Kernel Matrix:\n"
padded_msg: .asciiz "Padded Matrix:\n"
output_msg: .asciiz "Output Matrix:\n"
space: .asciiz " "
newline: .asciiz "\n"

.align 2
float_zero: .float 0.0
float_half: .float 0.5
float_one: .float 1.0
float_two: .float 2.0
float_three: .float 3.0
float_four: .float 4.0
float_five: .float 5.0
float_ten: .float 10.0
float_hundred: .float 100.0
float_epsilon: .float 1.0e-6

.align 2
N: .float 0.0
M: .float 0.0
p: .float 0.0
s: .float 0.0

.align 2
image: .word 0
kernel: .word 0
output: .word 0
padded_image: .word 0
output_size: .word 0

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
    la $s3, temp
    li $t1, 0

get_param:
    lb $t2, ($s2)
    beq $t2, 32, end_param
    beq $t2, 10, end_param
    beq $t2, 0, end_param

    sb $t2, ($s3)
    addi $s2, $s2, 1
    addi $s3, $s3, 1
    addi $t1, $t1, 1
    j get_param

end_param:
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
    bne $t7, $t8, convert_loop
    li $s7, -1
    addi $t3, $t3, 1

convert_loop:
    lb $t7, ($t3)
    beqz $t7, end_convert
    beq $t7, 46, set_decimal

    addi $t7, $t7, -48

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
    cvt.w.s $f0, $f0
    mfc1 $t1, $f0
    li $t2, 3
    li $t3, 7
    blt $t1, $t2, params_error1
    bgt $t1, $t3, params_error2
    j next_param

store_M:
    s.s $f0, M
    cvt.w.s $f0, $f0
    mfc1 $t1, $f0
    li $t2, 2
    li $t3, 4
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
    lw $s3, kernel
    beqz $s3, params_error
    l.s $f0, M
    cvt.w.s $f0, $f0
    mfc1 $s4, $f0
    mul $s6, $s4, $s4
    li $t0, 0

parse_kernel:
    beq $t0, $s6, finish_parsing
    la $t8, temp
    li $t1, 0

get_kernel_num:
    lb $t2, ($s2)
    beqz $t2, end_kernel_num
    beq $t2, 32, skip_kernel_space
    beq $t2, 10, skip_kernel_space

    sb $t2, ($t8)
    addi $t8, $t8, 1
    addi $t1, $t1, 1
    addi $s2, $s2, 1
    j get_kernel_num

skip_kernel_space:
    addi $s2, $s2, 1
    beqz $t1, get_kernel_num
    j end_kernel_num

end_kernel_num:
    beqz $t1, parse_kernel
    sb $zero, ($t8)
    jal string_to_float
    s.s $f0, ($s3)
    addi $s3, $s3, 4
    addi $t0, $t0, 1
    j parse_kernel

finish_parsing:
    jal check_if_padding
    j print_all_matrices

check_if_padding:
    l.s $f0, N
    l.s $f1, M
    c.lt.s $f0, $f1
    bc1f continue_check

    l.s $f0, p
    l.s $f1, float_zero
    c.eq.s $f0, $f1
    bc1t size_error

continue_check:
    l.s $f0, p
    l.s $f1, float_zero
    c.eq.s $f0, $f1
    bc1t no_padding

    j setup_padding

no_padding:
    l.s $f0, N
    l.s $f1, M
    sub.s $f2, $f0, $f1
    l.s $f3, float_one
    add.s $f2, $f2, $f3

    cvt.w.s $f2, $f2
    mfc1 $t0, $f2

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
    l.s $f0, p
    cvt.w.s $f0, $f0
    mfc1 $s1, $f0

    l.s $f0, N
    cvt.w.s $f0, $f0
    mfc1 $s2, $f0
    add $s3, $s2, $s1
    add $s3, $s3, $s1

    mul $t0, $s3, $s3
    sll $t0, $t0, 2
    li $v0, 9
    move $a0, $t0
    syscall
    sw $v0, padded_image

    move $t0, $v0
    mul $t1, $s3, $s3
    l.s $f2, float_zero
init_padded:
    s.s $f2, ($t0)
    addi $t0, $t0, 4
    addi $t1, $t1, -1
    bnez $t1, init_padded

    lw $s4, image
    lw $s5, padded_image
    li $t0, 0
copy_row_pad:
    li $t1, 0
copy_element_pad:
    mul $t2, $t0, $s2
    add $t2, $t2, $t1
    sll $t2, $t2, 2
    add $t2, $t2, $s4

    add $t3, $t0, $s1
    mul $t3, $t3, $s3
    add $t3, $t3, $t1
    add $t3, $t3, $s1
    sll $t3, $t3, 2
    add $t3, $t3, $s5

    l.s $f0, ($t2)
    s.s $f0, ($t3)

    addi $t1, $t1, 1
    blt $t1, $s2, copy_element_pad

    addi $t0, $t0, 1
    blt $t0, $s2, copy_row_pad

    sw $s3, output_size
    j calculate_convolution

calculate_convolution:
    l.s $f0, p
    l.s $f1, float_zero
    c.eq.s $f0, $f1
    bc1t use_original_image

    lw $s1, padded_image
    lw $s3, output_size
    j continue_convolution

use_original_image:
    lw $s1, image
    l.s $f0, N
    cvt.w.s $f0, $f0
    mfc1 $s3, $f0

continue_convolution:
    lw $s2, kernel
    l.s $f0, M
    cvt.w.s $f0, $f0
    mfc1 $s6, $f0
    l.s $f0, s
    cvt.w.s $f0, $f0
    mfc1 $s7, $f0

    sub $t0, $s3, $s6
    div $t0, $t0, $s7
    mflo $t0
    addi $t0, $t0, 1
    sw $t0, output_size
    move $t9, $t0

    mul $t1, $t9, $t9
    sll $t1, $t1, 2
    li $v0, 9
    move $a0, $t1
    syscall
    sw $v0, output
    move $s0, $v0

    li $t0, 0

conv_row_loop:
    bge $t0, $t9, convolution_done
    li $t1, 0

conv_col_loop:
    bge $t1, $t9, next_output_row

    l.s $f10, float_zero

    li $t2, 0
kernel_row_loop:
    bge $t2, $s6, accumulate
    li $t3, 0
kernel_col_loop:
    bge $t3, $s6, next_kernel_row

    mul $t4, $t0, $s7
    add $t4, $t4, $t2
    mul $t5, $t1, $s7
    add $t5, $t5, $t3

    mul $t6, $t4, $s3
    add $t6, $t6, $t5
    sll $t6, $t6, 2
    add $t6, $t6, $s1

    mul $t7, $t2, $s6
    add $t7, $t7, $t3
    sll $t7, $t7, 2
    add $t7, $t7, $s2

    l.s $f0, 0($t6)
    l.s $f1, 0($t7)
    mul.s $f2, $f0, $f1
    add.s $f10, $f10, $f2

    addi $t3, $t3, 1
    j kernel_col_loop

next_kernel_row:
    addi $t2, $t2, 1
    j kernel_row_loop

accumulate:
    mul $t8, $t0, $t9
    add $t8, $t8, $t1
    sll $t8, $t8, 2
    add $t8, $t8, $s0
    s.s $f10, 0($t8)

    addi $t1, $t1, 1
    j conv_col_loop

next_output_row:
    addi $t0, $t0, 1
    j conv_row_loop

convolution_done:
    j print_all_matrices

round_for_print:
    li $t7, 0

    l.s $f2, float_zero
    c.lt.s $f12, $f2
    bc1f do_round
    neg.s $f12, $f12
    li $t7, 1
    j do_round

do_round:
    l.s $f2, float_ten
    mul.s $f14, $f12, $f2

    l.s $f3, float_one
    l.s $f4, float_two
    div.s $f3, $f3, $f4
    add.s $f14, $f14, $f3

    cvt.w.s $f14, $f14
    cvt.s.w $f14, $f14

    div.s $f14, $f14, $f2

    abs.s $f16, $f14
    l.s $f17, float_epsilon
    c.lt.s $f16, $f17
    bc1f check_sign
    l.s $f14, float_zero

check_sign:
    beqz $t7, done
    neg.s $f14, $f14

done:
    abs.s $f16, $f14
    l.s $f2, float_zero
    c.eq.s $f16, $f2
    bc1f set_result
    mov.s $f14, $f2

set_result:
    mov.s $f12, $f14
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
    bne $t1, $s4, print_kernel_element

    li $v0, 4
    la $a0, newline
    syscall

    addi $t0, $t0, 1
    bne $t0, $s4, print_kernel
print_padded:
    l.s $f0, p
    l.s $f1, float_zero
    c.eq.s $f0, $f1
    bc1t print_output

    li $v0, 4
    la $a0, padded_msg
    syscall

    l.s $f0, p
    cvt.w.s $f0, $f0
    mfc1 $s1, $f0

    l.s $f0, N
    cvt.w.s $f0, $f0
    mfc1 $s2, $f0
    add $s4, $s2, $s1
    add $s4, $s4, $s1

    li $t0, 0

print_padded_row:
    li $t1, 0
print_padded_element:
    l.s $f12, ($s3)
    jal round_for_print

    li $v0, 2
    syscall

    li $v0, 4
    la $a0, space
    syscall

    addi $s3, $s3, 4
    addi $t1, $t1, 1
    blt $t1, $s4, print_padded_element

    li $v0, 4
    la $a0, newline
    syscall

    addi $t0, $t0, 1
    blt $t0, $s4, print_padded_row

print_output:
    li $v0, 4
    la $a0, output_msg
    syscall

    lw $s3, output
    lw $t9, output_size
    li $t0, 0

print_output_row:
    bge $t0, $t9, end_print_output
    li $t1, 0

print_output_element:
    bge $t1, $t9, next_row

    l.s $f12, ($s3)
    jal round_for_print

    li $v0, 2
    syscall

    li $v0, 4
    la $a0, space
    syscall

    addi $s3, $s3, 4
    addi $t1, $t1, 1
    j print_output_element

next_row:
    li $v0, 4
    la $a0, newline
    syscall

    addi $t0, $t0, 1
    j print_output_row

end_print_output:
    j write_output

write_output:
    li $v0, 13
    la $a0, output_file
    li $a1, 1
    li $a2, 0
    syscall
    bltz $v0, file_error
    move $t8, $v0

    lw $s3, output
    lw $t9, output_size

    move $s4, $s3
    li $s5, 0

write_output_element:
    bge $s5, $t9, end_write_output

    l.s $f12, 0($s4)
    jal float_to_string

    la $a0, number
    jal write_string_to_file

    addi $s4, $s4, 4
    addi $s5, $s5, 1

    bge $s5, $t9, write_output_element
    la $a0, space
    jal write_string_to_file

    j write_output_element

end_write_output:
    li $v0, 16
    move $a0, $t8
    syscall

    j exit

write_string_to_file:
    move $t0, $a0
    move $t1, $t8

    move $t2, $t0

write_string_loop:
    lb $t3, ($t2)
    beqz $t3, write_string_done
    addi $t2, $t2, 1
    j write_string_loop

write_string_done:
    subu $a2, $t2, $t0
    move $a0, $t1
    move $a1, $t0
    li $v0, 15
    syscall
    jr $ra

float_to_string:
    li $t7, 0

    l.s $f2, float_zero
    c.lt.s $f12, $f2
    bc1f float_positive
    neg.s $f12, $f12
    li $t7, 1

float_positive:
    l.s $f2, float_ten
    mul.s $f14, $f12, $f2

    l.s $f3, float_one
    l.s $f4, float_two
    div.s $f3, $f3, $f4
    add.s $f14, $f14, $f3

    cvt.w.s $f14, $f14

    mfc1 $t1, $f14
    div $t2, $t1, 10
    mflo $t2
    rem $t3, $t1, 10
    mfhi $t3

    la $a0, temp_int
    li $t4, 0

convert_int_part:
    bnez $t2, int_loop
    j check_zero_int

int_loop:
    div $t5, $t2, 10
    mflo $t5
    rem $t6, $t2, 10
    mfhi $t6
    addi $t6, $t6, 48
    sb $t6, ($a0)
    addi $a0, $a0, 1
    addi $t4, $t4, 1
    move $t2, $t5
    bnez $t2, int_loop

    j reverse_int_string

check_zero_int:
    li $t6, 48
    sb $t6, ($a0)
    addi $a0, $a0, 1
    addi $t4, $t4, 1
    j reverse_int_string

reverse_int_string:
    la $a0, temp_int
    add $a0, $a0, $t4
    sub $a0, $a0, 1
    la $a1, number
    beqz $t7, store_int
    li $t6, 45
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

    li $t6, 46
    sb $t6, ($a1)
    addi $a1, $a1, 1

    addi $t3, $t3, 48
    sb $t3, ($a1)
    addi $a1, $a1, 1

    sb $zero, ($a1)
    jr $ra

file_write_error:
    li $v0, 4             
    la $a0, error_write 
    syscall

    li $v0, 13
    la $a0, output_file
    li $a1, 1
    li $a2, 0
    syscall
    bltz $v0, file_error
    move $t8, $v0

    la $a0, error_write
    jal write_string_to_file

    li $v0, 16
    move $a0, $t8
    syscall

    j exit

file_error:
    li $v0, 4             
    la $a0, error_open   
    syscall

    li $v0, 13
    la $a0, output_file
    li $a1, 1
    li $a2, 0
    syscall
    bltz $v0, file_error
    move $t8, $v0

    la $a0, error_open
    jal write_string_to_file

    li $v0, 16
    move $a0, $t8
    syscall

    j exit

parse_error:
    li $v0, 4             
    la $a0, error_parse 
    syscall

    li $v0, 13
    la $a0, output_file
    li $a1, 1
    li $a2, 0
    syscall
    bltz $v0, file_error
    move $t8, $v0

    la $a0, error_parse
    jal write_string_to_file

    li $v0, 16
    move $a0, $t8
    syscall

    j exit

params_error:
    li $v0, 4             
    la $a0, error_params   
    syscall

    li $v0, 13        
    la $a0, output_file 
    li $a1, 1           
    li $a2, 0          
    syscall
    bltz $v0, file_error
    move $t8, $v0       

    la $a0, error_params
    jal write_string_to_file

    li $v0, 16         
    move $a0, $t8
    syscall

    j exit

params_error1:
    li $v0, 4             
    la $a0, error_params1 
    syscall

    li $v0, 13
    la $a0, output_file
    li $a1, 1
    li $a2, 0
    syscall
    bltz $v0, file_error
    move $t8, $v0

    la $a0, error_params1
    jal write_string_to_file

    li $v0, 16
    move $a0, $t8
    syscall

    j exit

params_error2:
    li $v0, 4             
    la $a0, error_params2 
    syscall

    li $v0, 13
    la $a0, output_file
    li $a1, 1
    li $a2, 0
    syscall
    bltz $v0, file_error
    move $t8, $v0

    la $a0, error_params2
    jal write_string_to_file

    li $v0, 16
    move $a0, $t8
    syscall

    j exit

params_error3:
    li $v0, 4             
    la $a0, error_params3  
    syscall

    li $v0, 13
    la $a0, output_file
    li $a1, 1
    li $a2, 0
    syscall
    bltz $v0, file_error
    move $t8, $v0

    la $a0, error_params3
    jal write_string_to_file

    li $v0, 16
    move $a0, $t8
    syscall

    j exit

params_error4:
    li $v0, 4             
    la $a0, error_params4   
    syscall

    li $v0, 13
    la $a0, output_file
    li $a1, 1
    li $a2, 0
    syscall
    bltz $v0, file_error
    move $t8, $v0

    la $a0, error_params4
    jal write_string_to_file

    li $v0, 16
    move $a0, $t8
    syscall

    j exit

params_error5:
    li $v0, 4             
    la $a0, error_params5  
    syscall

    li $v0, 13
    la $a0, output_file
    li $a1, 1
    li $a2, 0
    syscall
    bltz $v0, file_error
    move $t8, $v0

    la $a0, error_params5
    jal write_string_to_file

    li $v0, 16
    move $a0, $t8
    syscall

    j exit

params_error6:
    li $v0, 4             
    la $a0, error_params6  
    syscall

    li $v0, 13
    la $a0, output_file
    li $a1, 1
    li $a2, 0
    syscall
    bltz $v0, file_error
    move $t8, $v0

    la $a0, error_params6
    jal write_string_to_file

    li $v0, 16
    move $a0, $t8
    syscall

    j exit

params_error7:
    li $v0, 4             
    la $a0, error_params7  
    syscall

    li $v0, 13
    la $a0, output_file
    li $a1, 1
    li $a2, 0
    syscall
    bltz $v0, file_error
    move $t8, $v0

    la $a0, error_params7
    jal write_string_to_file

    li $v0, 16
    move $a0, $t8
    syscall

    j exit

params_error8:
    li $v0, 4             
    la $a0, error_params8   
    syscall

    li $v0, 13
    la $a0, output_file
    li $a1, 1
    li $a2, 0
    syscall
    bltz $v0, file_error
    move $t8, $v0

    la $a0, error_params8
    jal write_string_to_file

    li $v0, 16
    move $a0, $t8
    syscall

    j exit

size_error:
    li $v0, 4             
    la $a0, error_size  
    syscall

    li $v0, 13
    la $a0, output_file
    li $a1, 1
    li $a2, 0
    syscall
    bltz $v0, file_error
    move $t8, $v0

    la $a0, error_size
    jal write_string_to_file

    li $v0, 16
    move $a0, $t8
    syscall

    j exit

exit:
    li $v0, 10
    syscall