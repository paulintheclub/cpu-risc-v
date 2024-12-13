.global _boot
.text

_boot:
    addi x3, x0, 0x0
    jal x0, _test_case_0    

_regs_to_mem:
    sw x24, 0(x3)
    sw x25, 4(x3)
    sw x26, 8(x3)
    sw x27, 12(x3)
    sw x28, 16(x3)
    sw x29, 20(x3)
    sw x30, 24(x3)
    sw x31, 28(x3)
    addi x3, x3, 32     
    jalr x0, x1, 0                

_clear_regs:
    addi x24, x0, 0
    addi x25, x0, 0
    addi x26, x0, 0
    addi x27, x0, 0
    addi x28, x0, 0
    addi x29, x0, 0
    addi x30, x0, 0
    addi x31, x0, 0
    jalr x0, x1, 0

_test_case_0:  
    addi x10, x0, 0x100
    addi x11, x0, 0x10

    slli x24, x10, 23    
    srli x25, x11, 8    
    srai x26, x24, 31    
    addi x27, x10, -1    
    xori x28, x26, -2048 
    andi x29, x26, -2048 
    ori  x30, x27, -2048 
    auipc x31, 0x1       
    jal x1, _regs_to_mem

_test_case_1:
    addi x10, x0, 0x8
    lui x24, 0x800       
    nop                  
    sll x25, x24, x10    
    srl x26, x24, x10    
    sra x27, x25, x10    
    add x28, x24, x10   
    xor x29, x25, x27    
    and x30, x25, x27      
    or  x31, x25, x29   
    jal x1, _regs_to_mem

_test_case_2:
    addi x10, x0, 1
    addi x11, x0, -1

    slti x24, x10, -1     
    sltiu x25, x10, -1    
    slt x26, x11, x10     
    sltu x27, x11, x10    
    sub x28, x10, x11     
    sub x29, x11, x11    
    sub x30, x0, x10      
    sub x31, x11, x10     
    jal x1, _regs_to_mem

_test_case_3:
    addi x10, x0, 1
    addi x11, x0, 192

    add x24, x11, x10
    add x25, x24, x10
    sub x26, x25, x24
    sub x27, x24, x26
    sw x27, 0(x27)
    lw x28, 0(x27)
    addi x29, x28, -4
    lw x30, 4(x29)
    sw x30, 4(x30)
    lw x31, 8(x29)
    jal x1, _regs_to_mem

_test_case_4:
    addi x10, x0, 2
    slli x11, x10, 30

    mul x24, x11, x10
    mulhu x25, x11, x10
    mulh x26, x11, x10
    mulhsu x27, x26, x10
    addi x28, x0, 240
    slli x27, x27, 4
    srli x27, x27, 4
    mulhsu x29, x28, x27
    add x30, x29, x10
    mul x31, x30, x30
    jal x1, _regs_to_mem

_test_case_5:
    addi x10, x0, 0
    addi x11, x0, -1

_branch_0:
    beq x10, x11, _branch_1
    addi x25, x0, 123
_branch_1:
    bne x10, x11, _branch_2
    addi x26, x0, 123
_branch_2:
    blt x10, x11, _branch_3
    addi x27, x0, 123
_branch_3:
    bltu x10, x11, _branch_4
    addi x28, x0, 123
_branch_4:
    bge x11, x10, _branch_5
    addi x29, x0, 123
_branch_5:
    bgeu x11, x10, _test_3_end
    addi x30, x0, 123
_test_3_end:                
    jal x1, _regs_to_mem

_end:
    ebreak