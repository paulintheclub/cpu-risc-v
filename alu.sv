module alu (
    input  logic         s_clk,
    input  logic         s_reset,
    input  logic [31:0]  a, b,
    input  logic [2:0]   funct3,
    input  logic [6:0]   funct7,
    input  logic [31:0]  imm,
    input  logic         is_imm,
    input  logic         is_store,
    input  logic         is_load,
    input  logic         is_mul,
    output logic         busy, 
    output logic [31:0]  result,
    output logic         mul_done
);

    logic s_compute_mult;
    logic s_busy_mult;
    logic [63:0] s_result_mult;
    logic s_cancel_mult;

    logic signed_a, signed_b;
    always_comb begin
        signed_a = 1'b0;
        signed_b = 1'b0;
        if (is_mul) begin
            case(funct3)
                3'b000, 3'b001: begin // MUL, MULH
                    signed_a = 1'b1; 
                    signed_b = 1'b1;
                end
                3'b010: begin // MULHSU
                    signed_a = 1'b1;
                    signed_b = 1'b0;
                end
                3'b011: begin // MULHU
                    signed_a = 1'b0;
                    signed_b = 1'b0;
                end
                default: begin
                    signed_a = 1'b0;
                    signed_b = 1'b0;
                end
            endcase
        end
    end

    logic [31:0] opA, opB;
    logic res_neg;
    always_comb begin
        res_neg = 1'b0;
        opA = a;
        opB = b;
        if (is_mul) begin
            if (signed_a && a[31]) begin
                opA = (~a + 1'b1);
                res_neg = ~res_neg;
            end
            if (signed_b && b[31]) begin
                opB = (~b + 1'b1);
                res_neg = ~res_neg;
            end
        end
    end

    multiplier mult_inst (
        .s_clk_i(s_clk),
        .s_resetn_i(s_reset),
        .s_compute_i(s_compute_mult),
        .s_cancel_i(s_cancel_mult),
        .s_multiplicand_i(opA),
        .s_multiplier_i(opB),
        .s_busy_o(s_busy_mult),
        .s_result_o(s_result_mult)
    );

    typedef enum logic [1:0] {
        MUL_IDLE,
        MUL_WAIT,
        MUL_DONE_STATE
    } mul_state_t; 

    mul_state_t mul_state, mul_next_state;

    logic [31:0] mul_reg;

    always_ff @(posedge s_clk or negedge s_reset) begin
        if (!s_reset)
            mul_state <= MUL_IDLE;
        else
            mul_state <= mul_next_state;
    end

    always_comb begin
        logic [63:0] final_product;
        logic [31:0] mul_final;

        mul_next_state = mul_state;
        s_compute_mult = 1'b0;
        mul_done = 1'b0; 
        s_cancel_mult = 1'b0;

        case (mul_state)
            MUL_IDLE: begin
                if (is_mul) begin
                    if (!s_busy_mult) begin
                        s_compute_mult = 1'b1;
                        mul_next_state = MUL_WAIT;
                    end
                end
            end
            MUL_WAIT: begin
                if (is_mul) begin
                    if (!s_busy_mult) begin
                        final_product = s_result_mult;
                        if (res_neg) final_product = (~final_product) + 1'b1;

                        case (funct3)
                            3'b000: mul_final = final_product[31:0];    // MUL
                            3'b001: mul_final = final_product[63:32];   // MULH
                            3'b010: mul_final = final_product[63:32];   // MULHSU
                            3'b011: mul_final = final_product[63:32];   // MULHU
                            default: mul_final = 32'b0;
                        endcase

                        mul_reg = mul_final;
                        mul_next_state = MUL_DONE_STATE;
                    end
                end else begin
                    mul_next_state = MUL_IDLE;
                    s_cancel_mult = 1'b1;
                end
            end
            MUL_DONE_STATE: begin
                mul_done = 1'b1;
                if (!is_mul)
                    mul_next_state = MUL_IDLE;
                else if (is_mul && !s_busy_mult) begin
                    mul_next_state = MUL_IDLE;
                end
            end
        endcase
    end

    assign busy = (mul_state == MUL_WAIT) || (mul_state == MUL_IDLE && is_mul && s_busy_mult);

    logic [31:0] normal_result;
    always_comb begin
        normal_result = 32'b0;
        if (is_store) begin
            normal_result = a + b;
        end else if (is_load) begin
            normal_result = a + imm;
        end else if (!is_mul) begin
            case (funct3)
                3'b000: normal_result = is_imm ? a + imm : (funct7[5] ? a - b : a + b);
                3'b001: normal_result = a << (is_imm ? imm[4:0] : b[4:0]);
                3'b010: normal_result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
                3'b011: normal_result = (a < b) ? 32'd1 : 32'd0;
                3'b100: normal_result = a ^ (is_imm ? imm : b);
                3'b101: begin
                    if (funct7[5]) begin // SRA
                        normal_result = $signed(a) >>> (is_imm ? imm[4:0] : b[4:0]);
                    end else begin // SRL
                        normal_result = a >> (is_imm ? imm[4:0] : b[4:0]);
                    end
                end
                3'b110: normal_result = a | (is_imm ? imm : b);
                3'b111: normal_result = a & (is_imm ? imm : b);
                default: normal_result = 32'b0;
            endcase
        end
    end

    always_comb begin
        if (is_mul) begin
            case (mul_state)
                MUL_IDLE: begin

                end
                MUL_WAIT: begin
                    result = 32'b0;
                end
                MUL_DONE_STATE: begin
                    result = mul_reg;
                end
            endcase
        end else begin
            result = normal_result;
        end
    end

endmodule
