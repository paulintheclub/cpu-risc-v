module cpu_top (
    input logic s_clk_i,
    input logic s_resetn_i,
    input logic [31:0] s_boot_add_i,
    output logic s_error_o,

    input logic [31:0] s_ibus_val_i,          
    output logic s_ibus_write_o,              
    output logic [31:0] s_ibus_add_o,         
    output logic [31:0] s_ibus_val_o,         

    input logic [31:0] s_dbus_val_i,          
    output logic s_dbus_write_o,            
    output logic [31:0] s_dbus_add_o,        
    output logic [31:0] s_dbus_val_o          
);

    typedef enum logic [2:0] {
        RESET,
        FETCH,
        DECODE,
        EXECUTE,
        MEMORY,
        WRITEBACK
    } state_t;

    state_t current_state, next_state;

    logic [31:0] pc;
    logic [31:0] pc_next;

    logic [31:0] instruction_reg;

    logic [6:0] opcode;
    logic [4:0] rd, rs1, rs2;
    logic [2:0] funct3;
    logic [6:0] funct7;
    logic [31:0] imm;
    logic valid;
    logic is_mul;

    logic [31:0] alu_result;
    logic [31:0] reg_rd1, reg_rd2;

    logic [31:0] memory_data_reg;

    logic reg_write_enable;
    logic [31:0] reg_write_data;

    logic is_store;
    logic is_load;
    logic is_imm;
    logic alu_busy;
    logic alu_mul_done;

    instruction_decoder decoder (
        .instruction(instruction_reg),
        .opcode(opcode),
        .rd(rd),
        .funct3(funct3),
        .rs1(rs1),
        .rs2(rs2),
        .funct7(funct7),
        .imm(imm),
        .valid(valid),
        .is_mul(is_mul)
    );

    register_file reg_file (
        .s_clk(s_clk_i),
        .s_reset(~s_resetn_i), 
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .wd(reg_write_data),               
        .we(reg_write_enable),              
        .rd1(reg_rd1),
        .rd2(reg_rd2)
    );

    alu alu (
        .s_clk(s_clk_i),
        .s_reset(s_resetn_i), 
        .a(reg_rd1),
        .b((opcode == 7'b0010011 || opcode == 7'b0000011 || opcode == 7'b0100011 || opcode == 7'b0010111) ? imm : reg_rd2),
        .funct3(funct3),
        .funct7(funct7),
        .imm(imm),
        .is_imm(opcode == 7'b0010011 || opcode == 7'b0000011 || opcode == 7'b0100011 || opcode == 7'b0010111),
        .is_store(is_store),
        .is_load(is_load),
        .is_mul(is_mul),
        .busy(alu_busy),
        .result(alu_result),
        .mul_done(alu_mul_done)
    );

    always_ff @(posedge s_clk_i or negedge s_resetn_i) begin
        $display("State: %s, PC: %h, Instruction: %h", current_state.name(), pc, instruction_reg);
        if (~s_resetn_i) begin
            current_state <= RESET;
            pc <= s_boot_add_i;
            instruction_reg <= 32'b0;


            $display("Reset activated. PC initialized to %h (s_boot_add_i=%h)", pc, s_boot_add_i);
        end else begin
            current_state <= next_state;

            case (current_state)
                RESET: begin

                end
                FETCH: begin

                end
                DECODE: begin
                    instruction_reg <= s_ibus_val_i;
                    $display("DECODE: PC = %h, Instruction fetched: %h", pc, s_ibus_val_i);
                end
                EXECUTE: begin
                    if (is_mul && !alu_mul_done) begin
                        // Stay
                    end else begin
                        pc <= pc_next;
                        $display("EXECUTE: ALU operation result = %h", alu_result);
                    end
                    if (~valid) begin
                        $display("Invalid instruction %h at PC %h", instruction_reg, pc);
                        s_error_o = 1'b1;
                    end else begin
                        s_error_o <= 1'b0;
                    end
                end
                MEMORY: begin

                end
                WRITEBACK: begin
                    if (reg_write_enable) begin
                        $display("WRITEBACK: Register x%0d updated with value %h", rd, reg_write_data);
                    end
                end
            endcase
        end
    end

    always_comb begin
        next_state = current_state;
        s_ibus_add_o = 32'b0;
        s_ibus_write_o = 1'b0;
        s_ibus_val_o = 32'b0;

        s_dbus_write_o = 1'b0;

        reg_write_enable = 1'b0;
        reg_write_data = 32'b0;

        pc_next = pc + 4;

        is_store = (opcode == 7'b0100011);

        is_load = (opcode == 7'b0000011);

        case (current_state)
            RESET: begin
                if (s_resetn_i) begin
                    next_state = FETCH;
                end else begin
                    next_state = RESET;
                end
            end
            FETCH: begin
                s_ibus_add_o = pc; 
                next_state = DECODE; 
            end
            DECODE: begin

                next_state = EXECUTE;
            end
            EXECUTE: begin
                if (is_mul && !alu_mul_done) begin
                    next_state = EXECUTE;
                end else begin
                    if (opcode == 7'b0110111) begin // LUI
                        reg_write_enable = 1'b1;
                        reg_write_data = imm; 
                        $display("EXECUTE: LUI instruction, imm = 0x%h, rd = x%0d", imm, rd);
                    end else if (opcode == 7'b1101111) begin // JAL
                        pc_next = pc + imm;
                        reg_write_enable = 1'b1;
                        reg_write_data = pc + 4;
                        
                        $display("EXECUTE: JAL instruction, imm = %h, pc_next = %h", imm, pc_next);
                    end else if (opcode == 7'b1100111) begin // JALR
                        pc_next = (reg_rd1 + imm) & ~1;
                        reg_write_enable = 1'b1;
                        reg_write_data = pc + 4;
                        $display("EXECUTE: JALR instruction, pc_next = %h", pc_next);
                    end else if (opcode == 7'b1100011) begin // Branch instructions
                        if (branch_taken()) begin
                            pc_next = pc + imm;
                            $display("EXECUTE: Branch taken, pc_next = %h", pc_next);
                        end else begin
                            $display("EXECUTE: Branch not taken");
                        end
                    end else if (opcode == 7'b0010111) begin // AUIPC
                        reg_write_enable = 1'b1;
                        reg_write_data = pc + imm;
                        $display("EXECUTE: AUIPC instruction, imm = %h, pc_next = %h, alu_result = %h", imm, pc_next, alu_result);
                    end 



                    if (opcode == 7'b0000011 || opcode == 7'b0100011) begin // LW or SW
                        next_state = MEMORY;
                        $display("EXECUTE: LW - rs1 = x%0d, reg_rd1 = 0x%x, imm = 0x%x", rs1, reg_rd1, imm);
                    end else begin
                        next_state = WRITEBACK;
                    end
                end
            end
            MEMORY: begin
                if (opcode == 7'b0000011) begin // LW
                    s_dbus_add_o = alu_result;
                    s_dbus_write_o = 1'b0;
                    memory_data_reg <= s_dbus_val_i; 
                    $display("MEMORY: Reading from address 0x%x, data = 0x%x", alu_result, s_dbus_val_i);
                    next_state = WRITEBACK; 
                end else if (opcode == 7'b0100011) begin // SW
                    s_dbus_add_o = alu_result & ~3;
                    s_dbus_write_o = 1'b1;
                    s_dbus_val_o = reg_rd2;
                    $display("MEMORY: Storing register x%d (0x%x) to address 0x%x", rs2, reg_rd2, s_dbus_add_o);
                    next_state = WRITEBACK;
                end
            end
            WRITEBACK: begin
                if (opcode == 7'b0000011) begin // LW
                    reg_write_enable = 1'b1;
                    reg_write_data = memory_data_reg; 
                    $display("WRITEBACK: Loaded data %h into register x%0d", memory_data_reg, rd);
                end else if (opcode == 7'b0010011 || opcode == 7'b0110011) begin 
                    reg_write_enable = 1'b1;
                    reg_write_data = alu_result;
                    $display("WRITEBACK: Register x%0d updated with value %h", rd, reg_write_data);

                end
                next_state = FETCH;
            end
            default: begin
                next_state = FETCH;
            end
        endcase

        if (~s_resetn_i) begin
            pc_next = s_boot_add_i;
        end
    end

    function logic branch_taken;
        case (funct3)
            3'b000: branch_taken = (reg_rd1 == reg_rd2);           // BEQ
            3'b001: branch_taken = (reg_rd1 != reg_rd2);           // BNE
            3'b100: branch_taken = ($signed(reg_rd1) < $signed(reg_rd2)); // BLT
            3'b101: branch_taken = ($signed(reg_rd1) >= $signed(reg_rd2)); // BGE
            3'b110: branch_taken = (reg_rd1 < reg_rd2);            // BLTU
            3'b111: branch_taken = (reg_rd1 >= reg_rd2);           // BGEU
            default: branch_taken = 1'b0;
        endcase
    endfunction


endmodule
