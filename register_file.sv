module register_file (
    input logic s_clk,
    input logic s_reset,
    input logic [4:0] rs1, rs2, rd,
    input logic [31:0] wd,
    input logic we,
    output logic [31:0] rd1, rd2
);

    logic [31:0] regs [31:0];

    always_ff @(posedge s_clk or posedge s_reset) begin
        if (s_reset) begin
            for (int i = 1; i < 32; i++) begin
                regs[i] <= 32'b0;
            end
            $display("REGISTER_FILE: Reset - All registers set to 0");
        end else if (we && rd != 5'd0) begin
            regs[rd] <= wd; 
            $display("REGISTER_FILE: Register x%0d updated to 0x%x", rd, wd);
        end
    end


    assign rd1 = (rs1 == 5'd0) ? 32'b0 : regs[rs1]; 
    assign rd2 = (rs2 == 5'd0) ? 32'b0 : regs[rs2]; 

endmodule
