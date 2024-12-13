module multiplier (
    input logic s_clk_i,
    input logic s_resetn_i,
    input logic s_compute_i,
    input logic s_cancel_i, 
    input logic [31:0] s_multiplicand_i,
    input logic [31:0] s_multiplier_i,
    output logic s_busy_o,
    output logic [63:0] s_result_o
);

    logic [63:0] multiplicand;
    logic [31:0] multiplier;
    logic [63:0] product;
    logic [5:0] count;

    always_ff @(posedge s_clk_i or negedge s_resetn_i) begin
        if (!s_resetn_i) begin
            product <= 64'd0;
            count <= 6'd0;
            s_busy_o <= 1'b0;
            s_result_o <= 64'd0;
        end else if (s_cancel_i && s_busy_o) begin
            product <= 64'd0;
            count <= 6'd0;
            s_busy_o <= 1'b0;
            s_result_o <= 64'd0;
        end else if (s_compute_i && !s_busy_o) begin
            multiplicand <= {32'b0, s_multiplicand_i}; 
            multiplier <= s_multiplier_i;
            product <= 64'd0;
            count <= 6'd32;
            s_busy_o <= 1'b1; 
        end else if (s_busy_o && count > 0) begin
            if (multiplier[0]) begin
                product <= product + multiplicand;
            end
            multiplicand <= multiplicand << 1;
            multiplier <= multiplier >> 1;
            count <= count - 1;
        end else if (count == 0 && s_busy_o) begin
            s_busy_o <= 1'b0; 
            s_result_o <= product; 
        end
    end
endmodule
