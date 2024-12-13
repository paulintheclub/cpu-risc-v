.global _boot
.text

_boot:
    addi x3, x0, 0x0    //base data memory address
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
    addi x3, x3, 32     //increment memory pointer
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

    slli x24, x10, 23    // x24 = 0x80000000
    srli x25, x11, 8     // x25 = 0x00000000
    srai x26, x24, 31    // x26 = 0xFFFFFFFF
    addi x27, x10, -1    // x27 = 0x000000FF
    xori x28, x26, -2048 // x28 = 0x000007FF
    andi x29, x26, -2048 // x29 = 0xFFFFF800   
    ori  x30, x27, -2048 // x30 = 0xFFFFF8FF
    auipc x31, 0x1       // x31 = 0x00001078
    jal x1, _regs_to_mem

_test_case_1:
    addi x10, x0, 0x8
    lui x24, 0x800       // x24 = 0x00800000
    nop                  //pseudo-instruction "addi x0, x0, 0"
    sll x25, x24, x10    // x25 = 0x80000000
    srl x26, x24, x10    // x26 = 0x00008000
    sra x27, x25, x10    // x27 = 0xFF800000
    add x28, x24, x10    // x28 = 0x00800008
    xor x29, x25, x27    // x29 = 0x7F800000
    and x30, x25, x27    // x30 = 0x80000000   
    or  x31, x25, x29    // x31 = 0xFF800000
    jal x1, _regs_to_mem

_test_case_2:
    addi x10, x0, 1
    addi x11, x0, -1

    slti x24, x10, -1     // x24 = 0x00000000
    sltiu x25, x10, -1    // x25 = 0x00000001
    slt x26, x11, x10     // x26 = 0x00000001
    sltu x27, x11, x10    // x27 = 0x00000000
    sub x28, x10, x11     // x28 = 0x00000002
    sub x29, x11, x11     // x29 = 0x00000000
    sub x30, x0, x10      // x30 = 0xFFFFFFFF
    sub x31, x11, x10     // x31 = 0xFFFFFFFE
    jal x1, _regs_to_mem

_test_case_3:
    addi x10, x0, 1
    addi x11, x0, 192

    add x24, x11, x10     // x24 = 0x000000C1
    add x25, x24, x10     // x25 = 0x000000C2
    sub x26, x25, x24     // x26 = 0x00000001
    sub x27, x24, x26     // x27 = 0x000000C0
    sw x27, 0(x27)        // dmem(0xC0) = 0x000000C0
    lw x28, 0(x27)        // x28 = 0x000000C0
    addi x29, x28, -4     // x29 = 0x000000BC
    lw x30, 4(x29)        // x30 = 0x000000C0
    sw x30, 4(x30)        // dmem(0xC4) = 0x000000C0
    lw x31, 8(x29)        // x31 = 0x000000C0
    jal x1, _regs_to_mem

_test_case_4:
    addi x10, x0, 2       // x10 = 0x00000002
    slli x11, x10, 30     // x11 = 0x80000000

    mul x24, x11, x10     // x24 = 0x00000000
    mulhu x25, x11, x10   // x25 = 0x00000001
    mulh x26, x11, x10    // x26 = 0xFFFFFFFF
    mulhsu x27, x26, x10  // x27 = 0xFFFFFFFF
    addi x28, x0, 240     // x28 = 0x000000F0
    slli x27, x27, 4      // x27 = 0xFFFFFFF0
    srli x27, x27, 4      // x27 = 0x0FFFFFFF
    mulhsu x29, x28, x27  // x29 = 0x0000000E
    add x30, x29, x10     // x30 = 0x00000010 
    mul x31, x30, x30     // x31 = 0x00000100
    jal x1, _regs_to_mem

_test_case_5:
    addi x10, x0, 0
    addi x11, x0, -1

_branch_0:
    beq x10, x11, _branch_1  // shouldn't jump
    addi x25, x0, 123
_branch_1:
    bne x10, x11, _branch_2  // should jump
    addi x26, x0, 123
_branch_2:
    blt x10, x11, _branch_3  // shouldn't jump
    addi x27, x0, 123
_branch_3:
    bltu x10, x11, _branch_4  // should jump
    addi x28, x0, 123
_branch_4:
    bge x11, x10, _branch_5  // shouldn't jump
    addi x29, x0, 123
_branch_5:
    bgeu x11, x10, _test_3_end // should jump
    addi x30, x0, 123
_test_3_end:                
    jal x1, _regs_to_mem

_end:
    ebreak
