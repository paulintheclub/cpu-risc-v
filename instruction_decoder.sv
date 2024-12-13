module instruction_decoder (
    input  logic [31:0] instruction,  
    output logic [6:0]  opcode,         
    output logic [4:0]  rd,              
    output logic [2:0]  funct3,           
    output logic [4:0]  rs1,               
    output logic [4:0]  rs2,               
    output logic [6:0]  funct7,           
    output logic [31:0] imm,               
    output logic valid,
    output logic is_mul                     
);


    assign opcode = instruction[6:0];

    always_comb begin
        rd      = 5'b0;
        funct3  = 3'b0;
        rs1     = 5'b0;
        rs2     = 5'b0;
        funct7  = 7'b0;
        imm     = 32'b0;
        valid   = 1'b1;  
        is_mul  = 1'b0;  

        $display("Opcode in decoder %b", opcode);

        case (opcode)
            7'b0110011: begin  
// R-Type (ADD, SUB, AND, OR, MUL, MULH, MULHU, MULHSU)

                rd     = instruction[11:7];
                funct3 = instruction[14:12];
                rs1    = instruction[19:15];
                rs2    = instruction[24:20];
                funct7 = instruction[31:25];
                imm    = 32'b0;

                if (funct7 == 7'b0000001 && 
                   (funct3 == 3'b000 || funct3 == 3'b001 || funct3 == 3'b010 || funct3 == 3'b011)) begin
                    is_mul = 1'b1;
                    $display("DECODE: R-Type (Mul Instruction) - rs1 = x%0d, rs2 = x%0d, funct3 = %b, funct7 = %b", rs1, rs2, funct3, funct7);
                end else begin
                    $display("DECODE: R-Type (Non-Mul Instruction)");
                end
            end
  
            7'b0000011: begin
// I-Type (LW)
                rd     = instruction[11:7];
                funct3 = instruction[14:12];
                rs1    = instruction[19:15];
                rs2    = 5'b0; 
                funct7 = instruction[31:25];
                imm    = {{20{instruction[31]}}, instruction[31:20]}; 
                $display("Opcode is I-Type (Load)");
            end

            7'b1100111: begin
// I-Type (JALR)
                rd     = instruction[11:7];
                funct3 = instruction[14:12];
                rs1    = instruction[19:15];
                rs2    = 5'b0; 
                funct7 = instruction[31:25];
                imm    = {{20{instruction[31]}}, instruction[31:20]}; 
                $display("Opcode is I-Type (JALR)");
            end

            7'b0010011: begin
// I-Type (ADDI, SRAI, etc.)
                rd     = instruction[11:7];
                funct3 = instruction[14:12];
                rs1    = instruction[19:15];
                rs2    = 5'b0; 
                funct7 = instruction[31:25];
                imm    = {{20{instruction[31]}}, instruction[31:20]}; 
                $display("Opcode is I-Type (Arithmetic)");
            end

            7'b0100011: begin
// S-Type (SW)
                rd     = 5'b0;
                funct3 = instruction[14:12];
                rs1    = instruction[19:15];
                rs2    = instruction[24:20];
                funct7 = 7'b0; 
                imm    = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
                $display("Opcode is S-Type (SW)");
            end

            7'b1100011: begin
// B-Type (BEQ, BNE)
                rd     = 5'b0; 
                funct3 = instruction[14:12];
                rs1    = instruction[19:15];
                rs2    = instruction[24:20];
                funct7 = 7'b0; 
                imm    = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0}; 
            end

            7'b1101111: begin
// J-Type (JAL)
                rd     = instruction[11:7];
                funct3 = 3'b0; 
                rs1    = 5'b0;
                rs2    = 5'b0; 
                funct7 = 7'b0; 
                imm    = {{11{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0}; 
                $display("J-Type (JAL)");
            end

            7'b0010111: begin
            // U-Type (AUIPC)
                rd     = instruction[11:7];
                funct3 = 3'b0; 
                rs1    = 5'b0;
                rs2    = 5'b0;
                funct7 = 7'b0; 
                imm    = {instruction[31:12], 12'b0};
                $display("U-Type (AUIPC)");
            end
            7'b0110111: begin
            // U-Type (LUI)
                rd     = instruction[11:7];
                funct3 = 3'b0; 
                rs1    = 5'b0;
                rs2    = 5'b0;
                funct7 = 7'b0; 
                imm    = {instruction[31:12], 12'b0};
                $display("U-Type (LUI)");
            end

            default: begin
                valid = 1'b0;
                imm   = 32'b0;
            end
        endcase
    end

endmodule
